/* =========================================================================
   NHS Patient Hub — authenticated portal logic
   Pure vanilla JS + Supabase JS client (loaded via CDN as `supabase`).

   SECURITY MODEL (strict):
   - This is an AUTHENTICATED portal. There is NO anonymous data path.
   - All reads run under the logged-in user's JWT, so Supabase Row Level
     Security isolates each patient's data server-side.
   - IDOR-safe: data queries pass NO user id. RLS must restrict rows to
     auth.uid() (e.g. USING (patient_user_id = auth.uid())). We never trust
     a client-supplied identifier to choose whose data to load.
   - No credentials are stored in this repo. The "NHS Login" button simulates
     the OIDC flow; for local testing it reveals a form so the tester types
     their own test credentials. Production replaces it with the real NHS
     Login OIDC provider (db.auth.signInWithOAuth).
   ========================================================================= */

(() => {
  "use strict";

  // ---- Config (PUBLIC values only) ----------------------------------------
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
  // No backend configured → local preview mode (mock session, sample data).
  const devMock = !db;

  // ---- Elements -----------------------------------------------------------
  const els = {
    login:       document.getElementById("login"),
    dashboard:   document.getElementById("dashboard"),
    nhsLogin:    document.getElementById("nhsLogin"),
    devSignin:   document.getElementById("devSignin"),
    devEmail:    document.getElementById("devEmail"),
    devPassword: document.getElementById("devPassword"),
    devSubmit:   document.getElementById("devSubmit"),
    loginError:  document.getElementById("loginError"),
    signOut:     document.getElementById("signOut"),
    greeting:    document.getElementById("greeting"),
    proxyToggle: document.getElementById("proxyToggle"),
    proxyBanner: document.getElementById("proxyBanner"),
    wlProcedure: document.getElementById("wlProcedure"),
    wlStatus:    document.getElementById("wlStatus"),
    wlStatusText:document.getElementById("wlStatusText"),
    wlReferred:  document.getElementById("wlReferred"),
    wlHospital:  document.getElementById("wlHospital"),
    dashError:   document.getElementById("dashError"),
  };

  // ---- Small helpers ------------------------------------------------------
  function show(el) { if (el) el.hidden = false; }
  function hide(el) { if (el) el.hidden = true; }
  function setError(el, msg) { if (el) { el.textContent = msg; el.hidden = !msg; } }
  function setBusy(btn, busy) {
    if (!btn) return;
    btn.setAttribute("aria-busy", String(busy));
    btn.disabled = busy;
  }
  function fmtDate(v) {
    if (!v) return "—";
    const d = new Date(v);
    return isNaN(d) ? String(v) : d.toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" });
  }
  function titleCase(s) {
    return String(s || "").toLowerCase().replace(/(^|[\s_])\w/g, (m) => m.toUpperCase()).replace(/_/g, " ");
  }

  // ---- View routing -------------------------------------------------------
  function showLoginView() {
    hide(els.dashboard);
    show(els.login);
    setError(els.loginError, "");
    if (els.nhsLogin) els.nhsLogin.focus();
  }
  function showDashboardView() {
    hide(els.login);
    show(els.dashboard);
  }

  function setGreeting(user) {
    let name = "";
    if (user) {
      const meta = user.user_metadata || {};
      name = meta.full_name || meta.name || meta.given_name ||
             (user.email ? user.email.split("@")[0] : "");
    }
    if (devMock && !name) name = "Joe";
    els.greeting.textContent = name ? `Hello, ${titleCase(name)}.` : "Hello.";
  }

  function renderEntry(entry) {
    if (!entry) {
      els.wlProcedure.textContent = "We don’t have an active waiting-list entry for you.";
      els.wlStatus.textContent = "—";
      els.wlStatus.dataset.status = "";
      return;
    }
    // Read defensively — reconcile field names with the real schema later.
    const procedure = entry.procedure || entry.procedure_name || entry.treatment || "Your procedure";
    const status    = (entry.status || "").toUpperCase();
    const referred  = entry.referred_at || entry.created_at || entry.added_at;
    const hospital  = entry.hospital_name || entry.hospital || "Your hospital";

    els.wlProcedure.textContent = procedure;
    els.wlStatus.textContent = status ? titleCase(status) : "—";
    els.wlStatus.dataset.status = status;
    els.wlStatusText.textContent = status ? titleCase(status) : "—";
    els.wlReferred.textContent = fmtDate(referred);
    els.wlHospital.textContent = hospital;
  }

  // ---- Secure data fetch (IDOR-safe) --------------------------------------
  // RLS restricts rows to the authenticated user (auth.uid()). We pass NO id.
  async function loadMyWaitlist() {
    if (devMock) {
      return {
        procedure: "Total Hip Replacement",
        status: "ACTIVE",
        referred_at: "2026-03-02",
        hospital_name: "Royal Surrey County Hospital",
      };
    }
    const { data, error } = await db
      .from("waitlist_entries")
      .select("*")              // TODO: narrow to explicit columns (data minimisation) once schema confirmed
      .order("created_at", { ascending: false })
      .limit(1);
    if (error) throw error;
    return (data && data[0]) || null;
  }

  async function hydrate(user) {
    setGreeting(user);
    setError(els.dashError, "");
    try {
      renderEntry(await loadMyWaitlist());
    } catch (err) {
      console.error("waitlist load failed:", err);
      // RLS / schema not yet provisioned, or transient error — fail closed & friendly.
      renderEntry(null);
      setError(els.dashError, "We couldn’t load your waiting-list details right now. Please try again later.");
    }
  }

  function route(session) {
    if (session && session.user) {
      showDashboardView();
      hydrate(session.user);
    } else {
      showLoginView();
    }
  }

  // ---- Auth lifecycle -----------------------------------------------------
  if (db) {
    db.auth.onAuthStateChange((_event, session) => route(session));
    db.auth.getSession().then(({ data }) => route(data.session))
      .catch(() => showLoginView());
  } else {
    // Dev preview (no backend configured). `?demo=1` jumps straight to a mock
    // dashboard so the authenticated view is previewable without a real session.
    // DEV-ONLY: this whole branch runs only when Supabase is NOT configured, so it
    // can never bypass real authentication in a deployed (configured) environment.
    const params = new URLSearchParams(location.search);
    if (params.get("demo")) {
      route({ user: { email: "joe@example.nhs.uk", user_metadata: { full_name: "Joe" } } });
    } else {
      showLoginView();
    }
  }

  // ---- Login interactions -------------------------------------------------
  // "Sign in with NHS Login": production -> db.auth.signInWithOAuth({ provider: <NHS OIDC> }).
  // Here it reveals the mock credential form (no creds are stored in the repo).
  if (els.nhsLogin) {
    els.nhsLogin.addEventListener("click", () => {
      hide(els.nhsLogin);
      show(els.devSignin);
      if (els.devEmail) els.devEmail.focus();
    });
  }

  if (els.devSignin) {
    els.devSignin.addEventListener("submit", async (e) => {
      e.preventDefault();
      setError(els.loginError, "");
      const email = (els.devEmail.value || "").trim();
      const password = els.devPassword.value || "";
      if (!email || !password) {
        setError(els.loginError, "Please enter your email and password.");
        return;
      }
      setBusy(els.devSubmit, true);
      try {
        if (devMock) {
          // Local preview only — simulate a verified session. No real auth.
          await new Promise((r) => setTimeout(r, 500));
          route({ user: { email, user_metadata: {} } });
        } else {
          const { error } = await db.auth.signInWithPassword({ email, password });
          if (error) throw error;
          // onAuthStateChange will route to the dashboard.
        }
      } catch (err) {
        console.error("sign-in failed:", err);
        setError(els.loginError, "We couldn’t sign you in. Check your details and try again.");
      } finally {
        setBusy(els.devSubmit, false);
        if (els.devPassword) els.devPassword.value = "";  // never keep the password around
      }
    });
  }

  // ---- Sign out -----------------------------------------------------------
  if (els.signOut) {
    els.signOut.addEventListener("click", async () => {
      if (db) { try { await db.auth.signOut(); } catch (_) {} }
      // Reset mock form state and route to login.
      if (els.devSignin) hide(els.devSignin);
      if (els.nhsLogin) show(els.nhsLogin);
      route(null);
    });
  }

  // ---- Proxy view (MOCK) --------------------------------------------------
  // Real proxy access requires a verified proxy relationship + its own RLS and
  // Caldicott-approved consent. This toggle only demonstrates the UX; it does
  // NOT fetch anyone else's data.
  if (els.proxyToggle) {
    els.proxyToggle.addEventListener("click", () => {
      const on = els.proxyToggle.getAttribute("aria-checked") !== "true";
      els.proxyToggle.setAttribute("aria-checked", String(on));
      if (on) {
        setError(els.proxyBanner, "Demo: proxy view is a placeholder. Real proxy access requires verified authorisation and is not enabled.");
      } else {
        setError(els.proxyBanner, "");
      }
    });
  }
})();
