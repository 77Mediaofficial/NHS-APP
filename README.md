# NHS Waitlist Validation

A patient-facing waitlist validation app: a patient taps a single-use, PII-free link
and confirms whether they still need their scheduled procedure. Static frontend
(vanilla HTML/CSS/JS) on Vercel, talking to a hardened Supabase token + RPC backend.

> ⚠️ **Not certified.** This is built to *align with* NHS standards (DCB0129/0160,
> UK GDPR/DPIA, DTAC v2, WCAG 2.2 AA) but is **not "compliant"** — go-live legally
> requires the Trust's Clinical Safety Officer, Data Protection Officer, and Caldicott
> Guardian sign-off. See `COMPLIANCE.md` for the living status (single source of truth).

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
1. `20260528000000_base_schema.sql` — scaffolds `hospitals`, `hospital_staff`,
   `waitlist_entries` (with `hospital_id`, `status`, FORCE RLS), `sms_dispatch_jobs`,
   `auth.current_hospital_id()`, `get_next_sms_batch()`, and the `updated_at` trigger.
   **Run this first on any empty project.**
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
