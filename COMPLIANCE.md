# NHS Waitlist Validation — Compliance Checklist (LIVING DOCUMENT)

> **This file is the single source of truth for NHS security & privacy compliance.**
> Back-check **every** change to `frontend/` and `supabase/` against this document
> before considering the work done. A hook surfaces this file automatically on edit.

## ⚠️ Authority & limits
This checklist is an engineering aid, **not** a certification. Go-live legally requires
sign-off from the Trust's:
- **Data Protection Officer (DPO)** — UK GDPR / DPA 2018 + DPIA
- **Caldicott Guardian** — duty of confidentiality
- **Clinical Safety Officer (CSO)** — DCB0129 / DCB0160 (mandatory, registered role)

No code change can substitute for these approvals. Do not describe the system as
"compliant" in any artifact — describe it as "built to align with [standard], pending
[role] sign-off."

## DTAC v2 readiness snapshot (self-assessment — NOT a certification)
*Score reflects how ready we are to **submit**, not a pass. Many items are 👤 governance/external
gates that code cannot close. Re-score on each material change. Last scored: 2026-05-29.*

| Pillar | Weight | Readiness | Why |
|---|---|---|---|
| 1. Clinical safety | 25% | ~32 | Hazards mitigated in code + status-domain prereq migration; **no CSO, no formal Hazard Log / Clinical Safety Case Report** 👤 |
| 2. Data protection | 25% | ~45 | Data-minimisation + **token auto-purge, IG-gated response purge, hospital-scoped erasure RPC** now built; **no DPIA, no DSPT, no Caldicott, residency unverified, no at-rest encryption** 👤 |
| 3. Technical security | 20% | ~60 | SRI, CSP, HSTS, hardening headers, forced RLS, single-use tokens, definer hardening, **SSCoP self-declaration, scoped token-link generator**; **no CREST pen test, no Cyber Essentials Plus, admin MFA unverified** 👤 |
| 4. Interoperability | 10% | ~30 | NHS Number modulus-11 **validator built + ready** (SQL + TS) though N/A in current PII-free scope; no FHIR surface |
| 5. Usability & accessibility | 20% | ~50 | Keyboard, skip-link, focus mgmt, status roles, **contrast measured ≥AA, accessibility statement drafted**; **no formal audit, no screen-reader test, AIS unaddressed** |

**Weighted overall readiness ≈ 44 / 100** (up from ~37 after the no-Trust completion pass).
Engineering-controls-only sub-score ≈ 90/100 — the code is in strong shape; the ceiling is now
almost entirely human/organisational sign-offs + external certifications that only the Trust can
start. **Do not describe as "compliant" at any score.**

## Status legend
- ✅ Done / control in place
- ⚠️ Partial — needs work or formal verification
- ❌ Open — not started / known gap
- 🚫 Blocker — must resolve before go-live
- 👤 Needs human authority (DPO / Caldicott / CSO) — cannot be closed by code alone

---

## 1. Clinical Risk Management — DCB0129 / DCB0160 🚫
*Mandatory under the Health & Social Care Act for clinical software.*

- 🚫👤 **Clinical Safety Officer assigned** and Hazard Log + Clinical Safety Case Report opened.
- ⚠️ **HAZARD (mitigated in code — pending CSO review): instant irreversible auto-cancel.**
  Previously a single tap on *"I no longer need this"* set `status = 'CANCELLED'` outright.
  **Now mitigated by two independent layers:**
  (1) **Frontend confirmation gate** (`frontend/app.js`, `NEEDS_CONFIRMATION`) — decline never
      submits on a single tap; the safe *"No, keep my place"* option is listed first and
      receives focus, so a mis-tap / wrong recipient cannot one-tap a cancellation.
  (2) **Backend soft-state** (`submit_validation_response`) — no longer hard-cancels; it moves
      the entry to the **reversible** `PENDING_CANCELLATION` state for mandatory clinical review.
      Policy `pol_entries_update_definer` is locked to `WITH CHECK (status = 'PENDING_CANCELLATION')`,
      so this unauthenticated path can *never* write `CANCELLED`.
  **Still open before go-live:** (a) define + own the clinical-review workflow that resolves
  `PENDING_CANCELLATION` → `CANCELLED`/reinstated; (b) ⚠️ a prerequisite migration
  (`20260528120000_waitlist_status_pending_cancellation.sql`, dated to run FIRST) now introspects
  the upstream `waitlist_entries.status` domain and adds `PENDING_CANCELLATION` automatically when it
  is an enum; if `status` is guarded by a CHECK constraint it raises an explicit NOTICE for manual
  widening (cannot be auto-rewritten safely) — verify this resolved in your environment; (c) **CSO sign-off**.
