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

  // ---- NHS Login OIDC provider (PUBLIC config; credentials live in Supabase) ----
  // When the backend is configured AND a provider name is set in env, the "Sign in
  // with NHS Login" button starts the REAL OIDC flow (db.auth.signInWithOAuth).
  // The provider itself (client id/secret, NHS Login issuer URLs, scopes incl.
  // 'nhs_number') is registered in the Supabase dashboard — NEVER in this repo.
  // Empty/absent → the button falls back to the local mock credential form.
  // 👤 NHS Login integration + assurance (real client registration, P9 identity
  // proofing, claim mapping to nhs_number/identity_proofing_level) is a Trust step.
  const NHS_OIDC_PROVIDER = (window.__ENV?.NHS_OIDC_PROVIDER || "").trim();
  const useRealOidc = !devMock && NHS_OIDC_PROVIDER !== "";

  // ---- Session hygiene: idle auto sign-out config -------------------------
  // Patient health data must not stay open on an unattended/shared device. After
  // IDLE_LIMIT_MS of no interaction we warn, then sign the patient out. Configurable
  // via window.__ENV.IDLE_TIMEOUT_MINUTES (default 10). In dev-mock ONLY, ?idle=<minutes>
  // overrides it for quick testing (e.g. ?idle=0.05 ≈ 3s). The warning appears
  // IDLE_WARN_MS before logout so slow readers get an explicit chance to stay.
  let _idleMin = Number(window.__ENV?.IDLE_TIMEOUT_MINUTES) || 10;
  if (devMock) {
    const _q = new URLSearchParams(location.search).get("idle");
    if (_q && Number(_q) > 0) _idleMin = Number(_q);
  }
  const IDLE_LIMIT_MS = Math.max(1000, _idleMin * 60 * 1000);
  const IDLE_WARN_MS = Math.min(60000, Math.floor(IDLE_LIMIT_MS / 2));
  const IDLE_NOTICE = "For your security, you were signed out after a period of inactivity. Please sign in again.";
  let idleTimer = null, warnTimer = null, countdownInt = null, lastActivity = 0;
  let pendingLoginNotice = "";

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
    idleWarning: document.getElementById("idleWarning"),
    idleStay:    document.getElementById("idleStay"),
    idleSignOutNow: document.getElementById("idleSignOutNow"),
    idleCountdown:  document.getElementById("idleCountdown"),
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
    // Preserve any pending notice (e.g. "signed out due to inactivity"); it is
    // cleared when the patient starts interacting with the login screen.
    setError(els.loginError, pendingLoginNotice || "");
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
    // Data minimisation (UK GDPR / COMPLIANCE.md §2): select ONLY the non-PII
    // columns the dashboard renders. Deliberately EXCLUDES nhs_number and
    // patient_user_id — the portal never needs the patient's identifiers in the
    // browser, even though RLS already limits rows to the caller's own record.
    const { data, error } = await db
      .from("waitlist_entries")
      .select("procedure, status, referred_at, created_at")
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
      armIdleTimers();
    } else {
      clearIdleTimers();
      hideIdleWarning();
      showLoginView();
    }
  }

  // ---- Session hygiene: idle auto sign-out --------------------------------
  function isSignedIn() { return els.dashboard && !els.dashboard.hidden; }

  function clearIdleTimers() {
    if (idleTimer) { clearTimeout(idleTimer); idleTimer = null; }
    if (warnTimer) { clearTimeout(warnTimer); warnTimer = null; }
    if (countdownInt) { clearInterval(countdownInt); countdownInt = null; }
  }

  function hideIdleWarning() {
    if (countdownInt) { clearInterval(countdownInt); countdownInt = null; }
    hide(els.idleWarning);
  }

  function armIdleTimers() {
    clearIdleTimers();
    hide(els.idleWarning);
    if (!isSignedIn()) return;
    warnTimer = setTimeout(showIdleWarning, Math.max(0, IDLE_LIMIT_MS - IDLE_WARN_MS));
    idleTimer = setTimeout(function () { performSignOut(IDLE_NOTICE); }, IDLE_LIMIT_MS);
  }

  function showIdleWarning() {
    if (!isSignedIn()) return;
    const logoutAt = Date.now() + IDLE_WARN_MS;
    const tick = function () {
      const secs = Math.max(0, Math.round((logoutAt - Date.now()) / 1000));
      if (els.idleCountdown) {
        els.idleCountdown.textContent =
          "Signing out in " + secs + " second" + (secs === 1 ? "" : "s") + ".";
      }
    };
    tick();
    if (countdownInt) clearInterval(countdownInt);
    countdownInt = setInterval(tick, 1000);
    show(els.idleWarning);
    if (els.idleStay) els.idleStay.focus();
  }

  function onUserActivity() {
    if (!isSignedIn()) return;
    const warningUp = els.idleWarning && !els.idleWarning.hidden;
    const now = Date.now();
    // Throttle re-arming during normal use; but always respond while the warning is up.
    if (!warningUp && now - lastActivity < 1000) return;
    lastActivity = now;
    armIdleTimers();
  }

  async function performSignOut(notice) {
    pendingLoginNotice = notice || "";
    clearIdleTimers();
    hideIdleWarning();
    if (db) { try { await db.auth.signOut(); } catch (_) {} }
    if (els.devSignin) hide(els.devSignin);
    if (els.nhsLogin) show(els.nhsLogin);
    route(null);
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
  // "Sign in with NHS Login":
  //   • Real OIDC (backend configured + NHS_OIDC_PROVIDER set) → redirect to the NHS
  //     Login provider via Supabase Auth. On return, detectSessionInUrl + the
  //     onAuthStateChange handler route to the dashboard.
  //   • Otherwise → reveal the local mock credential form (no creds stored in repo).
  async function startNhsLogin() {
    pendingLoginNotice = "";
    setError(els.loginError, "");
    if (useRealOidc) {
      setBusy(els.nhsLogin, true);
      try {
        const { error } = await db.auth.signInWithOAuth({
          provider: NHS_OIDC_PROVIDER,
          options: { redirectTo: window.location.origin + window.location.pathname },
        });
        if (error) throw error;
        // Success navigates away to the provider; nothing else to do here.
      } catch (err) {
        console.error("NHS Login start failed:", err);
        setError(els.loginError, "We couldn’t start NHS Login right now. Please try again.");
        setBusy(els.nhsLogin, false);
      }
      return;
    }
    // Mock path (local dev / no provider configured).
    hide(els.nhsLogin);
    show(els.devSignin);
    if (els.devEmail) els.devEmail.focus();
  }

  if (els.nhsLogin) {
    els.nhsLogin.addEventListener("click", startNhsLogin);
  }

  if (els.devSignin) {
    els.devSignin.addEventListener("submit", async (e) => {
      e.preventDefault();
      pendingLoginNotice = "";
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
    els.signOut.addEventListener("click", () => performSignOut(""));
  }

  // ---- Idle-warning controls ----------------------------------------------
  if (els.idleStay) {
    els.idleStay.addEventListener("click", () => armIdleTimers());
  }
  if (els.idleSignOutNow) {
    els.idleSignOutNow.addEventListener("click", () => performSignOut(""));
  }

  // Any interaction resets the idle timer (no-op when signed out).
  ["pointerdown", "keydown", "touchstart", "scroll"].forEach((evt) =>
    window.addEventListener(evt, onUserActivity, { passive: true }));

  // ---- Proxy view (UI still a MOCK; backend scaffold now exists) ----------
  // The SERVER-SIDE foundation for real proxy access now exists (migration
  // 20260601030000: patient_proxies + auth.has_proxy_access() + pol_entries_proxy_select
  // + staff-gated grant/revoke RPCs). But this CLIENT toggle is still a UX demo: it does
  // NOT switch identity or fetch anyone else's data, because (a) no proxy relationships
  // are granted (Caldicott consent is a 👤 governance step) and (b) no subject-picker UI
  // is wired. Keep the banner honest until a real grant + picker exist.
  if (els.proxyToggle) {
    els.proxyToggle.addEventListener("click", () => {
      const on = els.proxyToggle.getAttribute("aria-checked") !== "true";
      els.proxyToggle.setAttribute("aria-checked", String(on));
      if (on) {
        setError(els.proxyBanner, "Demo only: proxy view is not active. Viewing someone else’s record requires verified, consented authorisation set up by the hospital — no other person’s data is shown here.");
      } else {
        setError(els.proxyBanner, "");
      }
    });
  }
})();
