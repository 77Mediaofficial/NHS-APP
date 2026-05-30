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

    try:
        commit = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"], cwd=ROOT,
            capture_output=True, text=True, check=True
        ).stdout.strip()
    except Exception:
        commit = "(unknown)"

    parts = [
        "# NHS Waitlist Validation — MASTER bundle\n",
        "> **AUTO-GENERATED — do not edit by hand.** Single-file snapshot of every\n"
        "> git-tracked text file, for easy review / handover. Regenerate with\n"
        "> `python tools/build_master.py`. The individual files remain the source of\n"
        f"> truth; this is a convenience copy. Generated from commit `{commit}`.\n"
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
