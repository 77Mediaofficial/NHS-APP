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
