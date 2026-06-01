# NHS Waitlist Validation

An elective-waitlist validation system with **three static surfaces** (vanilla
HTML/CSS/JS on Vercel) over a hardened Supabase token + RPC + RLS backend:
- **`frontend/`** — patient SMS validation: tap a single-use, **PII-free** link and
  confirm whether you still need your procedure (no login, no PII in the URL).
- **`portal/`** — authenticated **Patient Hub**: sign in (NHS Login) to view your own
  waitlist status. Per-user JWT + RLS isolation; idle auto sign-out.
- **`staff/`** — authenticated **Staff Console**: clinical review of declined slots
  (`PENDING_CANCELLATION`) + proxy-access management, via hardened RPCs. *Mock auth
  for local demo; real NHS staff auth is a Trust step.*

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
frontend/                 Patient SMS validation UI (PII-free)   — deploy to Vercel
portal/                   Patient Hub (authenticated dashboard)  — deploy to Vercel
staff/                    Staff Console (clinical review + proxy) — deploy to Vercel
  (each surface: index.html + styles.css + app.js + env.example.js + vercel.json)
supabase/
  config.toml             Local project config (PG15)
  migrations/             SQL, applied in filename order (11 files — see "Migrations")
  functions/              Edge functions (sms-dispatch-worker) + _shared utils
  tests/verify.sql        Assertion harness (run after applying migrations)
project-status/index.html Engineering status dashboard (open in a browser)
governance/               Pre-populated DPIA + Hazard Log DRAFTS (Trust completes)
COMPLIANCE.md             Living NHS compliance checklist + DTAC v2 readiness  <- source of truth
DEPLOYMENT.md             Execution runbook: stand up + verify the live system
SECURITY.md               Secure-SDLC self-declaration (DSIT/NCSC)
SECURITY-INCIDENT.md      Breach-response runbook (72h ICO clock + NHS routes)
ACCESSIBILITY.md          Draft accessibility statement (WCAG 2.2 AA)
MASTER.md                 Auto-generated single-file bundle of all tracked text
.claude/                  Claude Code project config (TRAVELS with the repo):
  hooks/compliance_backcheck.py   NHS back-check hook + auto change-ledger
  settings.local.json             Hook wiring + permission allow-list
  launch.json                     Preview servers (frontend:5500, status:5600, portal:5700, staff:5800)
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
python -m http.server 5500 --directory frontend        # patient SMS app -> http://localhost:5500
python -m http.server 5700 --directory portal          # Patient Hub     -> http://localhost:5700
python -m http.server 5800 --directory staff           # Staff Console   -> http://localhost:5800
python -m http.server 5600 --directory project-status  # status board    -> http://localhost:5600
```
The authenticated surfaces run in a safe **dev-mock** mode with no backend; append
`?demo=1` to jump straight to the signed-in view (portal dashboard / staff console).

## The NHS compliance hook
On every `Write`/`Edit`/`MultiEdit`, `.claude/hooks/compliance_backcheck.py` runs. When the
edited file is under `frontend/` or `supabase/`, it surfaces the `COMPLIANCE.md` change-review
ritual (does this touch a clinical hazard? PII? update the status markers?). It's a silent
no-op for other files. **Requires `python` on PATH.**

## Migrations (11, apply in filename order)
The base schema **is now in the repo** (`20260527000000_base_schema.sql`) and runs first.
`DEPLOYMENT.md` is the authoritative, annotated apply order; in short:
`base_schema` → `pending_cancellation` (status prereq) → `section_11_tokens_rpc` →
`retention_and_erasure` → `nhs_number_modulus11` → `issue_validation_token` →
`patient_portal_rls` → `link_patient_identity` → `clinical_review_workflow` →
`audit_hash_chain` → `proxy_access_scaffold`.

Apply with `supabase db push` once a **London (`eu-west-2`)** project exists, then run
`supabase/tests/verify.sql` to assert the safety-critical logic. **All backend SQL is
currently code-reviewed, not executed** — see `DEPLOYMENT.md`.

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
