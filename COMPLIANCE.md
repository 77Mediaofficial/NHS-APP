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
  (3) **Clinical-review resolution now in code** (`20260601010000_clinical_review_workflow.sql`):
      `resolve_cancellation(entry_id, decision, note)` (SECURITY DEFINER, `authenticated`-only,
      hospital-scoped, row-locked) makes the ONLY `PENDING_CANCELLATION → CANCELLED` (CONFIRM) or
      `→ ACTIVE` (REINSTATE) transition, and every resolution is written to an append-only
      `cancellation_reviews` audit ledger (who/when + before/after + optional clinical note).
      `anon` is never granted execute, so the patient path still can never hard-cancel. A scoped
      `pol_entries_resolve_definer` policy (USING `status='PENDING_CANCELLATION'`, WITH CHECK
      `status IN ('CANCELLED','ACTIVE')`) bounds the transition at the RLS layer too. *Code-reviewed,
      not executed (no live DB this session).*
  **Still open before go-live:** (a) 🚫👤 a **staff-facing UI / tooling** that lists
  `PENDING_CANCELLATION` entries and calls `resolve_cancellation()` — needs REAL staff auth + the
  `hospital_id` JWT claim (not built; the workflow ships the safety-critical *mechanism*, the human
  trigger is the follow-on), and **CSO sign-off + a Hazard Log / CSCR entry** for this workflow;
  (b) ⚠️ a prerequisite migration
  (`20260528120000_waitlist_status_pending_cancellation.sql`, dated to run FIRST) now introspects
  the upstream `waitlist_entries.status` domain and adds `PENDING_CANCELLATION` automatically when it
  is an enum; if `status` is guarded by a CHECK constraint it raises an explicit NOTICE for manual
  widening (cannot be auto-rewritten safely) — verify this resolved in your environment; (c) **CSO sign-off**.
- ⚠️ **HAZARD: wrong-recipient submission.** Token in SMS could reach the wrong person.
  Now mitigated by PII-free URL **+ the confirmation gate** (a mis-delivered link cannot one-tap
  a cancellation) **+ the reversible soft-state** (any erroneous response is recoverable via
  clinical review, now with an audited `resolve_cancellation` path that records who reinstated/confirmed).
  Still assess tamper-evident audit of who *responded* (patient side): `validation_responses` records the
  response but not a tamper-evident chain — see §6 audit-trail item.
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
  randomized AEAD, not "deterministic AEAD." **Raised priority:** `waitlist_entries.nhs_number`
  (added 2026-06-01 for identity matching, §10) is personal data now stored at rest — it must be
  covered by this control and by the DPIA before go-live.

