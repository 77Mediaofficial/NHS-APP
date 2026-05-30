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
