/* =========================================================================
   NHS Waitlist Validation — patient response logic
   Pure vanilla JS + Supabase JS client (loaded via CDN as `supabase`).

   Security: patients are unauthenticated. They never write to tables directly.
   Every submission calls the SECURITY DEFINER RPC submit_validation_response(),
   which validates a single-use token server-side before recording anything.

   Clinical safety (DCB0129/0160): the destructive "no longer need it" response
   is gated behind an explicit confirmation step before it is ever sent, and the
   backend only moves the entry to a REVERSIBLE 'PENDING_CANCELLATION' soft-state
   for clinical review — never a hard cancel on a single tap.
   ========================================================================= */

(() => {
  "use strict";

  // ---- Configuration -------------------------------------------------------
  // The anon key is PUBLIC by design — safe to ship to the browser. It grants
  // only EXECUTE on the validation RPC; the underlying tables are locked down.
  // On Vercel, inject these at build time or replace before deploy.
  const SUPABASE_URL = window.__ENV?.SUPABASE_URL || "%%SUPABASE_URL%%";
  const SUPABASE_ANON_KEY = window.__ENV?.SUPABASE_ANON_KEY || "%%SUPABASE_ANON_KEY%%";

  // The patient's single-use token arrives via a signed link. The canonical SMS
  // link spec uses ?t=<token> (short, data-minimised). Accept the legacy ?token=
  // as a fallback so any links already issued keep working.
  const params = new URLSearchParams(window.location.search);
  const TOKEN = params.get("t") || params.get("token");

  // Each button maps to a response_type enum value. The semantics
  // (still_needs_care, symptoms_worsened) are derived SERVER-SIDE, not here.
  const RESPONSE_TYPE = {
    confirm:  "STILL_WAITING",
    worsened: "SYMPTOMS_WORSENED",
    decline:  "NO_LONGER_NEEDED",
  };

  // Destructive responses are not sent on a single tap — they route through the
  // confirmation gate first (DCB0129/0160 mis-tap / wrong-recipient mitigation).
  const NEEDS_CONFIRMATION = new Set(["decline"]);

  const SUCCESS_DETAIL = {
    confirm:  "You remain on the waiting list. We'll be in touch with your appointment.",
    worsened: "A clinician will review your case. If your condition is urgent, call 111 or 999.",
    decline:  "Your care team will review your request before your place is removed. If you change your mind, contact the number on your appointment letter.",
  };

  // ---- Elements ------------------------------------------------------------
  const els = {
    question:     document.getElementById("question"),
    confirm:      document.getElementById("confirm"),
    confirmYes:   document.getElementById("confirmYes"),
    confirmNo:    document.getElementById("confirmNo"),
    confirmError: document.getElementById("confirmError"),
    success:      document.getElementById("success"),
    detail:       document.getElementById("successDetail"),
    error:        document.getElementById("error"),
    // Only the primary question buttons — confirm buttons are wired separately.
    buttons:      Array.from(document.querySelectorAll("#question .choice")),
  };

  // ---- Supabase client -----------------------------------------------------
  let db = null;
  const configured =
    SUPABASE_URL && !SUPABASE_URL.startsWith("%%") &&
    SUPABASE_ANON_KEY && !SUPABASE_ANON_KEY.startsWith("%%");

  if (configured && window.supabase?.createClient) {
    db = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  }

  // In production a missing token means the link is invalid — block submission.
  // In local dev (no Supabase configured) we allow a mock run without a token.
  const devMock = !db;

  // Every interactive control, for global enable/disable.
  const allControls = () =>
    [...els.buttons, els.confirmYes, els.confirmNo].filter(Boolean);

  // ---- UI helpers ----------------------------------------------------------
  function showError(message, target) {
    const el = target || els.error;
    el.textContent = message;
    el.hidden = false;
  }
  function clearErrors() {
    [els.error, els.confirmError].forEach((el) => {
      if (el) { el.hidden = true; el.textContent = ""; }
    });
  }

  function setButtonsDisabled(disabled) {
    allControls().forEach((btn) => { btn.disabled = disabled; });
  }

  function setBusy(activeButton, busy) {
    allControls().forEach((btn) => {
      btn.disabled = busy;
      if (btn === activeButton) btn.setAttribute("aria-busy", String(busy));
      else btn.removeAttribute("aria-busy");
    });
  }

  // ---- State transitions ---------------------------------------------------
  function showConfirm() {
    clearErrors();
    els.question.hidden = true;
    els.confirm.hidden = false;
    els.confirm.scrollIntoView({ behavior: "smooth", block: "center" });
    // Focus the SAFE default so a keyboard/screen-reader user doesn't land on
    // the destructive option.
    if (els.confirmNo) els.confirmNo.focus();
  }

  function hideConfirm() {
    clearErrors();
    els.confirm.hidden = true;
    els.question.hidden = false;
  }

  function showSuccess(responseKey) {
    els.detail.textContent = SUCCESS_DETAIL[responseKey] || "";
    els.question.hidden = true;
    els.confirm.hidden = true;
    els.success.hidden = false;
    els.success.scrollIntoView({ behavior: "smooth", block: "center" });
    // Move focus to the outcome so screen-reader and keyboard users are taken to
    // the confirmation message (the role="status" region also announces it).
    if (typeof els.success.focus === "function") els.success.focus();
  }

  // ---- Submit --------------------------------------------------------------
  async function submitResponse(responseKey, button) {
    // Surface errors next to whichever panel the user is actually looking at.
    const errorTarget =
      els.confirm && !els.confirm.hidden ? els.confirmError : els.error;

    clearErrors();
    setBusy(button, true);

    try {
      if (db) {
        const { error } = await db.rpc("submit_validation_response", {
          p_token: TOKEN,
          p_response_type: RESPONSE_TYPE[responseKey],
        });
        if (error) throw error;
      } else {
        // Local/dev fallback so the UI is demonstrable without credentials.
        console.warn("[dev] Supabase not configured — mock submit:", {
          token: TOKEN, response_type: RESPONSE_TYPE[responseKey],
        });
        await new Promise((r) => setTimeout(r, 600));
      }
      showSuccess(responseKey);
    } catch (err) {
      console.error("Submission failed:", err);
      const message = String(err?.message || "");
      if (message.includes("INVALID_OR_EXPIRED_TOKEN")) {
        showError("This validation link is invalid, expired, or has already been used. Please use the most recent link we sent you.", errorTarget);
        setButtonsDisabled(true);
      } else {
        showError("Sorry — we couldn't record your response. Please try again.", errorTarget);
        setBusy(button, false);
      }
    }
  }

  // ---- Init ----------------------------------------------------------------
  function init() {
    if (!TOKEN && !devMock) {
      showError("This link is missing its validation code. Please open the link exactly as we sent it to you.");
      setButtonsDisabled(true);
      return;
    }

    els.buttons.forEach((button) => {
      button.addEventListener("click", () => {
        const key = button.dataset.response;
        if (!RESPONSE_TYPE[key]) return;
        if (NEEDS_CONFIRMATION.has(key)) showConfirm();
        else submitResponse(key, button);
      });
    });

    if (els.confirmYes) {
      els.confirmYes.addEventListener("click", () =>
        submitResponse("decline", els.confirmYes));
    }
    if (els.confirmNo) {
      els.confirmNo.addEventListener("click", () => {
        hideConfirm();
        // Return focus to the option the patient originally chose.
        const declineBtn = document.querySelector('#question .choice[data-response="decline"]');
        if (declineBtn) declineBtn.focus();
      });
    }
  }

  init();
})();
