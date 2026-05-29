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
