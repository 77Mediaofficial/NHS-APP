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
