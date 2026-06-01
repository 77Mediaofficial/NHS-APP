/* =========================================================================
   NHS Staff Console — clinical-review worklist + proxy management
   Pure vanilla JS + Supabase JS client (CDN global `supabase`).

   SECURITY MODEL:
   - Authenticated STAFF surface. In production, sign-in must carry the
     `hospital_id` JWT claim; the worklist read is scoped by admin RLS
     (hospital_id = auth.current_hospital_id()), and the actions call the
     SECURITY DEFINER RPCs that re-check that scope server-side:
       • resolve_cancellation(entry_id, decision, note)
       • grant_proxy_access(subject, proxy, relationship, valid_until, note)  [staff-gated]
       • revoke_proxy_access(subject, proxy)
   - This file NEVER trusts the client for authorisation — every mutation goes
     through an RPC whose server-side checks are the real control.
   - DEV/MOCK: when Supabase is NOT configured, a mock session + sample worklist
     make the workflow previewable. The mock can never run in a configured deploy.
   - No credentials stored in the repo; env.js holds only the PUBLIC url + anon key.
   ========================================================================= */
(() => {
  "use strict";

  const SUPABASE_URL = window.__ENV?.SUPABASE_URL || "%%SUPABASE_URL%%";
  const SUPABASE_ANON_KEY = window.__ENV?.SUPABASE_ANON_KEY || "%%SUPABASE_ANON_KEY%%";
  const configured =
    SUPABASE_URL && !SUPABASE_URL.startsWith("%%") &&
    SUPABASE_ANON_KEY && !SUPABASE_ANON_KEY.startsWith("%%");

  let db = null;
  if (configured && window.supabase?.createClient) {
    db = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true },
    });
  }
  const devMock = !db;

  const els = {
    login:        document.getElementById("login"),
    console:      document.getElementById("console"),
    staffSignin:  document.getElementById("staffSignin"),
    staffEmail:   document.getElementById("staffEmail"),
    staffPassword:document.getElementById("staffPassword"),
    staffSubmit:  document.getElementById("staffSubmit"),
    loginError:   document.getElementById("loginError"),
    signOut:      document.getElementById("signOut"),
    hospitalLabel:document.getElementById("hospitalLabel"),
    worklist:     document.getElementById("worklist"),
    worklistEmpty:document.getElementById("worklistEmpty"),
    pxSubject:    document.getElementById("pxSubject"),
    pxProxy:      document.getElementById("pxProxy"),
    pxRel:        document.getElementById("pxRel"),
    pxGrant:      document.getElementById("pxGrant"),
    pxRevoke:     document.getElementById("pxRevoke"),
    proxyMsg:     document.getElementById("proxyMsg"),
    consoleError: document.getElementById("consoleError"),
  };

  // ---- Helpers ------------------------------------------------------------
  const show = (el) => { if (el) el.hidden = false; };
  const hide = (el) => { if (el) el.hidden = true; };
  const setMsg = (el, msg, kind) => {
    if (!el) return;
    el.textContent = msg; el.hidden = !msg;
    el.dataset.kind = kind || "";
  };
  const setBusy = (btn, busy) => { if (btn) { btn.setAttribute("aria-busy", String(busy)); btn.disabled = busy; } };
  const fmtDate = (v) => {
    if (!v) return "—";
    const d = new Date(v);
    return isNaN(d) ? String(v) : d.toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
  };
  const esc = (s) => String(s == null ? "" : s).replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

  // ---- Mock state (dev only) ---------------------------------------------
  let mockRows = [
    { id: "11111111-1111-1111-1111-111111111111", procedure: "Total Hip Replacement", referred_at: "2026-02-10", status: "PENDING_CANCELLATION" },
    { id: "22222222-2222-2222-2222-222222222222", procedure: "Cataract Surgery",       referred_at: "2026-03-22", status: "PENDING_CANCELLATION" },
  ];

  // ---- Views --------------------------------------------------------------
  function showLogin() { hide(els.console); show(els.login); if (els.staffEmail) els.staffEmail.focus(); }
  function showConsole() { hide(els.login); show(els.console); }

  function route(session) {
    if (session && session.user) {
      showConsole();
      els.hospitalLabel.textContent = devMock ? "Demo Hospital (mock)" : "Your hospital";
      loadWorklist();
    } else {
      showLogin();
    }
  }

  // ---- Worklist (entries awaiting clinical review) ------------------------
  async function loadWorklist() {
    setMsg(els.consoleError, "", "");
    let rows = [];
    try {
      if (devMock) {
        rows = mockRows.filter((r) => r.status === "PENDING_CANCELLATION");
      } else {
        // Admin RLS scopes this to the staff member's own hospital. We request only
        // the non-identifying columns the worklist needs (no nhs_number to the client).
        const { data, error } = await db
          .from("waitlist_entries")
          .select("id, procedure, referred_at, status")
          .eq("status", "PENDING_CANCELLATION")
          .order("referred_at", { ascending: true });
        if (error) throw error;
        rows = data || [];
      }
    } catch (err) {
      console.error("worklist load failed:", err);
      setMsg(els.consoleError, "We couldn’t load the worklist right now. Please try again.", "error");
    }
    renderWorklist(rows);
  }

  function renderWorklist(rows) {
    els.worklist.innerHTML = "";
    if (!rows.length) { show(els.worklistEmpty); return; }
    hide(els.worklistEmpty);
    for (const r of rows) {
      const li = document.createElement("li");
      li.className = "wl-item";
      li.innerHTML =
        '<div class="wl-item__body">' +
          '<p class="wl-item__proc">' + esc(r.procedure || "Procedure") + "</p>" +
          '<p class="wl-item__meta">Referred ' + esc(fmtDate(r.referred_at)) +
            ' · entry <code>' + esc(String(r.id).slice(0, 8)) + "…</code></p>" +
        "</div>" +
        '<div class="wl-item__actions">' +
          '<button class="btn btn--primary" type="button" data-act="reinstate" data-id="' + esc(r.id) + '">Reinstate</button>' +
          '<button class="btn btn--danger" type="button" data-act="confirm" data-id="' + esc(r.id) + '">Confirm cancellation</button>' +
        "</div>";
      els.worklist.appendChild(li);
    }
  }

  async function resolve(entryId, decision, btn) {
    // decision: 'REINSTATE' | 'CONFIRM_CANCELLATION'
    setBusy(btn, true);
    setMsg(els.consoleError, "", "");
    try {
      if (devMock) {
        await new Promise((r) => setTimeout(r, 350));
        mockRows = mockRows.map((r) => r.id === entryId
          ? { ...r, status: decision === "REINSTATE" ? "ACTIVE" : "CANCELLED" } : r);
      } else {
        const { error } = await db.rpc("resolve_cancellation", {
          p_entry_id: entryId, p_decision: decision, p_note: null,
        });
        if (error) throw error;
      }
      await loadWorklist();
    } catch (err) {
      console.error("resolve failed:", err);
      setBusy(btn, false);
      setMsg(els.consoleError,
        "That action didn’t complete. The entry may have already been resolved — refresh and check.", "error");
    }
  }

  // ---- Proxy management ---------------------------------------------------
  async function grantProxy() {
    const subject = (els.pxSubject.value || "").trim();
    const proxy   = (els.pxProxy.value || "").trim();
    const rel     = (els.pxRel.value || "").trim();
    if (!subject || !proxy || !rel) { setMsg(els.proxyMsg, "Enter subject, proxy, and relationship.", "error"); return; }
    setBusy(els.pxGrant, true); setMsg(els.proxyMsg, "", "");
    try {
      if (devMock) {
        await new Promise((r) => setTimeout(r, 350));
        setMsg(els.proxyMsg, "Demo: would record a GRANTED proxy (real grant needs Caldicott consent + staff auth).", "ok");
      } else {
        const { error } = await db.rpc("grant_proxy_access", {
          p_subject: subject, p_proxy: proxy, p_relationship: rel, p_valid_until: null, p_note: null,
        });
        if (error) throw error;
        setMsg(els.proxyMsg, "Proxy access granted.", "ok");
      }
    } catch (err) {
      console.error("grant failed:", err);
      setMsg(els.proxyMsg, "Grant failed — you may not be authorised, or the IDs are invalid.", "error");
    } finally {
      setBusy(els.pxGrant, false);
    }
  }

  async function revokeProxy() {
    const subject = (els.pxSubject.value || "").trim();
    const proxy   = (els.pxProxy.value || "").trim();
    if (!subject || !proxy) { setMsg(els.proxyMsg, "Enter subject and proxy to revoke.", "error"); return; }
    setBusy(els.pxRevoke, true); setMsg(els.proxyMsg, "", "");
    try {
      if (devMock) {
        await new Promise((r) => setTimeout(r, 350));
        setMsg(els.proxyMsg, "Demo: would revoke the proxy relationship.", "ok");
      } else {
        const { data, error } = await db.rpc("revoke_proxy_access", { p_subject: subject, p_proxy: proxy });
        if (error) throw error;
        const n = (data && data.revoked) || 0;
        setMsg(els.proxyMsg, n ? "Proxy access revoked." : "No active relationship found to revoke.", "ok");
      }
    } catch (err) {
      console.error("revoke failed:", err);
      setMsg(els.proxyMsg, "Revoke failed. Please try again.", "error");
    } finally {
      setBusy(els.pxRevoke, false);
    }
  }

  // ---- Auth lifecycle -----------------------------------------------------
  if (db) {
    db.auth.onAuthStateChange((_e, session) => route(session));
    db.auth.getSession().then(({ data }) => route(data.session)).catch(() => showLogin());
  } else {
    const params = new URLSearchParams(location.search);
    if (params.get("demo")) {
      route({ user: { email: "clinician@example.nhs.uk" } });
    } else {
      showLogin();
    }
  }

  // ---- Events -------------------------------------------------------------
  if (els.staffSignin) {
    els.staffSignin.addEventListener("submit", async (e) => {
      e.preventDefault();
      setMsg(els.loginError, "", "");
      const email = (els.staffEmail.value || "").trim();
      const password = els.staffPassword.value || "";
      if (!email || !password) { setMsg(els.loginError, "Enter your email and password.", "error"); return; }
      setBusy(els.staffSubmit, true);
      try {
        if (devMock) {
          await new Promise((r) => setTimeout(r, 400));
          route({ user: { email } });
        } else {
          const { error } = await db.auth.signInWithPassword({ email, password });
          if (error) throw error;
        }
      } catch (err) {
        console.error("staff sign-in failed:", err);
        setMsg(els.loginError, "We couldn’t sign you in. Check your details and try again.", "error");
      } finally {
        setBusy(els.staffSubmit, false);
        if (els.staffPassword) els.staffPassword.value = "";
      }
    });
  }

  if (els.signOut) {
    els.signOut.addEventListener("click", async () => {
      if (db) { try { await db.auth.signOut(); } catch (_) {} }
      route(null);
    });
  }

  // Event delegation for the worklist action buttons.
  if (els.worklist) {
    els.worklist.addEventListener("click", (e) => {
      const btn = e.target.closest("button[data-act]");
      if (!btn) return;
      const id = btn.getAttribute("data-id");
      const act = btn.getAttribute("data-act");
      if (act === "reinstate") resolve(id, "REINSTATE", btn);
      else if (act === "confirm") resolve(id, "CONFIRM_CANCELLATION", btn);
    });
  }

  if (els.pxGrant) els.pxGrant.addEventListener("click", grantProxy);
  if (els.pxRevoke) els.pxRevoke.addEventListener("click", revokeProxy);
})();
