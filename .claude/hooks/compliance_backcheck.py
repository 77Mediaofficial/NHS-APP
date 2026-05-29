#!/usr/bin/env python3
"""
NHS compliance back-check hook (PostToolUse).

Fires after Write/Edit/MultiEdit. If the edited file lives under frontend/ or
supabase/, it injects a reminder (additionalContext) that the change MUST be
back-checked against COMPLIANCE.md before being considered done.

This exists because the user mandated: "BACK CHECK AGAINST THEIR REQUIREMENTS
CONSTANTLY WITHOUT FAIL." A standing model preference cannot reliably enforce
that across sessions; a deterministic hook can.

Contract: read hook JSON on stdin; emit a JSON object on stdout with
hookSpecificOutput.additionalContext when in scope; otherwise emit nothing.
Always exit 0 so a parsing hiccup never blocks the edit.
"""
import sys
import json
import re

MESSAGE = (
    "NHS COMPLIANCE BACK-CHECK REQUIRED. You just edited a file under frontend/ "
    "or supabase/. Before considering this change done, run the COMPLIANCE.md "
    "change-review ritual (project root):\n"
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
    "  6. Update the status markers in COMPLIANCE.md in the SAME change.\n"
    "Do not describe the system as 'compliant' - only 'built to align with "
    "[standard], pending [DPO/Caldicott/CSO] sign-off'."
)


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw) if raw.strip() else {}
    except (ValueError, TypeError):
        return  # never block on bad input

    tool_input = data.get("tool_input") or {}
    # Write/Edit use file_path; be defensive about alternatives.
    path = (
        tool_input.get("file_path")
        or tool_input.get("filePath")
        or tool_input.get("path")
        or ""
    )
    path = str(path).replace("\\", "/")

    # Match a frontend/ or supabase/ path segment (case-insensitive, Windows-safe).
    if re.search(r"(^|/)(frontend|supabase)(/|$)", path, re.IGNORECASE):
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
