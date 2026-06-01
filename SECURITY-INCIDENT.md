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
