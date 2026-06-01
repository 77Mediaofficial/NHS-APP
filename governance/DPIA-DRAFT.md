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