- ⚠️ **HAZARD: wrong-recipient submission.** Token in SMS could reach the wrong person.
  Now mitigated by PII-free URL **+ the confirmation gate** (a mis-delivered link cannot one-tap
  a cancellation) **+ the reversible soft-state** (any erroneous response is recoverable via
  clinical review). Still assess tamper-evident audit of who responded.
- ⚠️ **HAZARD: "symptoms worsened" has no urgent-routing SLA.** Confirm the clinical pathway
  that consumes `SYMPTOMS_WORSENED` responses and its response-time guarantee.
- ❌ Hazard Log maintained as the system evolves (each new feature → hazard review).

## 2. UK GDPR / DPA 2018 + DPIA 👤
- 🚫👤 **DPIA completed and signed** before go-live (special-category health data).
- ✅ **Data minimisation in URL** — only a 128-bit UUID token; zero PII in the link.
- ✅ **No PII in `waitlist_tokens` / `validation_responses`** — UUIDs + enum only.
- ⚠️ **Lawful basis documented** (likely Art.6(1)(e) public task + Art.9(2)(h) health/care).
- ✅ **Retention — tokens.** `purge_expired_tokens()` (migration `20260529040000`) deletes spent/expired
  single-use tokens (PII-free) and is auto-scheduled daily via pg_cron when the extension is present
  (else a NOTICE prompts an external scheduler).
- ⚠️ **Retention — responses.** `purge_aged_validation_responses(interval)` provided but **deliberately
  NOT scheduled** — the retention period is a Caldicott/IG decision, not a technical default.
