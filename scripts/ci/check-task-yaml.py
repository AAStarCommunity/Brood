#!/usr/bin/env python3
"""Fail the build if any backlog markdown has unparseable YAML frontmatter.

Why this exists: the backlog exporter does not error on bad frontmatter — it emits a record with
blank id/title that still carries the full raw markdown, and that empty record ships into the
public search index in dist/. The trigger is mundane and easy to repeat: an unquoted ':' inside a
title scalar, e.g.

    title: Fix /sync-progress fabrication: gh-api 200-OK validation   # ScannerError
    title: "Fix /sync-progress fabrication: gh-api 200-OK validation" # fine

One batch of hand-written tasks broke 10 files this way and nothing downstream noticed.

Exit 0 = every file parses; 1 = at least one does not (each is printed with the parser's own
message, so the fix is obvious from CI output alone).
"""
import pathlib
import re
import sys

import yaml

# Every directory the exporter reads records from. Tasks are the ones that have bitten us, but a
# malformed doc or decision would corrupt its endpoint the same way.
# backlog/milestones is exported to /api/milestones.json just like the others, so malformed
# frontmatter there ships unchecked — the exact incident class this gate exists to prevent.
SCAN_DIRS = ["backlog/tasks", "backlog/docs", "backlog/decisions", "backlog/archive",
             "backlog/milestones", "backlog/completed"]
FRONTMATTER = re.compile(r"^---\n(.*?)\n---", re.S)

def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[2]
    checked, bad = 0, []

    for rel in SCAN_DIRS:
        d = root / rel
        if not d.is_dir():
            continue
        for f in sorted(d.rglob("*.md")):
            text = f.read_text(encoding="utf-8")
            m = FRONTMATTER.match(text)
            if not m:
                # No frontmatter at all is legitimate for prose docs — only *malformed*
                # frontmatter corrupts the export, so don't fail on its absence.
                continue
            checked += 1
            try:
                yaml.safe_load(m.group(1))
            except yaml.YAMLError as e:
                first = str(e).splitlines()[0] if str(e) else e.__class__.__name__
                bad.append((f.relative_to(root), first))

    print(f"Checked frontmatter in {checked} file(s).")
    if not bad:
        print("All frontmatter parses as valid YAML.")
        return 0

    print(f"\n{len(bad)} file(s) with invalid YAML frontmatter:", file=sys.stderr)
    for path, err in bad:
        print(f"  {path}\n      {err}", file=sys.stderr)
    print(
        "\nMost common cause: an unquoted ':' inside a value. Wrap the value in double quotes,\n"
        'e.g.  title: "Fix X: do Y"',
        file=sys.stderr,
    )
    return 1

if __name__ == "__main__":
    sys.exit(main())
