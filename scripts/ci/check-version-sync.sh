#!/usr/bin/env bash
# check-version-sync.sh — the pilot skill's version is written in TWO places. Assert they agree.
#
#   plugins/pilot/.claude-plugin/plugin.json   "version": "1.3.0"    ← what an installer sees
#   plugins/pilot/skills/pilot/SKILL.md        version: 1.3.0        ← what the loaded skill says
#
# WHY this exists: they had already drifted (plugin.json 1.2.0 vs SKILL.md 1.1.0) and nobody
# noticed until a reviewer read both files in the same sitting. Neither number is load-bearing
# on its own, which is exactly why drift goes unseen — and an installed copy that reports a
# version it isn't makes every "which version has the fix?" question unanswerable.
#
# This is the same failure shape this repo keeps hitting: one fact written twice, then diverging.
# The fix is not vigilance, it is a check.
#
# SCOPE: exactly these two files declare the pilot version, and nothing else does — verified by
# grep at the time of writing (README.md carries no version string; the `1.1.1`-looking token in
# it is a Task ID). If a third place ever starts declaring it, add it here — this guard does not
# discover declarations, it compares the two it is told about.
#
# Exit: 0 = in sync, 1 = drift or unreadable.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
plugin_json="$root/plugins/pilot/.claude-plugin/plugin.json"
skill_md="$root/plugins/pilot/skills/pilot/SKILL.md"

fail() { echo "check-version-sync: $*" >&2; exit 1; }

[ -f "$plugin_json" ] || fail "missing $plugin_json"
[ -f "$skill_md" ]    || fail "missing $skill_md"

# Parse the JSON as JSON — a grep would also match a "version" key nested somewhere else.
pv="$(python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    print(json.load(f).get("version") or "")
' "$plugin_json")"

# SKILL.md frontmatter only: stop at the closing --- so a later line mentioning "version:" in
# prose cannot be picked up instead.
sv="$(python3 -c '
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
m = re.match(r"^---\n(.*?)\n---", text, re.S)
if m:
    v = re.search(r"^version:\s*(\S+)\s*$", m.group(1), re.M)
    print(v.group(1) if v else "")
else:
    print("")
' "$skill_md")"

[ -n "$pv" ] || fail "no \"version\" in plugins/pilot/.claude-plugin/plugin.json"
[ -n "$sv" ] || fail "no 'version:' in the SKILL.md frontmatter"

if [ "$pv" != "$sv" ]; then
  fail "version drift — plugin.json says '$pv', SKILL.md says '$sv'.
  Bump BOTH, or an installed copy will report a version it isn't."
fi

echo "check-version-sync: ok — pilot version $pv in both files"