## 3. Common Law Confidentiality + Caldicott Principles 👤
- ✅ Justify the purpose (waitlist accuracy) — documented in app copy.
- ✅ Use the minimum necessary PII — **none in either patient-facing layer**: the SMS page is UUID-only, and
  the portal client query selects explicit non-PII columns (the `nhs_number` match key added in §10 is stored
  on the record for staff/matching but is never sent to the patient's browser).
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

- ⚠️ **NHS.UK frontend / service manual.** Both surfaces — the SMS page (`frontend/`) and the portal
  (`portal/`) — now share ONE design system on the **official NHS palette** (Blue #005EB8, Black #212B32,
  Pale Grey #E8EDEE, Green #007F3B, Red #DA291C), consistent across pages. Still ⚠️: Service-Manual-*aligned*,
  not the actual NHS.UK component library, and not NHS-accredited (logo is a placeholder).
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
  **Disclosure file now drafted in-repo:** `frontend/.well-known/security.txt` (RFC 9116 template,
  served as `text/plain` via `frontend/vercel.json`) — every `%%PLACEHOLDER%%` (contact, `Expires`,
  canonical domain, policy) must be completed + ideally PGP-signed by the Trust before go-live.
  Pending: independent assurance + Trust completion of those contact details.
- ✅ **Single-use tokens** — atomic burn in `submit_validation_response`.
- ✅ **Token expiry** — 7-day default in `waitlist_tokens.expires_at`.
- ✅ **Least privilege** — `anon` has EXECUTE on the RPC only; tables locked by forced RLS.
- ✅ **SECURITY DEFINER hardened** — `SET search_path = public`.
- ⚠️ **Audit trail** — who/when responded + tamper-evidence + **no token↔PII correlation in request logs**.
  *Now substantially built:* **both** append-only ledgers — clinician `cancellation_reviews` (reviewed_by +
  before/after + note) **and** patient `validation_responses` — are immutable-by-RLS (no UPDATE/DELETE policy)
  **and cryptographically hash-chained** (`20260601020000_audit_hash_chain.sql`): a BEFORE INSERT trigger sets
  `row_hash = sha256(prev_hash || business-columns)` (PG15 core sha256, no extension), and `verify_audit_chain()`
  re-walks a chain to DETECT any later edit/deletion — including one that bypasses RLS via direct DB access.
  **Honest residual ⚠️:** tamper-*evident*, not tamper-*proof* (a DB admin could rewrite the whole chain
  consistently) — closing that needs periodic export of the tail `row_hash` to external WORM/notarisation
  (👤 Trust operational step). Token↔PII non-correlation in Supabase request logs still to confirm at deploy.
  *Code-reviewed, not executed (no live DB this session).*
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
- ⚠️👤 **Incident-response & breach-notification runbook DRAFTED** (`SECURITY-INCIDENT.md`): triage →
  contain (evidence-first) → the **72-hour ICO clock** (UK GDPR Art. 33) + Art. 34 patient notification +
  NHS routes (DSPT incident tool, NHS England Data Security Centre) → eradicate/recover → post-incident
  review. Names this system's PII surfaces (`nhs_number`, `patient_user_id`, `patient_phone`). Still 👤:
  the Trust must adopt/own it, fill every `%%PLACEHOLDER%%` (roles + contacts), rehearse it, and integrate
  it with the major-incident process. **Not** evidence of an operational capability — a drafted aid only.

## 9. Interoperability — DTAC v2 ⚠️
- ✅/➖ **NHS Number modulus-11 validation.** *Not applicable in the current patient-facing layer*
  (the public form holds **zero PII / no NHS Number** — only a UUID token; see §2). A reusable
  validator is now **built and ready at the ingest boundary**: SQL `is_valid_nhs_number(text)`
  (IMMUTABLE, migration `20260529050000`, usable as a CHECK constraint) + TS `isValidNhsNumber()` /
  `normaliseNhsNumber()` (`supabase/functions/_shared/nhs-number.ts`) for edge ingest workers.
  Pending: apply at the actual boundary if/when NHS Number is ingested, and document where it lives.
- ➖👤 **FHIR standard APIs — DECISION: not built now (deliberate, documented).** No FHIR surface exists,
  and one is **intentionally not built** in this iteration. *Rationale:* DTAC interoperability requires open
  standards **where systems interoperate** — today this app has no consumer for a FHIR feed (the patient portal
  reads its own DB via RLS; the SMS layer is PII-free UUID tokens). Building a speculative FHIR API now would add
  attack surface, PII exposure, and maintenance burden for **zero** current integration, and could not be
  verified against a real consumer — net-negative for security and honesty. *When it becomes in scope* (waitlist
  integrates with PAS / e-Referral Service, or must expose data to another system), implement **HL7 FHIR UK Core**:
  the waitlist entry maps to a `ServiceRequest` / `Appointment` + `Patient` (the `Patient.identifier` is the NHS
  Number — validate via the existing `is_valid_nhs_number` at that boundary), served read-only behind the same
  auth + residency controls. 👤 The Trust owns the trigger (is there a real integration requirement?) and the
  conformance/assurance. *This is a recorded decision, not an open gap — revisit if an integration need appears.*

## 10. Patient Hub portal (authenticated) — `portal/` ⚠️
*A separate, fully authenticated patient dashboard. Unlike the SMS validation page, it has
**no anonymous data path** — every read runs under the signed-in user's JWT so RLS isolates them.*

- ✅ **Strict auth gating.** `onAuthStateChange` + `getSession` route the UI: no session ⇒ login
  screen only; the dashboard is never shown without a session.
- ✅ **IDOR-safe + data-minimised reads.** The data query passes **no user id** (isolation is enforced
  server-side by RLS on `auth.uid()`; no client-supplied identifier chooses whose data loads) **and now selects
  only explicit non-PII columns** (`procedure, status, referred_at, created_at`) — it deliberately never pulls
  `nhs_number` or `patient_user_id` into the browser (UK GDPR data minimisation, §2). Closes the prior `select('*')` TODO.
- ✅ **Patient SELECT policy now in code.** `pol_entries_patient_select` (migration
  `20260529070000_patient_portal_rls.sql`) = `FOR SELECT TO authenticated USING (patient_user_id = auth.uid())`,
  on the `patient_user_id` column added by the base schema (`20260527000000_base_schema.sql`). This closes the
  previously-🚫 blocker: a signed-in patient can read **only their own** row, server-side, IDOR-safe, fail-closed
  when `patient_user_id` is NULL. *Code-reviewed, not yet executed (no live DB this session).*
- ⚠️ **Base schema now scaffolded in-repo** (`20260527000000_base_schema.sql`): `hospitals`,
  `waitlist_entries` (incl. `patient_user_id`, `status` CHECK with `PENDING_CANCELLATION`), `auth.current_hospital_id()`,
  `sms_dispatch_jobs` + `get_next_sms_batch()`. Minimal/dev foundation — **replace with the Trust's real tables**
  if one exists (point the app at those and delete this file).
- ✅ **Identity-matching step now in code.** `link_my_waitlist_record()` (migration
  `20260601000000_link_patient_identity.sql`, SECURITY DEFINER, `authenticated`-only) reads the caller's **own
  verified NHS Number** from the request JWT (claim `nhs_number`, gated on `identity_proofing_level = 'P9'`),
  validates it (modulus-11), and self-assigns `patient_user_id = auth.uid()` on matching **unclaimed** rows
  (first-claim-wins). Takes **no parameters** → IDOR-safe by construction (a caller can only ever claim their own
  verified rows for their own uid); fail-closed (missing/invalid number or sub-P9 → 0 rows linked). Adds a
  `waitlist_entries.nhs_number` column (modulus-11 CHECK + normalised expression index) as the match key.
  *Code-reviewed, not yet executed (no live DB this session).*
- 🚫👤 **Still required before real patient data shows (NOT closable in SQL alone):** (a) wire real NHS Login OIDC
  into Supabase Auth (portal mocks it today); (b) confirm the **JWT claim mapping** the matcher assumes
  (`nhs_number`, `identity_proofing_level='P9'`) matches the real NHS Login → Supabase OIDC config, and decide
  where linking runs (post-login/access-token hook recommended over the client calling the RPC); (c) the Trust's
  ingest/PAS must populate `waitlist_entries.nhs_number`. Until (a)+(b) align and rows carry a number, every row
  stays NULL → portal correctly empty.
- ⚠️👤 **NHS Login — real OIDC path now in code (config-activated); mock retained for dev.** The "Sign in
  with NHS Login" button now calls the **real** `db.auth.signInWithOAuth({ provider: NHS_OIDC_PROVIDER })`
  whenever the backend is configured **and** `window.__ENV.NHS_OIDC_PROVIDER` is set; otherwise it falls back to
  the local mock credential form. The provider (client id/secret, NHS Login issuer URLs, scopes incl.
  `nhs_number`/P9 proofing) is registered in the **Supabase dashboard — never in the repo**; `env.example.js`
  documents the public provider-name knob only. Verified live: with no provider (dev-mock) the button still
  reveals the mock form and the full login→dashboard flow works. 👤 **Still required:** real NHS Login client
  registration + identity-proofing (P9) + claim mapping, and assurance — only the Trust can do this. **No
  credentials are stored in the repo.**
- ⚠️👤 **Proxy access — server-side scaffold now in code; client still a MOCK.** Backend foundation built
  (`20260601030000_proxy_access_scaffold.sql`): a `patient_proxies` relationship table (active + consented +
  time-bounded), `auth.has_proxy_access()` (fail-closed predicate), a third permissive `pol_entries_proxy_select`
  policy that OR-combines with patient-self + admin reads, and **staff-gated** `grant_proxy_access` (requires the
  `hospital_id` JWT claim — a patient cannot self-grant) / `revoke_proxy_access` (subject/proxy/staff). Ships with
  **zero relationships granted**, so it changes no access by default. The portal CLIENT toggle is still a UX demo
  (no identity switch, no subject-picker, fetches no one else's data). 🚫👤 **Still required:** Caldicott-approved
  CONSENT + identity verification of both parties (the table records a decision, it does not make it), lawful basis
  for under-16s/incapacity, and a staff grant/revoke UI. *Code-reviewed, not executed.*
- ✅ **No secrets in client / CSP / SRI.** Only the public URL + anon key (`portal/env.js`, gitignored);
  defence-in-depth CSP meta; SRI-pinned `supabase-js@2.106.2`.
- ✅ **Accessibility (WCAG 2.2 AA aim).** Elderly-friendly: larger base type, ≥56px touch targets,
  skip link, `:focus-visible`, `role="status"`/`alert`, progressive disclosure, reduced-motion, light/dark.
  Still ❌ formal audit + AT testing (shared with §5).
- ⚠️ **DPIA scope.** Patient-facing authenticated access to health data must be covered by the §2 DPIA.
- ✅ **Session hygiene for shared/elderly devices — idle auto sign-out built + live-verified.** After
  `IDLE_TIMEOUT_MINUTES` (default 10; `window.__ENV`-configurable) of no interaction the portal shows an
  accessible warning (`role="alertdialog"`, live countdown, focus moved to "Stay signed in"), then signs the
  patient out and shows a security notice on the login screen — so a health record is never left open on an
  unattended/shared device. Any interaction (pointer/key/touch/scroll, throttled) or "Stay signed in" cancels +
  re-arms; an explicit "Sign out" remains in the dash bar. Verified live in preview (warn at 50% of limit →
  auto sign-out + notice; "Stay signed in" cancels the logout past the original deadline). `portal/app.js`
  (`armIdleTimers`/`showIdleWarning`/`performSignOut`), `portal/index.html` (`#idleWarning`), `portal/styles.css` (`.idle`).
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

_Last reviewed: 2026-06-01._

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

**Changelog — 2026-05-30 (portal restyle to official NHS palette):**
- §5/§10 — `portal/styles.css` rebuilt on the official NHS palette (Blue #005EB8, Black #212B32, Pale
  Grey #E8EDEE, Green #007F3B, Red #DA291C) per the NHS Digital Service Manual aesthetic. Verified live:
  pale-grey body, white 8px cards, NHS-blue primary button, NHS-green checks.
- Accessibility (WCAG 2.2 AA aim): 48px touch targets; `:focus-visible` = NHS-yellow 3px outline + black
  outer ring (visible on any surface); **status not conveyed by colour alone** (chip has a shape/dot + text
  label); `forced-colors` (Windows High Contrast) + `prefers-reduced-motion` support. Developer-measured
  contrasts ≥ AA (blue 5.6:1, grey-1 6.0:1, green 5.1:1, white-on-red 4.8:1) — still ❌ formal audit + AT testing.
- Light-only per Service Manual: `color-scheme` meta aligned to `light` to avoid dark native controls.
- Cache-bust `styles.css?v=20260530`. **Caveat:** "official NHS palette" ≠ NHS-accredited; real NHS
  brand/identity use requires permission, and the logo remains a placeholder.

**Changelog — 2026-05-30 (MASTER bundle tooling):**
- Added `tools/build_master.py` → generates `MASTER.md`, a single read-only bundle of all 29 git-tracked
  text files with a TOC, for easy review/handover. Regenerate with `python tools/build_master.py`.
- **Secret-safe by construction:** it bundles only git-tracked files, so the gitignored `env.js` is excluded;
  verified no real keys (only `%%` placeholders) and no self-recursion. The one `SUPABASE_SERVICE_ROLE_KEY`
  string in the bundle is the dispatch worker's `Deno.env.get(...)` *read* — the secret value is never in source.
- `tools/` is outside `frontend/`/`supabase/`/`portal/`, so it carries no compliance surface of its own.

**Changelog — 2026-05-30 (SMS page unified to the NHS design system):**
- §5 — `frontend/styles.css` rebuilt to the SAME official-NHS-palette design system as `portal/` (shared
  tokens, 8px cards, 48px touch targets, NHS-yellow+black `:focus-visible` ring, light-only via `color-scheme`,
  `forced-colors` + reduced-motion support). The SMS page and portal are now visually consistent.
- Verified live (devMock, :5500): pale-grey body, white card, NHS-blue accent, 48px choices, 3-choice question
  → decline → confirm (focus on safe "No") → success (NHS-green tick, focus moved); NHS-red error; no console/CSP errors.
- Clinical-safety flow (DCB0129/0160) unchanged and intact — restyle only; confirmation gate + reversible
  soft-state behaviour preserved. `frontend/index.html`: `color-scheme: light`, `styles.css?v=20260530` cache-bust.
- Caveat unchanged: NHS-palette ≠ NHS-accredited; logo is a placeholder; formal WCAG audit + AT testing still ❌.
- Correction note: an earlier (2026-05-30) draft referenced two files (`20260529070000_patient_portal_rls.sql`,
  `portal/vercel.json`) that did not exist at the time — those changelog lines were premature/hallucinated, and
  no false claim landed in the committed repo (caught pre-commit). **Update 2026-05-31:**
  `20260529070000_patient_portal_rls.sql` was subsequently authored for real and is now committed (see §10
  patient-SELECT RLS policy); `portal/vercel.json` still does **not** exist.

**Changelog — 2026-05-31 (portal idle auto sign-out — §10 session hygiene closed):**
- §10 — Built idle-timeout auto sign-out for the authenticated portal (shared/elderly-device safety; also
  supports §6 technical security + §2 data protection). After `IDLE_TIMEOUT_MINUTES` (default 10,
  `window.__ENV`-configurable; dev-mock `?idle=<min>` for testing) of no interaction: an accessible
  `role="alertdialog"` warning with a live 1-second countdown appears at 50% of the limit (capped 60s) and
  focus moves to "Stay signed in"; on expiry the patient is signed out (Supabase `auth.signOut()` when
  configured), the dashboard is hidden, and a security notice appears on the login screen. Any interaction
  (pointerdown/keydown/touchstart/scroll, throttled) or "Stay signed in" cancels + re-arms; an explicit
  "Sign out" stays in the dash bar. Status `❌ → ✅`.
- Files: `portal/app.js` (idle config + `armIdleTimers`/`showIdleWarning`/`onUserActivity`/`performSignOut`/
  `clearIdleTimers`/`hideIdleWarning`/`isSignedIn`; `route()` arms on session, clears on sign-out),
  `portal/index.html` (`#idleWarning` alertdialog markup; cache-bust `app.js?v=20260531` + `styles.css?v=20260531`),
  `portal/styles.css` (`.idle` panel — NHS-blue accent, reduced-motion-safe).
- Verified live (preview, `?demo=1&idle=0.05`): t0 dashboard armed → t≈1.9s warning + countdown + focus on
  "Stay signed in" → t≈3.5s signed out + login notice; separately "Stay signed in" kept the patient signed in
  past the original logout deadline. `node --check portal/app.js` OK.
- Honesty note: a built + live-verified control, **not** a compliance claim. Portal go-live still needs the
  §10 👤 items (real NHS Login OIDC, identity-matching) + Trust sign-offs (DPO/Caldicott/CSO).

**Changelog — 2026-06-01 (identity matching + portal data minimisation):**
- §10 — Added `link_my_waitlist_record()` (migration `20260601000000_link_patient_identity.sql`): the
  identity-matching step that links a verified NHS Login patient (`auth.uid()`) to their waitlist row(s) by
  matching the verified `nhs_number` JWT claim (gated on `identity_proofing_level='P9'`, modulus-11 validated).
  Takes no parameters → IDOR-safe by construction; fail-closed; first-claim-wins. Adds `waitlist_entries.nhs_number`
  (modulus-11 CHECK + normalised expression index) as the match key. Status of the identity-matching blocker `🚫 → ✅`
  (code); the remaining gate is 👤 integration (real OIDC + confirming the claim mapping + ingest populating the column).
- §10/§2 — Closed the `select('*')` data-minimisation TODO: `portal/app.js` now selects only
  `procedure, status, referred_at, created_at` — never `nhs_number`/`patient_user_id` to the browser.
  Verified live (mock dashboard still renders: greeting, procedure, Active chip, referred date; no console errors).
- §2 — Raised the at-rest-encryption priority: `nhs_number` is now personal data stored on `waitlist_entries`;
  flagged that it must be covered by the encryption-at-rest control **and** the DPIA before go-live.
- §3 — Restated "minimum necessary PII": both patient-facing layers remain PII-free in the client; the match key
  is stored for staff/matching only.
- Honesty note: code-reviewed, **not** executed (no live Postgres this session) and **not** a compliance claim.
  This is a deliberate, documented increase in the data-protection surface (storing NHS Number) that the DPIA must cover.

**Changelog — 2026-06-01 (vuln-disclosure file + incident-response runbook):**
- §6 — Added `frontend/.well-known/security.txt` (RFC 9116 vulnerability-disclosure template) and a
  `Content-Type: text/plain` rule for that path in `frontend/vercel.json` so it serves correctly at
  `/.well-known/security.txt`. `SECURITY.md` "Reporting a vulnerability" now points at the real file.
  It is a **template**: the Trust completes every `%%PLACEHOLDER%%` (contact, `Expires`, canonical
  domain, policy) and ideally PGP-signs it before go-live. Software Security Code of Practice item
  stays ⚠️👤 (independent assurance + contact completion outstanding).
- §8 — Added `SECURITY-INCIDENT.md` breach-response runbook (72-hour ICO clock, Art. 34 patient
  notification, DSPT incident tool + NHS England Data Security Centre routes, evidence-first containment,
  post-incident review). Incident-response item `❌ → ⚠️👤`. Explicitly **not** an operational capability —
  the Trust must adopt, staff, rehearse, and own it.
- Honesty note: both are drafted engineering aids with placeholders, **not** compliance claims. The
  destructive/credential steps in the runbook are flagged as human-only (no automation performs them).

**Changelog — 2026-06-01 (clinical-review workflow for PENDING_CANCELLATION):**
- §1 — Added `20260601010000_clinical_review_workflow.sql`, closing the long-open hazard sub-point that a
  declined slot sat in the reversible `PENDING_CANCELLATION` soft-state with **no code path to resolve it**.
  `resolve_cancellation(entry_id, decision, note)` (SECURITY DEFINER, `authenticated`-only, hospital-scoped,
  `FOR UPDATE` row-locked, guarded to act ONLY on `PENDING_CANCELLATION`) makes the sole
  CONFIRM_CANCELLATION→CANCELLED / REINSTATE→ACTIVE transition. The patient path is unchanged and `anon`
  is never granted execute, so it still can never hard-cancel.
- §1/§6 — New append-only `cancellation_reviews` audit ledger (reviewed_by=`auth.uid()`, before/after status,
  optional clinical note; admin-RLS-scoped to hospital; no UPDATE/DELETE policy → immutable from the app).
  §6 audit-trail item moved to *partial* — honestly flagged as immutable-by-RLS, **not** cryptographically
  tamper-evident, and the patient-response side still lacks a chain.
- RLS: added `pol_entries_resolve_definer` (USING `status='PENDING_CANCELLATION'`, WITH CHECK
  `status IN ('CANCELLED','ACTIVE')`). Documented the OR-combination with the existing patient-path policy and
  that the PRIMARY guarantee is the EXECUTE grant + in-function `auth.uid()`/hospital checks, not the RLS alone.
- 🚫👤 Still open: a staff-facing UI that calls the RPC (needs real staff auth + `hospital_id` claim — not built),
  **CSO sign-off + Hazard Log / CSCR** entry for the workflow.
- Honesty note: code-reviewed, **NOT** executed (no live Postgres this session); no frontend surface to preview
  (staff UI is the documented follow-on). Not a compliance claim — the clinical safety case remains 👤 with the CSO.

**Changelog — 2026-06-01 (tamper-evident audit hash chains):**
- §6 — Added `20260601020000_audit_hash_chain.sql`: SHA-256 hash-chaining on BOTH append-only ledgers
  (`cancellation_reviews`, `validation_responses`). A generic `audit_chain_append()` BEFORE INSERT trigger sets
  `prev_hash` + `row_hash = sha256(prev_hash || canonical-business-columns)`; appends are advisory-lock serialised
  per table to prevent chain forks. `verify_audit_chain(table)` re-walks a chain and returns
  `{rows, intact, first_broken_seq}` so alteration/deletion — even via direct DB access that bypasses RLS — is
  DETECTABLE. Uses PG15 **core** `sha256(bytea)` → no pgcrypto/extension dependency (lower apply risk).
- Design note: the trigger fires automatically, so the clinical-safety RPCs (`submit_validation_response`,
  `resolve_cancellation`) are UNCHANGED. Trigger and verifier hash the identical canonical payload
  (`to_jsonb(row)` minus `seq`/`prev_hash`/`row_hash`); `id`/`created_at` DEFAULTs resolve before the BEFORE
  INSERT trigger, so trigger-time and persisted rows hash the same. Updated the stale "later hardening" comment
  in the clinical-review migration to point here.
- Honesty note: tamper-**evident**, not tamper-**proof** — detection, not prevention; a DB admin could rewrite
  the entire chain. External WORM/notarisation of the tail hash is a 👤 Trust operational step. Code-reviewed,
  **NOT** executed; not a compliance claim.

**Changelog — 2026-06-01 (proxy access — server-side scaffold):**
- §10 — Added `20260601030000_proxy_access_scaffold.sql`: the SERVER-SIDE foundation for verified proxy access
  (caring for a dependent), so "proxy" can never be a client-asserted claim. `patient_proxies` (active +
  consented + time-bounded, `proxy<>subject`, unique pair); `auth.has_proxy_access()` STABLE fail-closed
  predicate; `pol_entries_proxy_select` third permissive SELECT policy (OR-combines with patient-self + admin);
  `grant_proxy_access` (**staff-gated** via the `hospital_id` claim → a patient cannot self-grant) and
  `revoke_proxy_access` (subject/proxy/staff). Proxy mock `🚫👤 → ⚠️👤`.
- Security back-check during build: caught + closed a self-grant hole — without the `hospital_id` gate any
  authenticated user could have granted themselves access to another record by passing `p_proxy = own uid`.
  Now fail-closed (no staff claim → `NOT_AUTHORISED_TO_GRANT_PROXY`). Ships with zero relationships → no access
  change by default.
- `portal/app.js`: comment + banner updated to honestly say the client is still a UX demo (no identity switch,
  no subject-picker) while the backend foundation now exists. Cache-bust `app.js?v=20260601b`.
- 🚫👤 Still required: Caldicott-approved consent + identity verification of both parties; lawful basis for
  under-16s / incapacity; a staff grant/revoke UI (shared with the §1 staff-auth follow-on).
- Honesty note: code-reviewed, **NOT** executed (no live Postgres this session); not a compliance claim.

**Changelog — 2026-06-01 (NHS Login OIDC — code-side wiring):**
- §10 — The portal's "Sign in with NHS Login" button now starts the REAL OIDC flow
  (`db.auth.signInWithOAuth({ provider, options:{ redirectTo } })`) when the backend is configured AND
  `window.__ENV.NHS_OIDC_PROVIDER` is set; otherwise it falls back to the local mock credential form. New
  `useRealOidc` config gate + `startNhsLogin()` handler in `portal/app.js`; `env.example.js` documents the
  public provider-name knob (the OIDC client id/secret + NHS Login issuer/scopes live in the Supabase dashboard,
  **never in the repo**). Mock-NHS-Login item `⚠️ → ⚠️👤` (code path real; integration is the Trust step).
- Verified live (dev-mock, no provider): the button still reveals the mock form, focus moves to email, and the
  full login → dashboard flow works (greeting renders); no console errors. Cache-bust `app.js?v=20260601c`.
- 👤 Still required (only the Trust can): real NHS Login client registration, P9 identity proofing, claim mapping
  (`nhs_number`, `identity_proofing_level`), and security assurance. The identity-matcher (`link_my_waitlist_record`,
  2026-06-01) consumes exactly those claims once they flow.
- Honesty note: not a compliance claim; the OAuth redirect path itself is code-reviewed but unexercised without a
  registered provider (no live OIDC this session).

**Changelog — 2026-06-01 (FHIR decision record + roadmap close-out):**
- §9 — Recorded an explicit DECISION not to build a FHIR surface now (`❌ → ➖👤`): there is no consuming system
  today, so a speculative FHIR API would add attack surface + PII exposure + maintenance for zero benefit and
  couldn't be verified. Documented the UK Core mapping (waitlist → `ServiceRequest`/`Appointment` + `Patient`,
  NHS Number as `Patient.identifier`, reuse `is_valid_nhs_number`) for if/when a real integration appears. This
  is a recorded architecture decision, **not** an open gap — the Trust owns the trigger.
- This closes the code-closeable roadmap (items 1–7): identity matching, portal data minimisation, security.txt,
  incident runbook, clinical-review workflow, tamper-evident audit chains, proxy-access scaffold, NHS Login OIDC
  code path, and this FHIR decision. **What remains is NOT code:** (a) stand up a real Supabase project and
  EXECUTE all 10 migrations (every backend item is "code-reviewed, not executed"); (b) dashboard settings
  (UK region, admin MFA, OIDC provider registration); (c) the staff-tooling UI + real staff auth; and (d) all
  👤 Trust governance sign-offs (CSO/Hazard Log/CSCR, DPIA, DSPT, Caldicott, CREST pen test, Cyber Essentials
  Plus, formal WCAG audit, at-rest encryption). **No "compliant" claim at any point — only "built to align with,
  pending sign-off."**
