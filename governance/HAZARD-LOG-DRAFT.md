# Clinical Risk — Hazard Log & Safety Case (DRAFT / PRE-POPULATED)

> **DRAFT. NOT an approved Clinical Safety Case.** DCB0129 (manufacturer) /
> DCB0160 (deploying org) are **mandatory** for clinical software and require a
> **Clinical Safety Officer (CSO)** — a registered, suitably-qualified clinician —
> to own the Hazard Log, assign risk scores, and approve the Safety Case Report.
> This file is an engineering-prepared starting point: it captures the hazards the
> build has been tracking and the mitigations already in code, in the standard
> format, so the CSO starts from structured content. **All risk ratings and the
> sign-off are `%%PLACEHOLDER%%` for the CSO.** Not evidence of clinical safety
> assurance; confers no compliance.

## Clinical Safety Officer & approval (to be completed)
| Item | Value |
|---|---|
| Clinical Safety Officer | `%%CSO_NAME%% (registered clinician)` |
| CSO registration / qualification | `%%DETAIL%%` |
| Safety Case Report status | `%%DRAFT/APPROVED%%` |
| Approval date | `%%DATE%%` |
| Review trigger | every material change + at `%%INTERVAL%%` |

## Risk matrix (DCB0129 standard — for reference; CSO applies it)
Likelihood × Consequence → 1–5 risk score. Consequence ranges from *Minor* (no/low
harm) to *Catastrophic* (death/multiple severe). **The CSO assigns initial and
residual scores; the values below are deliberately left blank.**

---

## Hazard Log

### HAZ-01 — Irreversible wrongful removal from a surgical waiting list
- **Hazard:** a patient is removed from the waitlist when they should not be (delayed
  or missed surgery → clinical deterioration).
- **Cause(s):** one-tap "I no longer need this"; mis-delivered SMS; mistaken tap.
- **Effect:** lost surgical slot; potential harm from delay.
- **Initial risk:** `%%CSO RATE%%`
- **Mitigations in place (code):**
  - Patient path **cannot hard-cancel** — it writes only the reversible
    `PENDING_CANCELLATION` (RLS `WITH CHECK`), never `CANCELLED`.
  - Frontend **confirmation gate**; the safe "keep my place" option is focused first.
  - Clinician-only `resolve_cancellation()` makes the CANCELLED/REINSTATE decision,
    fully audited (`cancellation_reviews`).
- **Residual risk:** `%%CSO RATE%%`
- **Owner / further action:** define + staff the clinical-review SOP that consumes
  `PENDING_CANCELLATION`; `%%CSO%%`.

### HAZ-02 — Wrong-recipient data exposure / action
- **Hazard:** SMS link reaches the wrong person, who sees data or acts on it.
- **Mitigations:** PII-free URL (UUID only); single-use, expiring token; confirmation
  gate; reversible soft-state so any wrong action is recoverable.
- **Initial / residual risk:** `%%CSO RATE%%`
- **Further action:** `%%confirm tamper-evident audit of who responded%%`.

### HAZ-03 — "Symptoms worsened" response has no urgent-routing SLA
- **Hazard:** a patient signals deterioration but no timely clinical follow-up occurs.
- **Status:** the system **records** `SYMPTOMS_WORSENED` but does not itself route it.
- **Initial risk:** `%%CSO RATE%%`
- **Mitigation required (non-code):** define the clinical pathway + response-time
  guarantee that consumes these responses. **OPEN — `%%CSO/Trust%%`.**

### HAZ-04 — Patient sees another patient's record (mis-identification)
- **Hazard:** wrong record shown → wrong clinical info, confidentiality breach.
- **Mitigations:** RLS isolation on `auth.uid()`; identity match requires a **verified
  P9 NHS Login** number (`link_my_waitlist_record`); fail-closed when unmatched.
- **Initial / residual risk:** `%%CSO RATE%%`
- **Further action:** verify NHS Login claim mapping in the live integration.

### HAZ-05 — Proxy access shows the wrong / non-consented record
- **Hazard:** a proxy sees a record they should not (no/withdrawn consent, expired).
- **Mitigations:** `patient_proxies` requires active+consented+in-window; staff-gated
  grant; `has_proxy_access` fail-closed; ships with zero grants.
- **Initial / residual risk:** `%%CSO RATE%%`
- **Further action (non-code):** Caldicott consent + identity verification of both
  parties; lawful basis for under-16s / incapacity. **OPEN — `%%Caldicott%%`.**

### HAZ-06 — Stale data shown due to caching
- **Hazard:** patient acts on out-of-date status.
- **Mitigations:** asset cache-busting; status read live under RLS at view time.
- **Initial risk:** `%%CSO RATE%%`; **action:** `%%confirm acceptable staleness window%%`.

### HAZ-07 — `%%ADD hazards identified during clinical review%%`
- Each new feature must trigger a hazard review (living log).

---

## Safety Case summary (CSO to author)
- **Scope of clinical use:** `%%DESCRIBE%%`
- **Residual risk acceptable for deployment?** `%%CSO DECISION%%`
- **Conditions / contraindications of use:** `%%LIST%%`
- **Post-deployment surveillance:** how incidents feed back to this log
  (`SECURITY-INCIDENT.md` links operational incidents to clinical review).

_Draft prepared 2026-06-01 (engineering). Clinical ownership: `%%CSO_NAME%%`. This draft confers no clinical-safety assurance._
