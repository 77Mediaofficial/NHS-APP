# NHS Waitlist Validation — MASTER bundle

> **AUTO-GENERATED — do not edit by hand.** Single-file snapshot of every
> git-tracked text file, for easy review / handover. Regenerate with
> `python tools/build_master.py`. The individual files remain the source of
> truth; this is a convenience copy.
>
> Secrets are never included — only git-tracked files are bundled, so the
> gitignored `env.js` is excluded and only the `env.example.js` template appears.


**48 files** in this bundle.


## Contents

- [`README.md`](#readme-md)
- [`COMPLIANCE.md`](#compliance-md)
- [`SECURITY.md`](#security-md)
- [`ACCESSIBILITY.md`](#accessibility-md)
- [`SESSION_LOG_2026-05-29.md`](#session-log-2026-05-29-md)
- [`COMPLIANCE_CHANGELOG.md`](#compliance-changelog-md)
- [`frontend/.well-known/security.txt`](#frontend-well-known-security-txt)
- [`frontend/app.js`](#frontend-app-js)
- [`frontend/env.example.js`](#frontend-env-example-js)
- [`frontend/index.html`](#frontend-index-html)
- [`frontend/styles.css`](#frontend-styles-css)
- [`frontend/vercel.json`](#frontend-vercel-json)
- [`portal/app.js`](#portal-app-js)
- [`portal/env.example.js`](#portal-env-example-js)
- [`portal/index.html`](#portal-index-html)
- [`portal/styles.css`](#portal-styles-css)
- [`portal/vercel.json`](#portal-vercel-json)
- [`supabase/config.toml`](#supabase-config-toml)
- [`supabase/functions/_shared/nhs-number.ts`](#supabase-functions-shared-nhs-number-ts)
- [`supabase/functions/sms-dispatch-worker/index.ts`](#supabase-functions-sms-dispatch-worker-index-ts)
- [`supabase/migrations/20260527000000_base_schema.sql`](#supabase-migrations-20260527000000-base-schema-sql)
- [`supabase/migrations/20260528120000_waitlist_status_pending_cancellation.sql`](#supabase-migrations-20260528120000-waitlist-status-pending-cancellation-sql)
- [`supabase/migrations/20260529000000_section_11_tokens_rpc.sql`](#supabase-migrations-20260529000000-section-11-tokens-rpc-sql)
- [`supabase/migrations/20260529040000_retention_and_erasure.sql`](#supabase-migrations-20260529040000-retention-and-erasure-sql)
- [`supabase/migrations/20260529050000_nhs_number_modulus11.sql`](#supabase-migrations-20260529050000-nhs-number-modulus11-sql)
- [`supabase/migrations/20260529060000_issue_validation_token.sql`](#supabase-migrations-20260529060000-issue-validation-token-sql)
- [`supabase/migrations/20260529070000_patient_portal_rls.sql`](#supabase-migrations-20260529070000-patient-portal-rls-sql)
- [`supabase/migrations/20260601000000_link_patient_identity.sql`](#supabase-migrations-20260601000000-link-patient-identity-sql)
- [`supabase/migrations/20260601010000_clinical_review_workflow.sql`](#supabase-migrations-20260601010000-clinical-review-workflow-sql)
- [`supabase/migrations/20260601020000_audit_hash_chain.sql`](#supabase-migrations-20260601020000-audit-hash-chain-sql)
- [`supabase/migrations/20260601030000_proxy_access_scaffold.sql`](#supabase-migrations-20260601030000-proxy-access-scaffold-sql)
- [`supabase/tests/verify.sql`](#supabase-tests-verify-sql)
- [`project-status/index.html`](#project-status-index-html)
- [`.claude/hooks/compliance_backcheck.py`](#claude-hooks-compliance-backcheck-py)
- [`.claude/launch.json`](#claude-launch-json)
- [`.claude/settings.local.json`](#claude-settings-local-json)
- [`tools/build_master.py`](#tools-build-master-py)
- [`.gitattributes`](#gitattributes)
- [`.gitignore`](#gitignore)
- [`DEPLOYMENT.md`](#deployment-md)
- [`SECURITY-INCIDENT.md`](#security-incident-md)
- [`governance/DPIA-DRAFT.md`](#governance-dpia-draft-md)
- [`governance/HAZARD-LOG-DRAFT.md`](#governance-hazard-log-draft-md)
- [`staff/app.js`](#staff-app-js)
- [`staff/env.example.js`](#staff-env-example-js)
- [`staff/index.html`](#staff-index-html)
- [`staff/styles.css`](#staff-styles-css)
- [`staff/vercel.json`](#staff-vercel-json)


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

> **Execution status.** All backend SQL is **code-reviewed, not executed** — there is no live database
> in the dev environment. `DEPLOYMENT.md` is the ordered runbook to stand the system up (Supabase UK
> region → apply the 11 migrations in order → dashboard settings → deploy → post-deploy checks), and
> `supabase/tests/verify.sql` is a self-rolling-back assertion harness for the safety-critical logic
> (NHS-number validation, the clinical-review state machine, hash-chain tamper detection, proxy
> fail-closed). Running them produces *evidence* for the sign-off roles; it does not itself confer
> compliance. RLS-as-a-role (authenticated/anon + JWT) is verified by the live post-deploy checks, not
> by the SQL harness — that boundary is stated in both files.

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
  *Head-start:* a **pre-populated Hazard Log draft** (`governance/HAZARD-LOG-DRAFT.md`) captures HAZ-01..06 in
  the DCB0129 format with the in-code mitigations filled in — but **all risk scores + the CSO sign-off are
  `%%PLACEHOLDER%%`**. A draft is not an approved Safety Case; a registered CSO must own it. Status stays 🚫👤.
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
  **Still open before go-live:** (a) ⚠️👤 a **staff-facing UI** that lists `PENDING_CANCELLATION` entries and
  calls `resolve_cancellation()` — now BUILT as a **mock-auth demo** (`staff/`, see §11) wired to the real RPC;
  still 👤 REAL staff auth + the `hospital_id` JWT claim (the demo uses mock sign-in), plus **CSO sign-off + a
  Hazard Log / CSCR entry** for this workflow;
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
  *Head-start:* a **pre-populated DPIA draft** (`governance/DPIA-DRAFT.md`) describes the processing, both
  data surfaces, the data categories/flow, minimisation evidence, and a risk register (R1..R7) pre-filled with
  the in-code mitigations — but **lawful-basis determinations, risk scoring/acceptance, and all signatures are
  `%%PLACEHOLDER%%`** for the DPO + Caldicott Guardian. A draft is not a completed DPIA. Status stays 🚫👤.
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
- ✅ **Content-Security-Policy.** Authoritative header in **both** `frontend/vercel.json` **and**
  `portal/vercel.json` (`default-src 'none'`, script/connect-src locked to self + jsdelivr + `*.supabase.co`
  — portal also `wss://*.supabase.co` for realtime, `frame-ancestors 'none'`, `upgrade-insecure-requests`);
  defence-in-depth `<meta>` CSP mirrors it in each `index.html` (kept byte-aligned with the header).
- ✅ **HSTS + transport.** `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
  + `upgrade-insecure-requests` in **both** `frontend/vercel.json` and `portal/vercel.json`. (TLS termination
  + HTTP→HTTPS handled by Vercel.)
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
  authoritative security headers (`portal/vercel.json`: CSP/HSTS/hardening) + a byte-aligned defence-in-depth
  CSP meta; SRI-pinned `supabase-js@2.106.2`.
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

## 11. Staff Console (clinical review + proxy management) — `staff/` ⚠️
*A separate authenticated STAFF surface that drives the §1 clinical-review workflow and the §10 proxy
mechanism. It exists so the safety-critical RPCs have a human trigger. Demo/mock auth only today.*

- ⚠️👤 **Mock staff auth (production needs real).** Ships with a mock sign-in for local demo; production must
  wire **NHS staff authentication** (Care Identity / hospital SSO) issuing the **`hospital_id` JWT claim** that
  the admin RLS + the RPCs depend on. No credentials in the repo. **This is the single biggest open item for
  this surface** — until real staff auth exists, the console cannot be used on real data.
- ✅ **Actions go through the hardened RPCs, never raw table writes.** Reinstate/Confirm call
  `resolve_cancellation(entry_id, decision)`; proxy grant/revoke call `grant_proxy_access` (staff-gated) /
  `revoke_proxy_access`. The client never mutates tables directly — server-side `auth.uid()`/`hospital_id`
  checks are the real control.
- ✅ **Data minimisation in the worklist.** The worklist query selects only `id, procedure, referred_at, status`
  — **no `nhs_number`** to the staff browser; isolation is by the admin RLS (`hospital_id`).
- ⚠️ **Worklist read scope.** Relies on the §6 admin SELECT policy (`hospital_id = auth.current_hospital_id()`).
  Correct ONLY when staff JWTs carry the hospital claim (the production-auth dependency above).
- ✅ **Same security envelope as the portal.** Own `staff/vercel.json` (CSP incl. `wss:`, HSTS, hardening
  headers) + byte-aligned `<meta>` CSP; SRI-pinned `supabase-js@2.106.2`; PUBLIC-only `staff/env.js` (gitignored).
- ✅ **Accessibility (WCAG 2.2 AA aim).** Shared NHS palette + tokens, 48px targets, `:focus-visible` ring, skip
  link, `role="status"`/`alert`, `forced-colors` + reduced-motion, white-on-red danger button (≈4.8:1). Still
  ❌ formal audit + AT testing (shared with §5).
- ⚠️ **Honest demo banner.** A persistent `role="note"` banner states this is mock staff sign-in, not production
  auth — so a reviewer is never misled about what it is.
- *Verified at logic level this session (Node DOM stub: `?demo=1` → console + 2-item worklist renders; clicking
  Reinstate transitions the entry and it leaves the worklist). Browser-eval click-through deferred (preview tool
  had no `staff` surface this session); live verification is in DEPLOYMENT.md §6.*

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
  patient-SELECT RLS policy). **Update 2026-06-01:** `portal/vercel.json` now also exists for real (added in
  this session's security-headers pass) — so both once-hallucinated paths are now legitimately present.

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

**Changelog — 2026-06-01 (portal authoritative security headers — closes a real gap):**
- §6/§10 — Added `portal/vercel.json` with the full header set (CSP incl. `wss://*.supabase.co` for realtime,
  HSTS preload, `X-Content-Type-Options`, `X-Frame-Options: DENY`, `Referrer-Policy`, `Permissions-Policy`,
  COOP/CORP). Until now the portal had only a defence-in-depth `<meta>` CSP and **no authoritative
  header-level policy** (the frontend had `vercel.json`; the portal did not) — a genuine gap, now closed.
  Aligned the portal `<meta>` CSP byte-for-byte with the header (added `upgrade-insecure-requests`) so the two
  cannot diverge. JSON validated.
- Honesty/consistency: updated the old correction-note — `portal/vercel.json` (once hallucinated) now
  legitimately exists. Not executed against a live deploy (header delivery to confirm at deploy time).

**Changelog — 2026-06-01 (execution bridge: DEPLOYMENT.md + verify.sql):**
- Added `DEPLOYMENT.md` — the ordered runbook from "code-reviewed" to "executed": create Supabase in the
  **UK region**, apply the **11 migrations in the documented order** (incl. the one expected manual NOTICE on
  the status-domain prereq), run the verification harness, complete the dashboard settings (admin MFA, NHS Login
  OIDC provider + claim mapping, region), configure PUBLIC-only env, deploy each surface to Vercel (UK `lhr1`),
  and a post-deploy checklist (headers, security.txt completeness, auth gating, idle timeout, live RLS isolation,
  clinical-review + chain-verify, proxy fail-closed). Human-only steps (credentials/settings) flagged as such.
- Added `supabase/tests/verify.sql` — a single-transaction, **auto-ROLLBACK** assertion harness that directly
  de-risks "code-reviewed, not executed": asserts the NHS-number validator (valid/invalid check digits
  independently verified), the `nhs_number` + `status` CHECK constraints, the clinical-review state machine
  failing **closed** without an identity, the SHA-256 audit chain DETECTING a tamper, and the proxy
  fail-closed predicate + self-grant CHECK. Honestly scoped: it does NOT test RLS-as-a-role (needs a live JWT;
  deferred to DEPLOYMENT.md §6).
- Added an "Execution status" callout under the readiness snapshot so the code-reviewed-vs-executed boundary
  is unmissable. Still not a compliance claim — running these produces evidence, the Trust assesses it.

**Changelog — 2026-06-01 (governance head-start drafts — DPIA + Hazard Log):**
- §2 — Added `governance/DPIA-DRAFT.md`: a pre-populated DPIA capturing the processing description, both data
  surfaces, data categories + flow, minimisation evidence, and a risk register (R1..R7) with in-code mitigations
  filled in. **All lawful-basis calls, risk scores/acceptance and signatures are `%%PLACEHOLDER%%`** for the
  DPO + Caldicott. DPIA item stays 🚫👤 — a draft is not a completed DPIA.
- §1 — Added `governance/HAZARD-LOG-DRAFT.md`: HAZ-01..06 in the DCB0129 format with the in-code mitigations
  documented. **All risk ratings + CSO sign-off are `%%PLACEHOLDER%%`.** Stays 🚫👤 — a registered CSO must own it.
- Why drafts (not "done"): completing these is the legal responsibility of the DPO/Caldicott/CSO; an engineer
  pre-filling the *factual/technical* parts accelerates them without crossing into decisions only those roles
  may make. Both files carry a prominent "DRAFT — confers no compliance" banner, consistent with the honesty rule.

**Changelog — 2026-06-01 (staff console — clinical-review + proxy UI, mock auth):**
- §11 (NEW) — Built `staff/` (index.html + app.js + styles.css + vercel.json + env.example.js): an authenticated
  staff surface that drives the §1 clinical-review workflow (a worklist of `PENDING_CANCELLATION` entries with
  Reinstate / Confirm-cancellation actions) and the §10 proxy mechanism (grant/revoke). Gives the safety-critical
  RPCs their human trigger. §1 hazard sub-point (a) `🚫👤 → ⚠️👤` (UI now exists; real staff auth still 👤).
- Security posture: all mutations go through the hardened RPCs (`resolve_cancellation`, staff-gated
  `grant_proxy_access`, `revoke_proxy_access`) — never raw table writes; worklist selects only non-PII columns
  (no `nhs_number` to the browser); own `vercel.json` security headers + byte-aligned meta CSP + SRI; `staff/env.js`
  gitignored (PUBLIC keys only). Shared NHS design system + WCAG 2.2 AA patterns.
- Honesty: persistent demo banner states it's mock staff sign-in, not production auth. Verified at LOGIC level
  (Node DOM stub: `?demo=1` renders the console + a 2-item worklist; Reinstate transitions an entry and it leaves
  the worklist). Browser click-through deferred (preview tool had no `staff` surface this session) → DEPLOYMENT.md §6.
- 👤 Biggest open item for this surface: real NHS staff authentication (Care Identity / SSO) issuing the
  `hospital_id` claim the RLS + RPCs require. Added `staff` to `.claude/launch.json` (:5800) and `staff/env.js`
  to `.gitignore`. Not a compliance claim.
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
A machine-readable disclosure file (RFC 9116) is provided at
`frontend/.well-known/security.txt`, served at `/.well-known/security.txt` on the
deploy domain (with `Content-Type: text/plain` set in `frontend/vercel.json`). It is a
**template**: the Trust MUST replace every `%%PLACEHOLDER%%` (monitored contact, an
`Expires` date < 1 year out, the canonical domain, disclosure policy) and ideally
PGP-clearsign it **before go-live** — a placeholder `security.txt` is worse than none.
Do not disclose vulnerabilities publicly before they are resolved. For the handling
process once a report arrives, see `SECURITY-INCIDENT.md` (breach-response runbook).

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

_Last reviewed: 2026-06-01 (engineering self-declaration)._
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


## `frontend/.well-known/security.txt`

```
# ============================================================================
# security.txt — vulnerability disclosure contact (RFC 9116)
# NHS Waitlist Validation
# ============================================================================
# This is a TEMPLATE. The Trust MUST replace every %%PLACEHOLDER%% with real,
# monitored values before deployment, then publish it at:
#     https://<deploy-domain>/.well-known/security.txt
#
# An out-of-date or placeholder security.txt is WORSE than none: complete it or
# remove it before go-live. Per RFC 9116 it SHOULD be served over HTTPS as
# text/plain and SHOULD be PGP-clearsigned (see the Signature note at the foot).
#
# RFC 9116 treats the entire text after each "Field:" colon as the value, so the
# example values below are given on their own "#" comment lines, never inline.
# ----------------------------------------------------------------------------

# REQUIRED — a monitored channel for reports. At least one Contact line.
#   example: Contact: mailto:security@example.nhs.uk
Contact: mailto:%%SECURITY_CONTACT_EMAIL%%
# Optional extra channels (uncomment + complete as appropriate):
# Contact: https://%%DEPLOY_DOMAIN%%/security-report
# Contact: tel:%%SECURITY_CONTACT_PHONE%%

# REQUIRED — expiry of this file's data, ISO 8601 (< 1 year out recommended).
# Refresh on every review so it never goes stale.
#   example: Expires: 2027-05-31T23:59:59Z
Expires: %%EXPIRES_ISO8601%%

# Canonical location of this file (where it is authoritatively published).
#   example: Canonical: https://waitlist.example.nhs.uk/.well-known/security.txt
Canonical: https://%%DEPLOY_DOMAIN%%/.well-known/security.txt

# Recommended — disclosure policy + the languages you can read reports in.
Policy: https://%%DEPLOY_DOMAIN%%/security-policy
Preferred-Languages: en

# Optional — PGP key for encrypted reports, and a public acknowledgements page.
# Encryption: https://%%DEPLOY_DOMAIN%%/.well-known/pgp-key.txt
# Acknowledgments: https://%%DEPLOY_DOMAIN%%/security-acknowledgments

# ----------------------------------------------------------------------------
# NOTE — NHS escalation: in addition to the Trust contact above, report to the
# Trust's IG / cyber team and, where applicable, the NHS England Data Security
# Centre national route. Add the correct internal + national contacts here.
#
# NOTE — coordinate this file with SECURITY.md (self-declaration) and
# SECURITY-INCIDENT.md (breach-response runbook) in the repo root.
#
# SIGNATURE — RFC 9116 recommends PGP-clearsigning this file with the security
# contact's key and linking that key via the Encryption field above. Add the
# signature block before publishing.
# ============================================================================
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
  <meta name="color-scheme" content="light" />
  <title>Waitlist Validation — NHS</title>
  <meta name="description" content="Confirm whether you still need your scheduled NHS procedure." />
  <!-- Content-Security-Policy: defense-in-depth. The AUTHORITATIVE policy is the HTTP
       response header set in vercel.json (a meta CSP cannot enforce frame-ancestors). -->
  <meta http-equiv="Content-Security-Policy"
        content="default-src 'none'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self'; connect-src 'self' https://*.supabase.co; img-src 'self' data:; font-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'" />
  <link rel="preconnect" href="https://cdn.jsdelivr.net" />
  <link rel="stylesheet" href="styles.css?v=20260530" />
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
   NHS Waitlist Validation (SMS page) — styles.css
   Same design system as the Patient Hub portal: official NHS palette + WCAG 2.2
   AA rules (NHS Digital Service Manual aesthetic). Calm, spacious, high-end.

   Built to ALIGN WITH the NHS Service Manual + WCAG 2.2 AA — not an accredited
   NHS product. Logo is a placeholder; real NHS identity needs brand permission.
   Contrast ratios are developer-measured against AA; confirm in a formal audit.

   Light-only by design (Service Manual). `color-scheme: light` keeps native
   controls light even on a dark-OS device.
   ========================================================================= */

:root {
  /* ---- Official NHS palette (shared with portal/) --------------------- */
  --nhs-blue:        #005EB8;  /* primary / accent. On white ≈ 5.6:1 (AA). */
  --nhs-dark-blue:   #003087;  /* hover/active. On white ≈ 10.9:1. */
  --nhs-black:       #212B32;  /* body text. On white ≈ 14.5:1. */
  --nhs-grey-1:      #4C6272;  /* secondary text. On white ≈ 6.0:1 (AA). */
  --nhs-pale-grey:   #E8EDEE;  /* page background. */
  --nhs-mid-grey:    #AEB7BD;  /* borders/dividers (decorative). */
  --nhs-white:       #FFFFFF;  /* elevated cards. */
  --nhs-green:       #007F3B;  /* success / "still need it". On white ≈ 5.1:1. */
  --nhs-warm-yellow: #FFB81C;  /* warning / "symptoms worse" (decorative accent). */
  --nhs-red:         #DA291C;  /* destructive / error. White-on-red ≈ 4.8:1 (AA). */
  --nhs-yellow:      #FFEB3B;  /* focus indicator. */

  /* Semantic aliases */
  --ink:        var(--nhs-black);
  --ink-soft:   var(--nhs-grey-1);
  --line:       #D8DDE0;
  --surface:    var(--nhs-white);
  --canvas:     var(--nhs-pale-grey);
  --focus:      var(--nhs-yellow);

  /* Per-choice accent (decorative bar; meaning is carried by the text label) */
  --affirm:     var(--nhs-green);
  --urgent:     var(--nhs-warm-yellow);
  --decline:    var(--nhs-red);

  /* ---- Soft-UI shadows ----------------------------------------------- */
  --shadow:      0 1px 2px rgba(33,43,50,.06), 0 6px 18px rgba(33,43,50,.08);
  --shadow-lift: 0 2px 6px rgba(33,43,50,.10), 0 14px 34px rgba(33,43,50,.14);

  /* ---- Radius / motion / touch --------------------------------------- */
  --radius:     8px;           /* cards / choices (per Service Manual) */
  --radius-lg:  12px;          /* hero container */
  --radius-sm:  6px;
  --ease:       cubic-bezier(.2,.7,.2,1);
  --tap:        48px;          /* minimum touch target (elderly-friendly) */

  --font: "Inter", Arial, -apple-system, BlinkMacSystemFont, "Segoe UI",
          Roboto, Helvetica, sans-serif;

  color-scheme: light;
}

/* ---- Reset ------------------------------------------------------------- */
* { box-sizing: border-box; margin: 0; padding: 0; }
html { -webkit-text-size-adjust: 100%; }

/* The [hidden] attribute must always win (author display rules below would
   otherwise leak the hidden question/confirm/success states). */
[hidden] { display: none !important; }

body {
  font-family: var(--font);
  color: var(--ink);
  background: var(--canvas);
  /* Fluid base type — comfortable for older eyes; everything scales from here. */
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

/* ---- Global focus indicator (WCAG 2.2) --------------------------------
   NHS-style: yellow outer outline + black ring, visible on any surface.
   Never outline:none without a high-contrast replacement. */
:where(a, button, input, select, textarea, summary, [tabindex]):focus-visible {
  outline: 3px solid var(--nhs-yellow);
  outline-offset: 3px;
  box-shadow: 0 0 0 3px var(--nhs-black);
  border-radius: 4px;
}

/* Containers focused programmatically (confirm gate, success) are focused only
   to ANNOUNCE — they are not controls, so suppress the ring. */
#confirm:focus, #confirm:focus-visible,
#success:focus, #success:focus-visible { outline: none; box-shadow: none; }

/* ---- Layout shell (mobile-first) -------------------------------------- */
.stage {
  min-height: 100svh;
  display: flex; flex-direction: column; justify-content: center;
  gap: 18px;
  padding: clamp(20px, 5vw, 44px) clamp(16px, 4vw, 28px);
  padding-top: max(24px, env(safe-area-inset-top));
  padding-bottom: max(24px, env(safe-area-inset-bottom));
}

.card {
  width: 100%; max-width: 520px; margin: 0 auto;
  background: var(--surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow);
  padding: clamp(26px, 7vw, 44px);
}

/* ---- Brand ------------------------------------------------------------- */
.brand { margin-bottom: 26px; }
.brand__mark { color: var(--nhs-blue); width: 68px; }   /* blue box, white "NHS" */
.brand__mark svg { display: block; width: 100%; height: auto; }
.brand__trust { margin-top: 12px; font-size: .9375rem; font-weight: 600; color: var(--ink-soft); }

/* ---- Type -------------------------------------------------------------- */
.eyebrow {
  font-size: .8125rem; font-weight: 700; text-transform: uppercase;
  letter-spacing: .12em; color: var(--ink-soft); margin-bottom: 14px;
}
.headline {
  font-size: clamp(1.7rem, 1.2rem + 2.6vw, 2.3rem); line-height: 1.14;
  letter-spacing: -0.02em; font-weight: 700; color: var(--ink); margin-bottom: 16px;
}
.headline em { font-style: normal; color: var(--nhs-blue); }   /* NHS-blue accent */
.lede { font-size: 1.0625rem; color: var(--ink-soft); max-width: 44ch; margin-bottom: 28px; }

/* ---- Choice cards (full-width, selectable) ---------------------------- */
.actions { display: flex; flex-direction: column; gap: 12px; }

.choice {
  --accent: var(--decline);
  display: flex; align-items: center; gap: 16px;
  width: 100%; min-height: var(--tap);
  text-align: left; cursor: pointer;
  background: var(--surface);
  border: 2px solid var(--line);
  border-radius: var(--radius);
  padding: 16px 18px;
  font-family: inherit; color: var(--ink);
  transition: transform .18s var(--ease), box-shadow .18s var(--ease),
              border-color .18s var(--ease);
}
/* Decorative accent bar (the text label carries the meaning, not the colour). */
.choice::before {
  content: ""; width: 5px; align-self: stretch; border-radius: 999px;
  background: var(--accent); flex: 0 0 auto;
}
.choice__body { display: flex; flex-direction: column; gap: 3px; flex: 1; }
.choice__title { font-size: 1.0625rem; font-weight: 700; letter-spacing: -.01em; }
.choice__note  { font-size: .9375rem; color: var(--ink-soft); }
.choice__chevron {
  font-size: 1.2rem; color: var(--nhs-blue);
  opacity: 0; transform: translateX(-6px);
  transition: opacity .18s var(--ease), transform .18s var(--ease);
}

.choice--affirm  { --accent: var(--affirm); }
.choice--urgent  { --accent: var(--urgent); }
.choice--decline { --accent: var(--decline); }

@media (hover: hover) {
  .choice:hover {
    transform: translateY(-2px); box-shadow: var(--shadow-lift);
    border-color: var(--nhs-blue);
  }
  .choice:hover .choice__chevron { opacity: 1; transform: translateX(0); }
}
/* Reveal the chevron on keyboard focus too (parity with hover). */
.choice:focus-visible .choice__chevron { opacity: 1; transform: translateX(0); }
.choice:active { transform: translateY(0) scale(.992); }

/* Busy / disabled */
.choice[aria-busy="true"] .choice__chevron { opacity: 1; transform: none; animation: spin .7s linear infinite; }
.choice:disabled { cursor: not-allowed; opacity: .5; }
@keyframes spin { to { transform: rotate(360deg); } }

/* ---- Error / alert (solid NHS red, white text ≈ 4.8:1) ---------------- */
.error {
  margin-top: 18px; padding: 14px 16px; font-size: 1rem; font-weight: 500;
  color: #fff; background: var(--nhs-red); border-radius: var(--radius-sm);
}

/* ---- Confirmation gate (destructive-action mitigation) ---------------- */
.confirm { animation: rise .4s var(--ease) both; }
.confirm__title {
  font-size: clamp(1.5rem, 1.1rem + 1.8vw, 1.9rem); line-height: 1.15;
  font-weight: 700; letter-spacing: -.02em; margin: 6px 0 12px;
}
.confirm__text { font-size: 1.0625rem; color: var(--ink-soft); max-width: 44ch; margin-bottom: 24px; }

/* ---- Success ----------------------------------------------------------- */
.success { text-align: center; padding: 12px 0 4px; }
.success__tick { width: 64px; height: 64px; margin: 0 auto 22px; }
.success__tick svg { width: 100%; height: 100%; }
.success__ring {
  stroke: var(--nhs-green); stroke-width: 2.5;
  stroke-dasharray: 151; stroke-dashoffset: 151;
  animation: ring .5s var(--ease) forwards;
}
.success__check {
  stroke: var(--nhs-green); stroke-width: 3.5;
  stroke-linecap: round; stroke-linejoin: round;
  stroke-dasharray: 44; stroke-dashoffset: 44;
  animation: check .35s var(--ease) .4s forwards;
}
@keyframes ring  { to { stroke-dashoffset: 0; } }
@keyframes check { to { stroke-dashoffset: 0; } }

.success__title {
  font-size: clamp(1.5rem, 1.1rem + 1.8vw, 1.9rem);
  font-weight: 700; letter-spacing: -.02em; margin-bottom: 8px;
}
.success__text   { font-size: 1.0625rem; color: var(--ink); }
.success__detail { font-size: .9375rem; color: var(--ink-soft); margin-top: 12px; }

/* ---- Footer ------------------------------------------------------------ */
.legal { max-width: 520px; margin: 0 auto; text-align: center; }
.legal p { font-size: .8125rem; color: var(--ink-soft); max-width: 40ch; margin: 0 auto; }

/* ---- View transition --------------------------------------------------- */
.question, .success { animation: rise .4s var(--ease) both; }
@keyframes rise { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

/* ---- Larger screens ---------------------------------------------------- */
@media (min-width: 600px) {
  .card { padding: 48px; }
  .choice { padding: 18px 22px; }
}

/* ---- Respect reduced motion ------------------------------------------- */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: .001ms !important; animation-iteration-count: 1 !important;
    transition-duration: .001ms !important;
  }
}

/* ---- Windows High Contrast / forced-colors ---------------------------- */
@media (forced-colors: active) {
  .choice { border: 2px solid currentColor; }
  .card { border: 1px solid currentColor; }
  :where(a, button, summary, [tabindex]):focus-visible { outline: 3px solid Highlight; }
}
```

---


## `frontend/vercel.json`

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "headers": [
    {
      "source": "/.well-known/security.txt",
      "headers": [
        {
          "key": "Content-Type",
          "value": "text/plain; charset=utf-8"
        }
      ]
    },
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
     • NHS_OIDC_PROVIDER is just the PROVIDER NAME configured in the Supabase
       dashboard (Authentication → Providers). The client id/secret, NHS Login
       issuer URLs and scopes (incl. nhs_number) are registered THERE, never here.
       Leave it empty/omitted to use the local mock credential form instead.
   ========================================================================= */
window.__ENV = {
  SUPABASE_URL: "https://YOUR-PROJECT-REF.supabase.co",
  SUPABASE_ANON_KEY: "YOUR-PUBLIC-ANON-KEY",

  // Optional: name of the NHS Login OIDC provider configured in Supabase Auth.
  // When set (and the backend is configured), the "Sign in with NHS Login" button
  // starts the real OIDC flow. Empty/omitted → local mock sign-in form.
  NHS_OIDC_PROVIDER: "",
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

  <!-- CSP: defence-in-depth. The AUTHORITATIVE policy is the HTTP header in portal/vercel.json;
       this meta mirrors it so the two never diverge. connect-src allows Supabase REST + Auth +
       Realtime (wss). No anon data path here — all reads run under the authenticated user's JWT
       so RLS isolates the patient. -->
  <meta http-equiv="Content-Security-Policy"
        content="default-src 'none'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self'; connect-src 'self' https://*.supabase.co wss://*.supabase.co; img-src 'self' data:; font-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; upgrade-insecure-requests" />

  <link rel="preconnect" href="https://cdn.jsdelivr.net" />
  <link rel="stylesheet" href="styles.css?v=20260531" />
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

      <!-- Idle session warning (shared/elderly-device safety). After a period of
           no interaction we warn, then sign the patient out so their health record
           is never left open on an unattended/shared device. "Stay signed in"
           cancels; any interaction also cancels. -->
      <div id="idleWarning" class="idle" role="alertdialog"
           aria-labelledby="idleTitle" aria-describedby="idleDesc" hidden>
        <h2 class="idle__title" id="idleTitle">Are you still there?</h2>
        <p class="idle__text" id="idleDesc">
          To keep your information safe we’ll sign you out soon.
          <span id="idleCountdown"></span>
        </p>
        <div class="idle__actions">
          <button class="btn btn--primary" id="idleStay" type="button">Stay signed in</button>
          <button class="btn btn--ghost" id="idleSignOutNow" type="button">Sign out now</button>
        </div>
      </div>

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
  <script src="app.js?v=20260601c" defer></script>
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

/* ---- Idle session warning (shared/elderly-device safety) --------------- */
.idle {
  background: var(--surface); border-radius: var(--radius);
  box-shadow: var(--shadow-lift); padding: clamp(18px, 5vw, 26px);
  border-left: 6px solid var(--nhs-blue);
  animation: rise .25s var(--ease) both;
}
.idle__title { font-size: 1.25rem; font-weight: 700; letter-spacing: -.01em; margin-bottom: 6px; }
.idle__text  { color: var(--ink-soft); margin-bottom: 18px; }
.idle__actions { display: flex; gap: 12px; flex-wrap: wrap; }
.idle__actions .btn { width: auto; flex: 1 1 auto; }

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


## `portal/vercel.json`

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'none'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self'; connect-src 'self' https://*.supabase.co wss://*.supabase.co; img-src 'self' data:; font-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; upgrade-insecure-requests"
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


## `supabase/migrations/20260527000000_base_schema.sql`

```sql
-- =============================================================================
-- BASE SCHEMA (foundation the rest of the repo assumes "upstream")
-- =============================================================================
-- Earlier migrations (section-11 tokens/RPC, status-domain prereq, token issuer,
-- retention/erasure, portal RLS) all REFERENCE these objects but never created
-- them — they were treated as managed upstream. On a fresh Supabase project there
-- is no upstream, so the stack can't apply. This migration provides a MINIMAL,
-- standards-aligned foundation. It is dated 2026-05-27 to run BEFORE every other
-- migration in this repo.
--
-- IMPORTANT — REPLACE-IN-PLACE EXPECTATION:
--   If your Trust already has a real waitlist system, DO NOT use this as-is — point
--   the app at the real tables instead and delete this file. This exists so the
--   project is self-contained and runnable for development / demonstration.
--
-- Contracts this must satisfy (verified against the other migrations + portal):
--   • hospitals(id)                                    — tenant anchor
--   • waitlist_entries(id, hospital_id, status, ...)   — status TEXT incl. PENDING_CANCELLATION
--   • waitlist_entries.patient_user_id                 — links a row to an NHS Login identity (portal RLS)
--   • auth.current_hospital_id()                       — admin's hospital from JWT
--   • sms_dispatch_jobs + get_next_sms_batch(int)      — used by the edge worker
-- Idempotent + safe to re-run. Target: PostgreSQL 15 (supabase/config.toml).
-- =============================================================================

-- ── 1. HOSPITALS (tenant anchor) ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS hospitals (
    id          UUID         NOT NULL DEFAULT gen_random_uuid(),
    name        TEXT         NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_hospitals PRIMARY KEY (id)
);
COMMENT ON TABLE hospitals IS 'Tenant anchor. Each waitlist entry belongs to exactly one hospital.';


-- ── 2. WAITLIST ENTRIES (the core clinical record) ───────────────────────────
-- status is TEXT + CHECK that ALREADY includes PENDING_CANCELLATION, so the
-- status-domain prereq migration (20260528120000) will simply NOTICE "already
-- permits" rather than needing to widen anything.
CREATE TABLE IF NOT EXISTS waitlist_entries (
    id              UUID         NOT NULL DEFAULT gen_random_uuid(),
    hospital_id     UUID         NOT NULL,
    -- patient_user_id links this entry to an authenticated NHS Login identity
    -- (auth.users.id). NULLable + NULL by default: a row is invisible in the
    -- patient portal until an identity-matching step populates it (fail-closed).
    patient_user_id UUID,
    procedure       TEXT         NOT NULL DEFAULT 'Procedure',
    status          TEXT         NOT NULL DEFAULT 'ACTIVE',
    referred_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_waitlist_entries PRIMARY KEY (id),
    CONSTRAINT fk_entries_hospital FOREIGN KEY (hospital_id)
        REFERENCES hospitals(id) ON DELETE CASCADE,
    CONSTRAINT chk_entries_status CHECK (status IN
        ('ACTIVE', 'PENDING_CANCELLATION', 'CANCELLED', 'COMPLETED'))
);
COMMENT ON TABLE waitlist_entries IS 'Core waitlist record. status: ACTIVE -> (PENDING_CANCELLATION -> CANCELLED) | COMPLETED.';
COMMENT ON COLUMN waitlist_entries.patient_user_id IS 'auth.users.id of the patient (NHS Login). NULL until identity-matched; gates portal visibility.';

CREATE INDEX IF NOT EXISTS idx_waitlist_entries_hospital_id
    ON waitlist_entries(hospital_id);
CREATE INDEX IF NOT EXISTS idx_waitlist_entries_patient_user_id
    ON waitlist_entries(patient_user_id);


-- ── 3. auth.current_hospital_id() — admin's hospital from the JWT ─────────────
-- Reads a custom claim 'hospital_id' from the request JWT. Set this claim when
-- provisioning admin/staff accounts (e.g. via a custom access-token hook). Returns
-- NULL when absent, so policies that compare against it fail closed.
CREATE OR REPLACE FUNCTION auth.current_hospital_id()
RETURNS UUID
LANGUAGE sql
STABLE
AS $$
    SELECT NULLIF(
        current_setting('request.jwt.claims', true)::jsonb ->> 'hospital_id',
        ''
    )::uuid;
$$;
COMMENT ON FUNCTION auth.current_hospital_id() IS 'Hospital UUID from the request JWT claim ''hospital_id''; NULL if absent (fail-closed).';


-- ── 4. SMS DISPATCH QUEUE (used by the edge worker) ──────────────────────────
-- Columns match supabase/functions/sms-dispatch-worker/index.ts:
--   id, patient_phone, payload_link, status, retry_count, locked_at, last_error.
CREATE TABLE IF NOT EXISTS sms_dispatch_jobs (
    id                 UUID         NOT NULL DEFAULT gen_random_uuid(),
    waitlist_entry_id  UUID         NOT NULL,
    patient_phone      TEXT         NOT NULL,
    payload_link       TEXT         NOT NULL,
    status             TEXT         NOT NULL DEFAULT 'pending',
    retry_count        INTEGER      NOT NULL DEFAULT 0,
    locked_at          TIMESTAMPTZ,
    last_error         TEXT,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_sms_dispatch_jobs PRIMARY KEY (id),
    CONSTRAINT fk_sms_waitlist FOREIGN KEY (waitlist_entry_id)
        REFERENCES waitlist_entries(id) ON DELETE CASCADE,
    CONSTRAINT chk_sms_status CHECK (status IN ('pending', 'completed', 'failed'))
);
COMMENT ON TABLE sms_dispatch_jobs IS 'Outbound SMS queue. patient_phone is PII — see RLS below; never exposed to anon/patients.';

CREATE INDEX IF NOT EXISTS idx_sms_jobs_claimable
    ON sms_dispatch_jobs(status, locked_at) WHERE status = 'pending';


-- ── 5. get_next_sms_batch(batch_size) — atomic claim for the worker ──────────
-- SECURITY DEFINER so the worker (service_role) can atomically claim a batch:
-- locks pending rows, marks them locked, returns them. SKIP LOCKED makes
-- concurrent workers safe. search_path pinned.
CREATE OR REPLACE FUNCTION get_next_sms_batch(batch_size INTEGER)
RETURNS TABLE (
    id                UUID,
    waitlist_entry_id UUID,
    patient_phone     TEXT,
    payload_link      TEXT,
    retry_count       INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH claimed AS (
        SELECT j.id
          FROM sms_dispatch_jobs j
         WHERE j.status = 'pending'
           AND (j.locked_at IS NULL OR j.locked_at < NOW() - INTERVAL '5 minutes')
         ORDER BY j.created_at
         FOR UPDATE SKIP LOCKED
         LIMIT GREATEST(batch_size, 0)
    )
    UPDATE sms_dispatch_jobs j
       SET locked_at = NOW()
      FROM claimed
     WHERE j.id = claimed.id
    RETURNING j.id, j.waitlist_entry_id, j.patient_phone, j.payload_link, j.retry_count;
END;
$$;
COMMENT ON FUNCTION get_next_sms_batch(INTEGER) IS 'Atomically claims up to batch_size pending SMS jobs (FOR UPDATE SKIP LOCKED). service_role only.';

REVOKE EXECUTE ON FUNCTION get_next_sms_batch(INTEGER) FROM PUBLIC;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        EXECUTE 'GRANT EXECUTE ON FUNCTION get_next_sms_batch(INTEGER) TO service_role';
    END IF;
END;
$$;


-- ── 6. RLS ON BASE TABLES (forced; locked down by default) ───────────────────
-- waitlist_entries: admin read scoped to hospital; patient SELECT policy is added
-- by 20260529070000_patient_portal_rls.sql. The definer UPDATE policy for the
-- PENDING_CANCELLATION soft-state is added by section-11 (20260529000000).
ALTER TABLE hospitals          ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospitals          FORCE  ROW LEVEL SECURITY;
ALTER TABLE waitlist_entries   ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist_entries   FORCE  ROW LEVEL SECURITY;
ALTER TABLE sms_dispatch_jobs  ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_dispatch_jobs  FORCE  ROW LEVEL SECURITY;

-- Admin (authenticated staff) may read entries within their own hospital.
DROP POLICY IF EXISTS pol_entries_admin_select ON waitlist_entries;
CREATE POLICY pol_entries_admin_select
    ON waitlist_entries FOR SELECT TO authenticated
    USING (hospital_id = auth.current_hospital_id());

-- Admin may read hospitals (their own).
DROP POLICY IF EXISTS pol_hospitals_admin_select ON hospitals;
CREATE POLICY pol_hospitals_admin_select
    ON hospitals FOR SELECT TO authenticated
    USING (id = auth.current_hospital_id());

-- sms_dispatch_jobs holds PII (phone). No anon/patient access at all; the worker
-- uses service_role (bypasses RLS). Admin read scoped to their hospital.
DROP POLICY IF EXISTS pol_sms_admin_select ON sms_dispatch_jobs;
CREATE POLICY pol_sms_admin_select
    ON sms_dispatch_jobs FOR SELECT TO authenticated
    USING (waitlist_entry_id IN (
        SELECT id FROM waitlist_entries WHERE hospital_id = auth.current_hospital_id()
    ));
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


## `supabase/migrations/20260529070000_patient_portal_rls.sql`

```sql
-- =============================================================================
-- PATIENT PORTAL RLS — let a signed-in patient read ONLY their own entry
-- =============================================================================
-- Closes the Patient Hub's last code blocker (COMPLIANCE.md §10). The portal
-- (`portal/app.js`) runs `from('waitlist_entries').select(...)` under the patient's
-- own JWT and passes NO id — isolation MUST be enforced server-side by RLS. This
-- migration adds that policy: a patient sees a row only when its patient_user_id
-- equals their auth.uid().
--
-- DEPENDENCIES (apply order):
--   • 20260527000000_base_schema.sql defines waitlist_entries.patient_user_id (+ index).
--   • This file is dated after section-11 so the table + its other policies exist.
--
-- IDOR-safe by construction: the predicate is auth.uid() (from the verified JWT),
-- never a client-supplied value. Fail-closed: if patient_user_id IS NULL (not yet
-- identity-matched), the row is invisible.
--
-- STILL REQUIRED OUTSIDE THIS FILE (not closable in SQL alone):
--   (a) Real NHS Login OIDC wired into Supabase Auth (portal currently mocks it).
--   (b) An identity-matching step that sets waitlist_entries.patient_user_id from
--       the verified NHS Login subject. Until that runs, the portal stays empty.
-- Idempotent + safe to re-run.
-- =============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name   = 'waitlist_entries'
           AND column_name  = 'patient_user_id'
    ) THEN
        RAISE EXCEPTION
            'waitlist_entries.patient_user_id is missing — apply 20260527000000_base_schema.sql first.';
    END IF;
END;
$$;

-- Patient self-read. RLS is already ENABLED+FORCED on waitlist_entries (base schema).
DROP POLICY IF EXISTS pol_entries_patient_select ON waitlist_entries;
CREATE POLICY pol_entries_patient_select
    ON waitlist_entries FOR SELECT TO authenticated
    USING (patient_user_id = auth.uid());

COMMENT ON POLICY pol_entries_patient_select ON waitlist_entries IS
    'Patient portal: a signed-in patient may read ONLY rows whose patient_user_id = auth.uid(). IDOR-safe, fail-closed when NULL.';

-- NOTE on the two SELECT policies now on waitlist_entries:
--   • pol_entries_admin_select   — staff: hospital_id = auth.current_hospital_id()
--   • pol_entries_patient_select — patient: patient_user_id = auth.uid()
-- Postgres RLS combines multiple permissive policies with OR. That is correct
-- here: a staff JWT carries the hospital claim (and no matching patient_user_id),
-- a patient JWT carries neither a hospital claim nor admin rights — so each role
-- only ever sees its intended rows. (If staff accounts could also be patients,
-- revisit; today the claim sets are disjoint.)
```

---


## `supabase/migrations/20260601000000_link_patient_identity.sql`

```sql
-- =============================================================================
-- IDENTITY MATCHING — link a verified NHS Login patient to their waitlist row(s)
-- =============================================================================
-- Closes the §10 "identity-matching" dependency: `waitlist_entries.patient_user_id`
-- is NULL by default, so the portal (RLS: USING patient_user_id = auth.uid()) shows
-- a signed-in patient NOTHING until something links their auth identity to their
-- clinical record. This migration provides that link.
--
-- HOW THE MATCH WORKS (and why it is IDOR-safe by construction):
--   • NHS Login P9 (full identity verification) returns the patient's VERIFIED NHS
--     Number as a JWT claim. That number is the join key between "this authenticated
--     person" (auth.uid()) and "this clinical record" (waitlist_entries).
--   • `link_my_waitlist_record()` reads the caller's OWN verified NHS Number from the
--     request JWT (never a client-supplied parameter), validates it (modulus-11), and
--     sets patient_user_id = auth.uid() on matching rows that are NOT yet claimed.
--   • A caller can therefore only ever claim rows matching THEIR OWN verified number,
--     and only ever assign them to THEIR OWN uid. There is no parameter an attacker
--     could change to reach another patient's row. First-claim-wins (… IS NULL guard).
--   • Fail-closed: missing/invalid number, or identity not proven to P9 → 0 rows linked,
--     no error leaked.
--
-- DEPENDENCIES (apply order): runs AFTER
--   • 20260527000000_base_schema.sql        (waitlist_entries, patient_user_id, RLS)
--   • 20260529050000_nhs_number_modulus11.sql (is_valid_nhs_number)
--   • 20260529070000_patient_portal_rls.sql  (the patient SELECT policy this enables)
--
-- ⚠️ DATA PROTECTION (UK GDPR special-category / DPIA — see COMPLIANCE.md §2, §10):
--   This adds an NHS Number column to waitlist_entries. The NHS Number is PERSONAL,
--   special-category-adjacent data. It is:
--     • the clinical record's identifier (mirrors a real PAS waitlist row — expected),
--     • read-scoped to staff by the existing admin RLS (hospital_id), never anon,
--     • validated by a modulus-11 CHECK at the column,
--     • kept OUT of the patient-facing client query (portal/app.js selects explicit
--       non-PII columns only — data minimisation).
--   It MUST still be covered by the DPIA and the at-rest-encryption item (§2). Storing
--   it is a deliberate, documented increase in the data-protection surface.
--
-- 👤 INTEGRATION ASSUMPTIONS (confirm against the real NHS Login ↔ Supabase wiring;
--    cannot be verified in code alone):
--   • JWT claim name for the verified number is 'nhs_number'.
--   • JWT claim name for the identity-proofing level is 'identity_proofing_level',
--     and the value for full verification is 'P9'. Adjust REQUIRED_PROOFING / the
--     claim names below to match your OIDC mapping. Until they match, this fn fails
--     CLOSED (links nothing) — safe, but configure it correctly to enable matching.
--   • Best practice: run this linking server-side in a post-login / custom
--     access-token hook. Exposing it as an authenticated RPC (as here) is safe
--     because it only ever self-assigns the caller's own verified identity, but a
--     server-side hook removes the need for the client to call it at all.
-- Idempotent + safe to re-run. Target: PostgreSQL 15.
-- =============================================================================

-- ── 1. NHS Number on the clinical record (the match key) ─────────────────────
ALTER TABLE waitlist_entries
    ADD COLUMN IF NOT EXISTS nhs_number TEXT;

COMMENT ON COLUMN waitlist_entries.nhs_number IS
    'Patient NHS Number (PII). The Trust''s ingest/PAS populates this. Validated by '
    'modulus-11 CHECK; admin-RLS-scoped; never exposed to anon or to the patient client '
    'query. Used only to match a verified NHS Login identity to this row. DPIA scope.';

-- Modulus-11 CHECK at the column (no IF NOT EXISTS for ADD CONSTRAINT in PG → guard).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_entries_nhs_number'
    ) THEN
        ALTER TABLE waitlist_entries
            ADD CONSTRAINT chk_entries_nhs_number
            CHECK (nhs_number IS NULL OR is_valid_nhs_number(nhs_number));
    END IF;
END;
$$;

-- Expression index on the normalised number (strip spaces/dashes) so the match
-- lookup below is sargable. Only index rows that actually carry a number.
CREATE INDEX IF NOT EXISTS idx_waitlist_entries_nhs_number_norm
    ON waitlist_entries ((regexp_replace(nhs_number, '[\s-]', '', 'g')))
    WHERE nhs_number IS NOT NULL;


-- ── 2. link_my_waitlist_record() — self-service identity match ───────────────
-- SECURITY DEFINER: bypasses RLS to set patient_user_id (there is intentionally no
-- patient UPDATE policy). Safe because it takes NO parameters and acts only on the
-- caller's own verified claim + own uid. authenticated-only.
CREATE OR REPLACE FUNCTION link_my_waitlist_record()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    -- 👤 Adjust to match the real NHS Login → Supabase claim mapping (see header).
    REQUIRED_PROOFING CONSTANT TEXT := 'P9';
    v_claims  JSONB;
    v_uid     UUID;
    v_nhs_raw TEXT;
    v_nhs     TEXT;
    v_proof   TEXT;
    v_linked  INTEGER := 0;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        -- Not authenticated (defensive; GRANT already restricts to authenticated).
        RETURN jsonb_build_object('linked', 0, 'status', 'not_authenticated');
    END IF;

    v_claims  := NULLIF(current_setting('request.jwt.claims', true), '')::jsonb;
    v_nhs_raw := v_claims ->> 'nhs_number';
    v_proof   := v_claims ->> 'identity_proofing_level';

    -- Require full identity verification before trusting the number for matching.
    IF v_proof IS DISTINCT FROM REQUIRED_PROOFING THEN
        RETURN jsonb_build_object('linked', 0, 'status', 'identity_not_p9');
    END IF;

    -- Must have a syntactically valid (modulus-11) verified number.
    IF v_nhs_raw IS NULL OR NOT is_valid_nhs_number(v_nhs_raw) THEN
        RETURN jsonb_build_object('linked', 0, 'status', 'no_verified_nhs_number');
    END IF;

    v_nhs := regexp_replace(v_nhs_raw, '[\s-]', '', 'g');

    -- Claim ONLY this caller's own, not-yet-linked rows. First-claim-wins.
    -- `nhs_number IS NOT NULL` is logically implied (NULL never matches) but stated
    -- explicitly so the planner can use the partial expression index.
    UPDATE waitlist_entries
       SET patient_user_id = v_uid
     WHERE patient_user_id IS NULL
       AND nhs_number IS NOT NULL
       AND regexp_replace(nhs_number, '[\s-]', '', 'g') = v_nhs;

    GET DIAGNOSTICS v_linked = ROW_COUNT;

    RETURN jsonb_build_object('linked', v_linked, 'status', 'ok');
END;
$$;

COMMENT ON FUNCTION link_my_waitlist_record() IS
    'Links the caller''s VERIFIED NHS Login identity (auth.uid()) to their waitlist '
    'row(s) by matching the verified NHS Number JWT claim. Takes no parameters; only '
    'ever self-assigns the caller''s own unclaimed rows. IDOR-safe, fail-closed, '
    'first-claim-wins. authenticated-only.';

REVOKE EXECUTE ON FUNCTION link_my_waitlist_record() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION link_my_waitlist_record() TO authenticated;
```

---


## `supabase/migrations/20260601010000_clinical_review_workflow.sql`

```sql
-- =============================================================================
-- CLINICAL-REVIEW WORKFLOW — resolve PENDING_CANCELLATION (DCB0129/0160)
-- =============================================================================
-- Closes the open §1 clinical hazard: a patient "I no longer need this" response
-- moves the entry into the REVERSIBLE soft-state 'PENDING_CANCELLATION' (see
-- 20260529000000_section_11_tokens_rpc.sql), but until now there was NO code path
-- for a clinician to RESOLVE that state. A slot could sit pending forever, or be
-- resolved only by ad-hoc manual SQL (no audit, no scoping). This migration adds
-- the safe, audited resolution mechanism.
--
-- THE STATE MACHINE (authoritative):
--     ACTIVE ──patient declines──▶ PENDING_CANCELLATION ──clinician──▶ CANCELLED   (CONFIRM_CANCELLATION)
--                                          │              └──────────▶ ACTIVE      (REINSTATE)
--                                          COMPLETED is terminal and untouched here.
--   Only a clinician (authenticated staff, scoped to the entry's hospital) may make
--   the PENDING_CANCELLATION ▶ CANCELLED|ACTIVE transition. The patient path can
--   STILL only ever write PENDING_CANCELLATION.
--
-- DEPENDENCIES (apply order): runs AFTER
--   • 20260527000000_base_schema.sql        (waitlist_entries, status CHECK, current_hospital_id)
--   • 20260529000000_section_11_tokens_rpc.sql (the PENDING_CANCELLATION soft-state + its definer policy)
--
-- 🚫👤 STILL REQUIRED OUTSIDE THIS FILE (cannot be closed in SQL alone):
--   • CSO sign-off + Hazard Log / Clinical Safety Case Report entry for this workflow.
--   • A staff-facing UI (or staff tooling) that lists PENDING_CANCELLATION entries and
--     calls resolve_cancellation(). That UI needs REAL staff authentication + the
--     'hospital_id' JWT claim (not built — the portal mocks even patient auth). This
--     migration deliberately ships the safety-critical MECHANISM; the human-facing
--     trigger is a documented follow-on. Until staff auth exists, resolution is
--     reachable only by authenticated staff tooling that carries the hospital claim.
-- Idempotent + safe to re-run. Target: PostgreSQL 15.
-- =============================================================================

-- ── 1. AUDIT LEDGER — who resolved what, when (append-only) ──────────────────
-- Tamper-evidence aim (§6): every resolution is recorded with the acting clinician
-- (auth.uid()), the before/after status, and an optional clinical note. There are
-- intentionally NO UPDATE/DELETE policies, so the app cannot rewrite history.
-- (Cryptographic tamper-evidence — SHA-256 hash chaining — is ADDED on top of this
-- immutable-by-RLS ledger by 20260601020000_audit_hash_chain.sql.)
CREATE TABLE IF NOT EXISTS cancellation_reviews (
    id                 UUID         NOT NULL DEFAULT gen_random_uuid(),
    waitlist_entry_id  UUID         NOT NULL,
    hospital_id        UUID         NOT NULL,
    decision           TEXT         NOT NULL,
    previous_status    TEXT         NOT NULL,
    new_status         TEXT         NOT NULL,
    reviewed_by        UUID         NOT NULL,
    note               TEXT,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_cancellation_reviews PRIMARY KEY (id),
    CONSTRAINT fk_review_waitlist FOREIGN KEY (waitlist_entry_id)
        REFERENCES waitlist_entries(id) ON DELETE CASCADE,
    CONSTRAINT chk_review_decision CHECK (decision IN ('CONFIRM_CANCELLATION', 'REINSTATE')),
    CONSTRAINT chk_review_new_status CHECK (new_status IN ('CANCELLED', 'ACTIVE'))
);
COMMENT ON TABLE cancellation_reviews IS
    'Append-only audit of clinician resolutions of PENDING_CANCELLATION entries '
    '(DCB0129/0160). Health-adjacent: admin-RLS-scoped to hospital; never anon/patient.';

CREATE INDEX IF NOT EXISTS idx_cancellation_reviews_entry
    ON cancellation_reviews(waitlist_entry_id);
CREATE INDEX IF NOT EXISTS idx_cancellation_reviews_hospital
    ON cancellation_reviews(hospital_id);


-- ── 2. RLS on the ledger (forced; locked down) ───────────────────────────────
ALTER TABLE cancellation_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE cancellation_reviews FORCE  ROW LEVEL SECURITY;

-- Staff may read reviews for their own hospital (need-to-know, Caldicott §3).
DROP POLICY IF EXISTS pol_reviews_admin_select ON cancellation_reviews;
CREATE POLICY pol_reviews_admin_select
    ON cancellation_reviews FOR SELECT TO authenticated
    USING (hospital_id = auth.current_hospital_id());

-- Inserts happen ONLY via the SECURITY DEFINER RPC below (runs as postgres).
-- No UPDATE/DELETE policy at all → the ledger is immutable from the application.
DROP POLICY IF EXISTS pol_reviews_insert_definer ON cancellation_reviews;
CREATE POLICY pol_reviews_insert_definer
    ON cancellation_reviews FOR INSERT TO postgres
    WITH CHECK (true);


-- ── 3. Resolution UPDATE policy on waitlist_entries ──────────────────────────
-- The existing pol_entries_update_definer (section 11) is locked to
-- WITH CHECK (status = 'PENDING_CANCELLATION') — correct for the PATIENT path, but
-- it would BLOCK this clinician path from writing CANCELLED/ACTIVE. Postgres
-- combines multiple PERMISSIVE policies for the same role+command with OR, so this
-- ADDITIONAL policy widens what the definer role may write WITHOUT touching the
-- patient guarantee in code.
--
-- Combined effect for role `postgres` on UPDATE of waitlist_entries:
--   USING:      true OR (status = 'PENDING_CANCELLATION')           = any row (unchanged)
--   WITH CHECK: (status = 'PENDING_CANCELLATION')                   [patient path]
--               OR (status IN ('CANCELLED','ACTIVE'))               [this clinician path]
--             = the new status must be one of PENDING_CANCELLATION | CANCELLED | ACTIVE
--               (COMPLETED and arbitrary values remain forbidden at the RLS layer).
--
-- ⚠️ HONEST NOTE: this relaxes the RLS-layer guarantee from "definer can only write
-- PENDING_CANCELLATION" to the bounded set above. The patient path can STILL never
-- hard-cancel a patient, because (a) `anon` may EXECUTE only submit_validation_response
-- (never resolve_cancellation — see grants below), and (b) that function's code only
-- ever writes PENDING_CANCELLATION, guarded against clobbering terminal states. The
-- RLS WITH CHECK is defence-in-depth, not the sole control.
DROP POLICY IF EXISTS pol_entries_resolve_definer ON waitlist_entries;
CREATE POLICY pol_entries_resolve_definer
    ON waitlist_entries FOR UPDATE TO postgres
    USING (status = 'PENDING_CANCELLATION')
    WITH CHECK (status IN ('CANCELLED', 'ACTIVE'));


-- ── 4. resolve_cancellation() — the audited clinician transition ─────────────
-- SECURITY DEFINER (writes under the definer policies above) with a pinned
-- search_path. authenticated-only; need-to-know scoped to the caller's hospital.
CREATE OR REPLACE FUNCTION resolve_cancellation(
    p_entry_id  UUID,
    p_decision  TEXT,
    p_note      TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid         UUID;
    v_caller_hosp UUID;
    v_hospital_id UUID;
    v_status      TEXT;
    v_new_status  TEXT;
    v_review_id   UUID;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'NOT_AUTHENTICATED' USING ERRCODE = 'P0001';
    END IF;

    -- Validate the decision before any data access.
    IF p_decision NOT IN ('CONFIRM_CANCELLATION', 'REINSTATE') THEN
        RAISE EXCEPTION 'INVALID_DECISION' USING ERRCODE = 'P0001';
    END IF;

    -- Lock the entry and read its hospital + current status (race-safe: a second
    -- concurrent resolver or a late patient re-submit will serialise behind this).
    SELECT hospital_id, status
      INTO v_hospital_id, v_status
      FROM waitlist_entries
     WHERE id = p_entry_id
     FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'WAITLIST_ENTRY_NOT_FOUND' USING ERRCODE = 'P0002';
    END IF;

    -- Need-to-know: caller's hospital must match the entry's (Caldicott §3). Enforced
    -- in-function because SECURITY DEFINER bypasses the admin SELECT RLS.
    v_caller_hosp := auth.current_hospital_id();
    IF v_caller_hosp IS NULL OR v_caller_hosp <> v_hospital_id THEN
        RAISE EXCEPTION 'NOT_AUTHORISED_FOR_THIS_HOSPITAL' USING ERRCODE = 'P0001';
    END IF;

    -- Only entries awaiting review can be resolved. Idempotent-safe: a double-submit
    -- finds the status already changed and is rejected here rather than re-cancelling.
    IF v_status <> 'PENDING_CANCELLATION' THEN
        RAISE EXCEPTION 'ENTRY_NOT_PENDING_CANCELLATION (current: %)', v_status
            USING ERRCODE = 'P0001';
    END IF;

    v_new_status := CASE p_decision
        WHEN 'CONFIRM_CANCELLATION' THEN 'CANCELLED'
        WHEN 'REINSTATE'            THEN 'ACTIVE'
    END;

    UPDATE waitlist_entries
       SET status = v_new_status
     WHERE id = p_entry_id;

    -- Append the immutable audit row (who/what/when + before/after + optional note).
    INSERT INTO cancellation_reviews
        (waitlist_entry_id, hospital_id, decision, previous_status, new_status, reviewed_by, note)
    VALUES
        (p_entry_id, v_hospital_id, p_decision, 'PENDING_CANCELLATION', v_new_status, v_uid, p_note)
    RETURNING id INTO v_review_id;

    RETURN jsonb_build_object(
        'status',     'ok',
        'entry_id',   p_entry_id,
        'new_status', v_new_status,
        'review_id',  v_review_id
    );
END;
$$;

COMMENT ON FUNCTION resolve_cancellation(UUID, TEXT, TEXT) IS
    'Clinician resolution of a PENDING_CANCELLATION entry: CONFIRM_CANCELLATION→CANCELLED '
    'or REINSTATE→ACTIVE. Hospital-scoped, row-locked, audited in cancellation_reviews. '
    'authenticated-only; never anon. DCB0129/0160 reversible-soft-state resolution.';


-- ── 5. Entitlements ──────────────────────────────────────────────────────────
-- Staff only. anon (the patient path) is NEVER granted execute — it cannot reach
-- the hard-cancel transition.
REVOKE EXECUTE ON FUNCTION resolve_cancellation(UUID, TEXT, TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION resolve_cancellation(UUID, TEXT, TEXT) TO authenticated;
```

---


## `supabase/migrations/20260601020000_audit_hash_chain.sql`

```sql
-- =============================================================================
-- TAMPER-EVIDENT AUDIT CHAINS — hash-chain the append-only ledgers (§6)
-- =============================================================================
-- Strengthens COMPLIANCE.md §6 "audit trail / tamper-evidence". The ledgers
-- (`cancellation_reviews`, `validation_responses`) are already immutable-by-RLS
-- (no UPDATE/DELETE policy). This adds CRYPTOGRAPHIC tamper-evidence on top: each
-- row carries a SHA-256 hash chaining it to the previous row, so ANY later edit or
-- deletion (e.g. by someone with direct DB/superuser access that bypasses RLS)
-- breaks the chain and is DETECTABLE by re-walking it (`verify_audit_chain`).
--
-- WHY THIS IS LOW-RISK SQL (no extension dependency):
--   PostgreSQL 15 (this project's target) ships sha256(bytea) in core — NO pgcrypto,
--   NO `extensions`-schema / search_path issues. Hashing is encode(sha256(convert_to(
--   <text>, 'UTF8')), 'hex').
--
-- CHAIN CONSTRUCTION (per table):
--   • seq BIGINT IDENTITY gives a strict append order.
--   • prev_hash = row_hash of the latest existing row (or 'GENESIS' for the first).
--   • row_hash  = sha256( prev_hash || '|' || <canonical business columns as jsonb text> ).
--   • A BEFORE INSERT trigger sets prev_hash + row_hash automatically, so the
--     clinical-safety RPCs need NO change. A per-table transaction advisory lock
--     serialises appends to prevent chain forks under concurrent inserts (audit
--     ledgers are low-write, so the serialisation cost is negligible).
--
-- DEPENDENCIES (apply order): runs AFTER
--   • 20260529000000_section_11_tokens_rpc.sql (validation_responses)
--   • 20260601010000_clinical_review_workflow.sql (cancellation_reviews)
--
-- HONEST LIMITS (so this is not over-claimed):
--   • Tamper-EVIDENT, not tamper-PROOF: it lets you DETECT alteration, it does not
--     prevent a DB admin from rewriting the whole chain consistently. For stronger
--     guarantees, periodically export the latest row_hash to external WORM storage
--     (notarisation) — a Trust operational step, not closable here.
--   • Rows that already existed BEFORE this migration (none on a fresh apply) are
--     not retro-hashed; verification starts from the first chained insert.
--   • Code-reviewed, NOT executed (no live Postgres this session).
-- Idempotent + safe to re-run. Target: PostgreSQL 15.
-- =============================================================================

-- ── 1. Chain columns on each ledger ──────────────────────────────────────────
ALTER TABLE cancellation_reviews ADD COLUMN IF NOT EXISTS seq       BIGINT GENERATED ALWAYS AS IDENTITY;
ALTER TABLE cancellation_reviews ADD COLUMN IF NOT EXISTS prev_hash TEXT;
ALTER TABLE cancellation_reviews ADD COLUMN IF NOT EXISTS row_hash  TEXT;

ALTER TABLE validation_responses ADD COLUMN IF NOT EXISTS seq       BIGINT GENERATED ALWAYS AS IDENTITY;
ALTER TABLE validation_responses ADD COLUMN IF NOT EXISTS prev_hash TEXT;
ALTER TABLE validation_responses ADD COLUMN IF NOT EXISTS row_hash  TEXT;

COMMENT ON COLUMN cancellation_reviews.row_hash IS 'SHA-256 tamper-evidence chain link: sha256(prev_hash||business cols). See verify_audit_chain().';
COMMENT ON COLUMN validation_responses.row_hash IS 'SHA-256 tamper-evidence chain link: sha256(prev_hash||business cols). See verify_audit_chain().';


-- ── 2. Generic chain-append trigger function ─────────────────────────────────
-- Reusable across any ledger that has (seq, prev_hash, row_hash). The hashed
-- payload is the row's jsonb MINUS the chain-metadata columns, so it covers only
-- the immutable business content. jsonb key order is deterministic, so the same
-- row always hashes identically (here and in verify_audit_chain).
CREATE OR REPLACE FUNCTION audit_chain_append()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_prev    TEXT;
    v_payload TEXT;
BEGIN
    -- Serialise appends to THIS table's chain (prevents forks under concurrency).
    PERFORM pg_advisory_xact_lock(hashtextextended(TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME, 0));

    -- Tail hash of the existing chain (NULL → 'GENESIS' for the first row).
    EXECUTE format('SELECT row_hash FROM %I.%I ORDER BY seq DESC LIMIT 1',
                   TG_TABLE_SCHEMA, TG_TABLE_NAME)
       INTO v_prev;
    v_prev := COALESCE(v_prev, 'GENESIS');

    -- Canonical business payload: drop chain metadata (and the hash cols, which are
    -- still NULL at BEFORE INSERT) so trigger + verifier hash exactly the same text.
    v_payload := ((to_jsonb(NEW) - 'row_hash') - 'prev_hash' - 'seq')::text;

    NEW.prev_hash := v_prev;
    NEW.row_hash  := encode(sha256(convert_to(v_prev || '|' || v_payload, 'UTF8')), 'hex');
    RETURN NEW;
END;
$$;
COMMENT ON FUNCTION audit_chain_append() IS
    'BEFORE INSERT trigger: sets prev_hash + SHA-256 row_hash to chain an append-only '
    'ledger row to the previous one. Advisory-lock serialised per table. PG15 core sha256.';

DROP TRIGGER IF EXISTS trg_chain_cancellation_reviews ON cancellation_reviews;
CREATE TRIGGER trg_chain_cancellation_reviews
    BEFORE INSERT ON cancellation_reviews
    FOR EACH ROW EXECUTE FUNCTION audit_chain_append();

DROP TRIGGER IF EXISTS trg_chain_validation_responses ON validation_responses;
CREATE TRIGGER trg_chain_validation_responses
    BEFORE INSERT ON validation_responses
    FOR EACH ROW EXECUTE FUNCTION audit_chain_append();


-- ── 3. verify_audit_chain(table) — detect tampering ──────────────────────────
-- Re-walks the chain and reports whether it is intact, the row count, and the first
-- broken seq (if any). Restricted to the known ledger tables (a whitelist, so it
-- cannot be pointed at arbitrary tables). authenticated-only; read-only.
CREATE OR REPLACE FUNCTION verify_audit_chain(p_table TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total   BIGINT;
    v_first_bad BIGINT;
BEGIN
    IF p_table NOT IN ('cancellation_reviews', 'validation_responses') THEN
        RAISE EXCEPTION 'UNKNOWN_LEDGER (%).', p_table USING ERRCODE = 'P0001';
    END IF;

    -- For each row, recompute the expected prev_hash (lag of row_hash) and the
    -- expected row_hash, then flag any mismatch. Same canonical payload as the
    -- trigger: jsonb minus chain metadata.
    EXECUTE format($q$
        WITH walked AS (
            SELECT
                seq,
                row_hash,
                prev_hash,
                COALESCE(lag(row_hash) OVER (ORDER BY seq), 'GENESIS') AS expected_prev,
                encode(sha256(convert_to(
                    COALESCE(lag(row_hash) OVER (ORDER BY seq), 'GENESIS') || '|' ||
                    (((to_jsonb(t) - 'row_hash') - 'prev_hash' - 'seq')::text), 'UTF8')), 'hex')
                    AS expected_hash
            FROM %I.%I t
        )
        SELECT count(*),
               min(seq) FILTER (WHERE row_hash IS DISTINCT FROM expected_hash
                                   OR prev_hash IS DISTINCT FROM expected_prev)
          FROM walked
    $q$, 'public', p_table)
    INTO v_total, v_first_bad;

    RETURN jsonb_build_object(
        'table',        p_table,
        'rows',         v_total,
        'intact',       (v_first_bad IS NULL),
        'first_broken_seq', v_first_bad
    );
END;
$$;
COMMENT ON FUNCTION verify_audit_chain(TEXT) IS
    'Re-walks a ledger hash chain; returns {rows, intact, first_broken_seq}. Whitelisted '
    'to the audit ledgers. Run periodically / before relying on the audit trail.';

REVOKE EXECUTE ON FUNCTION verify_audit_chain(TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION verify_audit_chain(TEXT) TO authenticated;
```

---


## `supabase/migrations/20260601030000_proxy_access_scaffold.sql`

```sql
-- =============================================================================
-- PROXY ACCESS SCAFFOLD — verified, consented, time-bounded (§10, Caldicott §3)
-- =============================================================================
-- The portal has a MOCK "Proxy view" toggle (caring for a dependent) that fetches
-- no one else's data. This migration builds the SERVER-SIDE foundation for REAL
-- proxy access — the data model + RLS — so that "proxy" can never be a client-
-- asserted claim. It deliberately does NOT enable any proxy relationship by data:
-- the table ships empty, and rows can only be created by an admin SECURITY DEFINER
-- function, never by a patient.
--
-- WHY proxy access is high-risk (and why this is conservative):
--   Letting account A read account B's health record is exactly the kind of
--   authorisation that, done loosely, becomes an IDOR / confidentiality breach.
--   So every read is gated on a relationship row that must be ALL of:
--     • active (not revoked), • consented, • within its valid-from/until window.
--   Anything missing → no access (fail-closed). The patient self-read policy is
--   untouched; this only ADDS a tightly-scoped third path.
--
-- 🚫👤 NOT closable in code (must precede any real use):
--   • Caldicott-approved CONSENT capture + identity verification of BOTH parties
--     (e.g. parental responsibility for a child, a registered carer). This table
--     RECORDS that a decision was made + by whom; it does not MAKE the decision.
--   • For under-16s / Gillick competence and for adults lacking capacity, the
--     lawful basis + safeguarding review are governance, not SQL.
--   • An admin UI to grant/revoke (the grant/revoke RPCs are here; the UI + real
--     staff auth are the follow-on, shared with the §1 staff-tooling gap).
--
-- DEPENDENCIES: runs AFTER 20260527000000_base_schema.sql and
-- 20260529070000_patient_portal_rls.sql. Idempotent. Target: PostgreSQL 15.
-- =============================================================================

-- ── 1. RELATIONSHIP TABLE ─────────────────────────────────────────────────────
-- One row = "proxy_user_id may act for subject_user_id" under recorded consent.
CREATE TABLE IF NOT EXISTS patient_proxies (
    id               UUID         NOT NULL DEFAULT gen_random_uuid(),
    subject_user_id  UUID         NOT NULL,   -- the patient whose data is viewed (auth.users.id)
    proxy_user_id    UUID         NOT NULL,   -- the person granted access      (auth.users.id)
    relationship     TEXT         NOT NULL,   -- e.g. 'parent', 'carer', 'lasting_power_of_attorney'
    consent_status   TEXT         NOT NULL DEFAULT 'PENDING',
    valid_from       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    valid_until      TIMESTAMPTZ,             -- NULL = open-ended (review still required)
    granted_by       UUID,                    -- staff auth.uid() who recorded the grant
    revoked_at       TIMESTAMPTZ,             -- non-NULL = revoked (kept for audit, not deleted)
    note             TEXT,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_patient_proxies PRIMARY KEY (id),
    CONSTRAINT chk_proxy_consent CHECK (consent_status IN ('PENDING', 'GRANTED', 'REVOKED')),
    CONSTRAINT chk_proxy_not_self CHECK (proxy_user_id <> subject_user_id),
    CONSTRAINT chk_proxy_window CHECK (valid_until IS NULL OR valid_until > valid_from),
    CONSTRAINT uq_proxy_pair UNIQUE (subject_user_id, proxy_user_id)
);
COMMENT ON TABLE patient_proxies IS
    'Verified proxy relationships (caring for a dependent). A row grants proxy_user_id read access to '
    'subject_user_id''s waitlist data ONLY while consent_status=GRANTED, not revoked, and within the '
    'validity window. Consent/identity verification is a Caldicott governance step recorded here, not made here.';

CREATE INDEX IF NOT EXISTS idx_patient_proxies_proxy   ON patient_proxies(proxy_user_id);
CREATE INDEX IF NOT EXISTS idx_patient_proxies_subject ON patient_proxies(subject_user_id);


-- ── 2. The single source of truth: is (proxy, subject) currently authorised? ──
-- STABLE helper used by both the RLS policy and any app check. Fail-closed.
CREATE OR REPLACE FUNCTION auth.has_proxy_access(p_subject UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM patient_proxies pp
         WHERE pp.proxy_user_id   = auth.uid()
           AND pp.subject_user_id = p_subject
           AND pp.consent_status  = 'GRANTED'
           AND pp.revoked_at IS NULL
           AND pp.valid_from <= NOW()
           AND (pp.valid_until IS NULL OR pp.valid_until > NOW())
    );
$$;
COMMENT ON FUNCTION auth.has_proxy_access(UUID) IS
    'TRUE iff the current user is a currently-authorised proxy for p_subject (GRANTED, not revoked, in window). Fail-closed.';


-- ── 3. RLS ─────────────────────────────────────────────────────────────────--
ALTER TABLE patient_proxies ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_proxies FORCE  ROW LEVEL SECURITY;

-- A user may SEE relationships where they are the subject or the proxy (transparency:
-- a patient can see who has access to them). No INSERT/UPDATE/DELETE policy for
-- normal users → relationships are managed ONLY by the definer RPCs below.
DROP POLICY IF EXISTS pol_proxies_party_select ON patient_proxies;
CREATE POLICY pol_proxies_party_select
    ON patient_proxies FOR SELECT TO authenticated
    USING (subject_user_id = auth.uid() OR proxy_user_id = auth.uid());

-- Definer write policy (grant/revoke RPCs run as postgres).
DROP POLICY IF EXISTS pol_proxies_write_definer ON patient_proxies;
CREATE POLICY pol_proxies_write_definer
    ON patient_proxies FOR ALL TO postgres
    USING (true) WITH CHECK (true);

-- THE PROXY READ PATH on waitlist_entries: a third permissive SELECT policy.
-- OR-combines with pol_entries_patient_select (own data) and pol_entries_admin_select
-- (staff). A proxy sees the subject's rows ONLY while auth.has_proxy_access() holds.
DROP POLICY IF EXISTS pol_entries_proxy_select ON waitlist_entries;
CREATE POLICY pol_entries_proxy_select
    ON waitlist_entries FOR SELECT TO authenticated
    USING (patient_user_id IS NOT NULL AND auth.has_proxy_access(patient_user_id));
COMMENT ON POLICY pol_entries_proxy_select ON waitlist_entries IS
    'Verified proxy read: a row is visible to a currently-authorised proxy of its patient_user_id. Fail-closed via auth.has_proxy_access().';


-- ── 4. Admin grant / revoke RPCs (consent recorded out-of-band) ──────────────
-- 🚫👤 These are the MECHANISM. The CONSENT + identity verification that justifies a
-- grant is a Caldicott governance step performed BEFORE calling grant_proxy_access.
-- STAFF-ONLY: granting access to one person over another's record is a staff action,
-- so grant_proxy_access requires the caller to carry the 'hospital_id' JWT claim (the
-- same signal the admin RLS uses — patients do NOT carry it). Without that gate, any
-- authenticated user could grant THEMSELVES access to another person's record by
-- passing p_proxy = their own uid. The gate closes that. (When real staff roles exist
-- — the §1 staff-auth follow-on — tighten further to an explicit role check.)
-- proxy<>subject is also enforced, and every grant is attributed to granted_by.
CREATE OR REPLACE FUNCTION grant_proxy_access(
    p_subject       UUID,
    p_proxy         UUID,
    p_relationship  TEXT,
    p_valid_until   TIMESTAMPTZ DEFAULT NULL,
    p_note          TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor UUID;
    v_id    UUID;
BEGIN
    v_actor := auth.uid();
    IF v_actor IS NULL THEN
        RAISE EXCEPTION 'NOT_AUTHENTICATED' USING ERRCODE = 'P0001';
    END IF;
    -- STAFF-ONLY gate: caller must carry the 'hospital_id' JWT claim. This prevents a
    -- patient from self-granting access to another person's record. (Fail-closed: no
    -- claim → not authorised.) Tighten to an explicit staff-role check once roles exist.
    IF auth.current_hospital_id() IS NULL THEN
        RAISE EXCEPTION 'NOT_AUTHORISED_TO_GRANT_PROXY' USING ERRCODE = 'P0001';
    END IF;
    IF p_subject IS NULL OR p_proxy IS NULL OR p_subject = p_proxy THEN
        RAISE EXCEPTION 'INVALID_PROXY_PAIR' USING ERRCODE = 'P0001';
    END IF;
    IF COALESCE(btrim(p_relationship), '') = '' THEN
        RAISE EXCEPTION 'RELATIONSHIP_REQUIRED' USING ERRCODE = 'P0001';
    END IF;

    -- Upsert the pair to GRANTED (re-granting a revoked pair re-activates it + audits).
    INSERT INTO patient_proxies
        (subject_user_id, proxy_user_id, relationship, consent_status, valid_until, granted_by, revoked_at, note)
    VALUES
        (p_subject, p_proxy, p_relationship, 'GRANTED', p_valid_until, v_actor, NULL, p_note)
    ON CONFLICT (subject_user_id, proxy_user_id) DO UPDATE
        SET consent_status = 'GRANTED',
            relationship   = EXCLUDED.relationship,
            valid_until    = EXCLUDED.valid_until,
            granted_by     = v_actor,
            revoked_at     = NULL,
            note           = EXCLUDED.note
    RETURNING id INTO v_id;

    RETURN jsonb_build_object('status', 'ok', 'proxy_id', v_id, 'consent_status', 'GRANTED');
END;
$$;
COMMENT ON FUNCTION grant_proxy_access(UUID, UUID, TEXT, TIMESTAMPTZ, TEXT) IS
    'Records a GRANTED proxy relationship (consent/identity verified out-of-band, Caldicott). STAFF-ONLY '
    '(requires the hospital_id JWT claim); proxy<>subject enforced; grant attributed to granted_by=auth.uid().';

CREATE OR REPLACE FUNCTION revoke_proxy_access(p_subject UUID, p_proxy UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor UUID;
    v_n     INTEGER;
BEGIN
    v_actor := auth.uid();
    IF v_actor IS NULL THEN
        RAISE EXCEPTION 'NOT_AUTHENTICATED' USING ERRCODE = 'P0001';
    END IF;

    -- Authorisation (revoking only REMOVES access — safety-positive — but still scoped):
    -- allowed if the caller is the SUBJECT (revoking access to their own record), the
    -- PROXY themselves (declining the access), or staff (carry the hospital_id claim).
    IF NOT (
        v_actor = p_subject
        OR v_actor = p_proxy
        OR auth.current_hospital_id() IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'NOT_AUTHORISED_TO_REVOKE_PROXY' USING ERRCODE = 'P0001';
    END IF;

    UPDATE patient_proxies
       SET consent_status = 'REVOKED', revoked_at = NOW()
     WHERE subject_user_id = p_subject
       AND proxy_user_id   = p_proxy
       AND revoked_at IS NULL;
    GET DIAGNOSTICS v_n = ROW_COUNT;

    RETURN jsonb_build_object('status', 'ok', 'revoked', v_n);
END;
$$;
COMMENT ON FUNCTION revoke_proxy_access(UUID, UUID) IS
    'Revokes a proxy relationship (sets REVOKED + revoked_at). Kept for audit, not deleted. authenticated-only.';


-- ── 5. Entitlements ──────────────────────────────────────────────────────────
REVOKE EXECUTE ON FUNCTION grant_proxy_access(UUID, UUID, TEXT, TIMESTAMPTZ, TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION grant_proxy_access(UUID, UUID, TEXT, TIMESTAMPTZ, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION revoke_proxy_access(UUID, UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION revoke_proxy_access(UUID, UUID) TO authenticated;
-- has_proxy_access is used by RLS; expose to authenticated for app-side checks too.
REVOKE EXECUTE ON FUNCTION auth.has_proxy_access(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION auth.has_proxy_access(UUID) TO authenticated;
```

---


## `supabase/tests/verify.sql`

```sql
-- =============================================================================
-- VERIFICATION HARNESS — runnable assertions for the safety-critical logic
-- =============================================================================
-- PURPOSE: turn "code-reviewed, not executed" into "executed + asserted". Run this
-- AFTER applying all 11 migrations (see DEPLOYMENT.md §3), in psql or the Supabase
-- SQL editor. Every check uses ASSERT — the script RAISES on the first failure, so
-- "completed with no exception, ROLLBACK done" == all assertions passed.
--
-- SAFETY: the whole thing runs inside one transaction and ROLLS BACK at the end, so
-- it leaves NO test data behind. It only writes to its own throwaway rows.
--
-- SCOPE — what this can and cannot prove in a plain SQL session:
--   ✓ CAN: table/constraint shape, the clinical-review state machine, the hash-chain
--     trigger + verify_audit_chain tamper detection, the NHS Number validator, the
--     proxy fail-closed predicate, function guard logic reachable as the table owner.
--   ✗ CANNOT here: the RLS POLICIES as experienced by the `authenticated`/`anon`
--     roles with a real JWT (auth.uid()/claims). Those need a live authenticated
--     session — they are covered by the post-deploy checks in DEPLOYMENT.md §6.
--     This file documents that boundary rather than pretending to cross it.
-- =============================================================================

BEGIN;
SET LOCAL client_min_messages = NOTICE;

DO $$
DECLARE
    v_hosp     UUID;
    v_other    UUID;
    v_entry    UUID;
    v_uid      UUID := gen_random_uuid();   -- a stand-in clinician/patient id
    v_res      JSONB;
    v_status   TEXT;
    v_chain    JSONB;
    v_count    INTEGER;
BEGIN
    RAISE NOTICE '--- 1. NHS Number modulus-11 validator ---';
    -- Known-valid test number (passes modulus-11). 9434765919 is a standard example.
    ASSERT is_valid_nhs_number('9434765919'),            'valid NHS number rejected';
    ASSERT is_valid_nhs_number('943 476 5919'),          'spaces should be stripped';
    ASSERT NOT is_valid_nhs_number('9434765918'),        'bad check digit accepted';
    ASSERT NOT is_valid_nhs_number('123'),               'too-short accepted';
    ASSERT NOT is_valid_nhs_number(NULL),                'NULL accepted';
    ASSERT NOT is_valid_nhs_number('abcdefghij'),        'non-numeric accepted';

    RAISE NOTICE '--- 2. Seed a hospital + entry (as table owner) ---';
    INSERT INTO hospitals (name) VALUES ('Test Trust Hospital') RETURNING id INTO v_hosp;
    INSERT INTO hospitals (name) VALUES ('Other Hospital')      RETURNING id INTO v_other;
    INSERT INTO waitlist_entries (hospital_id, procedure, status, nhs_number)
        VALUES (v_hosp, 'Test Procedure', 'ACTIVE', '9434765919')
        RETURNING id INTO v_entry;

    RAISE NOTICE '--- 3. NHS Number CHECK constraint on waitlist_entries ---';
    BEGIN
        INSERT INTO waitlist_entries (hospital_id, procedure, nhs_number)
            VALUES (v_hosp, 'Bad', '9434765918');         -- invalid check digit
        ASSERT false, 'CHECK should have rejected an invalid NHS number';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '    ok: invalid NHS number rejected by CHECK';
    END;

    RAISE NOTICE '--- 4. status CHECK forbids arbitrary values ---';
    BEGIN
        UPDATE waitlist_entries SET status = 'BOGUS' WHERE id = v_entry;
        ASSERT false, 'status CHECK should forbid BOGUS';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '    ok: bogus status rejected';
    END;

    RAISE NOTICE '--- 5. Clinical-review state machine (resolve_cancellation) ---';
    -- Move to PENDING_CANCELLATION (the only state resolve_cancellation acts on).
    UPDATE waitlist_entries SET status = 'PENDING_CANCELLATION' WHERE id = v_entry;
    -- resolve_cancellation reads auth.uid()/current_hospital_id(); in a plain session
    -- those are NULL, so it should fail CLOSED (NOT_AUTHENTICATED). That itself proves
    -- the guard ordering — it does not transition without an identity.
    BEGIN
        v_res := resolve_cancellation(v_entry, 'REINSTATE', 'test');
        ASSERT false, 'resolve_cancellation should fail closed without auth.uid()';
    EXCEPTION WHEN others THEN
        RAISE NOTICE '    ok: resolve_cancellation fails closed without identity (%).', SQLERRM;
    END;
    -- Entry must still be PENDING_CANCELLATION (no transition happened).
    SELECT status INTO v_status FROM waitlist_entries WHERE id = v_entry;
    ASSERT v_status = 'PENDING_CANCELLATION', 'entry changed despite failed resolve';

    RAISE NOTICE '--- 6. Audit hash chain (direct ledger insert + verify) ---';
    -- Insert two ledger rows directly (as owner) to exercise the BEFORE INSERT chain
    -- trigger, then verify the chain is intact, then tamper and confirm detection.
    INSERT INTO cancellation_reviews
        (waitlist_entry_id, hospital_id, decision, previous_status, new_status, reviewed_by, note)
    VALUES
        (v_entry, v_hosp, 'REINSTATE', 'PENDING_CANCELLATION', 'ACTIVE', v_uid, 'row 1'),
        (v_entry, v_hosp, 'CONFIRM_CANCELLATION', 'PENDING_CANCELLATION', 'CANCELLED', v_uid, 'row 2');

    SELECT count(*) INTO v_count FROM cancellation_reviews;
    ASSERT v_count = 2, 'expected 2 ledger rows';

    v_chain := verify_audit_chain('cancellation_reviews');
    RAISE NOTICE '    chain after inserts: %', v_chain;
    ASSERT (v_chain->>'intact')::boolean,        'fresh chain should be intact';
    ASSERT (v_chain->>'rows')::int = 2,          'verify_audit_chain row count wrong';

    -- Tamper: mutate a business column WITHOUT recomputing the hash. (Possible here
    -- only because we are the table owner — exactly the bypass-RLS threat the chain
    -- exists to DETECT.) The chain must now report broken.
    UPDATE cancellation_reviews SET note = 'TAMPERED' WHERE note = 'row 1';
    v_chain := verify_audit_chain('cancellation_reviews');
    RAISE NOTICE '    chain after tamper: %', v_chain;
    ASSERT NOT (v_chain->>'intact')::boolean,    'tamper not detected by hash chain!';
    ASSERT (v_chain->>'first_broken_seq') IS NOT NULL, 'no broken seq reported';

    RAISE NOTICE '--- 7. Proxy fail-closed predicate (auth.has_proxy_access) ---';
    -- With no patient_proxies rows and no auth.uid(), access must be FALSE.
    ASSERT NOT auth.has_proxy_access(v_uid), 'has_proxy_access should be false with no grant';
    -- A revoked / out-of-window grant must also read as no-access.
    INSERT INTO patient_proxies (subject_user_id, proxy_user_id, relationship, consent_status, valid_from, valid_until)
        VALUES (gen_random_uuid(), v_uid, 'carer', 'GRANTED', NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day');
    ASSERT NOT auth.has_proxy_access(v_uid), 'expired grant should not confer access';

    RAISE NOTICE '--- 8. Proxy self-grant structurally blocked ---';
    BEGIN
        INSERT INTO patient_proxies (subject_user_id, proxy_user_id, relationship, consent_status)
            VALUES (v_uid, v_uid, 'self', 'GRANTED');     -- proxy = subject
        ASSERT false, 'self-proxy should be rejected by CHECK';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '    ok: proxy = subject rejected';
    END;

    RAISE NOTICE '====================================================';
    RAISE NOTICE 'ALL ASSERTIONS PASSED. (Transaction will ROLL BACK.)';
    RAISE NOTICE 'Note: RLS-as-a-role checks (authenticated/anon + JWT) are NOT';
    RAISE NOTICE 'covered here — see DEPLOYMENT.md §6 live post-deploy checks.';
    RAISE NOTICE '====================================================';
END;
$$;

ROLLBACK;
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
    },
    {
      "name": "staff",
      "runtimeExecutable": "python",
      "runtimeArgs": ["-m", "http.server", "5800", "--directory", "staff"],
      "port": 5800
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


## `tools/build_master.py`

````python
#!/usr/bin/env python3
"""
Build MASTER.md — a single, read-only bundle of every text source file in the
project, for easy review / handover / pasting into a fresh session.

WHY a generator (not a hand-written file): a hand-pasted master goes stale the
moment any source changes. This walks the *git-tracked* text files (so it can
never include secrets, env.js, videos, or untracked junk), in a sensible reading
order, and concatenates them with a table of contents.

Run it anytime:   python tools/build_master.py
Output:           MASTER.md at the project root (overwritten each run).

MASTER.md is GENERATED — never edit it by hand; edit the real source files and
re-run this script.
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "MASTER.md")

# Binary / non-text extensions to skip (defence-in-depth; git list is text anyway).
SKIP_EXT = {
    ".png", ".jpg", ".jpeg", ".gif", ".ico", ".webp", ".mp4", ".mov",
    ".zip", ".7z", ".pdf", ".woff", ".woff2", ".ttf", ".otf",
}
# Never include the bundle itself (avoid recursion) or its generator's output.
SKIP_NAMES = {"MASTER.md"}

# Curated reading order: top-level docs first, then grouped source dirs.
PRIORITY = [
    "README.md",
    "COMPLIANCE.md",
    "SECURITY.md",
    "ACCESSIBILITY.md",
    "SESSION_LOG_2026-05-29.md",
    "COMPLIANCE_CHANGELOG.md",
]
GROUP_ORDER = ["frontend/", "portal/", "supabase/", "project-status/", ".claude/", "tools/"]

# Extension -> markdown code-fence language hint.
LANG = {
    ".py": "python", ".js": "javascript", ".ts": "typescript", ".html": "html",
    ".css": "css", ".json": "json", ".sql": "sql", ".toml": "toml",
    ".md": "markdown", ".sh": "bash",
}


def tracked_text_files():
    out = subprocess.run(
        ["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True
    ).stdout.splitlines()
    files = []
    for f in (x.strip() for x in out):
        if not f or f in SKIP_NAMES:
            continue
        if os.path.splitext(f)[1].lower() in SKIP_EXT:
            continue
        files.append(f)
    return files


def order_key(path):
    if path in PRIORITY:
        return (0, PRIORITY.index(path), path)
    for i, g in enumerate(GROUP_ORDER):
        if path.startswith(g):
            return (1, i, path)
    return (2, 0, path)


def lang_for(path):
    if os.path.basename(path) in (".gitignore", ".gitattributes"):
        return ""
    return LANG.get(os.path.splitext(path)[1].lower(), "")


def fence_for(content):
    """Choose a backtick fence longer than the longest run already present, so
    nested ``` blocks (e.g. inside markdown files) never break the bundle."""
    longest = run = 0
    for ch in content:
        if ch == "`":
            run += 1
            longest = max(longest, run)
        else:
            run = 0
    return "`" * max(3, longest + 1)


def anchor(path):
    a = path.lower()
    for ch in "/. _":
        a = a.replace(ch, "-")
    while "--" in a:
        a = a.replace("--", "-")
    return a.strip("-")


def main():
    files = sorted(tracked_text_files(), key=order_key)

    # NOTE: deliberately NOT embedding the current commit hash here. The hash
    # changes on every commit, which would make MASTER.md drift by one line after
    # each commit forever (perpetual churn). By keeping the header static, the
    # bundle changes ONLY when real source content changes — so "git diff
    # MASTER.md" is meaningful and a stale bundle is easy to spot.
    parts = [
        "# NHS Waitlist Validation — MASTER bundle\n",
        "> **AUTO-GENERATED — do not edit by hand.** Single-file snapshot of every\n"
        "> git-tracked text file, for easy review / handover. Regenerate with\n"
        "> `python tools/build_master.py`. The individual files remain the source of\n"
        "> truth; this is a convenience copy.\n"
        ">\n"
        "> Secrets are never included — only git-tracked files are bundled, so the\n"
        "> gitignored `env.js` is excluded and only the `env.example.js` template appears.\n",
        f"\n**{len(files)} files** in this bundle.\n",
        "\n## Contents\n",
    ]
    parts += [f"- [`{f}`](#{anchor(f)})" for f in files]
    parts.append("")

    for f in files:
        full = os.path.join(ROOT, f)
        try:
            with open(full, "r", encoding="utf-8") as fh:
                content = fh.read()
        except (OSError, UnicodeDecodeError) as e:
            content = f"[could not read this file: {e}]"
        fence = fence_for(content)
        parts.append("\n---\n")
        parts.append(f"\n## `{f}`\n")
        parts.append(f"{fence}{lang_for(f)}")
        parts.append(content.rstrip("\n"))
        parts.append(fence)

    with open(OUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(parts) + "\n")

    print(f"Wrote {OUT} ({len(files)} files).")


if __name__ == "__main__":
    sys.exit(main())
````

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
staff/env.js

# ---- Supabase local state --------------------------------------------------
.supabase/
supabase/.branches/
supabase/.temp/

# ---- Python (tools/) -------------------------------------------------------
__pycache__/
*.pyc

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

---


## `DEPLOYMENT.md`

````markdown
# Deployment & Execution Runbook — NHS Waitlist Validation

> **The bridge from "code-reviewed" to "executed."** Every backend item in
> `COMPLIANCE.md` is currently *code-reviewed, not executed* — there is no live
> database in the development environment. This runbook is the ordered set of steps
> to stand the system up and **verify** it. Nothing here is a compliance claim;
> completing it produces *evidence*, which the Trust's sign-off roles then assess.
>
> **Who runs this:** a Trust engineer / admin with authority over the Supabase and
> Vercel accounts. Steps that touch credentials, billing, account settings, or
> destructive actions are **human-only** — do not automate them.

---

## 0. Prerequisites
- A Supabase account and a Vercel account owned by / contracted to the Trust.
- The Supabase CLI (`supabase`) installed locally, or access to the dashboard SQL editor.
- This repository checked out. Confirm the migration set is intact:
  `git ls-files supabase/migrations/` → **11 files** (see §2).

---

## 1. Create the Supabase project — **UK region** (COMPLIANCE §7)
1. Create a new Supabase project. **Region: London (eu-west-2).** This is the
   data-residency control — set it at creation; it cannot be changed later without
   a migration. Record the choice as evidence for the DPIA.
2. Note the project ref, the **public** URL, and the **anon** key (these are safe to
   ship to the browser). Note the **service-role key** — it is a secret; it goes ONLY
   into server-side settings, **never** into the repo or the browser (`SECURITY.md`).
3. Set a strong DB password; store it in the Trust's secret manager, not here.

---

## 2. Apply the migrations — **in this exact order**
The filenames are date-prefixed so lexical order = apply order. Apply all 11:

```
20260527000000_base_schema.sql                      # hospitals, waitlist_entries (+patient_user_id), current_hospital_id, SMS queue
20260528120000_waitlist_status_pending_cancellation.sql  # ensures status domain permits PENDING_CANCELLATION (runs FIRST of the dependents)
20260529000000_section_11_tokens_rpc.sql            # tokens + submit_validation_response (soft-cancel only)
20260529040000_retention_and_erasure.sql            # purge + erasure RPCs
20260529050000_nhs_number_modulus11.sql             # is_valid_nhs_number()
20260529060000_issue_validation_token.sql           # issue_validation_token()
20260529070000_patient_portal_rls.sql               # patient self-read policy
20260601000000_link_patient_identity.sql            # nhs_number column + link_my_waitlist_record()
20260601010000_clinical_review_workflow.sql         # resolve_cancellation() + cancellation_reviews ledger
20260601020000_audit_hash_chain.sql                 # tamper-evident SHA-256 chains + verify_audit_chain()
20260601030000_proxy_access_scaffold.sql            # patient_proxies + has_proxy_access + grant/revoke
```

**Via CLI:** `supabase link --project-ref <ref>` then `supabase db push`.
**Via dashboard:** paste each file into the SQL editor in the order above.

**Watch for the one expected manual step:** `20260528120000` introspects the
`status` domain. On this repo's own base schema it will `NOTICE "already permits"`.
If you pointed the app at a **pre-existing** Trust table whose `status` is guarded by
a CHECK constraint, it will instead raise a NOTICE telling you to widen that
constraint by hand (it cannot be auto-rewritten safely). Resolve that before relying
on the soft-cancel path.

---

## 3. Run the verification harness (de-risks "code-reviewed, not executed")
After applying, run `supabase/tests/verify.sql` (psql or SQL editor). It asserts the
core safety properties: RLS isolation, the clinical-review state machine, hash-chain
tamper detection, and proxy fail-closed. **All assertions must pass** before go-live
testing. A failure means an assumption this repo made about the live DB is wrong —
investigate before proceeding. (See that file's header for how to read results.)

---

## 4. Dashboard settings (COMPLIANCE §6, §7, §10) — human-only
- [ ] **Admin MFA** — enforce MFA for every account with dashboard / DB access (§6).
- [ ] **Auth → URL config** — set the Site URL + redirect allow-list to the portal's
      deployed origin (the OIDC `redirectTo` must be allow-listed).
- [ ] **Auth → Providers → NHS Login (OIDC)** — register the real provider: client
      id/secret, NHS Login issuer/discovery URL, scopes incl. the one that returns the
      verified **NHS Number**, and identity proofing at **P9**. Map claims so the JWT
      carries `nhs_number` and `identity_proofing_level` (consumed by
      `link_my_waitlist_record()`). Then set `NHS_OIDC_PROVIDER` in the portal env
      (see §5) to the provider name. **Credentials live here, never in the repo.**
- [ ] Confirm the project region is **London** (§1 above).
- [ ] Review Postgres logs settings so you can later confirm **no token↔PII
      correlation** in request logs (§6 audit item).

---

## 5. Configure runtime env (PUBLIC values only) & deploy to Vercel
1. **Frontend** (`frontend/`): copy `env.example.js` → `env.js`, fill `SUPABASE_URL`
   + `SUPABASE_ANON_KEY`. `env.js` is gitignored — never commit it.
2. **Portal** (`portal/`): copy `env.example.js` → `env.js`, fill the same two, plus
   `NHS_OIDC_PROVIDER` (the provider name from §4; leave empty to keep the mock form).
3. Deploy each directory as its own Vercel project (each has its own `vercel.json`
   that sets the security headers). Pin serverless/edge region to **UK (`lhr1`)** for
   anything that could touch PII (§7).
4. The service-role key (if any edge functions need it) goes in **Vercel/Supabase
   function env**, never in `env.js`.

---

## 6. Post-deploy verification
- [ ] **Headers** — `curl -sI https://<portal-domain>/` shows `content-security-policy`,
      `strict-transport-security`, `x-frame-options: DENY`, etc. Repeat for the frontend.
- [ ] **security.txt** — `https://<frontend-domain>/.well-known/security.txt` returns
      `text/plain` and every `%%PLACEHOLDER%%` has been replaced (an incomplete one is
      worse than none — `SECURITY.md`).
- [ ] **Auth gating** — signed out, the portal shows only the login screen; the
      dashboard is never reachable without a session.
- [ ] **Idle timeout** — confirm the inactivity sign-out fires (default 10 min;
      `IDLE_TIMEOUT_MINUTES` configurable).
- [ ] **RLS isolation (live)** — sign in as two test patients with distinct
      `nhs_number`s + linked rows; confirm each sees ONLY their own entry.
- [ ] **Clinical review** — drive a test entry through PENDING_CANCELLATION →
      `resolve_cancellation` (REINSTATE and CONFIRM); confirm `cancellation_reviews`
      gets an audit row and `verify_audit_chain('cancellation_reviews')` reports intact.
- [ ] **Proxy fail-closed** — with no `patient_proxies` row, a second account sees
      nothing of the first; a non-staff caller of `grant_proxy_access` is rejected.

---

## 7. What this runbook does NOT do (still 👤 Trust sign-off)
Executing every step above produces a *running, self-verified* system — it does **not**
make it "compliant." Still required and owned by the Trust:
- **CSO** sign-off + Hazard Log / Clinical Safety Case Report (DCB0129/0160).
- **DPIA** completed + signed (special-category data, incl. stored NHS Number).
- **DSPT** submission; **Caldicott Guardian** approval; **DPO** sign-off.
- **CREST/CHECK** penetration test; **Cyber Essentials Plus**.
- Formal independent **WCAG 2.2 AA** audit + assistive-technology testing.
- **PII encryption at rest** decision (`COMPLIANCE.md` §2).
- The **staff-tooling UI** + real staff authentication that drives
  `resolve_cancellation` / `grant_proxy_access`.

Describe the result as **"built to align with [standard], pending [role] sign-off"** —
never "compliant."

_Drafted 2026-06-01 (engineering runbook). Execution owner: the Trust's deploying engineer._
````

---


## `SECURITY-INCIDENT.md`

```markdown
# Security Incident & Personal-Data-Breach Runbook — NHS Waitlist Validation

> **DRAFT runbook, built to align with UK GDPR Art. 33/34, the DSPT incident
> process, and NHS breach-reporting routes — pending Trust ownership and sign-off
> (DPO + Caldicott Guardian + SIRO).** This is NOT evidence of an operational
> incident-response capability. The Trust MUST adopt it, fill every
> `%%PLACEHOLDER%%`, name the responsible people, rehearse it, and integrate it
> with the Trust's existing major-incident process before go-live. See
> `COMPLIANCE.md` §8 (DSPT) and §2 (UK GDPR).

A personal-data breach is *"a breach of security leading to the accidental or
unlawful destruction, loss, alteration, unauthorised disclosure of, or access to,
personal data."* It does **not** require malicious intent — a misdirected SMS, an
over-broad RLS policy, or a lost laptop all count.

---

## 0. Roles (fill in before go-live)

| Role | Name / contact | Responsibility |
|---|---|---|
| Incident Lead | `%%INCIDENT_LEAD%%` | Owns the response, declares start/end |
| Data Protection Officer (DPO) | `%%DPO_CONTACT%%` | Decides on ICO + data-subject notification |
| Caldicott Guardian | `%%CALDICOTT%%` | Confidentiality / clinical-impact judgement |
| SIRO (Senior Information Risk Owner) | `%%SIRO%%` | Accountable owner of information risk |
| Clinical Safety Officer (CSO) | `%%CSO%%` | Assesses patient-safety impact (DCB0129/0160) |
| Technical responder | `%%TECH_ONCALL%%` | Containment, evidence, remediation |
| Comms / press | `%%COMMS%%` | External messaging if required |

**The 72-hour clock starts when the Trust becomes **aware** of the breach — not
when investigation finishes.** Assume awareness = the moment any staff member
reasonably suspects a breach, and start the timeline immediately.

---

## 1. Triage & severity (first 60 minutes)

1. **Record the clock.** Note the date/time of awareness — this anchors the 72h
   ICO deadline. Open an incident record (timestamp, who, what was observed).
2. **Classify.** Is personal/special-category data (health data, NHS Number)
   involved? This system's sensitive surfaces:
   - `waitlist_entries.nhs_number` (PII — added for identity matching)
   - `waitlist_entries.patient_user_id` ↔ auth identity linkage
   - `sms_dispatch_jobs.patient_phone` (PII — phone numbers)
   - The patient-facing layers are **PII-free by design** (UUID token only); a
     breach there is lower-severity unless it correlates a token to an identity.
3. **Assess risk to individuals** (drives whether you must notify them, Art. 34):
   likelihood + severity of harm (distress, discrimination, identity exposure,
   clinical risk if waitlist status is altered).
4. **Assign severity** `%%SEV_SCALE%%` (e.g. SEV1 confirmed health-data
   disclosure → SEV4 contained near-miss) and page the roles in §0 accordingly.

---

## 2. Contain (immediately, in parallel with triage)

Do the minimum that stops ongoing exposure without destroying evidence:

- **Revoke / rotate credentials** if a key may be exposed — rotate the Supabase
  **service-role key** and DB password in the Supabase dashboard, and any Vercel
  env values. *(Claude/automation must NOT do this — a human performs all
  credential changes; see the security rules.)*
- **Disable the leak path.** If an RLS policy or RPC is over-permissive, disable
  the offending policy/function (a forward-fix migration, not a manual prod edit,
  where possible) and redeploy.
- **Burn affected tokens.** `purge_expired_tokens()` exists; for a targeted burn,
  revoke specific `waitlist_tokens` rows.
- **Preserve evidence FIRST.** Before deleting anything, capture Supabase logs,
  request logs, and the relevant DB rows (see §3). Containment ≠ destruction.
- **Do NOT** permanently delete data, empty trash, or alter access controls as a
  "fix" — that can destroy evidence and may itself be a notifiable change. Capture,
  then change forward.

---

## 3. Preserve evidence

- Export relevant **Supabase logs** (Auth, Postgres, Edge) and **Vercel** access
  logs for the window. Note: confirm whether request logs ever correlate a token
  with PII (`COMPLIANCE.md` §6 audit-trail item) — if so, that itself is a finding.
- Snapshot affected rows (`waitlist_entries`, `sms_dispatch_jobs`, `waitlist_tokens`)
  with timestamps. Record the migration/commit SHA deployed at the time of breach.
- Keep an append-only incident log (who did what, when). Timeline integrity matters
  for the ICO and for the post-incident review.

---

## 4. Notify — the deadlines that matter

### a) ICO (Information Commissioner's Office) — within **72 hours** of awareness
Notify the ICO **unless** the breach is **unlikely to result in a risk** to
individuals' rights and freedoms (UK GDPR Art. 33(1)). When in doubt, the DPO
decides; document the reasoning either way.
- If you cannot gather full details in 72h, submit what you have and supplement
  later (Art. 33(4) explicitly allows phased reporting). **Do not** wait past 72h
  to start.
- ICO breach report: `https://ico.org.uk/for-organisations/report-a-breach/`.
- Include: nature of breach, categories & approximate number of individuals &
  records, likely consequences, measures taken/proposed, DPO contact.

### b) Affected individuals (patients) — **without undue delay** (Art. 34)
Required when the breach is likely to result in a **high risk** to individuals.
Communicate in clear, plain language: what happened, likely consequences, what
you're doing, what they can do. Coordinate wording with the DPO + Comms.
**Sending these communications is a human-authorised action — Claude must not send
patient notifications.**

### c) NHS-specific routes (run in parallel with the ICO)
- **DSPT incident reporting tool** — report via the Data Security and Protection
  Toolkit; for NHS organisations this is the route that also notifies the ICO and
  NHS England for notifiable incidents. Confirm the Trust's DSPT process owner.
- **NHS England Data Security Centre** / national cyber route where the incident
  is a cyber attack. Add the Trust's correct internal escalation here:
  `%%NHS_ESCALATION%%`.
- Internal: SIRO, Caldicott Guardian, and (if patient safety could be affected)
  the **CSO** under the clinical-safety process (DCB0129/0160).

---

## 5. Eradicate & recover

- Deploy the verified fix (forward migration / code change + redeploy). Confirm the
  leak path is closed in a test before prod.
- Rotate any remaining exposed secrets; confirm no service-role key reached the
  client (`SECURITY.md`).
- Validate RLS isolation after the fix (a signed-in patient still sees only their
  own row; admin scoped to `hospital_id`).
- Resume normal operation only when the Incident Lead + DPO agree containment is
  complete.

---

## 6. Post-incident review (within `%%PIR_DAYS%%` working days)

- Blameless timeline: detection → containment → notification → recovery.
- Root cause + contributing factors. Did we meet the 72h clock? If not, why?
- Actions with owners + due dates. Update `COMPLIANCE.md` (§8 status, hazard log if
  clinical), this runbook, and the DSPT record.
- Feed any new clinical hazard back into `COMPLIANCE.md` §1.

---

## Quick reference — clocks & contacts

| Item | Value |
|---|---|
| ICO deadline | **72 hours** from awareness |
| ICO report | `https://ico.org.uk/for-organisations/report-a-breach/` |
| Patient notification | Without undue delay, if **high risk** (Art. 34) |
| DSPT incident tool | `%%DSPT_INCIDENT_URL%%` |
| NHS escalation | `%%NHS_ESCALATION%%` |
| Incident Lead | `%%INCIDENT_LEAD%%` |
| DPO | `%%DPO_CONTACT%%` |

---

## What this runbook is NOT
- **Not** proof of an operational incident-response capability — that requires the
  Trust to own, staff, rehearse, and integrate it with the major-incident process.
- **Not** legal advice — the DPO/legal team make the notification calls.
- **Not** a substitute for the DSPT submission (`COMPLIANCE.md` §8) or the DPIA (§2).

_Drafted 2026-06-01 (engineering aid). Owner before go-live: `%%RUNBOOK_OWNER%%` (DPO/SIRO)._
```

---


## `governance/DPIA-DRAFT.md`

```markdown
# DPIA — Data Protection Impact Assessment (DRAFT / PRE-POPULATED)

> **DRAFT. NOT a completed or approved DPIA.** This is an engineering-prepared
> starting point that captures what the *code* already establishes (data flows,
> minimisation, security controls). Every decision, risk acceptance, lawful-basis
> determination and signature is a `%%PLACEHOLDER%%` for the Trust's **Data
> Protection Officer** and **Caldicott Guardian** to complete and own. A DPIA is
> **mandatory before go-live** for special-category (health) data (UK GDPR Art. 35).
> Do not treat this file as evidence of compliance — it is scaffolding to accelerate
> the real assessment.

## Sign-off block (to be completed by the Trust)
| Role | Name | Date | Signature |
|---|---|---|---|
| Data Protection Officer | `%%DPO_NAME%%` | `%%DATE%%` | `%%SIG%%` |
| Caldicott Guardian | `%%CALDICOTT_NAME%%` | `%%DATE%%` | `%%SIG%%` |
| SIRO | `%%SIRO_NAME%%` | `%%DATE%%` | `%%SIG%%` |
| Information Asset Owner | `%%IAO_NAME%%` | `%%DATE%%` | `%%SIG%%` |

---

## 1. Need for a DPIA (screening)
This processing is **high-risk** and a DPIA is required because it involves:
- **Special-category data** — health data (waitlist/procedure status) (Art. 9).
- **NHS Number** — a unique national identifier (stored on `waitlist_entries`).
- **Vulnerable data subjects** — patients, including potentially elderly users and
  (via proxy access) dependents.
- **Large-scale** processing within an NHS Trust context.

## 2. Description of the processing
**Purpose:** keep elective-surgery waiting lists accurate by (a) letting patients
confirm/decline their place via a PII-free SMS link, and (b) letting them view their
own waitlist status in an authenticated portal.

**Two surfaces (distinct data exposure):**
| Surface | Auth | Data exposed to the client |
|---|---|---|
| SMS validation (`frontend/`) | Anonymous, single-use UUID token | **Zero PII** — only a random token in the URL |
| Patient Hub portal (`portal/`) | NHS Login (OIDC), per-user JWT | The signed-in patient's own `procedure, status, referred_at, created_at` (no `nhs_number`, no `patient_user_id` sent to the browser) |

**Data categories processed (server-side):**
- NHS Number (`waitlist_entries.nhs_number`) — identity match key.
- Health data — procedure + waitlist status.
- Contact data — `sms_dispatch_jobs.patient_phone` (phone number).
- Auth identity — `auth.users` (NHS Login subject), `patient_user_id` linkage.
- Audit — `cancellation_reviews`, `validation_responses` (who/what/when).

**Data flow:** `%%CONFIRM/EXPAND%%` — PAS/source populates `waitlist_entries`
(incl. `nhs_number`) → token issued (`issue_validation_token`) → SMS dispatched
(`sms_dispatch_jobs`) → patient responds (PII-free) **or** signs in via NHS Login,
`link_my_waitlist_record()` matches `auth.uid()` to their row → portal shows own data.

**Recipients / processors:** Supabase (DB/auth host), Vercel (static hosting/CDN),
SMS provider `%%SMS_PROVIDER%%`, NHS Login (identity provider). `%%CONFIRM data
processing agreements (Art. 28) in place for each%%`.

**Retention:** tokens auto-purged (`purge_expired_tokens`); response retention is a
`%%CALDICOTT/IG DECISION — set interval%%` (`purge_aged_validation_responses` exists
but is deliberately unscheduled); erasure via `erase_patient_validation_data`.

**International transfers / residency:** target region London (eu-west-2). `%%CONFIRM
no data leaves the UK at any layer%%` (§7).

## 3. Consultation
- Data subjects / patient representatives: `%%RECORD consultation%%`
- DPO advice: `%%DPO ADVICE%%`
- Processors / security team: `%%RECORD%%`

## 4. Necessity & proportionality
- **Lawful basis (Art. 6):** likely `%%6(1)(e) public task%%` — DPO to confirm.
- **Special-category condition (Art. 9):** likely `%%9(2)(h) health/social care%%` — confirm.
- **Data minimisation (built):** SMS layer holds zero PII; portal client query is
  restricted to non-PII columns; URL carries only a UUID. *(Evidence: COMPLIANCE §2.)*
- **Proportionality of NHS Number storage:** required to match a verified NHS Login
  identity to the correct clinical record; not exposed to the patient's browser.
  `%%DPO to confirm this is the least-intrusive means%%`.

## 5. Risks to individuals (DPO/Caldicott to score & accept)
| # | Risk | Source / likelihood | Impact | Mitigation already in code | Residual (Trust to rate) |
|---|---|---|---|---|---|
| R1 | Wrong person sees a patient's data (IDOR) | Mis-scoped query | High | RLS `patient_user_id = auth.uid()`; client passes no id; portal selects non-PII cols | `%%RATE%%` |
| R2 | Mis-delivered SMS → wrong recipient acts | SMS to wrong number | Med | PII-free URL; confirmation gate; reversible `PENDING_CANCELLATION` | `%%RATE%%` |
| R3 | Irreversible wrongful cancellation | One-tap decline | High→Low | No hard-cancel on patient path; soft-state + clinician `resolve_cancellation`; audit ledger | `%%RATE%%` |
| R4 | NHS Number exposed at rest | DB compromise | High | Admin-RLS-scoped, never to client; **encryption-at-rest still ❌ — Trust decision** | `%%RATE%%` |
| R5 | Proxy used to over-reach into another's record | Loose authz | High | Verified/consented/time-bounded `patient_proxies`; staff-gated grant; fail-closed | `%%RATE%%` |
| R6 | Session left open on shared/elderly device | Walk-away | Med | Idle auto sign-out + explicit sign-out | `%%RATE%%` |
| R7 | Audit record altered to hide an action | Insider/DB admin | Med | Append-only ledgers + SHA-256 hash chain (`verify_audit_chain`) — tamper-evident | `%%RATE%%` |
| R8 | `%%ADD any the Trust identifies%%` | | | | |

## 6. Measures to reduce risk
Engineering controls are catalogued in `COMPLIANCE.md` (§2/§3/§6/§10) and `SECURITY.md`.
**Outstanding non-code measures (Trust):** at-rest encryption (R4), CREST pen test,
Cyber Essentials Plus, admin MFA enforcement, DSPT, formal WCAG audit, and the
processor DPAs above.

## 7. Outcome (Trust to complete)
- Residual risk acceptable? `%%YES/NO + rationale%%`
- Approved to proceed? `%%DPO DECISION%%`  Review date: `%%DATE%%`
- ICO prior consultation needed (Art. 36, if high residual risk)? `%%YES/NO%%`

_Draft prepared 2026-06-01 (engineering). Owner: `%%DPO_NAME%%`. This draft confers no compliance._
```

---


## `governance/HAZARD-LOG-DRAFT.md`

```markdown
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
```

---


## `staff/app.js`

```javascript
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
```

---


## `staff/env.example.js`

```javascript
/* =========================================================================
   Runtime configuration template for the NHS Staff Console (staff/).
   Copy to env.js and fill in, OR generate env.js at deploy time.

   SECURITY:
     • SUPABASE_URL + SUPABASE_ANON_KEY are PUBLIC by design. Staff actions run
       under the signed-in staff member's JWT; the worklist read is scoped by
       admin RLS (hospital_id) and every mutation goes through a SECURITY DEFINER
       RPC that re-checks authorisation server-side.
     • NEVER put the service-role key (or any secret) here — it would be exposed
       to every visitor. Secrets live only in server-side functions.
     • PRODUCTION AUTH: this console ships with a MOCK sign-in for local demo.
       Real deployment must wire NHS staff authentication (Care Identity / hospital
       SSO) that issues the `hospital_id` JWT claim the RLS + RPCs depend on. That
       integration is a Trust step — see DEPLOYMENT.md.
   ========================================================================= */
window.__ENV = {
  SUPABASE_URL: "https://YOUR-PROJECT-REF.supabase.co",
  SUPABASE_ANON_KEY: "YOUR-PUBLIC-ANON-KEY",
};
```

---


## `staff/index.html`

```html
<!DOCTYPE html>
<html lang="en-GB">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
  <meta name="color-scheme" content="light" />
  <title>Staff Console — Waitlist Clinical Review (NHS)</title>
  <meta name="description" content="Staff console: review pending waitlist cancellations and manage proxy access." />

  <!-- CSP: defence-in-depth; authoritative policy is the HTTP header in staff/vercel.json
       (kept byte-aligned). connect-src allows Supabase REST + Auth + Realtime (wss). -->
  <meta http-equiv="Content-Security-Policy"
        content="default-src 'none'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self'; connect-src 'self' https://*.supabase.co wss://*.supabase.co; img-src 'self' data:; font-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; upgrade-insecure-requests" />

  <link rel="preconnect" href="https://cdn.jsdelivr.net" />
  <link rel="stylesheet" href="styles.css?v=20260601" />
</head>
<body>
  <a class="skip-link" href="#main">Skip to main content</a>

  <!-- DEV/MOCK BANNER: this console uses mock auth for local demo. In production it is
       replaced by real staff authentication carrying the hospital_id JWT claim. -->
  <p class="devbanner" role="note">
    Demo console — <strong>mock staff sign-in</strong>. Production requires real NHS
    staff authentication (Care Identity / hospital SSO) with a verified hospital scope.
  </p>

  <main id="main" class="stage">

    <!-- ===== STATE A — signed out ===== -->
    <section id="login" class="card login" aria-labelledby="loginTitle" hidden>
      <div class="brand">
        <div class="brand__mark" aria-hidden="true">
          <svg viewBox="0 0 80 32" role="img" focusable="false">
            <rect width="80" height="32" rx="4" fill="currentColor" />
            <text x="40" y="22" text-anchor="middle" font-family="Arial, sans-serif"
                  font-weight="700" font-size="16" fill="#ffffff" letter-spacing="0.5">NHS</text>
          </svg>
        </div>
        <p class="brand__trust">Staff Console</p>
      </div>
      <h1 id="loginTitle" class="headline">Waitlist clinical review</h1>
      <p class="lede">Sign in to review patient responses that need clinical action and to manage proxy access.</p>

      <form id="staffSignin" class="devform">
        <p class="devform__note">Mock staff sign-in (local demo only — no real credentials stored)</p>
        <label class="field">
          <span class="field__label">Staff email</span>
          <input id="staffEmail" class="field__input" type="email" autocomplete="username" inputmode="email" required />
        </label>
        <label class="field">
          <span class="field__label">Password</span>
          <input id="staffPassword" class="field__input" type="password" autocomplete="current-password" required />
        </label>
        <button id="staffSubmit" class="btn btn--primary" type="submit"><span class="btn__label">Sign in</span></button>
      </form>
      <p id="loginError" class="error" role="alert" hidden></p>
    </section>

    <!-- ===== STATE B — signed in ===== -->
    <section id="console" class="console" aria-labelledby="consoleTitle" hidden>
      <header class="topbar">
        <div class="brand brand--inline">
          <div class="brand__mark brand__mark--sm" aria-hidden="true">
            <svg viewBox="0 0 80 32" role="img" focusable="false">
              <rect width="80" height="32" rx="4" fill="currentColor" />
              <text x="40" y="22" text-anchor="middle" font-family="Arial, sans-serif"
                    font-weight="700" font-size="16" fill="#ffffff" letter-spacing="0.5">NHS</text>
            </svg>
          </div>
          <span id="hospitalLabel" class="topbar__scope">—</span>
        </div>
        <button id="signOut" class="btn btn--ghost" type="button">Sign out</button>
      </header>

      <h1 id="consoleTitle" class="console__title">Clinical review worklist</h1>
      <p class="console__lead">Patients who tapped “I no longer need this”. Each entry is held in a
        <strong>reversible</strong> state until you confirm or reinstate it — nothing was auto-cancelled.</p>

      <p id="worklistEmpty" class="empty" hidden>No entries are awaiting review.</p>

      <ul id="worklist" class="worklist" aria-label="Entries awaiting clinical review"></ul>

      <!-- Proxy management -->
      <section class="panel" aria-labelledby="proxyTitle">
        <h2 id="proxyTitle" class="panel__title">Proxy access</h2>
        <p class="panel__lead">Grant a verified carer/parent access to a patient’s record, or revoke it.
          Granting requires recorded Caldicott consent + identity verification (out of band).</p>
        <div class="proxy-grid">
          <label class="field"><span class="field__label">Patient (subject) user ID</span>
            <input id="pxSubject" class="field__input" type="text" inputmode="text" placeholder="uuid" /></label>
          <label class="field"><span class="field__label">Proxy user ID</span>
            <input id="pxProxy" class="field__input" type="text" inputmode="text" placeholder="uuid" /></label>
          <label class="field"><span class="field__label">Relationship</span>
            <input id="pxRel" class="field__input" type="text" placeholder="parent / carer / LPA" /></label>
        </div>
        <div class="proxy-actions">
          <button id="pxGrant" class="btn btn--primary" type="button">Grant access</button>
          <button id="pxRevoke" class="btn btn--ghost" type="button">Revoke access</button>
        </div>
        <p id="proxyMsg" class="msg" role="status" hidden></p>
      </section>

      <p id="consoleError" class="error" role="alert" hidden></p>
    </section>
  </main>

  <script
    src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.106.2"
    integrity="sha384-4Cjkyy4cE1EgIS0C+Y3xzGmJ2noQFRRU91yKAW8IxtPfVtbQXPMqadSc3sYnjwou"
    crossorigin="anonymous"
    referrerpolicy="no-referrer"></script>
  <script src="env.js"></script>
  <script src="app.js?v=20260601" defer></script>
</body>
</html>
```

---


## `staff/styles.css`

```css
/* =========================================================================
   NHS Staff Console — styles.css
   Built to ALIGN WITH the NHS Digital Service Manual + WCAG 2.2 AA (same palette
   + tokens as the patient portal). Self-contained (separate Vercel deploy, so no
   cross-directory @import). Light-only. Logo is a placeholder; not NHS-accredited.
   Contrast ratios noted are developer-measured vs AA — confirm in a formal audit.
   ========================================================================= */
:root {
  --nhs-blue: #005EB8; --nhs-dark-blue: #003087; --nhs-black: #212B32;
  --nhs-grey-1: #4C6272; --nhs-pale-grey: #E8EDEE; --nhs-mid-grey: #AEB7BD;
  --nhs-white: #FFFFFF; --nhs-green: #007F3B; --nhs-red: #DA291C; --nhs-yellow: #FFEB3B;
  --nhs-warm-yellow: #FFB81C;
  --ink: var(--nhs-black); --ink-soft: var(--nhs-grey-1); --line: #D8DDE0;
  --surface: var(--nhs-white); --canvas: var(--nhs-pale-grey);
  --primary: var(--nhs-blue); --primary-press: var(--nhs-dark-blue); --focus: var(--nhs-yellow);
  --shadow: 0 1px 2px rgba(33,43,50,.06), 0 6px 18px rgba(33,43,50,.08);
  --radius: 8px; --radius-sm: 6px; --tap: 48px;
  --ease: cubic-bezier(.2,.7,.2,1);
  --font: "Inter", Arial, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, sans-serif;
  color-scheme: light;
}

* { box-sizing: border-box; margin: 0; padding: 0; }
html { -webkit-text-size-adjust: 100%; }
[hidden] { display: none !important; }

body {
  font-family: var(--font); color: var(--ink); background: var(--canvas);
  line-height: 1.55; min-height: 100svh; -webkit-font-smoothing: antialiased;
}

/* ---- Accessibility primitives ---- */
.skip-link {
  position: fixed; top: -120px; left: 12px; z-index: 100; padding: 12px 16px;
  background: var(--nhs-black); color: #fff; border-radius: var(--radius-sm);
  text-decoration: none; transition: top .15s var(--ease);
}
.skip-link:focus-visible { top: 12px; }
:where(a, button, input, select, textarea, summary, [tabindex]):focus-visible {
  outline: 3px solid var(--focus); outline-offset: 2px;
  box-shadow: 0 0 0 5px var(--nhs-black); border-radius: var(--radius-sm);
}

/* ---- Demo banner (mock-auth honesty) ---- */
.devbanner {
  background: #FFF4D6; border-bottom: 2px solid var(--nhs-warm-yellow);
  color: #3d2f00; padding: 10px 20px; font-size: .95rem; text-align: center;
}

/* ---- Layout ---- */
.stage { max-width: 860px; margin: 0 auto; padding: 28px 20px 64px; }

.card {
  background: var(--surface); border-radius: var(--radius); box-shadow: var(--shadow);
  padding: 32px 28px; margin-top: 28px;
}
.login { max-width: 480px; }

.brand { display: flex; align-items: center; gap: 12px; }
.brand--inline { margin: 0; }
.brand__mark { color: var(--nhs-blue); width: 80px; }
.brand__mark--sm { width: 56px; }
.brand__mark svg { width: 100%; height: auto; display: block; }
.brand__trust, .topbar__scope { font-weight: 600; color: var(--ink-soft); }

.headline { font-size: 1.9rem; line-height: 1.15; margin: 18px 0 10px; }
.lede { color: var(--ink-soft); font-size: 1.0625rem; margin-bottom: 22px; }

/* ---- Buttons ---- */
.btn {
  display: inline-flex; align-items: center; justify-content: center; gap: 8px;
  min-height: var(--tap); padding: 12px 20px; border: 0; border-radius: var(--radius-sm);
  font: inherit; font-weight: 600; font-size: 1.0625rem; cursor: pointer;
  transition: background .15s var(--ease), transform .05s var(--ease);
}
.btn--primary { background: var(--primary); color: #fff; box-shadow: var(--shadow); }
.btn--primary:hover { background: var(--primary-press); }
.btn--ghost { background: #fff; color: var(--nhs-blue); border: 2px solid var(--nhs-blue); }
.btn--ghost:hover { background: #eef4fb; }
.btn--danger { background: var(--nhs-red); color: #fff; }     /* white-on-red ≈ 4.8:1 (AA) */
.btn--danger:hover { background: #b71f14; }
.btn:active { transform: scale(.99); }
.btn:disabled, .btn[aria-busy="true"] { opacity: .5; cursor: not-allowed; transform: none; box-shadow: none; }

/* ---- Fields ---- */
.field { display: flex; flex-direction: column; gap: 8px; margin-bottom: 16px; }
.field__label { font-size: 1rem; font-weight: 600; }
.field__input {
  min-height: var(--tap); padding: 13px 16px; font: inherit; color: var(--ink);
  background: #fff; border: 2px solid var(--nhs-mid-grey); border-radius: var(--radius-sm);
}
.field__input:hover { border-color: var(--nhs-grey-1); }
.field__input:focus { border-color: var(--nhs-blue); }
.devform__note { font-size: .95rem; color: var(--ink-soft); margin-bottom: 14px; }

/* ---- Top bar ---- */
.topbar {
  display: flex; align-items: center; justify-content: space-between; gap: 16px;
  padding-bottom: 18px; border-bottom: 1px solid var(--line);
}

.console__title { font-size: 1.7rem; margin: 24px 0 8px; }
.console__lead { color: var(--ink-soft); margin-bottom: 22px; }
.empty { color: var(--ink-soft); padding: 18px; background: var(--surface); border-radius: var(--radius); box-shadow: var(--shadow); }

/* ---- Worklist ---- */
.worklist { list-style: none; display: flex; flex-direction: column; gap: 14px; }
.wl-item {
  display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 16px;
  background: var(--surface); border-radius: var(--radius); box-shadow: var(--shadow);
  padding: 18px 20px; border-left: 4px solid var(--nhs-warm-yellow);
}
.wl-item__proc { font-weight: 700; font-size: 1.125rem; }
.wl-item__meta { color: var(--ink-soft); font-size: .95rem; margin-top: 4px; }
.wl-item__meta code { background: var(--nhs-pale-grey); padding: 1px 6px; border-radius: 4px; }
.wl-item__actions { display: flex; gap: 10px; flex-wrap: wrap; }
.wl-item__actions .btn { width: auto; }

/* ---- Panels ---- */
.panel { background: var(--surface); border-radius: var(--radius); box-shadow: var(--shadow); padding: 26px 24px; margin-top: 30px; }
.panel__title { font-size: 1.3rem; margin-bottom: 8px; }
.panel__lead { color: var(--ink-soft); margin-bottom: 18px; }
.proxy-grid { display: grid; grid-template-columns: 1fr; gap: 4px 18px; }
@media (min-width: 640px) { .proxy-grid { grid-template-columns: 1fr 1fr 1fr; } }
.proxy-actions { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 6px; }
.proxy-actions .btn { width: auto; }

/* ---- Messages ---- */
.msg, .error { margin-top: 14px; padding: 12px 16px; border-radius: var(--radius-sm); font-weight: 600; }
.msg[data-kind="ok"] { background: #E6F3EC; color: var(--nhs-green); }
.msg[data-kind="error"], .error { background: #FBE9E8; color: var(--nhs-red); }

/* ---- Reduced motion / forced colors ---- */
@media (prefers-reduced-motion: reduce) { * { transition: none !important; animation: none !important; } }
@media (forced-colors: active) {
  .btn { border: 1px solid; }
  :where(a, button, input, summary, [tabindex]):focus-visible { outline: 3px solid Highlight; }
}
```

---


## `staff/vercel.json`

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'none'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self'; connect-src 'self' https://*.supabase.co wss://*.supabase.co; img-src 'self' data:; font-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; upgrade-insecure-requests"
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