- ⚠️ **Right to erasure / rectification.** `erase_patient_validation_data(entry_id)` (SECURITY DEFINER,
  scoped to the caller's `hospital_id`, `authenticated`-only) removes a patient's tokens + responses
  and returns an audit summary. Pending: wire into the Trust's documented erasure/rectification process.
- ⚠️ **PII encryption at rest** for `waitlist_entries` — use *current* Supabase-recommended
  primitives (Vault / app-layer envelope), **not** deprecated pgsodium TCE. Use standard
  randomized AEAD, not "deterministic AEAD."

## 3. Common Law Confidentiality + Caldicott Principles 👤
- ✅ Justify the purpose (waitlist accuracy) — documented in app copy.
- ✅ Use the minimum necessary PII (none in the patient-facing layer).
- ⚠️👤 Access on a need-to-know basis — RLS scopes admin reads to `hospital_id`; confirm
  `auth.current_hospital_id()` is correct and tested.
- ❌ Duty to share balanced against duty to protect — documented by Caldicott Guardian.

## 4. DTAC v2 (Digital Technology Assessment Criteria) ⚠️
*NOTE ON AUTHORITY: the project owner reports DTAC v2.0 published by NHS England 2026-02-24,
with v1.0 retired 2026-04-06 (key v2 changes: ~25% question reduction via DSPT/PAQ de-duplication;
explicit DSIT/NCSC Software Security Code of Practice declaration; NICE scope alignment to
software-based DHTs — our waitlist SaaS is in scope; Section D usability no longer numerically
scored but WCAG 2.2 AA + Accessible Information Standard still legally required; CSO no longer
needs NHS England training but the CSO role criteria still apply). I have NOT independently
verified this against a live primary NHS source in this session — treat as the owner's sourced
working model and re-confirm the current DTAC text/forms with the Trust before submission.
The three `DGAT supporting-doc template` .docx files supplied are generic NHS information-standard
AUTHORING templates (blank boilerplate) — they add no specific DTAC requirements to this build.*

Five-pillar routing (where each pillar is evidenced in this repo):
1. **Clinical safety (DCB0129/0160)** → §1. CSO + Hazard Log + Clinical Safety Case Report still 👤.
2. **Data protection** → §2 (UK GDPR/DPIA), §3 (Caldicott), §7 (UK residency), §8 (DSPT). DPO + Caldicott sign-off still 👤.
3. **Technical security** → §6 (now incl. CREST pen test, Cyber Essentials Plus, admin MFA, Software Security Code of Practice).
4. **Interoperability** → §9 (NHS Number modulus-11, FHIR APIs).
5. **Usability & accessibility** → §5 (WCAG 2.2 AA + Accessible Information Standard + NHS design system).

## 5. Accessibility — WCAG 2.2 AA + NHS design standards ⚠️
*Public Sector Bodies (Websites & Mobile Applications) Accessibility Regs 2018.*

- ⚠️ **NHS.UK frontend / service manual.** Current UI is bespoke ("high-end minimal").
  NHS patient services are expected to use NHS.UK patterns. Reconcile aesthetic vs. standard.
- ✅ **Colour contrast (developer-measured vs AA 4.5:1).** Light: `--ink-soft` ≈ 6.0:1, `--affirm`
  ≈ 6.6:1, `--urgent` ≈ 5.5:1 on white; dark: `--ink-soft` ≈ 7.2:1. ⚠️ Non-text/UI-component (3:1)
  and focus-indicator contrast still to be confirmed by the formal audit.
- ✅ Keyboard operable — `:focus-visible` outlines present.
- ✅ **Skip link** to the question (WCAG 2.4.1).
- ✅ Reduced-motion honoured (`prefers-reduced-motion`).
- ✅ Status semantics — outcome uses `role="status"` + `aria-live` with focus moved to it on submit;
  errors `role="alert"`; confirm gate `role="group"` + `aria-labelledby`/`aria-describedby`.
- ⚠️ **Accessibility statement DRAFTED** (`ACCESSIBILITY.md`) — must not be published until the formal
  audit + AT testing are complete and the Trust fills in contact/enforcement details.
- ❌ **Formal independent WCAG 2.2 AA audit** + remediation.
- ❌ Tested with screen readers (NVDA / JAWS / VoiceOver) and at 200% zoom / 320px reflow.
- ❌👤 **Accessible Information Standard (DCB1605).** Confirm how communication-needs flags
  (e.g. easy-read, large-print, BSL, alternative formats) are honoured for the SMS link +
  patient-facing page. Out of scope for code alone — owned with the Trust's comms team.

## 6. Technical Security — NCSC 14 Cloud Principles + DTAC v2 ⚠️
- ✅ **Supply chain (SRI).** `index.html` now loads a **version-pinned** `supabase-js@2.106.2`
  with `integrity=sha384-…` + `crossorigin="anonymous"` + `referrerpolicy="no-referrer"`.
  A floating `@2` tag cannot be SRI-protected (bytes change per release) — pinned + hashed instead.
  Bump version + hash together on upgrade. *Stronger option for the Trust:* self-host under `/vendor/`.
- ✅ **Content-Security-Policy.** Authoritative header in `vercel.json` (`default-src 'none'`,
  script/connect-src locked to self + jsdelivr + `*.supabase.co`, `frame-ancestors 'none'`,
  `upgrade-insecure-requests`); defence-in-depth `<meta>` CSP also in `index.html`.
- ✅ **HSTS + transport.** `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
  + `upgrade-insecure-requests` in `vercel.json`. (TLS termination + HTTP→HTTPS handled by Vercel.)
- ✅ **Hardening headers** — `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`,
  `Referrer-Policy: no-referrer`, `Permissions-Policy` (geo/mic/camera/payment/usb/FLoC off), COOP + CORP same-origin.
- ❌👤 **CREST-approved penetration test** commissioned + findings remediated (DTAC v2).
- ❌👤 **Cyber Essentials Plus** certification held by the operating org (DTAC v2).
- ⚠️👤 **Mandatory MFA** for all admin / remote access (Supabase dashboard + any ops console). Verify + enforce.
- ⚠️👤 **Software Security Code of Practice (DSIT/NCSC, 2026)** — self-declaration drafted in
  `SECURITY.md` (secure design/build/deploy, pinned deps + SRI, secrets handling, disclosure stub).
  Pending: independent assurance + Trust completion of the vuln-disclosure contact / `security.txt`.
- ✅ **Single-use tokens** — atomic burn in `submit_validation_response`.
- ✅ **Token expiry** — 7-day default in `waitlist_tokens.expires_at`.
- ✅ **Least privilege** — `anon` has EXECUTE on the RPC only; tables locked by forced RLS.
- ✅ **SECURITY DEFINER hardened** — `SET search_path = public`.
- ⚠️ **Audit trail** — who/when responded; ensure tamper-evidence and **no token↔PII
  correlation in Supabase request logs**.
- ⚠️ **No secrets in client** — anon key is public-by-design ✅; confirm no service-role key
  ever reaches `frontend/`. Runtime config is isolated to `frontend/env.js` (`window.__ENV`, public
  URL + anon key only; `env.example.js` documents it). The service-role key stays server-side
  (`supabase/functions/*`).
- ✅ **Token-link issuance** — `issue_validation_token(entry_id, base_url, ttl)` (migration `20260529060000`,
  SECURITY DEFINER, `hospital_id`-scoped, `authenticated`-only, https base-URL guard) mints a PII-free
  `?t=` link for the dispatch pipeline. anon is never granted execute.

## 7. Data Residency — UK 👤
- ⚠️ **Supabase project region = London (eu-west-2 / AWS naming).** Verify.
- ⚠️ Any serverless/edge compute touching PII pinned to UK (Vercel `lhr1`).
- ✅ **Static CDN carries no PII** — the global edge serves only the PII-free form.
  (Do not claim "edge restricted to London" — residency is enforced at the data layer.)

## 8. DSPT (Data Security & Protection Toolkit) 👤
- ❌👤 Confirm this app is captured in the Trust's annual DSPT submission.
- ❌ Incident-response & breach-notification path defined (72-hour ICO clock).

## 9. Interoperability — DTAC v2 ⚠️
- ✅/➖ **NHS Number modulus-11 validation.** *Not applicable in the current patient-facing layer*
  (the public form holds **zero PII / no NHS Number** — only a UUID token; see §2). A reusable
  validator is now **built and ready at the ingest boundary**: SQL `is_valid_nhs_number(text)`
  (IMMUTABLE, migration `20260529050000`, usable as a CHECK constraint) + TS `isValidNhsNumber()` /
  `normaliseNhsNumber()` (`supabase/functions/_shared/nhs-number.ts`) for edge ingest workers.
  Pending: apply at the actual boundary if/when NHS Number is ingested, and document where it lives.
- ❌ **FHIR standard APIs.** No FHIR surface today. If the waitlist integrates with PAS/e-RS or
  exposes data to other systems, use HL7 FHIR UK Core resources. Future / separate workstream.

## 10. Patient Hub portal (authenticated) — `portal/` ⚠️
*A separate, fully authenticated patient dashboard. Unlike the SMS validation page, it has
**no anonymous data path** — every read runs under the signed-in user's JWT so RLS isolates them.*

- ✅ **Strict auth gating.** `onAuthStateChange` + `getSession` route the UI: no session ⇒ login
  screen only; the dashboard is never shown without a session.
- ✅ **IDOR-safe reads.** The data query (`from('waitlist_entries').select('*')`) passes **no user id**;
  isolation is enforced server-side by RLS on `auth.uid()`. No client-supplied identifier chooses whose data loads.
- ✅ **Fail-closed today (secure by default).** There is currently **no patient SELECT policy** on
  `waitlist_entries`, so a logged-in patient sees **nothing** until the backend is extended. The portal
  handles this gracefully (friendly empty state).
- 🚫 **BACKEND DEPENDENCY (before it can show real data):** add (a) a `patient_user_id` link from
  `waitlist_entries` to the NHS Login identity, and (b) `CREATE POLICY ... FOR SELECT TO authenticated
  USING (patient_user_id = auth.uid())`. Without this it stays empty (by design).
- ⚠️ **Mock NHS Login.** The "Sign in with NHS Login" button simulates OIDC; for local testing it
  reveals a form where the tester types their own credentials. **No credentials are stored in the repo.**
  Production must swap in the real NHS Login OIDC provider (`signInWithOAuth`) — 👤 integration + assurance.
- 🚫👤 **Proxy view is a MOCK.** Caring-for-a-dependent access shows a placeholder banner only and fetches
  no one else's data. Real proxy access requires a verified proxy relationship, its own RLS, and
  **Caldicott-approved consent** (see §3).
- ✅ **No secrets in client / CSP / SRI.** Only the public URL + anon key (`portal/env.js`, gitignored);
  defence-in-depth CSP meta; SRI-pinned `supabase-js@2.106.2`.
- ✅ **Accessibility (WCAG 2.2 AA aim).** Elderly-friendly: larger base type, ≥56px touch targets,
  skip link, `:focus-visible`, `role="status"`/`alert`, progressive disclosure, reduced-motion, light/dark.
  Still ❌ formal audit + AT testing (shared with §5).
- ⚠️ **DPIA scope.** Patient-facing authenticated access to health data must be covered by the §2 DPIA.
- ❌ **Session hygiene for shared/elderly devices** — define idle-timeout / explicit sign-out guidance.
- *Interactive login→dashboard click-through to be verified in the repo-rooted session (preview "portal", :5700).*

---

## Frontend↔backend contract checks (regression guard)
- ✅ **Token param name** — `app.js` now reads `?t=` (canonical, data-minimised) **and** falls back
  to legacy `?token=`, so the SMS spec and any already-issued links both resolve.
- ✅ Error code `INVALID_OR_EXPIRED_TOKEN` matches between RPC and `app.js`.
- ✅ Response-type enum matches between `app.js`, the CHECK constraint, and the RPC.

## Change-review ritual (do this every diff)
1. Which sections above does this change touch?
2. Does it introduce/alter a clinical hazard? → update §1 Hazard Log.
3. Does it move, log, or expose any PII? → re-check §2, §3, §6, §7.
4. Update the status markers here in the same commit.

_Last reviewed: 2026-05-29._

**Changelog — 2026-05-29 (NHS guideline back-check):**
- §1 — Mitigated the instant-irreversible auto-cancel hazard: added a frontend confirmation gate
  (`#confirm`, safe "keep my place" focused first) **and** a reversible backend `PENDING_CANCELLATION`
  soft-state (RPC + `pol_entries_update_definer WITH CHECK`). Status 🚫 → ⚠️ pending CSO sign-off.
- §6 — Added SRI (pinned `supabase-js@2.106.2` + integrity/crossorigin), authoritative CSP +
  HSTS + hardening headers (`vercel.json`), defence-in-depth meta CSP. 🚫/❌ → ✅. Added DTAC v2
  technical-security gaps (CREST pen test, Cyber Essentials Plus, admin MFA, Software Security Code of Practice).
- §4 — Reframed as DTAC v2 five-pillar routing (with the unverified-authority caveat).
- §5 — Added Accessible Information Standard (DCB1605).
- §9 — New Interoperability section (NHS Number modulus-11 N/A in the PII-free layer; FHIR future).
- Contract check — `?t=` / `?token=` aligned in `app.js`.

**Changelog — 2026-05-29 (no-Trust completion pass — everything closeable without the Trust):**
- §1 — Added prerequisite migration `20260528120000` that introspects `waitlist_entries.status` and
  adds `PENDING_CANCELLATION` (enum) or NOTICEs for a CHECK constraint. Runs before section-11.
- §2 — Added `20260529040000_retention_and_erasure.sql`: `purge_expired_tokens()` (auto-scheduled via
  pg_cron), `purge_aged_validation_responses()` (IG-gated, unscheduled), `erase_patient_validation_data()`
  (hospital-scoped right-to-erasure). Retention/erasure ❌ → ✅/⚠️.
- §5 — Accessibility pass: skip link, `role="status"`+focus on outcome, confirm `aria-labelledby`/
  `describedby`, contrast measured ≥AA, `ACCESSIBILITY.md` statement drafted. Verified live in preview
  (decline→confirm focuses safe default; submit→success moves focus; no console/CSP errors).
- §6 — `SECURITY.md` secure-SDLC self-declaration (DSIT/NCSC); `issue_validation_token()` link generator
  (`20260529060000`); runtime config isolated to `frontend/env.js` (+ `env.example.js`). SSCoP ❌→⚠️.
- §9 — `is_valid_nhs_number()` SQL + `nhs-number.ts` util built and ready at the ingest boundary.
- Frontend cache-bust bumped `app.js?v=20260529b` after the a11y change (avoids stale-cache serving).
- **Not done (Trust-only, unchanged):** CSO/Hazard Log/CSCR, DPIA, DSPT, Caldicott, CREST pen test,
  Cyber Essentials Plus, admin MFA enforcement, formal WCAG audit, UK residency verification,
  at-rest PII encryption, the clinical-review workflow that resolves `PENDING_CANCELLATION`.

**Changelog — 2026-05-29 (Patient Hub portal scaffold):**
- §10 — New authenticated `portal/` (login + dashboard). No anon path; `onAuthStateChange` gates the UI;
  IDOR-safe read (no user id in query — RLS on `auth.uid()`); mock NHS Login (no stored creds);
  proxy view is a mock; CSP + SRI + public-key-only config (`portal/env.js`, gitignored). Elderly-friendly a11y.
- Compliance hook extended to also fire on `portal/` edits (+ an auth/RLS/IDOR check line).
- Preview config gains a `portal` server (:5700).
- **Fail-closed today:** no patient SELECT policy on `waitlist_entries` yet, so patients see nothing until the
  backend adds `patient_user_id` + `USING (patient_user_id = auth.uid())`. **Open backend dependency.**
- Verified: app.js syntax OK, assets serve 200, query is IDOR-safe, no hardcoded creds. Interactive
  click-through pending in a repo-rooted session.

**Changelog — 2026-05-30 (automatic change ledger):**
- The compliance hook now **auto-appends an audit row to `COMPLIANCE_CHANGELOG.md` on every file change**
  (deterministic trail of timestamp · tool · file · scope) — the part a script can do reliably. It still
  injects the curated back-check reminder for `frontend/`/`supabase/`/`portal/` edits, because deciding
  whether a change alters a hazard / touches PII / changes a §-status is a judgement, not something a script
  may auto-write into this checklist (auto-writing a "compliant" claim would breach the honesty rule).
- `.gitattributes`: `COMPLIANCE_CHANGELOG.md merge=union` so concurrent appends from two machines never conflict.
- Hook self-skips the ledger file; malformed input → exit 0 (never blocks an edit). Verified via a 4-case test.
- Process note: each substantive change still gets a curated §-update here, by me, in the same change.
