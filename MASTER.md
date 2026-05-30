# NHS Waitlist Validation — MASTER bundle

> **AUTO-GENERATED — do not edit by hand.** Single-file snapshot of every
> git-tracked text file, for easy review / handover. Regenerate with
> `python tools/build_master.py`. The individual files remain the source of
> truth; this is a convenience copy. Generated from commit `38071ac`.
>
> Secrets are never included — only git-tracked files are bundled, so the
> gitignored `env.js` is excluded and only the `env.example.js` template appears.


**29 files** in this bundle.


## Contents

- [`README.md`](#readme-md)
- [`COMPLIANCE.md`](#compliance-md)
- [`SECURITY.md`](#security-md)
- [`ACCESSIBILITY.md`](#accessibility-md)
- [`SESSION_LOG_2026-05-29.md`](#session-log-2026-05-29-md)
- [`COMPLIANCE_CHANGELOG.md`](#compliance-changelog-md)
- [`frontend/app.js`](#frontend-app-js)
- [`frontend/env.example.js`](#frontend-env-example-js)
- [`frontend/index.html`](#frontend-index-html)
- [`frontend/styles.css`](#frontend-styles-css)
- [`frontend/vercel.json`](#frontend-vercel-json)
- [`portal/app.js`](#portal-app-js)
- [`portal/env.example.js`](#portal-env-example-js)
- [`portal/index.html`](#portal-index-html)
- [`portal/styles.css`](#portal-styles-css)
- [`supabase/config.toml`](#supabase-config-toml)
- [`supabase/functions/_shared/nhs-number.ts`](#supabase-functions-shared-nhs-number-ts)
- [`supabase/functions/sms-dispatch-worker/index.ts`](#supabase-functions-sms-dispatch-worker-index-ts)
- [`supabase/migrations/20260528120000_waitlist_status_pending_cancellation.sql`](#supabase-migrations-20260528120000-waitlist-status-pending-cancellation-sql)
- [`supabase/migrations/20260529000000_section_11_tokens_rpc.sql`](#supabase-migrations-20260529000000-section-11-tokens-rpc-sql)
- [`supabase/migrations/20260529040000_retention_and_erasure.sql`](#supabase-migrations-20260529040000-retention-and-erasure-sql)
- [`supabase/migrations/20260529050000_nhs_number_modulus11.sql`](#supabase-migrations-20260529050000-nhs-number-modulus11-sql)
- [`supabase/migrations/20260529060000_issue_validation_token.sql`](#supabase-migrations-20260529060000-issue-validation-token-sql)
- [`project-status/index.html`](#project-status-index-html)
- [`.claude/hooks/compliance_backcheck.py`](#claude-hooks-compliance-backcheck-py)
- [`.claude/launch.json`](#claude-launch-json)
- [`.claude/settings.local.json`](#claude-settings-local-json)
- [`.gitattributes`](#gitattributes)
- [`.gitignore`](#gitignore)


---


## `README.md`

````markdown
# NHS Waitlist Validation

A patient-facing waitlist validation app: a patient taps a single-use, PII-free link
and confirms whether they still need their scheduled procedure. Static frontend
(vanilla HTML/CSS/JS) on Vercel, talking to a hardened Supabase token + RPC backend.

> ⚠️ **Not certified.** This is built to *align with* NHS standards (DCB0129/0160,
> UK GDPR/DPIA, DTAC v2, WCAG 2.2 AA) but is **not "compliant"** — go-live legally
> requires the Trust's Clinical Safety Officer, Data Protection Officer, and Caldicott
> Guardian sign-off. See `COMPLIANCE.md` for the living status (single source of truth).

> 📦 **Everything in one file:** `MASTER.md` is an auto-generated, read-only bundle of every
> source file (with a table of contents) — handy for review, handover, or pasting into a fresh
> session. Regenerate any time with `python tools/build_master.py`. The individual files remain
> the source of truth; `MASTER.md` never contains secrets (only git-tracked files are bundled, so
> the gitignored `env.js` is excluded).

---

## Repository layout
```
frontend/                 Static patient UI (deploy this to Vercel)
  index.html              Markup + CSP + SRI-pinned Supabase client + env.js loader
  styles.css              Styles (mobile-first, dark mode, reduced-motion, a11y)
  app.js                  Response logic: reads ?t= token, confirm gate, secure RPC
  env.example.js          Template for runtime config -> copy to env.js (gitignored)
  vercel.json             Security headers (CSP, HSTS, etc.)
supabase/
  config.toml             Local project config (PG15)
  migrations/             SQL, applied in filename order (see "Migrations" below)
  functions/              Edge functions (sms-dispatch-worker) + _shared utils
project-status/index.html Engineering status dashboard (open in a browser)
COMPLIANCE.md             Living NHS compliance checklist + DTAC v2 readiness  <- source of truth
SECURITY.md               Secure-SDLC self-declaration (DSIT/NCSC)
ACCESSIBILITY.md          Draft accessibility statement (WCAG 2.2 AA)
SESSION_LOG_2026-05-29.md Build history / decisions
.claude/                  Claude Code project config (TRAVELS with the repo):
  hooks/compliance_backcheck.py   NHS back-check hook
  settings.local.json             Hook wiring + permission allow-list
  launch.json                     Preview servers (frontend:5500, status:5600)
```

## Work on a second machine, identically

Git carries the **code + `.claude/` project config**. It does **not** carry three things
you set up once per machine:

### 1. System prerequisites (install once)
- **Git** — `winget install Git.Git`
- **Python 3** (used by the compliance hook and the local preview) — `winget install Python.Python.3.12`
  - The hook calls `python`, so make sure `python --version` works in a fresh terminal.
- **Claude Code** — the agent we work in. Any one of:
  - **Desktop app (easiest — GUI, no terminal):** download for Windows from <https://claude.com/download>
  - **PowerShell:** `irm https://claude.ai/install.ps1 | iex`
  - **WinGet:** `winget install Anthropic.ClaudeCode`
  - Requires a Claude **Pro / Max / Team** (or Console/API) account — the free plan doesn't include Claude Code.
  - After install, open this project folder in the Desktop app (or run `claude` in it from a terminal) and **sign in with the same Anthropic account you use on the laptop**, so your plan, skills, and connectors come with you. Check it with `claude doctor`.

### 2. Clone the repo
```bash
git clone https://github.com/77Mediaofficial/NHS-APP.git
cd NHS-APP
copy frontend\env.example.js frontend\env.js     # macOS/Linux: cp frontend/env.example.js frontend/env.js
```
`env.js` is gitignored (so a real key can never be pushed). It holds only the **public**
Supabase URL + anon key; fill those in when the backend exists. Until then the app runs
in a safe local "dev-mock" mode.

### 3. Reconnect your MCP connectors
Connector/MCP setup is stored per machine (under `~/.claude`), not in the repo. After signing
in with the same account, most account connectors reappear; reconnect any that don't:
- **Supabase** (database/migrations) and **Vercel** (deploy) — the two needed for this app.
- Plus any others you use (Gmail, Drive, Notion, etc.) — personal, not required to build the app.

Once those three steps are done, the desktop behaves exactly like the laptop: same hook, same
preview servers, same files.

## Running locally
The preview servers are pre-defined in `.claude/launch.json` (Claude Code starts them),
or run them by hand:
```bash
python -m http.server 5500 --directory frontend        # patient app  -> http://localhost:5500
python -m http.server 5600 --directory project-status   # status board -> http://localhost:5600
```

## The NHS compliance hook
On every `Write`/`Edit`/`MultiEdit`, `.claude/hooks/compliance_backcheck.py` runs. When the
edited file is under `frontend/` or `supabase/`, it surfaces the `COMPLIANCE.md` change-review
ritual (does this touch a clinical hazard? PII? update the status markers?). It's a silent
no-op for other files. **Requires `python` on PATH.**

## Migrations (apply in this order)
1. **Base schema — TODO, not yet in repo.** `waitlist_entries` (with `hospital_id`, `status`),
   `hospitals`, `auth.current_hospital_id()`, `sms_dispatch_jobs` + `get_next_sms_batch`.
   These are assumed upstream; an empty project needs them scaffolded first.
2. `20260528120000_waitlist_status_pending_cancellation.sql` — ensures `status` permits the
   reversible `PENDING_CANCELLATION` soft-state (clinical-safety prerequisite).
3. `20260529000000_section_11_tokens_rpc.sql` — tokens, responses, RLS, the secure RPC.
4. `20260529040000_retention_and_erasure.sql` — token auto-purge + right-to-erasure.
5. `20260529050000_nhs_number_modulus11.sql` — NHS Number validator (for any ingest boundary).
6. `20260529060000_issue_validation_token.sql` — per-patient `?t=` link generator.

Apply with `supabase db push` once a **London (`eu-west-2`)** project exists.

## Daily git workflow (both machines)
```bash
git pull                                  # before you start
# ...edit...
git add -A && git commit -m "what changed" && git push   # when you finish
```
Rule of thumb: **pull before, push after.**

## Security rules (non-negotiable)
- Keep this repo **private**.
- **Never commit secrets** — the Supabase **service-role key** and **DB password** live only
  in Supabase/Vercel settings. Only the public URL + anon key go in `env.js` (which is gitignored).
- Don't take the app live before the Trust sign-offs in `COMPLIANCE.md`.
````

---


## `COMPLIANCE.md`

```markdown
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
- Correction note: an earlier draft this session referenced two files (`20260529070000_patient_portal_rls.sql`,
  `portal/vercel.json`) that **do not exist** — those were hallucinated and never committed; no false claim
  landed in the repo (verified: 29 tracked files, working tree clean).
```

---


## `SECURITY.md`

```markdown
# Security & secure-development declaration — NHS Waitlist Validation

> **Self-declaration, built to align with the DSIT/NCSC Software Security Code of
> Practice (DTAC v2 · Technical Security), pending independent assurance.** This is
> NOT an attestation of compliance. Formal assurance — a CREST/CHECK penetration
> test and Cyber Essentials Plus — has not been completed (see `COMPLIANCE.md` §6).

## Reporting a vulnerability
*(To be completed by the Trust before go-live.)* Provide a monitored security contact
(email / form) and expected acknowledgement time. Do not disclose vulnerabilities
publicly before they are resolved. A `SECURITY.txt` should be published at the deploy
domain (`/.well-known/security.txt`).

## Secure design
- **Least privilege.** Patients are unauthenticated and never write tables directly;
  every submission goes through the `submit_validation_response` SECURITY DEFINER RPC.
  `anon` holds EXECUTE on that RPC only. Tables use forced Row Level Security.
- **Data minimisation.** The patient link carries only a random UUID token — zero PII.
- **Reversible-by-default destructive action.** A patient "no longer need it" response
  moves the entry to the reversible `PENDING_CANCELLATION` soft-state for clinical
  review; the unauthenticated path can never write `CANCELLED` (DCB0129/0160).
- **Defence in depth.** CSP (header + meta), HSTS, `X-Content-Type-Options`,
  `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Permissions-Policy`,
  COOP/CORP — see `frontend/vercel.json`.

## Secure build
- **Supply chain.** The single third-party browser dependency (`supabase-js`) is
  **version-pinned** with **Subresource Integrity** (`integrity` + `crossorigin`).
  Version and hash are bumped together on upgrade. No build-time package manager in
  the static frontend reduces dependency surface.
- **Secrets.** Only the public Supabase URL + anon key reach the browser (public by
  design). The service-role key is used solely in server-side edge functions and is
  never shipped to the client. `frontend/env.js` is the only runtime-config surface
  and must contain no secrets.
- **Single-use, expiring tokens.** Atomic token burn in the RPC; 7-day default expiry;
  spent/expired tokens auto-purged (`purge_expired_tokens`).

## Secure deployment
- **TLS / transport.** HTTPS enforced (HSTS + `upgrade-insecure-requests`); TLS
  termination by the platform (Vercel).
- **Data residency.** Data layer to be confirmed in the UK (London / eu-west-2);
  the static edge serves only the PII-free page (`COMPLIANCE.md` §7).
- **Reproducible config.** Security headers are declared in version control
  (`vercel.json`), not set ad hoc.

## Dependency & patch management
- Pinned dependency + SRI hash reviewed on every upgrade.
- *(To set up with the Trust:)* automated dependency-vulnerability alerting and a
  defined patch SLA.

## Outstanding assurance (requires the Trust / external parties)
- ❌ CREST/CHECK penetration test commissioned and findings remediated.
- ❌ Cyber Essentials Plus certification held by the operating organisation.
- ⚠️ Mandatory MFA enforced + evidenced for all admin / remote access (Supabase
  dashboard and any operations console).
- ⚠️ Tamper-evident audit trail; confirm no token↔PII correlation in request logs.

_Last reviewed: 2026-05-29 (engineering self-declaration)._
```

---


## `ACCESSIBILITY.md`

```markdown
# Accessibility statement — NHS Waitlist Validation (DRAFT)

> **DRAFT — built to align with WCAG 2.2 AA, pending a formal independent audit and
> Trust sign-off.** This statement follows the GOV.UK / Public Sector Bodies
> (Websites and Mobile Applications) Accessibility Regulations 2018 model. It must
> NOT be published as final until an external WCAG 2.2 AA audit and screen-reader
> testing are complete. Do not describe the service as "fully compliant" before then.

## Scope
This statement covers the patient-facing waitlist validation page (`frontend/`):
the single-question response screen, the confirmation step, and the outcome message.

## How accessible this service is
We have designed and built this service to aim for **WCAG 2.2 level AA**. The following
are **in place and self-tested** (developer testing, not yet an independent audit):

- **Keyboard operable** — all controls are reachable and operable by keyboard;
  visible focus indicators via `:focus-visible`.
- **Skip link** to the main question (WCAG 2.4.1).
- **Status messaging** — outcomes use `role="status"` / `aria-live`; errors use
  `role="alert"`; focus moves to the outcome after submission.
- **Confirmation step** for the irreversible "no longer need it" choice, with the
  safe option presented first and focused (also a clinical-safety mitigation).
- **Reduced motion** honoured via `prefers-reduced-motion`.
- **Colour contrast (developer-measured against AA 4.5:1 normal text):**
  - Light theme — secondary text `#5a6473` on white ≈ **6.0:1**; green accent
    `#006a4e` ≈ **6.6:1**; alert text `#b8421f` ≈ **5.5:1**.
  - Dark theme — secondary text `#9aa4b2` on `#12161e` ≈ **7.2:1**.
  - *These are computed values and must be confirmed by the formal audit, including
    non-text/UI-component contrast (3:1) and focus-indicator contrast.*
- **Resize / reflow** — layout is fluid to 320 px with no horizontal scrolling and
  supports 200% zoom (viewport allows user scaling).
- **Language** of the page is set (`lang="en-GB"`).

## Known gaps / not yet done (before this statement can be finalised)
- ❌ **Formal independent WCAG 2.2 AA audit** and remediation.
- ❌ **Assistive-technology testing** with NVDA, JAWS and VoiceOver, plus mobile
  screen readers (TalkBack / VoiceOver iOS).
- ❌ **Accessible Information Standard (DCB1605)** — how communication-needs flags
  (easy-read, large-print, BSL, alternative formats) are honoured for the SMS link
  and this page. Owned with the Trust's communications team.
- ❌ **NHS.UK design system alignment** review — current UI is bespoke; reconcile
  against NHS.UK frontend patterns / service manual.
- ⚠️ Reading order, headings and labels to be verified with AT (h1 present in the
  question state; outcome state uses h2).

## Feedback and contact
*(To be completed by the Trust before publication.)* Provide an email/phone for
reporting accessibility problems and requesting information in an alternative format,
and the expected response time.

## Enforcement procedure
If you contact us with a complaint and are not happy with our response, contact the
Equality Advisory and Support Service (EASS). *(Confirm wording at publication.)*

## Preparation of this statement
- Statement drafted: 2026-05-29 (DRAFT — engineering self-assessment).
- Last self-tested: 2026-05-29.
- Formal audit date: **not yet scheduled.**
```

---


## `SESSION_LOG_2026-05-29.md`

```markdown
# Session Log — NHS Waitlist Validation — 2026-05-29

> Saved at user request ("SAVE ALL INFO FROM THIS SESSION"). Companion to `COMPLIANCE.md`
> (the living compliance source of truth). This is a point-in-time record of what happened
> and why. Re-read `COMPLIANCE.md` for the authoritative, maintained status.

## Standing mandate (still in force)
Follow NHS security & privacy rules strictly; back-check **every** `frontend/` and `supabase/`
change against `COMPLIANCE.md`. Enforcement = checklist + auto PostToolUse hook. Scope = full set.
**Honesty rule:** never describe the system as "compliant" — only "built to align with [standard],
pending [DPO / Caldicott / CSO] sign-off."

## DTAC v2 — facts as supplied by the project owner (NOT independently verified this session)
- NHS England published **DTAC v2.0 on 2026-02-24**; **v1.0 retired 2026-04-06** (v1.0 forms now rejected).
- **~25% question reduction** — de-duplicates overlap across DTAC / DSPT / PAQ; pass DSPT ⇒ don't re-evidence in DTAC.
- **DSIT/NCSC Software Security Code of Practice** — must explicitly declare secure design/build/deploy SDLC.
- **NICE scope alignment** — DTAC now explicitly targets software-based DHTs (SaaS, mobile, clinical decision tools); excludes generic corporate IT (HR etc.). *This waitlist SaaS is in scope.*
- **Section D usability no longer numerically scored** for pass/fail, but WCAG 2.2 AA + Accessible Information Standard still legally required.
- **CSO** no longer needs NHS England-provided training, but the CSO role criteria still apply.
- Accountable-officer / SME roles per section (from DTAC guidance): C1 clinical safety → CCIO/CNIO + CSO; C2 data protection → DPO + IG officer; C3 technical security → CISO/CTO + cyber manager/architect; C4 interoperability → CIO/CTO + architect; D1 usability → CTO/CIO + architect/BA.

## DGAT .docx files reviewed (in drive-download-20260529T075653Z-3-001)
`Change Specification`, `Implementation Guidance`, `Requirements Specification`.
**Finding:** these are **generic NHS England DGAT authoring templates** (blank boilerplate for
publishing a DAPB information standard under s.250 Health & Social Care Act 2012) — section
headings, style guide, `<insert>` placeholders, RFC 2119 / MoSCoW guidance. **No DTAC v2 content,
no specific requirements.** Transferable ideas only: MUST/SHOULD/MAY requirement discipline +
named accountable-officer/SME roles (which reinforce that key gates need human sign-off).

## Fixes implemented + live-verified this session
1. **Clinical hazard — single-tap irreversible cancel (DCB0129/0160).**
   - Frontend confirmation gate (`#confirm` in `index.html`, logic in `app.js`): decline never submits
     on one tap; safe "No, keep my place" listed first and focused.
   - Backend reversible soft-state: RPC `submit_validation_response` now sets
     `status = 'PENDING_CANCELLATION'` (not `CANCELLED`); policy `pol_entries_update_definer`
     locked `WITH CHECK (status = 'PENDING_CANCELLATION')`.
2. **Contract bug `?t=` vs `?token=`.** `app.js` now reads `?t=` (canonical) with `?token=` fallback.
3. **Supply chain / transport.** SRI-pinned `supabase-js@2.106.2` (integrity + crossorigin) in
   `index.html`; authoritative CSP + HSTS + hardening headers in `frontend/vercel.json`; meta CSP for defence-in-depth.

## Files touched
- `frontend/index.html` — CSP meta, SRI-pinned script, confirmation gate, versioned app.js.
- `frontend/styles.css` — `.confirm` panel styles.
- `frontend/app.js` — `?t=` read, NEEDS_CONFIRMATION flow, confirm/back handlers.
- `frontend/vercel.json` — CSP, HSTS, nosniff, frame DENY, referrer, Permissions-Policy, COOP/CORP.
- `supabase/migrations/20260529000000_section_11_tokens_rpc.sql` — soft-state + WITH CHECK + upstream note.
- `COMPLIANCE.md` — §1/§4/§5/§6/§9 updates, DTAC v2 caveat, readiness snapshot, changelog.
- `project-status/index.html` — rewritten: dual meters, DTAC pillar table, soft-state flow, blockers.
- `.claude/hooks/compliance_backcheck.py` + `.claude/settings.local.json` — PostToolUse back-check hook (Python; jq unavailable).

## DTAC v2 readiness self-assessment ≈ 37 / 100 (NOT a certification)
| Pillar | Wt | Score |
|---|---|---|
| 1 Clinical safety | 25% | 30 |
| 2 Data protection | 25% | 35 |
| 3 Technical security | 20% | 55 |
| 4 Interoperability | 10% | 20 |
| 5 Usability/accessibility | 20% | 40 |
Engineering-controls-only sub-score ≈ 85/100. Gap dominated by human/org gates + external certs.

## Open blockers
- **Code (I can do):** `waitlist_entries.status` domain must permit `PENDING_CANCELLATION` *before* migration applies (hard blocker); token retention/auto-purge + erasure; NHS Number mod-11 validator at any future ingest boundary; accessibility hardening + statement; secure-SDLC / SSCoP declaration doc.
- **Human authority (Trust only):** CSO + Hazard Log + Clinical Safety Case Report; DPIA + DPO + Caldicott; DSPT submission; CREST/CHECK pen test; Cyber Essentials Plus; admin MFA enforcement; formal WCAG 2.2 AA audit; verify Supabase region = London/eu-west-2.

## Caveats to carry forward
- DTAC v2 dates/wording above are the owner's sourced model — re-confirm live form with the Trust before submission.
- Postgres not runnable locally this session — SQL changes are code-reviewed, not executed.

---

## No-Trust completion pass (2026-05-29, later)
Goal: finish everything closeable WITHOUT the Trust. New files / changes:

**New migrations (supabase/migrations/):**
- `20260528120000_waitlist_status_pending_cancellation.sql` — PREREQUISITE (dated first). Introspects
  `waitlist_entries.status`; adds `PENDING_CANCELLATION` if enum, else NOTICEs for CHECK-constraint
  case. Resolves the hard blocker so the section-11 policy's `WITH CHECK` resolves. Never hard-fails.
- `20260529040000_retention_and_erasure.sql` — `purge_expired_tokens()` (auto-scheduled via pg_cron
  if present), `purge_aged_validation_responses(interval)` (IG-gated, unscheduled), and
  `erase_patient_validation_data(entry_id)` (hospital-scoped right-to-erasure). UK GDPR §2.
- `20260529050000_nhs_number_modulus11.sql` — `is_valid_nhs_number(text)` IMMUTABLE validator.
- `20260529060000_issue_validation_token.sql` — `issue_validation_token(entry_id, base_url, ttl)`
  token-link generator; SECURITY DEFINER, hospital-scoped, authenticated-only, https base-URL guard.

**New shared util:** `supabase/functions/_shared/nhs-number.ts` (`isValidNhsNumber`, `normaliseNhsNumber`).

**Frontend (a11y pass):** skip link; removed broad `aria-live` from `.card`; `#success`
`role="status"`+`aria-live`+`tabindex=-1` with focus moved to it on submit; `#confirm`
`aria-labelledby`/`aria-describedby`; CSS skip-link + programmatic-focus rules; `app.js` focuses
success; runtime config via `frontend/env.js` (+ `env.example.js`, loaded before app.js); cache-bust
bumped to `app.js?v=20260529b`. Contrast measured from tokens — all ≥ AA (no colour change needed).

**New root docs:** `ACCESSIBILITY.md` (DRAFT gov.uk-model statement), `SECURITY.md` (DSIT/NCSC
secure-SDLC self-declaration).

**Live-verified in preview (port 5500, devMock):** env.js + supabase load under CSP/SRI with zero
console errors; decline→confirm focuses safe "No" default; confirmYes→success moves focus to the
outcome; 3 question buttons; all a11y attributes present.

**Readiness re-scored:** ≈ **44/100** (from ~37); engineering sub-score ≈ 90/100.
`COMPLIANCE.md` (§1/§2/§5/§6/§9 + snapshot + changelog) and `project-status/index.html` updated.

**Still Trust-only (unchanged):** CSO + Hazard Log + CSCR; DPIA; DSPT; Caldicott; CREST pen test;
Cyber Essentials Plus; admin MFA enforcement; formal WCAG audit + AT testing; UK residency
verification; at-rest PII encryption; the clinical-review workflow resolving `PENDING_CANCELLATION`;
response retention period (IG decision).

---

## Relocation + GitHub (2026-05-29)
- Project **moved out of `Downloads`** into its own folder: `C:\Users\joedr\projects\nhs-waitlist-validation`.
  (Work from here, NOT Downloads, so the hook/preview fire.)
- **Git repo initialised + pushed** to a PRIVATE GitHub repo: `https://github.com/77Mediaofficial/NHS-APP`.
  `main` tracks `origin/main`. Added `.gitignore` (ignores `*/env.js`, media, secrets) + `.gitattributes` (LF).
- Added turnkey `README.md` (desktop setup: install Claude Code via <https://claude.com/download> or
  `winget install Anthropic.ClaudeCode`; sign in with the SAME Anthropic account; clone; `copy env.example.js env.js`;
  reconnect Supabase + Vercel MCP). Daily workflow: pull before, push after.
- Cross-machine model: git carries code + `.claude/`; it does NOT carry the Claude Code app, MCP account
  connectors, or system tools (Git/Python) — those are set up once per machine.

## Patient Hub portal scaffold (2026-05-29) — `portal/`
- New **fully authenticated** patient dashboard (separate from the anon SMS page). Files: `portal/index.html`,
  `styles.css`, `app.js`, `env.example.js` (+ gitignored `env.js`).
- Security: NO anon data path; `onAuthStateChange` + `getSession` strictly gate the dashboard; data read is
  **IDOR-safe** (`from('waitlist_entries').select('*')` with NO user id — RLS on `auth.uid()` isolates);
  mock NHS Login (button reveals a dev form; **no creds stored in repo**; prod swaps in real OIDC); proxy view
  is a MOCK (no real cross-patient data); CSP meta + SRI-pinned supabase-js; public URL/anon key only.
- A11y: elderly-friendly — larger base type, ≥56px targets, skip link, focus-visible, role=status/alert,
  progressive disclosure, light/dark, reduced-motion.
- Hook extended to fire on `portal/` (+ auth/RLS/IDOR check line). Preview config adds `portal` (:5700).
- **OPEN BACKEND DEPENDENCY (fail-closed today):** patients see nothing until `waitlist_entries` gets a
  `patient_user_id` column linked to the NHS Login identity **and** a policy
  `FOR SELECT TO authenticated USING (patient_user_id = auth.uid())`. See COMPLIANCE.md §10.
- Verified locally: app.js syntax OK; assets serve 200; query IDOR-safe; no hardcoded creds.

**Portal — live preview + fixes (2026-05-29, later):**
- **Bug found & fixed:** author `display:flex` on `.dash`/`.devform` overrode the UA `[hidden]{display:none}`,
  so the dashboard + dev form leaked onto the login screen. Added `[hidden]{display:none!important}` to
  `portal/styles.css`. (Caught by actually viewing the preview.)
- **Dev preview shortcut:** `portal/app.js` now supports `?demo=1` (DEV-ONLY — only when Supabase is NOT
  configured) to jump straight to a mock dashboard for previewing. Bumped `app.js?v=20260529b`.
- **Verified the full flow live** (devMock): login-only on load; Sign in with NHS Login → dev form → submit
  → dashboard hydrates (Hello, Joe · Total Hip Replacement · Active · 2 March 2026 · Royal Surrey County Hospital);
  `?demo=1` lands directly on the dashboard.
- Preview served on **:5701** via a TEMPORARY `Downloads/.claude/launch.json` shim (this session only; the
  project + its real `.claude/launch.json` (`portal` :5700) live in the repo). Sandbox occasionally reaps the
  dev server — just re-run `preview "portal"`. Screenshot tool was unreliable; verification done via DOM eval.
```

---


## `COMPLIANCE_CHANGELOG.md`

```markdown
# Compliance change ledger (AUTO-GENERATED — do not edit by hand)

> Appended automatically by `.claude/hooks/compliance_backcheck.py` on every
> file change (PostToolUse). This is the deterministic audit trail. The curated
> compliance status lives in `COMPLIANCE.md`; this file only records THAT a change
> happened, never a compliance judgement.

| Timestamp (UTC) | Tool | File | Scope |
|---|---|---|---|
```

---


## `frontend/app.js`

```javascript
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
```

---


## `frontend/env.example.js`

```javascript
/* =========================================================================
   Runtime configuration template for the NHS Waitlist Validation frontend.

   Copy this file to `env.js` and fill in the values for your environment, OR
   generate `env.js` at deploy time (e.g. a Vercel build step that echoes the
   public env vars into this shape).

   SECURITY:
     • SUPABASE_URL and SUPABASE_ANON_KEY are PUBLIC by design — the anon key only
       grants EXECUTE on the validation RPC; every table is locked by forced RLS.
       It is safe to ship these to the browser.
     • NEVER place the service-role key (or any secret) in this file — it would be
       exposed to every visitor. The service-role key belongs only in server-side
       edge functions (see supabase/functions/*).
   ========================================================================= */
window.__ENV = {
  SUPABASE_URL: "https://YOUR-PROJECT-REF.supabase.co",
  SUPABASE_ANON_KEY: "YOUR-PUBLIC-ANON-KEY",
};
```

---


## `frontend/index.html`

```html
<!DOCTYPE html>
<html lang="en-GB">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
  <meta name="color-scheme" content="light dark" />
  <title>Waitlist Validation — NHS</title>
  <meta name="description" content="Confirm whether you still need your scheduled NHS procedure." />
  <!-- Content-Security-Policy: defense-in-depth. The AUTHORITATIVE policy is the HTTP
       response header set in vercel.json (a meta CSP cannot enforce frame-ancestors). -->
  <meta http-equiv="Content-Security-Policy"
        content="default-src 'none'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self'; connect-src 'self' https://*.supabase.co; img-src 'self' data:; font-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'" />
  <link rel="preconnect" href="https://cdn.jsdelivr.net" />
  <link rel="stylesheet" href="styles.css" />
</head>
<body>
  <a class="skip-link" href="#question">Skip to the question</a>
  <main class="stage">
    <section class="card">

      <!-- Placeholder NHS Trust Logo -->
      <div class="brand">
        <div class="brand__mark" aria-hidden="true">
          <svg viewBox="0 0 80 32" role="img" focusable="false">
            <rect width="80" height="32" rx="4" fill="currentColor" />
            <text x="40" y="22" text-anchor="middle"
                  font-family="Arial, sans-serif" font-weight="700"
                  font-size="16" fill="#ffffff" letter-spacing="0.5">NHS</text>
          </svg>
        </div>
        <p class="brand__trust">Guildford &amp; Surrey NHS Foundation Trust</p>
      </div>

      <!-- ===== Question state ===== -->
      <div id="question" class="question">
        <p class="eyebrow">Waitlist validation</p>
        <h1 class="headline">Are you still waiting for your<br /><em>Total Hip Replacement?</em></h1>
        <p class="lede">
          Your answer helps us keep your place on the list accurate and offer
          appointments to the people who need them most. It takes one tap.
        </p>

        <div class="actions" role="group" aria-label="Choose the option that applies to you">
          <button class="choice choice--affirm" data-response="confirm" type="button">
            <span class="choice__body">
              <span class="choice__title">Yes, I still need my appointment</span>
              <span class="choice__note">Keep my place on the waiting list</span>
            </span>
            <span class="choice__chevron" aria-hidden="true">→</span>
          </button>

          <button class="choice choice--urgent" data-response="worsened" type="button">
            <span class="choice__body">
              <span class="choice__title">My symptoms have gotten worse</span>
              <span class="choice__note">Flag my case for clinical review</span>
            </span>
            <span class="choice__chevron" aria-hidden="true">→</span>
          </button>

          <button class="choice choice--decline" data-response="decline" type="button">
            <span class="choice__body">
              <span class="choice__title">I no longer need this procedure</span>
              <span class="choice__note">Ask to come off the list — we'll confirm first</span>
            </span>
            <span class="choice__chevron" aria-hidden="true">→</span>
          </button>
        </div>

        <p id="error" class="error" role="alert" hidden></p>
      </div>

      <!-- ===== Confirmation gate for the irreversible "decline" (hidden by default) =====
           DCB0129/0160 mitigation: a destructive response is never sent on a single tap.
           The safe option ("keep my place") is listed first and receives focus. -->
      <div id="confirm" class="confirm" role="group" aria-labelledby="confirmTitle" aria-describedby="confirmDesc" tabindex="-1" hidden>
        <p class="eyebrow">Please confirm</p>
        <h2 class="confirm__title" id="confirmTitle">Come off the waiting list?</h2>
        <p class="confirm__text" id="confirmDesc">
          This tells your care team you no longer need your Total Hip Replacement.
          A clinician reviews every request before your place is removed, and you can
          still change your mind by calling the number on your appointment letter.
        </p>
        <div class="actions">
          <button class="choice choice--affirm" id="confirmNo" type="button">
            <span class="choice__body">
              <span class="choice__title">No, keep my place</span>
              <span class="choice__note">Go back without making changes</span>
            </span>
            <span class="choice__chevron" aria-hidden="true">→</span>
          </button>
          <button class="choice choice--decline" id="confirmYes" type="button">
            <span class="choice__body">
              <span class="choice__title">Yes, ask to be removed</span>
              <span class="choice__note">Send to my care team for review</span>
            </span>
            <span class="choice__chevron" aria-hidden="true">→</span>
          </button>
        </div>
        <p id="confirmError" class="error" role="alert" hidden></p>
      </div>

      <!-- ===== Success state (hidden by default) =====
           role="status" + aria-live announce the outcome to assistive tech when it
           appears; tabindex="-1" lets us move focus here after submission. -->
      <div id="success" class="success" role="status" aria-live="polite" tabindex="-1" hidden>
        <div class="success__tick" aria-hidden="true">
          <svg viewBox="0 0 52 52" focusable="false">
            <circle class="success__ring" cx="26" cy="26" r="24" fill="none" />
            <path class="success__check" fill="none" d="M14 27l8 8 16-18" />
          </svg>
        </div>
        <h2 class="success__title">Thank you.</h2>
        <p class="success__text">Your hospital record has been updated.</p>
        <p id="successDetail" class="success__detail"></p>
      </div>

    </section>

    <footer class="legal">
      <p>This is a secure NHS service. Your response is recorded against your validated record only.</p>
    </footer>
  </main>

  <!-- Supabase JS client — VERSION-PINNED + Subresource Integrity (NCSC supply-chain control).
       A floating @2 tag cannot be SRI-protected because its bytes change on each release.
       Hash computed against this exact pinned URL; bump version + hash together on upgrade.
       Stronger alternative for the Trust to consider: self-host this file under /vendor/. -->
  <script
    src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.106.2"
    integrity="sha384-4Cjkyy4cE1EgIS0C+Y3xzGmJ2noQFRRU91yKAW8IxtPfVtbQXPMqadSc3sYnjwou"
    crossorigin="anonymous"
    referrerpolicy="no-referrer"></script>
  <!-- Runtime config (window.__ENV). Holds ONLY the public Supabase URL + anon key,
       which are public-by-design. Replaced at deploy time. NEVER put the service-role
       key here. Loaded before app.js; see env.example.js for the template. -->
  <script src="env.js"></script>
  <script src="app.js?v=20260529b" defer></script>
</body>
</html>
```

---


## `frontend/styles.css`

```css
/* =========================================================================
   NHS Waitlist Validation — "Refined visual storytelling"
   Mobile-first. System fonts. High-contrast type. Generous whitespace.
   ========================================================================= */

:root {
  --ink:        #0b1220;   /* near-black, high-contrast text */
  --ink-soft:   #5a6473;   /* secondary text */
  --line:       #e7e9ee;   /* hairline borders */
  --surface:    #ffffff;
  --canvas:     #f6f7f9;   /* page background */

  --affirm:     #006a4e;   /* calm NHS green */
  --urgent:     #b8421f;   /* warm amber-red, not alarming */
  --decline:    #3a4250;   /* quiet neutral */

  --focus:      #1d4ed8;
  --shadow:     0 1px 2px rgba(11,18,32,.04), 0 8px 24px rgba(11,18,32,.06);
  --shadow-lift:0 2px 4px rgba(11,18,32,.06), 0 16px 40px rgba(11,18,32,.10);

  --radius:     16px;
  --radius-sm:  12px;
  --ease:       cubic-bezier(.2,.7,.2,1);

  --font: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
          Helvetica, Arial, sans-serif;
}

@media (prefers-color-scheme: dark) {
  :root {
    --ink:      #f3f5f8;
    --ink-soft: #9aa4b2;
    --line:     #232a36;
    --surface:  #12161e;
    --canvas:   #0a0d13;
    --affirm:   #2fbf93;
    --urgent:   #e0734e;
    --decline:  #aeb7c4;
    --shadow:     0 1px 2px rgba(0,0,0,.4), 0 10px 30px rgba(0,0,0,.35);
    --shadow-lift:0 2px 4px rgba(0,0,0,.5), 0 18px 46px rgba(0,0,0,.5);
  }
}

* { box-sizing: border-box; margin: 0; padding: 0; }

html { -webkit-text-size-adjust: 100%; }

/* ---- Skip link (WCAG 2.4.1) — visible only when focused ----------------- */
.skip-link {
  position: absolute;
  left: 12px;
  top: -48px;
  z-index: 10;
  padding: 10px 14px;
  background: var(--surface);
  color: var(--ink);
  border: 1px solid var(--line);
  border-radius: var(--radius-sm);
  font-family: var(--font);
  font-size: .9375rem;
  text-decoration: none;
  transition: top .15s var(--ease);
}
.skip-link:focus-visible {
  top: 12px;
  outline: 2px solid var(--focus);
  outline-offset: 2px;
}

/* Containers focused programmatically (confirm gate, success message) should not
   show a focus ring — focus is moved only to announce, not to indicate a control. */
#confirm:focus, #confirm:focus-visible,
#success:focus, #success:focus-visible { outline: none; }

body {
  font-family: var(--font);
  color: var(--ink);
  background: var(--canvas);
  line-height: 1.5;
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}

/* ---- Layout shell (mobile-first) ---------------------------------------- */
.stage {
  min-height: 100svh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 20px;
  padding: clamp(20px, 6vw, 40px) clamp(18px, 5vw, 32px);
  padding-top: max(28px, env(safe-area-inset-top));
  padding-bottom: max(28px, env(safe-area-inset-bottom));
}

.card {
  width: 100%;
  max-width: 480px;
  margin: 0 auto;
  background: var(--surface);
  border: 1px solid var(--line);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  padding: clamp(24px, 7vw, 40px);
}

/* ---- Brand -------------------------------------------------------------- */
.brand { margin-bottom: 28px; }
.brand__mark { color: var(--affirm); width: 64px; }
.brand__mark svg { display: block; width: 100%; height: auto; }
.brand__trust {
  margin-top: 12px;
  font-size: .8125rem;
  font-weight: 500;
  color: var(--ink-soft);
  letter-spacing: .01em;
}

/* ---- Question ----------------------------------------------------------- */
.eyebrow {
  font-size: .75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: .14em;
  color: var(--ink-soft);
  margin-bottom: 14px;
}

.headline {
  font-size: clamp(1.6rem, 7vw, 2.1rem);
  line-height: 1.15;
  letter-spacing: -0.02em;
  font-weight: 700;
  margin-bottom: 16px;
}
.headline em {
  font-style: normal;
  color: var(--affirm);
}

.lede {
  font-size: 1rem;
  color: var(--ink-soft);
  max-width: 42ch;
  margin-bottom: 28px;
}

/* ---- Action buttons ----------------------------------------------------- */
.actions {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.choice {
  --accent: var(--decline);
  display: flex;
  align-items: center;
  gap: 16px;
  width: 100%;
  text-align: left;
  cursor: pointer;
  background: var(--surface);
  border: 1px solid var(--line);
  border-radius: var(--radius-sm);
  padding: 18px 18px;
  font-family: inherit;
  color: var(--ink);
  transition: transform .18s var(--ease),
              box-shadow .18s var(--ease),
              border-color .18s var(--ease);
}

.choice::before {
  content: "";
  width: 4px;
  align-self: stretch;
  border-radius: 999px;
  background: var(--accent);
  opacity: .85;
  transition: opacity .18s var(--ease);
}

.choice__body { display: flex; flex-direction: column; gap: 3px; flex: 1; }
.choice__title { font-size: 1.0625rem; font-weight: 600; letter-spacing: -.01em; }
.choice__note  { font-size: .8125rem; color: var(--ink-soft); }

.choice__chevron {
  font-size: 1.1rem;
  color: var(--accent);
  opacity: 0;
  transform: translateX(-6px);
  transition: opacity .18s var(--ease), transform .18s var(--ease);
}

.choice--affirm  { --accent: var(--affirm); }
.choice--urgent  { --accent: var(--urgent); }
.choice--decline { --accent: var(--decline); }

/* Hover / focus — clear, refined feedback */
@media (hover: hover) {
  .choice:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-lift);
    border-color: color-mix(in srgb, var(--accent) 45%, var(--line));
  }
  .choice:hover .choice__chevron { opacity: 1; transform: translateX(0); }
}

.choice:focus-visible {
  outline: 2px solid var(--focus);
  outline-offset: 3px;
}

.choice:active { transform: translateY(0) scale(.992); }

/* Busy / disabled states */
.choice[aria-busy="true"] {
  color: var(--ink-soft);
}
.choice[aria-busy="true"] .choice__chevron {
  opacity: 1; transform: none;
  animation: spin .7s linear infinite;
}
.choice:disabled { cursor: default; opacity: .55; }

@keyframes spin { to { transform: rotate(360deg); } }

/* ---- Error -------------------------------------------------------------- */
.error {
  margin-top: 18px;
  padding: 12px 14px;
  font-size: .875rem;
  color: var(--urgent);
  background: color-mix(in srgb, var(--urgent) 8%, transparent);
  border: 1px solid color-mix(in srgb, var(--urgent) 25%, transparent);
  border-radius: var(--radius-sm);
}

/* ---- Confirmation gate (destructive-action mitigation) ------------------ */
.confirm { animation: rise .4s var(--ease) both; }
.confirm__title {
  font-size: clamp(1.5rem, 6vw, 1.9rem);
  line-height: 1.15;
  font-weight: 700;
  letter-spacing: -.02em;
  margin: 6px 0 12px;
}
.confirm__text {
  font-size: 1rem;
  color: var(--ink-soft);
  max-width: 42ch;
  margin-bottom: 24px;
}

/* ---- Success ------------------------------------------------------------ */
.success { text-align: center; padding: 12px 0 4px; }

.success__tick { width: 64px; height: 64px; margin: 0 auto 22px; }
.success__tick svg { width: 100%; height: 100%; }
.success__ring {
  stroke: var(--affirm); stroke-width: 2.5;
  stroke-dasharray: 151; stroke-dashoffset: 151;
  animation: ring .5s var(--ease) forwards;
}
.success__check {
  stroke: var(--affirm); stroke-width: 3.5;
  stroke-linecap: round; stroke-linejoin: round;
  stroke-dasharray: 44; stroke-dashoffset: 44;
  animation: check .35s var(--ease) .4s forwards;
}
@keyframes ring  { to { stroke-dashoffset: 0; } }
@keyframes check { to { stroke-dashoffset: 0; } }

.success__title {
  font-size: clamp(1.5rem, 6vw, 1.9rem);
  font-weight: 700;
  letter-spacing: -.02em;
  margin-bottom: 8px;
}
.success__text   { font-size: 1.0625rem; color: var(--ink); }
.success__detail { font-size: .875rem; color: var(--ink-soft); margin-top: 12px; }

/* ---- Footer ------------------------------------------------------------- */
.legal {
  max-width: 480px;
  margin: 0 auto;
  text-align: center;
}
.legal p {
  font-size: .75rem;
  color: var(--ink-soft);
  max-width: 38ch;
  margin: 0 auto;
}

/* ---- View transition between states ------------------------------------ */
.question, .success { animation: rise .4s var(--ease) both; }
@keyframes rise {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* ---- Larger screens ----------------------------------------------------- */
@media (min-width: 600px) {
  .card { padding: 48px; }
  .choice { padding: 20px 22px; }
}

/* ---- Respect reduced motion -------------------------------------------- */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: .001ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: .001ms !important;
  }
}
```

---


## `frontend/vercel.json`

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'none'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self'; connect-src 'self' https://*.supabase.co; img-src 'self' data:; font-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; upgrade-insecure-requests"
        },
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=63072000; includeSubDomains; preload"
        },
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "Referrer-Policy",
          "value": "no-referrer"
        },
        {
          "key": "Permissions-Policy",
          "value": "geolocation=(), microphone=(), camera=(), payment=(), usb=(), interest-cohort=()"
        },
        {
          "key": "Cross-Origin-Opener-Policy",
          "value": "same-origin"
        },
        {
          "key": "Cross-Origin-Resource-Policy",
          "value": "same-origin"
        }
      ]
    }
  ]
}
```

---


## `portal/app.js`

```javascript
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
```

---


## `portal/env.example.js`

```javascript
/* =========================================================================
   Runtime configuration template for the NHS Patient Hub (portal).
   Copy to env.js and fill in, OR generate env.js at deploy time.

   SECURITY:
     • SUPABASE_URL + SUPABASE_ANON_KEY are PUBLIC by design. The anon key is
       used only to START an auth session; once signed in, every read runs
       under the user's JWT and Row Level Security isolates their data.
     • NEVER put the service-role key (or any secret) here — it would be
       exposed to every visitor. Secrets live only in server-side functions.
   ========================================================================= */
window.__ENV = {
  SUPABASE_URL: "https://YOUR-PROJECT-REF.supabase.co",
  SUPABASE_ANON_KEY: "YOUR-PUBLIC-ANON-KEY",
};
```

---


## `portal/index.html`

```html
<!DOCTYPE html>
<html lang="en-GB">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
  <meta name="color-scheme" content="light" />
  <title>Patient Hub — NHS</title>
  <meta name="description" content="Securely view your NHS waitlist status and manage your care." />

  <!-- CSP: defence-in-depth (authoritative policy belongs in HTTP headers / vercel.json).
       connect-src allows Supabase REST + Auth + Realtime (wss). No anon data path here —
       all reads run under the authenticated user's JWT so RLS isolates the patient. -->
  <meta http-equiv="Content-Security-Policy"
        content="default-src 'none'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self'; connect-src 'self' https://*.supabase.co wss://*.supabase.co; img-src 'self' data:; font-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'" />

  <link rel="preconnect" href="https://cdn.jsdelivr.net" />
  <link rel="stylesheet" href="styles.css?v=20260530" />
</head>
<body>
  <a class="skip-link" href="#main">Skip to main content</a>

  <main id="main" class="stage">

    <!-- ====================================================================
         STATE A — LOGGED OUT: stark, secure login screen
         ==================================================================== -->
    <section id="login" class="card login" aria-labelledby="loginTitle" hidden>
      <div class="brand">
        <div class="brand__mark" aria-hidden="true">
          <svg viewBox="0 0 80 32" role="img" focusable="false">
            <rect width="80" height="32" rx="4" fill="currentColor" />
            <text x="40" y="22" text-anchor="middle" font-family="Arial, sans-serif"
                  font-weight="700" font-size="16" fill="#ffffff" letter-spacing="0.5">NHS</text>
          </svg>
        </div>
        <p class="brand__trust">Guildford &amp; Surrey NHS Foundation Trust</p>
      </div>

      <p class="eyebrow">Patient Hub</p>
      <h1 id="loginTitle" class="headline">Your care,<br /><em>in one place.</em></h1>
      <p class="lede">
        Sign in securely to see your waiting list status, prepare for your
        procedure, and manage care for the people you look after.
      </p>

      <button id="nhsLogin" class="btn btn--primary" type="button">
        <span class="btn__label">Sign in with NHS&nbsp;Login</span>
        <span class="btn__chevron" aria-hidden="true">→</span>
      </button>

      <!-- DEV/MOCK sign-in. In production this whole block is removed: the button
           above redirects to the real NHS Login OIDC provider. For local testing we
           reveal a form so YOU type test credentials — none are stored in the repo. -->
      <form id="devSignin" class="devform" hidden>
        <p class="devform__note">Mock NHS Login (local testing only)</p>
        <label class="field">
          <span class="field__label">Email</span>
          <input id="devEmail" class="field__input" type="email" autocomplete="username"
                 inputmode="email" required />
        </label>
        <label class="field">
          <span class="field__label">Password</span>
          <input id="devPassword" class="field__input" type="password"
                 autocomplete="current-password" required />
        </label>
        <button id="devSubmit" class="btn btn--primary" type="submit">
          <span class="btn__label">Sign in</span>
        </button>
      </form>

      <p id="loginError" class="error" role="alert" hidden></p>
      <p class="login__legal">This is a secure NHS service. Your session is encrypted and your
        data is visible only to you.</p>
    </section>

    <!-- ====================================================================
         STATE B — LOGGED IN: patient dashboard
         ==================================================================== -->
    <section id="dashboard" class="dash" aria-labelledby="greeting" hidden>

      <header class="dash__bar">
        <div class="brand brand--inline">
          <div class="brand__mark brand__mark--sm" aria-hidden="true">
            <svg viewBox="0 0 80 32" role="img" focusable="false">
              <rect width="80" height="32" rx="4" fill="currentColor" />
              <text x="40" y="22" text-anchor="middle" font-family="Arial, sans-serif"
                    font-weight="700" font-size="16" fill="#ffffff" letter-spacing="0.5">NHS</text>
            </svg>
          </div>
        </div>

        <div class="dash__bar-actions">
          <!-- Proxy view: switch to caring for a dependent. MOCK ONLY — real proxy
               access requires verified authorisation + its own RLS + Caldicott consent. -->
          <div class="proxy">
            <button id="proxyToggle" class="proxy__toggle" type="button"
                    role="switch" aria-checked="false" aria-label="Proxy view: care for a dependent">
              <span class="proxy__track" aria-hidden="true"><span class="proxy__thumb"></span></span>
              <span class="proxy__text">Proxy view</span>
            </button>
          </div>
          <button id="signOut" class="btn btn--ghost" type="button">Sign out</button>
        </div>
      </header>

      <!-- Proxy banner (hidden unless proxy view is on) -->
      <p id="proxyBanner" class="proxy-banner" role="status" hidden></p>

      <h1 id="greeting" class="dash__greeting">Hello.</h1>

      <!-- PRIMARY: Waitlist status -->
      <section class="panel panel--primary" aria-labelledby="wlTitle">
        <div class="panel__head">
          <h2 id="wlTitle" class="panel__title">Your waiting list</h2>
          <span id="wlStatus" class="status-chip" data-status="">—</span>
        </div>

        <p class="panel__lead">
          <span id="wlProcedure" class="wl-procedure">Loading your procedure…</span>
        </p>

        <!-- Progressive disclosure: detail is tucked behind a control -->
        <details class="disclose">
          <summary class="disclose__summary">
            <span>What does this mean?</span>
            <span class="disclose__icon" aria-hidden="true">+</span>
          </summary>
          <div class="disclose__body">
            <dl class="kv">
              <div class="kv__row"><dt>Status</dt><dd id="wlStatusText">—</dd></div>
              <div class="kv__row"><dt>Referred</dt><dd id="wlReferred">—</dd></div>
              <div class="kv__row"><dt>Hospital</dt><dd id="wlHospital">—</dd></div>
            </dl>
            <p class="disclose__help">
              If your symptoms change, contact the number on your appointment letter.
            </p>
          </div>
        </details>
      </section>

      <!-- SECONDARY: Pre-op checklist -->
      <section class="panel" aria-labelledby="checkTitle">
        <div class="panel__head">
          <h2 id="checkTitle" class="panel__title">Get ready for your procedure</h2>
        </div>
        <ul class="checklist" id="checklist">
          <li class="check"><span class="check__box" aria-hidden="true">✓</span>
            <span class="check__text">Confirm your contact details are up to date</span></li>
          <li class="check"><span class="check__box" aria-hidden="true">✓</span>
            <span class="check__text">Read your pre-operative information leaflet</span></li>
          <li class="check check--todo"><span class="check__box" aria-hidden="true"></span>
            <span class="check__text">Arrange transport home for the day of surgery</span></li>
          <li class="check check--todo"><span class="check__box" aria-hidden="true"></span>
            <span class="check__text">Complete your health questionnaire</span></li>
        </ul>
      </section>

      <p id="dashError" class="error" role="alert" hidden></p>
    </section>

  </main>

  <!-- Supabase JS — version-pinned + Subresource Integrity (NCSC supply-chain control).
       Bump version + hash together on upgrade. -->
  <script
    src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.106.2"
    integrity="sha384-4Cjkyy4cE1EgIS0C+Y3xzGmJ2noQFRRU91yKAW8IxtPfVtbQXPMqadSc3sYnjwou"
    crossorigin="anonymous"
    referrerpolicy="no-referrer"></script>
  <!-- Runtime config: PUBLIC url + anon key only (env.js is gitignored; see env.example.js). -->
  <script src="env.js"></script>
  <script src="app.js?v=20260529b" defer></script>
</body>
</html>
```

---


## `portal/styles.css`

```css
/* =========================================================================
   NHS Patient Hub — styles.css
   "Refined visual storytelling": calm, spacious, high-end (Monzo/Revolut feel)
   built strictly on the OFFICIAL NHS palette + WCAG 2.2 AA rules.

   Built to ALIGN WITH the NHS Digital Service Manual + WCAG 2.2 AA — not an
   accredited/branded NHS product. Logo here is a placeholder; real NHS identity
   use requires brand permission. Contrast ratios below were computed against AA
   (4.5:1 normal text); confirm in a formal audit.

   Light-only by design: the NHS Service Manual specifies a light UI (NHS Pale
   Grey body, white cards). `color-scheme: light` keeps native form controls light.
   ========================================================================= */

:root {
  /* ---- Official NHS palette ------------------------------------------- */
  --nhs-blue:        #005EB8;  /* Primary. On white ≈ 5.6:1 (AA). */
  --nhs-dark-blue:   #003087;  /* Hover/active for primary. On white ≈ 10.9:1. */
  --nhs-bright-blue: #0072CE;  /* Accents/links if needed. */
  --nhs-black:       #212B32;  /* Body text. On white ≈ 14.5:1. */
  --nhs-grey-1:      #4C6272;  /* Secondary text. On white ≈ 6.0:1 (AA). */
  --nhs-pale-grey:   #E8EDEE;  /* Page background. */
  --nhs-mid-grey:    #AEB7BD;  /* Borders/dividers (decorative). */
  --nhs-white:       #FFFFFF;  /* Elevated cards. */
  --nhs-green:       #007F3B;  /* Success. On white ≈ 5.1:1 (AA). */
  --nhs-red:         #DA291C;  /* Destructive/error. White-on-red ≈ 4.8:1 (AA). */
  --nhs-yellow:      #FFEB3B;  /* Focus indicator (NHS focus state). */
  --nhs-warm-yellow: #FFB81C;  /* Reserved (warnings). */

  /* Semantic aliases */
  --ink:        var(--nhs-black);
  --ink-soft:   var(--nhs-grey-1);
  --line:       #D8DDE0;       /* hairline on white (≈ subtle, decorative) */
  --surface:    var(--nhs-white);
  --canvas:     var(--nhs-pale-grey);
  --primary:    var(--nhs-blue);
  --primary-press: var(--nhs-dark-blue);
  --focus:      var(--nhs-yellow);

  /* ---- Soft-UI shadows (depth without harsh borders) ------------------ */
  --shadow:      0 1px 2px rgba(33,43,50,.06), 0 6px 18px rgba(33,43,50,.08);
  --shadow-lift: 0 2px 6px rgba(33,43,50,.10), 0 14px 34px rgba(33,43,50,.14);

  /* ---- Radius / motion / spacing ------------------------------------- */
  --radius:     8px;           /* cards (per brief) */
  --radius-lg:  12px;          /* hero container */
  --radius-sm:  6px;           /* inputs / chips */
  --ease:       cubic-bezier(.2,.7,.2,1);
  --tap:        48px;          /* minimum touch target (elderly-friendly) */

  --font: "Inter", Arial, -apple-system, BlinkMacSystemFont, "Segoe UI",
          Roboto, Helvetica, sans-serif;

  color-scheme: light;
}

/* ---- Reset -------------------------------------------------------------- */
* { box-sizing: border-box; margin: 0; padding: 0; }
html { -webkit-text-size-adjust: 100%; }

/* The [hidden] attribute MUST always win — author display:flex/grid below would
   otherwise override the UA [hidden]{display:none} and leak hidden views. */
[hidden] { display: none !important; }

body {
  font-family: var(--font);
  color: var(--ink);
  background: var(--canvas);
  /* Fluid base type: comfortable for older eyes; everything scales from here. */
  font-size: clamp(1.0625rem, 0.98rem + 0.45vw, 1.1875rem);
  line-height: 1.55;
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}

/* ---- Skip link (WCAG 2.4.1) — visible only on focus -------------------- */
.skip-link {
  position: absolute; left: 12px; top: -64px; z-index: 30;
  padding: 12px 16px; background: var(--surface); color: var(--ink);
  border-radius: var(--radius-sm); text-decoration: none; font-weight: 600;
  box-shadow: var(--shadow); transition: top .15s var(--ease);
}
.skip-link:focus-visible { top: 12px; }

/* ---- Global focus indicator (WCAG 2.2 — keyboard navigation) -----------
   Never `outline:none` without a high-contrast replacement. NHS-style focus:
   a black inner ring + yellow outer ring, so it's visible on white, blue, or
   any coloured surface. */
:where(a, button, input, select, textarea, summary, [tabindex]):focus-visible {
  outline: 3px solid var(--nhs-yellow);
  outline-offset: 3px;
  box-shadow: 0 0 0 3px var(--nhs-black);
  border-radius: 4px;
}

/* ---- Layout shell (mobile-first) -------------------------------------- */
.stage {
  min-height: 100svh;
  display: flex; flex-direction: column; justify-content: center;
  gap: 18px;
  padding: clamp(20px, 5vw, 44px) clamp(16px, 4vw, 28px);
  padding-top: max(24px, env(safe-area-inset-top));
  padding-bottom: max(24px, env(safe-area-inset-bottom));
}

/* ---- Card (login) ------------------------------------------------------ */
.card {
  width: 100%; max-width: 520px; margin: 0 auto;
  background: var(--surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow);
  padding: clamp(26px, 7vw, 44px);
  animation: rise .4s var(--ease) both;
}

/* ---- Brand (NHS logo lockup) ------------------------------------------ */
.brand { margin-bottom: 26px; }
.brand--inline { margin: 0; }
.brand__mark { color: var(--nhs-blue); width: 68px; }   /* blue box, white "NHS" */
.brand__mark--sm { width: 52px; }
.brand__mark svg { display: block; width: 100%; height: auto; }
.brand__trust { margin-top: 12px; font-size: .9375rem; font-weight: 600; color: var(--ink-soft); }

/* ---- Type -------------------------------------------------------------- */
.eyebrow {
  font-size: .8125rem; font-weight: 700; text-transform: uppercase;
  letter-spacing: .12em; color: var(--ink-soft); margin-bottom: 14px;
}
.headline {
  font-size: clamp(2rem, 1.4rem + 3vw, 2.6rem); line-height: 1.12;
  letter-spacing: -0.02em; font-weight: 700; color: var(--ink); margin-bottom: 18px;
}
.headline em { font-style: normal; color: var(--nhs-blue); }   /* NHS-blue accent */
.lede { font-size: 1.0625rem; color: var(--ink-soft); max-width: 44ch; margin-bottom: 30px; }

/* ---- Buttons ----------------------------------------------------------- */
.btn {
  display: inline-flex; align-items: center; justify-content: center; gap: 12px;
  width: 100%; min-height: var(--tap);
  padding: 14px 22px; border-radius: var(--radius); border: 2px solid transparent;
  font-family: inherit; font-size: 1.0625rem; font-weight: 600; cursor: pointer;
  transition: background-color .2s var(--ease), border-color .2s var(--ease),
              transform .2s var(--ease), box-shadow .2s var(--ease);
}
/* Primary — solid NHS blue, white text (≈ 5.6:1) */
.btn--primary { background: var(--primary); color: #fff; box-shadow: var(--shadow); }
.btn--primary:hover { background: var(--primary-press); }       /* darker blue */
/* Secondary — outlined */
.btn--ghost {
  width: auto; min-height: var(--tap); padding: 11px 18px; font-size: 1rem;
  background: var(--surface); color: var(--nhs-blue); border-color: var(--nhs-blue);
}
.btn--ghost:hover { background: #eef4fb; }
/* Destructive — solid NHS red, white text (≈ 4.8:1) */
.btn--danger { background: var(--nhs-red); color: #fff; }
.btn--danger:hover { background: #b71f14; }

@media (hover: hover) {
  .btn--primary:hover, .btn--danger:hover { transform: translateY(-1px); box-shadow: var(--shadow-lift); }
}
.btn:active { transform: translateY(0) scale(.99); }
.btn:disabled, .btn[aria-busy="true"] { opacity: .5; cursor: not-allowed; transform: none; box-shadow: none; }
.btn__chevron { font-size: 1.2rem; line-height: 1; }

/* ---- Dev sign-in form -------------------------------------------------- */
.devform {
  margin-top: 22px; display: flex; flex-direction: column; gap: 16px;
  padding-top: 22px; border-top: 1px solid var(--line);
}
.devform__note {
  font-size: .8125rem; color: var(--ink-soft); font-weight: 700;
  text-transform: uppercase; letter-spacing: .08em;
}
.field { display: flex; flex-direction: column; gap: 8px; }
.field__label { font-size: 1rem; font-weight: 600; color: var(--ink); }
.field__input {
  min-height: var(--tap); padding: 13px 16px; font: inherit; color: var(--ink);
  background: var(--surface); border: 2px solid var(--nhs-mid-grey);
  border-radius: var(--radius-sm);
}
.field__input:hover { border-color: var(--nhs-grey-1); }
.field__input:focus { border-color: var(--nhs-blue); }       /* + focus-visible ring above */

/* ---- Login footnote ---------------------------------------------------- */
.login__legal { margin-top: 22px; font-size: .9375rem; color: var(--ink-soft); max-width: 44ch; }

/* ---- Error / alert ----------------------------------------------------- */
.error {
  margin-top: 18px; padding: 14px 16px; font-size: 1rem; font-weight: 500;
  color: #fff; background: var(--nhs-red);              /* white-on-red ≈ 4.8:1 */
  border-radius: var(--radius-sm);
}

/* ---- Dashboard --------------------------------------------------------- */
.dash {
  width: 100%; max-width: 640px; margin: 0 auto;
  display: flex; flex-direction: column; gap: 18px;
  animation: rise .4s var(--ease) both;
}
.dash__bar { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.dash__bar-actions { display: flex; align-items: center; gap: 14px; }
.dash__greeting { font-size: clamp(1.9rem, 1.4rem + 2.4vw, 2.4rem); font-weight: 700; letter-spacing: -.02em; }

/* ---- Proxy switch ------------------------------------------------------ */
.proxy__toggle {
  display: inline-flex; align-items: center; gap: 10px; min-height: var(--tap);
  background: none; border: 0; cursor: pointer; color: var(--ink); font: inherit;
  padding: 6px; border-radius: 10px;
}
.proxy__track {
  width: 52px; height: 30px; border-radius: 999px; background: var(--nhs-mid-grey);
  position: relative; transition: background-color .2s var(--ease); flex: 0 0 auto;
}
.proxy__thumb {
  position: absolute; top: 3px; left: 3px; width: 24px; height: 24px; border-radius: 50%;
  background: #fff; box-shadow: 0 1px 3px rgba(33,43,50,.35); transition: transform .2s var(--ease);
}
.proxy__toggle[aria-checked="true"] .proxy__track { background: var(--nhs-blue); }
.proxy__toggle[aria-checked="true"] .proxy__thumb { transform: translateX(22px); }
.proxy__text { font-size: 1rem; font-weight: 600; }

.proxy-banner {
  padding: 14px 16px; border-radius: var(--radius-sm); font-size: 1rem; font-weight: 500;
  color: var(--nhs-black); background: #eef4fb;            /* pale blue tint */
  border-left: 4px solid var(--nhs-blue);
}

/* ---- Panels (white cards, soft depth) --------------------------------- */
.panel {
  background: var(--surface); border-radius: var(--radius);
  box-shadow: var(--shadow); padding: clamp(20px, 5vw, 30px);
}
.panel--primary { border-left: 5px solid var(--nhs-blue); }
.panel__head { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 14px; }
.panel__title { font-size: 1.25rem; font-weight: 700; letter-spacing: -.01em; }
.panel__lead { font-size: 1.0625rem; }
.wl-procedure { font-size: 1.375rem; font-weight: 700; letter-spacing: -.01em; }

/* ---- Status chip — colour is NOT the only cue (dark text + label) ------ */
.status-chip {
  font-size: .9375rem; font-weight: 700; padding: 6px 14px; border-radius: 999px;
  background: var(--nhs-pale-grey); color: var(--nhs-black); white-space: nowrap;
  display: inline-flex; align-items: center; gap: 8px;
}
.status-chip::before {
  content: ""; width: 9px; height: 9px; border-radius: 50%;
  background: var(--nhs-mid-grey); flex: 0 0 auto;
}
.status-chip[data-status="ACTIVE"] { background: #e3f2e9; }            /* pale green */
.status-chip[data-status="ACTIVE"]::before { background: var(--nhs-green); }
.status-chip[data-status="PENDING_CANCELLATION"] { background: #fbe7e5; } /* pale red */
.status-chip[data-status="PENDING_CANCELLATION"]::before { background: var(--nhs-red); }

/* ---- Progressive disclosure ------------------------------------------- */
.disclose { margin-top: 18px; border-top: 1px solid var(--line); padding-top: 6px; }
.disclose__summary {
  display: flex; align-items: center; justify-content: space-between;
  min-height: var(--tap); cursor: pointer; font-weight: 600; font-size: 1.0625rem;
  list-style: none; padding: 8px 2px;
}
.disclose__summary::-webkit-details-marker { display: none; }
.disclose__icon { font-size: 1.5rem; color: var(--nhs-blue); transition: transform .2s var(--ease); line-height: 1; }
.disclose[open] .disclose__icon { transform: rotate(45deg); }
.disclose__body { padding: 6px 2px 10px; }
.disclose__help { margin-top: 12px; color: var(--ink-soft); }

.kv__row { display: flex; justify-content: space-between; gap: 16px; padding: 10px 0; border-bottom: 1px solid var(--line); }
.kv__row:last-child { border-bottom: 0; }
.kv dt { color: var(--ink-soft); }
.kv dd { font-weight: 600; text-align: right; }

/* ---- Pre-op checklist -------------------------------------------------- */
.checklist { list-style: none; display: flex; flex-direction: column; gap: 12px; }
.check { display: flex; align-items: center; gap: 14px; min-height: var(--tap); font-size: 1.0625rem; }
.check__box {
  flex: 0 0 auto; width: 30px; height: 30px; border-radius: 8px;
  display: grid; place-items: center; font-size: .9rem; font-weight: 800;
  background: var(--nhs-green); color: #fff;             /* white tick on green ≈ 5.1:1 */
}
.check--todo .check__box { background: transparent; color: transparent; border: 2px solid var(--nhs-mid-grey); }
.check--todo .check__text { color: var(--ink-soft); }

/* ---- Shared rise transition ------------------------------------------- */
@keyframes rise { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

/* ---- Larger screens ---------------------------------------------------- */
@media (min-width: 640px) {
  .card { padding: 48px; }
  .panel { padding: 32px; }
}

/* ---- Respect reduced motion ------------------------------------------- */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: .001ms !important; animation-iteration-count: 1 !important;
    transition-duration: .001ms !important;
  }
}

/* ---- Windows High Contrast / forced-colors: keep focus + structure ----- */
@media (forced-colors: active) {
  .btn { border: 2px solid currentColor; }
  :where(a, button, input, summary, [tabindex]):focus-visible { outline: 3px solid Highlight; }
  .panel, .card { border: 1px solid currentColor; }
}
```

---


## `supabase/config.toml`

```toml
# A string used to distinguish different Supabase projects on the same host. Defaults to the working directory name.
project_id = "nhs-waitlist-validation"

[api]
port = 54321
# Extracted from your SQL schema setup
schemas = ["public", "graphql_public"]
extra_search_path = ["public", "extensions"]
max_rows = 1000

[db]
port = 54322
# NHS standard requires at least PG15 for some advanced JSONB and security features
major_version = 15

[db.pooler]
enabled = true
port = 54329
pool_mode = "transaction"
default_pool_size = 20
max_client_conn = 100

[edge_runtime]
enabled = true
port = 54328

# ── Function Configurations ───────────────────────────────────────────────────

[functions.sms-dispatch-worker]
# Disables JWT verification since this is invoked by pg_cron (database internal),
# not by an authenticated frontend client.
verify_jwt = false
```

---


## `supabase/functions/_shared/nhs-number.ts`

```typescript
/**
 * NHS Number — modulus 11 check-digit validation (DTAC v2 · Interoperability).
 *
 * Mirror of the SQL `is_valid_nhs_number()` for use in edge/ingest workers
 * (e.g. an admin import or FHIR feed) where PII first enters the system. The
 * patient-facing app is PII-free and does NOT use this.
 *
 * Algorithm (NHS Data Dictionary): 10 digits; weight digits 1..9 by 10..2; sum;
 * remainder = sum % 11; check = 11 - remainder; 11 -> 0; 10 -> invalid; the
 * 10th digit must equal the computed check digit.
 */
export function isValidNhsNumber(input: string | null | undefined): boolean {
  if (input == null) return false;

  const digits = String(input).replace(/[\s-]/g, "");
  if (!/^\d{10}$/.test(digits)) return false;

  let sum = 0;
  for (let i = 0; i < 9; i++) {
    sum += Number(digits[i]) * (10 - i);
  }

  let check = 11 - (sum % 11);
  if (check === 11) check = 0;
  if (check === 10) return false;

  return check === Number(digits[9]);
}

/** Normalise to the canonical 10-digit form, or null if invalid. */
export function normaliseNhsNumber(input: string | null | undefined): string | null {
  if (input == null) return null;
  const digits = String(input).replace(/[\s-]/g, "");
  return isValidNhsNumber(digits) ? digits : null;
}
```

---


## `supabase/functions/sms-dispatch-worker/index.ts`

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

// Initialize Supabase Client with the Service Role Key
// CRITICAL: Bypasses RLS to act as a trusted cross-tenant background worker
const supabaseUrl = Deno.env.get('SUPABASE_URL') as string
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') as string
const supabase = createClient(supabaseUrl, supabaseServiceKey)

const BATCH_SIZE = 100;
const MAX_RETRIES = 3;

// Mock GOV.UK Notify function (Replace with actual fetch to Notify API)
// `reference` is the idempotency key: Notify de-duplicates repeat references,
// so a re-send after a failed completion-write becomes a no-op at the provider.
async function sendGovUkNotify(phone: string, link: string, reference: string) {
  // Simulate network latency
  await new Promise((resolve) => setTimeout(resolve, Math.random() * 150 + 50));

  // Simulate a 1% random failure rate for testing the retry logic
  if (Math.random() < 0.01) throw new Error("GOV.UK Notify API Timeout");

  return true;

  // Real implementation:
  //   const res = await fetch("https://api.notifications.service.gov.uk/v2/notifications/sms", {
  //     method: "POST",
  //     headers: { Authorization: `ApiKey-v1 ${Deno.env.get("NOTIFY_API_KEY")}`,
  //                "Content-Type": "application/json" },
  //     body: JSON.stringify({
  //       phone_number: phone,
  //       template_id: Deno.env.get("NOTIFY_TEMPLATE_ID"),
  //       personalisation: { validation_link: link },
  //       reference, // idempotency key — Notify rejects/dedupes repeats
  //     }),
  //   });
  //   if (!res.ok) throw new Error(`Notify ${res.status}: ${await res.text()}`);
}

Deno.serve(async (req) => {
  // 1. Claim the next batch of jobs using the RPC function
  const { data: jobs, error: claimError } = await supabase.rpc('get_next_sms_batch', {
    batch_size: BATCH_SIZE
  });

  if (claimError) {
    console.error("Failed to claim jobs:", claimError);
    return new Response(JSON.stringify({ error: claimError.message }), { status: 500 });
  }

  if (!jobs || jobs.length === 0) {
    return new Response(JSON.stringify({ message: "Queue empty. No jobs processed." }), { status: 200 });
  }

  console.log(`Processing batch of ${jobs.length} jobs...`);

  // Execution counters
  let successes = 0;
  let retried = 0;
  let permanentlyFailed = 0;

  // 2. Process all jobs concurrently without failing the whole batch if one drops
  await Promise.allSettled(
    jobs.map(async (job: any) => {
      try {
        // Attempt to send the SMS (job.id doubles as the Notify idempotency reference)
        await sendGovUkNotify(job.patient_phone, job.payload_link, job.id);

        // On success, mark as completed (lowercase to match DB ENUM)
        const { error: updateError } = await supabase
          .from('sms_dispatch_jobs')
          .update({
            status: 'completed',
            locked_at: null,
            last_error: null
          })
          .eq('id', job.id);

        if (updateError) throw updateError; // Throw to the catch block to be retried

        successes++;

      } catch (err: any) {
        // Resolve error message
        const errorMessage = err instanceof Error ? err.message : String(err);

        // Assess retry threshold and new status (lowercase ENUMs)
        const newRetryCount = job.retry_count + 1;
        const isPermanentFailure = newRetryCount > MAX_RETRIES;
        const newStatus = isPermanentFailure ? 'failed' : 'pending';

        console.warn(`Job ${job.id} failed (Retry ${newRetryCount}):`, errorMessage);

        // Safely update the failure state and populate last_error
        const { error: fallbackUpdateError } = await supabase
          .from('sms_dispatch_jobs')
          .update({
            status: newStatus,
            retry_count: newRetryCount,
            locked_at: null, // Release lock so it can be reclaimed if pending
            last_error: errorMessage
          })
          .eq('id', job.id);

        // Unchecked failure-path defence: Log if the database rejects the failure update
        if (fallbackUpdateError) {
          console.error(`CRITICAL: Failed to write failure state for job ${job.id}:`, fallbackUpdateError);
        }

        // Increment the correct summary counter
        if (isPermanentFailure) {
            permanentlyFailed++;
        } else {
            retried++;
        }
      }
    })
  );

  // 3. Summarize execution cleanly for the dashboard metrics
  return new Response(
    JSON.stringify({
      message: "Batch complete",
      total_processed: jobs.length,
      successes: successes,
      retried_transient: retried,
      failed_dead_letter: permanentlyFailed
    }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
```

---


## `supabase/migrations/20260528120000_waitlist_status_pending_cancellation.sql`

```sql
-- =============================================================================
-- PREREQUISITE: waitlist_entries.status must permit 'PENDING_CANCELLATION'
-- =============================================================================
-- CLINICAL-SAFETY (DCB0129/0160): the patient-facing RPC moves a declined entry
-- into the REVERSIBLE soft-state 'PENDING_CANCELLATION' instead of a hard cancel.
-- The section-11 migration (20260529000000) defines a policy whose
-- `WITH CHECK (status = 'PENDING_CANCELLATION')` expression must resolve against
-- the column's domain — so this value MUST exist BEFORE that migration runs.
-- This file is intentionally dated earlier so it applies first.
--
-- `waitlist_entries` is an UPSTREAM/managed table not created in this repo, and we
-- do not know whether `status` is a Postgres ENUM or a TEXT column with a CHECK
-- constraint. This migration introspects the live schema and does the right thing,
-- and NEVER hard-fails: if it cannot safely widen the domain it raises an explicit
-- NOTICE telling the operator exactly what to change. Idempotent + safe to re-run.
-- Target: PostgreSQL 15 (per supabase/config.toml) — ALTER TYPE ... ADD VALUE is
-- permitted inside a transaction on PG12+ (the value is not USED in this same tx).
-- =============================================================================

DO $$
DECLARE
    v_type_oid   oid;
    v_typname    text;
    v_typnsp     text;
    v_typtype    "char";
    v_has_value  boolean;
    v_check_rec  record;
    v_found      boolean := false;
BEGIN
    -- Resolve the data type backing public.waitlist_entries.status
    SELECT t.oid, t.typname, n.nspname, t.typtype
      INTO v_type_oid, v_typname, v_typnsp, v_typtype
      FROM pg_attribute a
      JOIN pg_class     c ON c.oid = a.attrelid
      JOIN pg_namespace cn ON cn.oid = c.relnamespace
      JOIN pg_type      t ON t.oid = a.atttypid
      JOIN pg_namespace n ON n.oid = t.typnamespace
     WHERE cn.nspname = 'public'
       AND c.relname  = 'waitlist_entries'
       AND a.attname  = 'status'
       AND a.attnum   > 0
       AND NOT a.attisdropped;

    IF NOT FOUND THEN
        RAISE NOTICE '[status-domain] public.waitlist_entries.status not found. '
            'If this table is managed elsewhere, ensure its status domain permits '
            '''PENDING_CANCELLATION'' before applying migration 20260529000000.';
        RETURN;
    END IF;

    -- CASE 1: status is an ENUM ------------------------------------------------
    IF v_typtype = 'e' THEN
        SELECT EXISTS (
            SELECT 1 FROM pg_enum
             WHERE enumtypid = v_type_oid AND enumlabel = 'PENDING_CANCELLATION'
        ) INTO v_has_value;

        IF v_has_value THEN
            RAISE NOTICE '[status-domain] enum %.% already contains '
                '''PENDING_CANCELLATION'' — no change needed.', v_typnsp, v_typname;
        ELSE
            EXECUTE format(
                'ALTER TYPE %I.%I ADD VALUE IF NOT EXISTS %L',
                v_typnsp, v_typname, 'PENDING_CANCELLATION'
            );
            RAISE NOTICE '[status-domain] added ''PENDING_CANCELLATION'' to enum %.%.',
                v_typnsp, v_typname;
        END IF;
        RETURN;
    END IF;

    -- CASE 2: status is TEXT/VARCHAR/etc. — look for CHECK constraints ----------
    FOR v_check_rec IN
        SELECT con.conname, pg_get_constraintdef(con.oid) AS def
          FROM pg_constraint con
          JOIN pg_class      c  ON c.oid = con.conrelid
          JOIN pg_namespace  cn ON cn.oid = c.relnamespace
         WHERE cn.nspname = 'public'
           AND c.relname  = 'waitlist_entries'
           AND con.contype = 'c'
           AND pg_get_constraintdef(con.oid) ILIKE '%status%'
    LOOP
        v_found := true;
        IF v_check_rec.def ILIKE '%PENDING_CANCELLATION%' THEN
            RAISE NOTICE '[status-domain] CHECK constraint % already permits '
                '''PENDING_CANCELLATION'' — no change needed. (%).',
                v_check_rec.conname, v_check_rec.def;
        ELSE
            RAISE NOTICE '[status-domain] ACTION REQUIRED: CHECK constraint % on '
                'public.waitlist_entries restricts status and does NOT permit '
                '''PENDING_CANCELLATION''. Current definition: %. Drop and recreate '
                'it to include ''PENDING_CANCELLATION'' (cannot be auto-rewritten '
                'safely without knowing the full intended value set).',
                v_check_rec.conname, v_check_rec.def;
        END IF;
    END LOOP;

    IF NOT v_found THEN
        RAISE NOTICE '[status-domain] public.waitlist_entries.status is type %.% '
            'with no CHECK constraint — free text accepts ''PENDING_CANCELLATION'' '
            'already. No change needed.', v_typnsp, v_typname;
    END IF;
END;
$$;

-- Verification (run manually after apply):
--   SELECT e.enumlabel FROM pg_enum e
--     JOIN pg_type t ON t.oid = e.enumtypid
--    WHERE t.typname = (SELECT udt_name FROM information_schema.columns
--                        WHERE table_name='waitlist_entries' AND column_name='status');
```

---


## `supabase/migrations/20260529000000_section_11_tokens_rpc.sql`

```sql
-- =============================================================================
-- SECTION 11: SINGLE-USE TOKENS & SECURE RPC (FULLY HARDENED & IDEMPOTENT)
-- =============================================================================
-- Architecture Note: This file relies on explicit permissive RLS policies
-- targeted at the 'postgres' role. If this function's ownership is altered
-- (e.g., ALTER FUNCTION ... OWNER TO least_priv_role), these policies must
-- be updated in tandem to match the new definer security context.
--
-- CLINICAL-SAFETY UPSTREAM DEPENDENCY (DCB0129/0160): a patient response NEVER
-- hard-cancels a waitlist entry. The destructive path moves the entry into the
-- REVERSIBLE soft-state 'PENDING_CANCELLATION', which a clinician reviews and
-- confirms out-of-band. Before applying this migration, ensure the upstream
-- waitlist_entries.status domain (enum or CHECK constraint) permits the value
-- 'PENDING_CANCELLATION'. The hard 'CANCELLED' transition is now owned by the
-- clinical-review workflow, not by an unauthenticated single tap.
-- =============================================================================

-- ── 1. DATA LAYER: TOKENS & RESPONSES ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS waitlist_tokens (
    token               UUID            NOT NULL DEFAULT gen_random_uuid(),
    waitlist_entry_id   UUID            NOT NULL,
    expires_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW() + INTERVAL '7 days',
    used_at             TIMESTAMPTZ,    -- NULL means active/unused
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_waitlist_tokens PRIMARY KEY (token),
    CONSTRAINT fk_token_waitlist  FOREIGN KEY (waitlist_entry_id) REFERENCES waitlist_entries(id) ON DELETE CASCADE
);

COMMENT ON TABLE waitlist_tokens IS 'Cryptographic, single-use URL tokens for unauthenticated patient access.';

CREATE TABLE IF NOT EXISTS validation_responses (
    id                  UUID            NOT NULL DEFAULT gen_random_uuid(),
    waitlist_entry_id   UUID            NOT NULL,
    response_type       TEXT            NOT NULL,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_validation_responses PRIMARY KEY (id),
    CONSTRAINT fk_validation_waitlist  FOREIGN KEY (waitlist_entry_id) REFERENCES waitlist_entries(id) ON DELETE CASCADE,
    CONSTRAINT chk_response_type       CHECK (response_type IN ('STILL_WAITING', 'SYMPTOMS_WORSENED', 'NO_LONGER_NEEDED'))
);

COMMENT ON TABLE validation_responses IS 'Immutable record of patient submissions via the secure RPC.';


-- ── 2. PERFORMANCE OPTIMIZATION INDEXES ──────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_waitlist_tokens_entry_id
    ON waitlist_tokens(waitlist_entry_id);

CREATE INDEX IF NOT EXISTS idx_validation_responses_entry_id
    ON validation_responses(waitlist_entry_id);


-- ── 3. ROW LEVEL SECURITY HARDENING & DEFINE POLICIES ────────────────────────

ALTER TABLE waitlist_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist_tokens FORCE ROW LEVEL SECURITY;

ALTER TABLE validation_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_responses FORCE ROW LEVEL SECURITY;

-- Admin Read Policies
DROP POLICY IF EXISTS pol_tokens_select ON waitlist_tokens;
CREATE POLICY pol_tokens_select
    ON waitlist_tokens FOR SELECT TO authenticated
    USING (waitlist_entry_id IN (
        SELECT id FROM waitlist_entries WHERE hospital_id = auth.current_hospital_id()
    ));

DROP POLICY IF EXISTS pol_validation_select ON validation_responses;
CREATE POLICY pol_validation_select
    ON validation_responses FOR SELECT TO authenticated
    USING (waitlist_entry_id IN (
        SELECT id FROM waitlist_entries WHERE hospital_id = auth.current_hospital_id()
    ));

-- Definer Write Policies (Bypasses implicit reliance on administrative superuser attributes)
DROP POLICY IF EXISTS pol_tokens_update_definer ON waitlist_tokens;
CREATE POLICY pol_tokens_update_definer
    ON waitlist_tokens FOR UPDATE TO postgres
    USING (true);

DROP POLICY IF EXISTS pol_validation_insert_definer ON validation_responses;
CREATE POLICY pol_validation_insert_definer
    ON validation_responses FOR INSERT TO postgres
    WITH CHECK (true);

-- Explicit permission allowing the Security Definer to flag entries for clinical review.
-- CLINICAL-SAFETY (DCB0129/0160): a patient response may ONLY move an entry into the
-- reversible 'PENDING_CANCELLATION' soft-state. WITH CHECK strictly isolates the write
-- to that single value, so this code path can never hard-cancel a patient.
DROP POLICY IF EXISTS pol_entries_update_definer ON waitlist_entries;
CREATE POLICY pol_entries_update_definer
    ON waitlist_entries FOR UPDATE TO postgres
    USING (true)
    WITH CHECK (status = 'PENDING_CANCELLATION');


-- ── 4. SECURITY DEFINER EXECUTION LAYER ──────────────────────────────────────

CREATE OR REPLACE FUNCTION submit_validation_response(
    p_token UUID,
    p_response_type TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_waitlist_entry_id UUID;
    v_response_id UUID;
BEGIN
    -- [CONCURRENCY SAFE]: Atomic evaluation and invalidation state change
    UPDATE waitlist_tokens
    SET used_at = NOW()
    WHERE token = p_token
      AND used_at IS NULL
      AND expires_at > NOW()
    RETURNING waitlist_entry_id INTO v_waitlist_entry_id;

    -- [STABLE MACHINE CONTRACT]: Error string strictly maps to app.js error branch handling
    IF NOT FOUND THEN
        RAISE EXCEPTION 'INVALID_OR_EXPIRED_TOKEN' USING ERRCODE = 'P0001';
    END IF;

    -- Write directly to the validation ledger
    INSERT INTO validation_responses (waitlist_entry_id, response_type)
    VALUES (v_waitlist_entry_id, p_response_type)
    RETURNING id INTO v_response_id;

    -- CLINICAL-SAFETY (DCB0129/0160): a single patient tap must NEVER irreversibly remove
    -- them from a surgical waitlist. Instead of a hard 'CANCELLED', move the entry into the
    -- reversible 'PENDING_CANCELLATION' soft-state for MANDATORY clinical review. The
    -- frontend additionally gates this response behind an explicit confirmation step.
    -- Guard: only transition from an active state; never clobber an already-terminal status.
    IF p_response_type = 'NO_LONGER_NEEDED' THEN
        UPDATE waitlist_entries
        SET status = 'PENDING_CANCELLATION'
        WHERE id = v_waitlist_entry_id
          AND status NOT IN ('CANCELLED', 'PENDING_CANCELLATION');
    END IF;

    RETURN jsonb_build_object('status', 'success', 'response_id', v_response_id);
END;
$$;

-- ── 5. APPLICATION LAYER ENTITLEMENTS ────────────────────────────────────────

REVOKE EXECUTE ON FUNCTION submit_validation_response(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION submit_validation_response(UUID, TEXT) TO anon;
```

---


## `supabase/migrations/20260529040000_retention_and_erasure.sql`

```sql
-- =============================================================================
-- DATA RETENTION & RIGHT TO ERASURE (UK GDPR / DPA 2018)
-- =============================================================================
-- Addresses COMPLIANCE.md §2:
--   • Retention schedule for tokens + responses, enforced by an auto-purge job.
--   • Right to erasure / rectification process for patient responses.
--
-- DESIGN / SAFETY NOTES:
--   • waitlist_tokens are single-use, PII-FREE (UUID + FK + timestamps). Spent or
--     long-expired tokens carry no clinical value, so purging them automatically
--     is low-risk and is scheduled below (if pg_cron is available).
--   • validation_responses record a patient's clinical decision. Their retention
--     period is an INFORMATION-GOVERNANCE / Caldicott decision, NOT a purely
--     technical one. We therefore provide a purge function but DO NOT schedule it
--     by default — the Trust must set the retention interval and own the schedule.
--   • All functions are SECURITY DEFINER with a pinned search_path. The erasure
--     function is scoped to the caller's hospital_id (need-to-know, Caldicott §3).
-- Idempotent + safe to re-run.
-- =============================================================================

-- ── 1. PURGE SPENT / EXPIRED TOKENS (safe to automate) ───────────────────────
-- Removes tokens that are used OR expired beyond a grace window. Returns the row
-- count so a scheduler / dashboard can record purge volumes.
CREATE OR REPLACE FUNCTION purge_expired_tokens(
    p_used_retention    INTERVAL DEFAULT INTERVAL '30 days',
    p_expired_grace     INTERVAL DEFAULT INTERVAL '7 days'
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_deleted INTEGER;
BEGIN
    DELETE FROM waitlist_tokens
     WHERE (used_at IS NOT NULL AND used_at < NOW() - p_used_retention)
        OR (expires_at < NOW() - p_expired_grace);
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;

COMMENT ON FUNCTION purge_expired_tokens(INTERVAL, INTERVAL) IS
    'Deletes spent/expired single-use tokens (PII-free). Safe to schedule. '
    'Returns number of rows purged.';

REVOKE EXECUTE ON FUNCTION purge_expired_tokens(INTERVAL, INTERVAL) FROM PUBLIC;
-- service_role runs the scheduled job; anon is never granted execute.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        EXECUTE 'GRANT EXECUTE ON FUNCTION purge_expired_tokens(INTERVAL, INTERVAL) TO service_role';
    END IF;
END;
$$;


-- ── 2. PURGE AGED VALIDATION RESPONSES (IG-gated — NOT auto-scheduled) ────────
-- Retention period MUST be set by the Trust's IG / Caldicott Guardian. Provided
-- as a callable function only; deliberately left unscheduled. No default that
-- silently destroys clinical records.
CREATE OR REPLACE FUNCTION purge_aged_validation_responses(
    p_retention INTERVAL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_deleted INTEGER;
BEGIN
    IF p_retention IS NULL THEN
        RAISE EXCEPTION 'retention interval is required (set by IG/Caldicott policy)';
    END IF;
    DELETE FROM validation_responses
     WHERE created_at < NOW() - p_retention;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;

COMMENT ON FUNCTION purge_aged_validation_responses(INTERVAL) IS
    'Deletes validation_responses older than the IG-defined retention interval. '
    'NOT scheduled by default — retention period requires Caldicott/IG sign-off.';

REVOKE EXECUTE ON FUNCTION purge_aged_validation_responses(INTERVAL) FROM PUBLIC;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        EXECUTE 'GRANT EXECUTE ON FUNCTION purge_aged_validation_responses(INTERVAL) TO service_role';
    END IF;
END;
$$;


-- ── 3. RIGHT TO ERASURE / RECTIFICATION (admin, need-to-know scoped) ──────────
-- Erases all patient-response artefacts for a single waitlist entry. Callable by
-- an authenticated admin, but ONLY for entries within their own hospital_id
-- (Caldicott need-to-know). SECURITY DEFINER bypasses RLS, so the hospital check
-- is enforced explicitly in-function. Returns a JSONB summary for the audit log.
CREATE OR REPLACE FUNCTION erase_patient_validation_data(
    p_waitlist_entry_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_hospital_id   UUID;
    v_caller_hosp   UUID;
    v_tokens_del    INTEGER := 0;
    v_resp_del      INTEGER := 0;
BEGIN
    -- Need-to-know: confirm the entry belongs to the caller's hospital.
    SELECT hospital_id INTO v_hospital_id
      FROM waitlist_entries WHERE id = p_waitlist_entry_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'WAITLIST_ENTRY_NOT_FOUND' USING ERRCODE = 'P0002';
    END IF;

    v_caller_hosp := auth.current_hospital_id();
    IF v_caller_hosp IS NULL OR v_caller_hosp <> v_hospital_id THEN
        RAISE EXCEPTION 'NOT_AUTHORISED_FOR_THIS_HOSPITAL' USING ERRCODE = 'P0001';
    END IF;

    DELETE FROM validation_responses WHERE waitlist_entry_id = p_waitlist_entry_id;
    GET DIAGNOSTICS v_resp_del = ROW_COUNT;

    DELETE FROM waitlist_tokens WHERE waitlist_entry_id = p_waitlist_entry_id;
    GET DIAGNOSTICS v_tokens_del = ROW_COUNT;

    RETURN jsonb_build_object(
        'status', 'erased',
        'waitlist_entry_id', p_waitlist_entry_id,
        'responses_deleted', v_resp_del,
        'tokens_deleted', v_tokens_del
    );
END;
$$;

COMMENT ON FUNCTION erase_patient_validation_data(UUID) IS
    'UK GDPR right-to-erasure: removes tokens + responses for one waitlist entry, '
    'scoped to the caller''s hospital_id. Returns an audit summary.';

REVOKE EXECUTE ON FUNCTION erase_patient_validation_data(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION erase_patient_validation_data(UUID) TO authenticated;


-- ── 4. SCHEDULE THE SAFE TOKEN PURGE (only if pg_cron is present) ─────────────
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        -- Re-register idempotently: unschedule any prior job of the same name.
        PERFORM cron.unschedule('purge-expired-waitlist-tokens')
          WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'purge-expired-waitlist-tokens');
        PERFORM cron.schedule(
            'purge-expired-waitlist-tokens',
            '17 3 * * *',                          -- daily 03:17
            $cron$ SELECT public.purge_expired_tokens(); $cron$
        );
        RAISE NOTICE '[retention] scheduled daily token purge via pg_cron.';
    ELSE
        RAISE NOTICE '[retention] pg_cron not installed — token purge NOT scheduled. '
            'Enable pg_cron (or call purge_expired_tokens() from an external scheduler).';
    END IF;
END;
$$;
```

---


## `supabase/migrations/20260529050000_nhs_number_modulus11.sql`

```sql
-- =============================================================================
-- NHS NUMBER — MODULUS 11 CHECK-DIGIT VALIDATION (DTAC v2 · Interoperability)
-- =============================================================================
-- Addresses COMPLIANCE.md §9. The patient-facing layer in this repo is PII-FREE
-- (UUID tokens only), so no NHS Number is handled here. This reusable, IMMUTABLE
-- validator is provided so that ANY future ingest boundary (admin import, FHIR
-- feed, PAS sync) can enforce the standard modulus-11 check at the point PII
-- first enters the system — e.g. as a CHECK constraint or a guard in an RPC.
--
-- Algorithm (NHS Data Dictionary): 10 digits. Multiply digits 1..9 by weights
-- 10..2, sum, take remainder mod 11, check digit = 11 - remainder. A result of
-- 11 maps to 0; a result of 10 means the number is INVALID. The 10th digit must
-- equal the computed check digit. Non-digits/spaces/dashes are stripped first.
-- Returns FALSE (never errors) for any malformed input. Idempotent.
-- =============================================================================

CREATE OR REPLACE FUNCTION is_valid_nhs_number(p_input TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE
AS $$
DECLARE
    v_digits TEXT;
    v_sum    INTEGER := 0;
    v_i      INTEGER;
    v_check  INTEGER;
BEGIN
    IF p_input IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Strip spaces and dashes (common formatting), keep digits only.
    v_digits := regexp_replace(p_input, '[\s-]', '', 'g');

    -- Must be exactly 10 numeric digits.
    IF v_digits !~ '^[0-9]{10}$' THEN
        RETURN FALSE;
    END IF;

    -- Weighted sum of the first 9 digits (weights 10 down to 2).
    FOR v_i IN 1..9 LOOP
        v_sum := v_sum + (substr(v_digits, v_i, 1))::INTEGER * (11 - v_i);
    END LOOP;

    v_check := 11 - (v_sum % 11);
    IF v_check = 11 THEN
        v_check := 0;
    ELSIF v_check = 10 THEN
        RETURN FALSE;   -- 10 is not a valid check digit → number invalid
    END IF;

    RETURN v_check = (substr(v_digits, 10, 1))::INTEGER;
END;
$$;

COMMENT ON FUNCTION is_valid_nhs_number(TEXT) IS
    'TRUE if input is a valid 10-digit NHS Number per modulus-11 check digit. '
    'Strips spaces/dashes; returns FALSE for any malformed input. Use at ingest '
    'boundaries where PII enters (admin import, FHIR feed) — not in the PII-free '
    'patient-facing layer.';

-- Pure function, no data access — safe to expose broadly.
GRANT EXECUTE ON FUNCTION is_valid_nhs_number(TEXT) TO PUBLIC;

-- Example usage at a future ingest boundary (commented — apply where appropriate):
--   ALTER TABLE waitlist_entries
--     ADD CONSTRAINT chk_nhs_number_mod11
--     CHECK (nhs_number IS NULL OR is_valid_nhs_number(nhs_number));
```

---


## `supabase/migrations/20260529060000_issue_validation_token.sql`

```sql
-- =============================================================================
-- TOKEN-LINK GENERATOR — issue_validation_token()
-- =============================================================================
-- Issues a single-use validation token for a waitlist entry and returns the
-- canonical, data-minimised patient link (?t=<uuid>). Used by admin tooling /
-- the dispatch pipeline to populate sms_dispatch_jobs.payload_link.
--
-- SECURITY:
--   • SECURITY DEFINER (writes waitlist_tokens under the definer policy) with a
--     pinned search_path.
--   • Need-to-know scoped: an authenticated admin may only issue tokens for
--     entries within their own hospital_id (Caldicott §3). Enforced in-function
--     because SECURITY DEFINER bypasses RLS.
--   • The link contains ONLY a random UUID — zero PII (UK GDPR data minimisation).
--   • anon is NEVER granted execute; only `authenticated`.
-- Idempotent (CREATE OR REPLACE).
-- =============================================================================

CREATE OR REPLACE FUNCTION issue_validation_token(
    p_waitlist_entry_id UUID,
    p_base_url          TEXT,
    p_ttl               INTERVAL DEFAULT INTERVAL '7 days'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_hospital_id UUID;
    v_caller_hosp UUID;
    v_token       UUID;
    v_expires     TIMESTAMPTZ;
    v_base        TEXT;
    v_sep         TEXT;
BEGIN
    -- Validate the entry exists and resolve its hospital.
    SELECT hospital_id INTO v_hospital_id
      FROM waitlist_entries WHERE id = p_waitlist_entry_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'WAITLIST_ENTRY_NOT_FOUND' USING ERRCODE = 'P0002';
    END IF;

    -- Need-to-know: caller's hospital must match the entry's hospital.
    v_caller_hosp := auth.current_hospital_id();
    IF v_caller_hosp IS NULL OR v_caller_hosp <> v_hospital_id THEN
        RAISE EXCEPTION 'NOT_AUTHORISED_FOR_THIS_HOSPITAL' USING ERRCODE = 'P0001';
    END IF;

    -- Basic guard on the base URL (must be https, no query/fragment injection).
    IF p_base_url IS NULL OR p_base_url !~ '^https://[A-Za-z0-9.\-/]+$' THEN
        RAISE EXCEPTION 'INVALID_BASE_URL' USING ERRCODE = 'P0001';
    END IF;

    v_expires := NOW() + COALESCE(p_ttl, INTERVAL '7 days');

    INSERT INTO waitlist_tokens (waitlist_entry_id, expires_at)
    VALUES (p_waitlist_entry_id, v_expires)
    RETURNING token INTO v_token;

    -- Build "<base>?t=<token>" (or "&t=" if the base already has a query string).
    v_base := rtrim(p_base_url, '/');
    v_sep  := CASE WHEN position('?' IN v_base) > 0 THEN '&' ELSE '?' END;

    RETURN jsonb_build_object(
        'token',      v_token,
        'expires_at', v_expires,
        'link',       v_base || v_sep || 't=' || v_token::text
    );
END;
$$;

COMMENT ON FUNCTION issue_validation_token(UUID, TEXT, INTERVAL) IS
    'Issues a single-use, PII-free validation token and returns the ?t= link. '
    'Scoped to the caller''s hospital_id. authenticated-only; never anon.';

REVOKE EXECUTE ON FUNCTION issue_validation_token(UUID, TEXT, INTERVAL) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION issue_validation_token(UUID, TEXT, INTERVAL) TO authenticated;
```

---


## `project-status/index.html`

```html
<!DOCTYPE html>
<html lang="en-GB">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>NHS Waitlist Validation — Build &amp; Compliance Status</title>
<style>
  :root{
    --ink:#0b1220; --soft:#5a6473; --faint:#8a94a3;
    --line:#e7e9ee; --surface:#fff; --canvas:#f6f7f9;
    --done:#006a4e; --done-bg:#e6f4ef;
    --pend:#b8421f; --pend-bg:#fbeee9;
    --warn:#8a5a00; --warn-bg:#fbf3e2;
    --human:#5b3aa6; --human-bg:#efeafb;
    --info:#3a4250;
    --radius:16px; --radius-sm:11px;
    --font:"Inter",-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
    --mono:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;
    --shadow:0 1px 2px rgba(11,18,32,.04),0 10px 30px rgba(11,18,32,.06);
  }
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:var(--font);color:var(--ink);background:var(--canvas);line-height:1.5;-webkit-font-smoothing:antialiased}
  .wrap{max-width:960px;margin:0 auto;padding:clamp(24px,5vw,56px) clamp(18px,4vw,32px)}

  header{margin-bottom:8px}
  .badge{display:inline-flex;align-items:center;gap:8px;background:var(--warn);color:#fff;
    font-size:.72rem;font-weight:700;letter-spacing:.08em;text-transform:uppercase;
    padding:5px 11px;border-radius:6px}
  h1{font-size:clamp(1.7rem,5vw,2.4rem);font-weight:700;letter-spacing:-.025em;margin:18px 0 8px}
  .sub{color:var(--soft);font-size:1.02rem;max-width:64ch}

  /* Honesty banner */
  .note{margin:22px 0 4px;background:var(--warn-bg);border:1px solid #efdcae;border-left:4px solid var(--warn);
    border-radius:var(--radius-sm);padding:14px 16px;font-size:.875rem;color:#5e4300}
  .note b{color:#3f2d00}

  /* Meters */
  .meters{display:grid;gap:18px;grid-template-columns:1fr;margin:26px 0 8px}
  @media(min-width:640px){.meters{grid-template-columns:1fr 1fr}}
  .meter-card{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);padding:18px 20px}
  .meter-card h4{font-size:.82rem;font-weight:700;letter-spacing:.04em;text-transform:uppercase;color:var(--faint);margin-bottom:6px}
  .big{font-size:2rem;font-weight:700;letter-spacing:-.02em}
  .meter{margin:12px 0 6px;height:12px;border-radius:99px;background:#e7e9ee;overflow:hidden}
  .meter__fill{height:100%;border-radius:99px}
  .fill-eng{width:90%;background:linear-gradient(90deg,#006a4e,#2fbf93)}
  .fill-dtac{width:44%;background:linear-gradient(90deg,#b8421f,#e08a3c)}
  .meter-card p{font-size:.8rem;color:var(--soft)}

  .eyebrow{font-size:.72rem;font-weight:700;letter-spacing:.14em;text-transform:uppercase;
    color:var(--faint);margin:40px 0 14px}

  .grid{display:grid;gap:14px;grid-template-columns:1fr}
  @media(min-width:640px){.grid{grid-template-columns:1fr 1fr}}

  .card{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);
    box-shadow:var(--shadow);padding:20px 20px 18px;position:relative;overflow:hidden}
  .card::before{content:"";position:absolute;left:0;top:0;bottom:0;width:4px;background:var(--done)}
  .card.pend::before{background:var(--pend)}
  .card.warn::before{background:var(--warn)}
  .card h3{font-size:1.05rem;font-weight:650;letter-spacing:-.01em;display:flex;align-items:center;gap:9px;flex-wrap:wrap}
  .card .file{font-family:var(--mono);font-size:.78rem;color:var(--faint);margin-top:2px}
  .card ul{list-style:none;margin:13px 0 0;display:flex;flex-direction:column;gap:7px}
  .card li{font-size:.875rem;color:var(--soft);display:flex;gap:9px;align-items:flex-start}
  .tick{flex:0 0 auto;width:16px;height:16px;border-radius:99px;background:var(--done-bg);
    color:var(--done);display:grid;place-items:center;font-size:.66rem;font-weight:800;margin-top:2px}
  .tick.p{background:var(--pend-bg);color:var(--pend)}
  .tick.w{background:var(--warn-bg);color:var(--warn)}
  .tick.h{background:var(--human-bg);color:var(--human)}

  .pill{font-size:.66rem;font-weight:700;letter-spacing:.05em;text-transform:uppercase;
    padding:3px 9px;border-radius:99px;background:var(--done-bg);color:var(--done)}
  .pill.p{background:var(--pend-bg);color:var(--pend)}
  .pill.w{background:var(--warn-bg);color:var(--warn)}

  /* DTAC table */
  .tbl{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);overflow-x:auto}
  table{min-width:520px}
  table{width:100%;border-collapse:collapse;font-size:.875rem}
  th,td{text-align:left;padding:12px 16px;border-bottom:1px solid var(--line);vertical-align:top}
  th{font-size:.7rem;letter-spacing:.08em;text-transform:uppercase;color:var(--faint);font-weight:700}
  tr:last-child td{border-bottom:0}
  .score{font-weight:700;font-variant-numeric:tabular-nums}
  .s-lo{color:var(--pend)} .s-mid{color:var(--warn)} .s-hi{color:var(--done)}
  td .why{color:var(--soft);font-size:.82rem}

  .flow{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);
    box-shadow:var(--shadow);padding:24px;margin-top:4px}
  .flow__row{display:flex;align-items:stretch;gap:0;flex-wrap:wrap}
  .node{flex:1;min-width:120px;text-align:center;padding:14px 10px;border:1px solid var(--line);
    border-radius:var(--radius-sm);background:var(--canvas)}
  .node b{display:block;font-size:.9rem;font-weight:650}
  .node span{font-family:var(--mono);font-size:.72rem;color:var(--faint)}
  .arrow{display:grid;place-items:center;color:var(--faint);font-size:1.2rem;padding:0 6px;min-width:28px}
  @media(max-width:560px){.arrow{transform:rotate(90deg);width:100%;padding:6px 0}}

  .next{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);
    box-shadow:var(--shadow);padding:22px 24px;margin-top:4px}
  .next ul{list-style:none;margin:0;padding:0}
  .next li{font-size:.9rem;color:var(--ink);padding:10px 0;border-bottom:1px solid var(--line);
    display:flex;gap:11px;align-items:flex-start}
  .next li:last-child{border-bottom:0}
  .num{flex:0 0 auto;width:22px;height:22px;border-radius:99px;background:var(--info);color:#fff;
    display:grid;place-items:center;font-size:.74rem;font-weight:700}
  .num.h{background:var(--human)}
  .next code{font-family:var(--mono);font-size:.82rem;background:var(--canvas);padding:1px 6px;border-radius:5px}
  .legend{font-size:.78rem;color:var(--soft);margin-top:10px}
  .legend b{color:var(--human)}

  footer{margin-top:40px;text-align:center;color:var(--faint);font-size:.78rem}
</style>
</head>
<body>
<div class="wrap">

  <header>
    <span class="badge">● Build in progress · not certified</span>
    <h1>NHS Waitlist Validation</h1>
    <p class="sub">Patient-facing waitlist validation app — Vercel-ready static frontend wired to a hardened Supabase token + RPC backend. Built to <em>align with</em> NHS standards; go-live requires Trust sign-off.</p>
  </header>

  <div class="note">
    <b>This is an engineering status page, not a certification.</b> The system must not be described as
    “compliant”. Go-live legally requires the Trust’s Clinical Safety Officer (DCB0129/0160), Data Protection
    Officer (UK GDPR + DPIA), and Caldicott Guardian sign-off — none of which code can substitute for.
    DTAC v2 dates/wording supplied by the project owner are <b>not independently verified</b> in this build.
  </div>

  <div class="note" style="background:var(--pend-bg);border-color:#e7b9a6;border-left-color:var(--pend)">
    <b>Backend not provisioned yet.</b> There is no Supabase project for this app. The only projects on the
    account (77MEDIAOFFICIAL) are unrelated and in <b>eu-west-1 (Ireland)</b>. Before anything can be applied
    or deployed: (1) create a Supabase project in <b>London — eu-west-2</b> (UK residency, §7; can't be changed
    later); (2) scaffold the <b>base schema</b> (<code>waitlist_entries</code>, <code>hospitals</code>,
    <code>auth.current_hospital_id()</code>, <code>sms_dispatch_jobs</code>) — it is assumed upstream and is
    <b>not in this repo</b>, so our migrations can't apply to an empty project until it exists.
  </div>

  <div class="meters">
    <div class="meter-card">
      <h4>Engineering build</h4>
      <div class="big" style="color:var(--done)">≈ 90<span style="font-size:1rem;color:var(--faint)">/100</span></div>
      <div class="meter"><div class="meter__fill fill-eng"></div></div>
      <p>All <em>code</em> closeable without the Trust is done (retention/erasure, NHS-number validator, token generator, accessibility pass, secure-SDLC declaration). Not yet provisioned: no Supabase project + base schema still to scaffold.</p>
    </div>
    <div class="meter-card">
      <h4>DTAC v2 submission readiness</h4>
      <div class="big" style="color:var(--pend)">≈ 44<span style="font-size:1rem;color:var(--faint)">/100</span></div>
      <div class="meter"><div class="meter__fill fill-dtac"></div></div>
      <p>Self-assessment, not a pass (up from ~37). The ceiling is now almost entirely governance/external gates (CSO, DPIA, DSPT, pen test, CE+).</p>
    </div>
  </div>

  <!-- DTAC v2 READINESS -->
  <p class="eyebrow">DTAC v2 readiness by pillar · self-assessment</p>
  <div class="tbl">
    <table>
      <thead><tr><th>Pillar</th><th>Wt</th><th>Score</th><th>Why</th></tr></thead>
      <tbody>
        <tr><td>1 · Clinical safety</td><td>25%</td><td class="score s-lo">32</td><td class="why">Hazards mitigated in code + status-domain prerequisite migration. No CSO, no formal Hazard Log / Clinical Safety Case Report.</td></tr>
        <tr><td>2 · Data protection</td><td>25%</td><td class="score s-mid">45</td><td class="why">Data-minimisation + token auto-purge, IG-gated response purge, hospital-scoped erasure RPC now built. No DPIA, no DSPT, no Caldicott, residency unverified, no at-rest encryption.</td></tr>
        <tr><td>3 · Technical security</td><td>20%</td><td class="score s-mid">60</td><td class="why">SRI, CSP, HSTS, hardening headers, forced RLS, single-use tokens, definer hardening, SSCoP self-declaration, scoped token generator. No CREST pen test, no Cyber Essentials Plus, admin MFA unverified.</td></tr>
        <tr><td>4 · Interoperability</td><td>10%</td><td class="score s-lo">30</td><td class="why">NHS Number modulus-11 validator built + ready (SQL + TS), though N/A in current PII-free scope. No FHIR surface.</td></tr>
        <tr><td>5 · Usability &amp; accessibility</td><td>20%</td><td class="score s-mid">50</td><td class="why">Keyboard, skip-link, focus mgmt, status roles, contrast measured ≥AA, accessibility statement drafted. No formal audit, no screen-reader test, AIS unaddressed.</td></tr>
      </tbody>
    </table>
  </div>

  <!-- FRONTEND -->
  <p class="eyebrow">Frontend · <span style="color:var(--done)">complete</span></p>
  <div class="grid">
    <div class="card">
      <h3>Patient UI <span class="pill">Done</span></h3>
      <div class="file">frontend/index.html</div>
      <ul>
        <li><span class="tick">✓</span>NHS Trust logo + headline</li>
        <li><span class="tick">✓</span>Three accent-coded action buttons</li>
        <li><span class="tick">✓</span>Confirmation gate for destructive “decline” (safe option focused first)</li>
        <li><span class="tick">✓</span>Hidden success state w/ animation</li>
      </ul>
    </div>
    <div class="card">
      <h3>Styling <span class="pill">Done</span></h3>
      <div class="file">frontend/styles.css</div>
      <ul>
        <li><span class="tick">✓</span>System fonts, high-contrast type</li>
        <li><span class="tick">✓</span>Mobile-first, soft shadows</li>
        <li><span class="tick">✓</span>Hover / focus / busy states</li>
        <li><span class="tick">✓</span>Dark mode + reduced-motion; <code>.confirm</code> panel styles</li>
      </ul>
    </div>
    <div class="card">
      <h3>Logic <span class="pill">Done</span></h3>
      <div class="file">frontend/app.js</div>
      <ul>
        <li><span class="tick">✓</span>Reads <code>?t=</code> (canonical) + <code>?token=</code> fallback</li>
        <li><span class="tick">✓</span>Confirmation flow before any decline submit</li>
        <li><span class="tick">✓</span>Secure RPC submission</li>
        <li><span class="tick">✓</span>Error + success state handling</li>
      </ul>
    </div>
    <div class="card warn">
      <h3>Accessibility <span class="pill w">Partial</span></h3>
      <div class="file">WCAG 2.2 AA · AIS · ACCESSIBILITY.md</div>
      <ul>
        <li><span class="tick">✓</span>Skip link, keyboard, focus mgmt on outcome</li>
        <li><span class="tick">✓</span>role="status"/alert, confirm labelledby/describedby</li>
        <li><span class="tick">✓</span>Contrast measured ≥AA; statement drafted</li>
        <li><span class="tick w">!</span>No formal audit / screen-reader test; AIS open</li>
      </ul>
    </div>
  </div>

  <!-- BACKEND -->
  <p class="eyebrow">Backend · <span style="color:var(--done)">code complete</span></p>
  <div class="grid">
    <div class="card">
      <h3>Schema &amp; RLS <span class="pill">Done</span></h3>
      <div class="file">supabase/migrations/…section_11…sql</div>
      <ul>
        <li><span class="tick">✓</span>waitlist_tokens + validation_responses</li>
        <li><span class="tick">✓</span>Forced RLS + admin read policies</li>
        <li><span class="tick">✓</span>Definer write policies (3 tables)</li>
        <li><span class="tick">✓</span>FK indexes, idempotent script</li>
      </ul>
    </div>
    <div class="card">
      <h3>Secure RPC <span class="pill">Done</span></h3>
      <div class="file">submit_validation_response()</div>
      <ul>
        <li><span class="tick">✓</span>Atomic single-use token burn</li>
        <li><span class="tick">✓</span>Stable error contract</li>
        <li><span class="tick">✓</span><b>Reversible</b> <code>PENDING_CANCELLATION</code> soft-state (never hard-cancel)</li>
        <li><span class="tick">✓</span>anon EXECUTE grant, public revoked</li>
      </ul>
    </div>
  </div>

  <!-- DATA PROTECTION & INTEROP (no-Trust pass) -->
  <p class="eyebrow">Data protection &amp; interoperability · <span style="color:var(--done)">new this pass</span></p>
  <div class="grid">
    <div class="card">
      <h3>Retention &amp; erasure <span class="pill">Done</span></h3>
      <div class="file">migrations/20260529040000…sql</div>
      <ul>
        <li><span class="tick">✓</span><code>purge_expired_tokens()</code> — auto-scheduled (pg_cron)</li>
        <li><span class="tick">✓</span><code>erase_patient_validation_data()</code> — hospital-scoped</li>
        <li><span class="tick w">!</span>Response retention period is IG/Caldicott-gated (unscheduled)</li>
        <li><span class="tick">✓</span>service_role / authenticated grants; never anon</li>
      </ul>
    </div>
    <div class="card">
      <h3>Tokens &amp; NHS-number <span class="pill">Done</span></h3>
      <div class="file">migrations 20260528120000 · …050000 · …060000</div>
      <ul>
        <li><span class="tick">✓</span>Status-domain prereq migration (runs first)</li>
        <li><span class="tick">✓</span><code>issue_validation_token()</code> → PII-free <code>?t=</code> link</li>
        <li><span class="tick">✓</span><code>is_valid_nhs_number()</code> SQL + <code>nhs-number.ts</code> (mod-11)</li>
        <li><span class="tick w">!</span>Apply NHS-number check at the real ingest boundary</li>
      </ul>
    </div>
  </div>

  <!-- SECURITY -->
  <p class="eyebrow">Security &amp; transport · <span style="color:var(--done)">hardened</span></p>
  <div class="grid">
    <div class="card">
      <h3>Supply chain + headers <span class="pill">Done</span></h3>
      <div class="file">frontend/index.html · frontend/vercel.json</div>
      <ul>
        <li><span class="tick">✓</span>SRI-pinned <code>supabase-js@2.106.2</code> (integrity + crossorigin)</li>
        <li><span class="tick">✓</span>Authoritative CSP (header) + defence-in-depth meta CSP</li>
        <li><span class="tick">✓</span>HSTS + upgrade-insecure-requests</li>
        <li><span class="tick">✓</span>nosniff, frame DENY, no-referrer, Permissions-Policy, COOP/CORP</li>
      </ul>
    </div>
    <div class="card warn">
      <h3>External assurance <span class="pill w">Needs Trust</span></h3>
      <div class="file">DTAC v2 · pillar 3</div>
      <ul>
        <li><span class="tick h">●</span>CREST/CHECK penetration test</li>
        <li><span class="tick h">●</span>Cyber Essentials Plus certification</li>
        <li><span class="tick w">!</span>Admin MFA — enforce + evidence</li>
        <li><span class="tick w">!</span>SSCoP self-declared (SECURITY.md) — needs independent assurance</li>
      </ul>
    </div>
  </div>

  <!-- PIPELINE -->
  <p class="eyebrow">Data flow</p>
  <div class="flow">
    <div class="flow__row">
      <div class="node"><b>Patient tap</b><span>index.html</span></div>
      <div class="arrow">→</div>
      <div class="node"><b>Confirm (decline)</b><span>safe default</span></div>
      <div class="arrow">→</div>
      <div class="node"><b>RPC call</b><span>app.js · ?t=</span></div>
      <div class="arrow">→</div>
      <div class="node"><b>Validate + burn</b><span>SECURITY DEFINER</span></div>
      <div class="arrow">→</div>
      <div class="node"><b>Record + soft-state</b><span>PENDING_CANCELLATION</span></div>
      <div class="arrow">→</div>
      <div class="node"><b>Clinical review</b><span>out-of-band</span></div>
    </div>
  </div>

  <!-- REMAINING -->
  <p class="eyebrow">Remaining before launch · provisioning &amp; deploy</p>
  <div class="next">
    <ul>
      <li><span class="num h">①</span><div><b>(You) Create the Supabase project — London `eu-west-2`.</b> Not set up yet. Region is permanent and must be UK for §7. Share only the public Project URL + anon key; never the service-role key or DB password.</div></li>
      <li><span class="num">②</span><div><b>(Code, ready when you are) Scaffold the base schema</b> — <code>waitlist_entries</code>, <code>hospitals</code>, <code>auth.current_hospital_id()</code>, <code>sms_dispatch_jobs</code> + <code>get_next_sms_batch</code>. Not in repo today; required before our migrations apply.</div></li>
      <li><span class="num">③</span><div><b>Config</b> — write <code>frontend/env.js</code> from <code>env.example.js</code> with the public URL + anon key (mechanism built).</div></li>
      <li><span class="num">④</span><div><b>Apply migrations</b> — <code>supabase db push</code>: base schema → status-domain prereq → section-11 → retention/erasure → NHS-number → token generator. Re-read the status-domain NOTICE to confirm the domain widened.</div></li>
      <li><span class="num">⑤</span><div><b>Issue links + enqueue</b> — <code>issue_validation_token()</code> per patient → populate <code>sms_dispatch_jobs.payload_link</code>.</div></li>
      <li><span class="num h">⑥</span><div><b>Deploy to Vercel — gated.</b> Ship <code>frontend/</code> static once the clinical/IG sign-offs below are in place. Do not take a patient-facing clinical service live pre-sign-off.</div></li>
      <li><span class="num h">A</span><div><b>Clinical Safety Officer</b> — assign + open Hazard Log &amp; Clinical Safety Case Report; own the <code>PENDING_CANCELLATION</code> → cancel/reinstate review workflow.</div></li>
      <li><span class="num h">A</span><div><b>DPIA + DPO + Caldicott Guardian</b> sign-off; capture app in the Trust’s DSPT submission; set the response retention period.</div></li>
      <li><span class="num h">A</span><div><b>CREST pen test, Cyber Essentials Plus, formal WCAG 2.2 AA audit + AT testing, admin MFA</b> commissioned / enforced + remediated.</div></li>
    </ul>
    <p class="legend"><b>① / ⑥ / “A” (purple)</b> = needs you or human authority (account creation, CSO / DPO / Caldicott / external assurance) — cannot be closed by code alone. Steps ②–⑤ are ready to run the moment the London project exists.</p>
  </div>

  <footer>NHS Waitlist Validation · engineering status as of 29 May 2026 · backend not yet provisioned · single source of truth: <code>COMPLIANCE.md</code></footer>
</div>
</body>
</html>
```

---


## `.claude/hooks/compliance_backcheck.py`

```python
#!/usr/bin/env python3
"""
NHS compliance back-check hook (PostToolUse).

Fires after Write/Edit/MultiEdit. Two jobs:

  (A) AUTOMATIC AUDIT LEDGER (deterministic — happens every time, never skipped).
      Appends a timestamped row to COMPLIANCE_CHANGELOG.md for EVERY file change.
      This is the part a script can do reliably: an immutable trail of what changed
      and when (supports DSPT / IG audit expectations).

  (B) CURATED BACK-CHECK REMINDER (judgement — for the model/human to action).
      When the change touches frontend/, supabase/, or portal/, it injects the
      COMPLIANCE.md change-review ritual. A script must NOT auto-write compliance
      *claims* into the curated checklist — deciding whether a change introduces a
      clinical hazard / touches PII / changes a §-status requires reasoning, and an
      auto-written "compliant" line would violate the project's honesty rule.

This exists because the user mandated: "BACK CHECK AGAINST THEIR REQUIREMENTS
CONSTANTLY WITHOUT FAIL" and "UPDATE OUR CHECKLIST EVERY TIME A CHANGE IS MADE."

Contract: read hook JSON on stdin; append to the ledger; emit JSON on stdout with
hookSpecificOutput.additionalContext when in scope. Always exit 0 so any hiccup
never blocks the edit.
"""
import sys
import os
import json
import re
import datetime

LEDGER_NAME = "COMPLIANCE_CHANGELOG.md"

LEDGER_HEADER = (
    "# Compliance change ledger (AUTO-GENERATED — do not edit by hand)\n\n"
    "> Appended automatically by `.claude/hooks/compliance_backcheck.py` on every\n"
    "> file change (PostToolUse). This is the deterministic audit trail. The curated\n"
    "> compliance status lives in `COMPLIANCE.md`; this file only records THAT a change\n"
    "> happened, never a compliance judgement.\n\n"
    "| Timestamp (UTC) | Tool | File | Scope |\n"
    "|---|---|---|---|\n"
)

MESSAGE = (
    "NHS COMPLIANCE BACK-CHECK REQUIRED. You just edited a file under frontend/, "
    "supabase/, or portal/. An audit row was auto-appended to COMPLIANCE_CHANGELOG.md. "
    "Now run the COMPLIANCE.md change-review ritual (project root):\n"
    "  1. Which COMPLIANCE.md sections does this change touch?\n"
    "  2. Does it introduce or alter a clinical hazard? -> update Section 1 "
    "Hazard Log (DCB0129 / DCB0160). The instant irreversible auto-cancel "
    "hazard is still OPEN.\n"
    "  3. Does it move, log, or expose any PII? -> re-check Section 2 (UK GDPR / "
    "DPA 2018 + DPIA), Section 3 (Caldicott), Section 6 (NCSC 14 Cloud "
    "Principles), Section 7 (UK data residency).\n"
    "  4. Is it a UI/markup/style change? -> verify WCAG 2.2 AA + NHS.UK design "
    "alignment (Section 5).\n"
    "  5. Check the frontend<->backend contract guard (token param name, error "
    "codes, response enum).\n"
    "  5b. PORTAL (authenticated) change? -> no anon data path; reads rely on "
    "auth.uid() via RLS with NO user id in the query (IDOR-safe); no secrets/PII "
    "in the client; auth state strictly gates the dashboard.\n"
    "  6. Update the status markers in COMPLIANCE.md in the SAME change.\n"
    "Do not describe the system as 'compliant' - only 'built to align with "
    "[standard], pending [DPO/Caldicott/CSO] sign-off'."
)

IN_SCOPE_RE = re.compile(r"(^|/)(frontend|supabase|portal)(/|$)", re.IGNORECASE)


def project_root():
    """Prefer CLAUDE_PROJECT_DIR; else derive from this script's location
    (<root>/.claude/hooks/this_file.py)."""
    env = os.environ.get("CLAUDE_PROJECT_DIR")
    if env:
        return env.replace("\\", "/").rstrip("/")
    here = os.path.abspath(__file__).replace("\\", "/")
    # .../.claude/hooks/compliance_backcheck.py -> up three
    return "/".join(here.split("/")[:-3])


def relativise(path, root):
    p = path.replace("\\", "/")
    r = root.replace("\\", "/").rstrip("/")
    if r and p.lower().startswith(r.lower() + "/"):
        return p[len(r) + 1:]
    return p


def append_ledger(root, tool_name, rel_path, in_scope):
    ledger = os.path.join(root, LEDGER_NAME).replace("\\", "/")
    ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    scope = "frontend/supabase/portal" if in_scope else "other"
    # Escape pipes so the markdown table never breaks.
    safe_path = rel_path.replace("|", "\\|")
    row = f"| {ts} | {tool_name} | {safe_path} | {scope} |\n"
    exists = os.path.exists(ledger)
    with open(ledger, "a", encoding="utf-8") as fh:
        if not exists:
            fh.write(LEDGER_HEADER)
        fh.write(row)


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw) if raw.strip() else {}
    except (ValueError, TypeError):
        return  # never block on bad input

    tool_name = data.get("tool_name") or data.get("toolName") or "Edit"
    tool_input = data.get("tool_input") or {}
    path = (
        tool_input.get("file_path")
        or tool_input.get("filePath")
        or tool_input.get("path")
        or ""
    )
    if not path:
        return

    root = project_root()
    rel = relativise(str(path), root)

    # Never log the ledger's own writes (the hook writes it directly, not via a
    # tool, so there's no real recursion — but skip it to avoid meta-noise).
    if rel.replace("\\", "/").lower().endswith(LEDGER_NAME.lower()):
        return

    in_scope = bool(IN_SCOPE_RE.search(rel))

    # (A) Always record the change in the audit ledger.
    try:
        append_ledger(root, str(tool_name), rel, in_scope)
    except Exception:
        pass  # the ledger must never block an edit

    # (B) In-scope changes also get the curated back-check reminder.
    if in_scope:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": MESSAGE,
            }
        }))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # Defensive: a hook must never crash the edit pipeline.
        pass
    sys.exit(0)
```

---


## `.claude/launch.json`

```json
{
  "version": "0.0.1",
  "configurations": [
    {
      "name": "frontend",
      "runtimeExecutable": "python",
      "runtimeArgs": ["-m", "http.server", "5500", "--directory", "frontend"],
      "port": 5500
    },
    {
      "name": "status",
      "runtimeExecutable": "python",
      "runtimeArgs": ["-m", "http.server", "5600", "--directory", "project-status"],
      "port": 5600
    },
    {
      "name": "portal",
      "runtimeExecutable": "python",
      "runtimeArgs": ["-m", "http.server", "5700", "--directory", "portal"],
      "port": 5700
    }
  ]
}
```

---


## `.claude/settings.local.json`

```json
{
  "permissions": {
    "allow": [
      "mcp__Claude_Preview__preview_start",
      "Bash(curl -s -o NUL -w \"%{http_code}\" http://127.0.0.1:5500/index.html)",
      "Bash(curl -s http://127.0.0.1:5500/app.js)",
      "Bash(findstr /C:\"submit_validation_response\")",
      "Bash(python -c \"import json; d=json.load\\(open\\('.claude/settings.local.json'\\)\\); h=d['hooks']['PostToolUse'][0]; assert h['matcher']=='Write|Edit|MultiEdit'; c=h['hooks'][0]; assert c['type']=='command'; print\\('VALID JSON. matcher=',h['matcher']\\); print\\('command=',c['command']\\)\")",
      "Bash(curl -s \"https://data.jsdelivr.com/v1/packages/npm/@supabase/supabase-js/resolved?specifier=2\")",
      "Bash(openssl version *)",
      "Bash(node --check frontend/app.js)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "python \"$CLAUDE_PROJECT_DIR/.claude/hooks/compliance_backcheck.py\"",
            "timeout": 15,
            "statusMessage": "NHS compliance back-check"
          }
        ]
      }
    ]
  }
}
```

---


## `.gitattributes`

```
# Normalise line endings across machines (laptop ↔ desktop) so files don't show
# as "modified" just from CRLF/LF differences. Text files stored as LF in the repo.
* text=auto eol=lf

# Auto-generated append-only audit ledger: union-merge so concurrent appends from
# two machines never conflict (git keeps both sides' new lines automatically).
COMPLIANCE_CHANGELOG.md merge=union

# Treat binaries as binary (never normalise)
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.mp4 binary
*.mov binary
*.zip binary
*.pdf binary
```

---


## `.gitignore`

```
# ============================================================================
# NHS Waitlist Validation — .gitignore
# Keep this repo PRIVATE. Never commit secrets (service-role key, DB password):
# those live ONLY in Supabase / Vercel settings, never in source control.
# ============================================================================

# ---- Secrets / credentials (NEVER commit) ----------------------------------
.env
.env.*
!.env.example
*.key
*.pem
*secret*
*service-role*
*service_role*

# Runtime config holds env-specific public keys — committed template only.
# Copy env.example.js -> env.js locally; env.js is ignored so a real key can
# never be pushed by accident.
frontend/env.js
portal/env.js

# ---- Supabase local state --------------------------------------------------
.supabase/
supabase/.branches/
supabase/.temp/

# ---- Node (if tooling is added later) --------------------------------------
node_modules/
npm-debug.log*
yarn-error.log*
pnpm-debug.log*

# ---- Build / deploy output -------------------------------------------------
dist/
build/
.vercel/

# ---- Large media / binaries (don't sync through git) -----------------------
*.mp4
*.mov
*.heic
*.HEIC
*.zip
*.7z

# ---- OS / editor cruft -----------------------------------------------------
.DS_Store
Thumbs.db
desktop.ini
*.swp
*~
.idea/
.vscode/

# NOTE: .claude/ IS tracked on purpose so the compliance hook + project config
# travel to your other machine. settings.local.json contains no secrets here.
```
