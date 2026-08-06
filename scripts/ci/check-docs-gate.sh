#!/usr/bin/env bash
# Assert that pilot's planning-docs gate really fails CLOSED.
#
# check-docs.sh is what an unattended `pilot run` consults before it starts writing code, opening
# PRs and merging. It shipped claiming FAIL-CLOSED while actually failing OPEN: `[ n -lt abc ]` is a
# runtime error, not a false comparison, and with no `set -e` that error inside an `elif` merely
# made the branch false — so every document fell through to the success path and seven untouched
# templates reported "ready, exit 0". A gate that reports safety it never verified is worse than no
# gate, so these cases are asserted mechanically rather than trusted to stay fixed.
#
# Exit 0 = all assertions hold.
set -uo pipefail

GATE="plugins/pilot/skills/pilot/scripts/check-docs.sh"
# Absolute form: assertion 5 must `cd` into a fixture (planning_requires entries are repo-relative
# by design), and a relative $GATE stops resolving the moment we leave the repo root.
GATE_ABS="$PWD/$GATE"
TEMPLATES="plugins/pilot/skills/pilot/templates"
fails=0

if [ ! -f "$GATE" ]; then
  echo "ERROR: gate script not found at $GATE" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# A directory of PRISTINE templates: files exist, but every slot is still a `<placeholder>`.
# This is the dangerous case — it looks populated to anything that only checks existence.
for d in research acceptance architecture spec roadmap tasks progress; do
  [ -f "$TEMPLATES/$d.md" ] && cp "$TEMPLATES/$d.md" "$tmp/$d.md"
done

check() {  # check <description> <expected_rc> <actual_rc>
  if [ "$2" = "$3" ]; then
    echo "  ok   $1 (rc=$3)"
  else
    echo "  FAIL $1 — expected rc=$2, got rc=$3" >&2
    fails=$((fails + 1))
  fi
}

# --no-config on EVERY call: these assertions are about the gate's own logic against a fixture
# directory, and this script runs from the repo root. Without it, the gate would read this repo's
# .pilot.yml, see `planning_requires:`, and check backlog/ instead of $tmp — every assertion below
# would keep printing "ok" while testing something else entirely. Assertion 7 pins that down.
run() { bash "$GATE" --no-config --docs-dir "$tmp" "$@" >/dev/null 2>&1; echo $?; }

echo "check-docs.sh fail-closed assertions:"

# 1. Untouched templates must NOT pass. This is the whole point of the gate.
check "pristine templates rejected (strict)"  1 "$(run --strict)"
check "pristine templates rejected (minimal)" 1 "$(run --minimal)"

# 2. A malformed threshold must ABORT, never silently widen the gate. Each of these previously
#    produced ok=7/7 + exit 0 on the very directory above.
check "non-numeric threshold rejected" 2 "$(PILOT_DOC_MIN_BYTES=abc  run --strict)"
check "typo'd threshold rejected"      2 "$(PILOT_DOC_MIN_BYTES=120B run --strict)"
# An EMPTY value is not an error: `${PILOT_DOC_MIN_BYTES:-120}` treats empty as unset, so the gate
# falls back to its default and keeps working normally. Assert that safe fallback (pristine
# templates still rejected, rc=1) rather than an abort — an unset-looking var must not break a run.
check "empty threshold falls back to default" 1 "$(PILOT_DOC_MIN_BYTES='' run --strict)"
# 0 would pass any file that merely exists — disabling the gate, not tuning it.
check "zero threshold rejected"        2 "$(PILOT_DOC_MIN_BYTES=0    run --strict)"

# 3. Missing files must be rejected too (the gate's other half).
empty="$(mktemp -d)"
check "empty docs dir rejected" 1 "$(bash "$GATE" --no-config --docs-dir "$empty" --strict >/dev/null 2>&1; echo $?)"
rm -rf "$empty"

# 4. The gate must still PASS on genuinely filled docs — otherwise it is just broken, and a gate
#    nobody can satisfy gets disabled by whoever hits it next.
filled="$(mktemp -d)"
for d in research acceptance architecture spec roadmap tasks progress; do
  {
    echo "# $d"
    echo
    echo "本文档已填写真实内容:目标明确、边界清晰、可照此执行,包含足够的实质描述以通过门禁检查。"
    echo "补充说明:这一段用于验证门禁在文档确实填写之后能够正常放行,而不是一律拒绝。"
  } > "$filled/$d.md"
done
check "filled docs accepted" 0 "$(bash "$GATE" --no-config --docs-dir "$filled" --strict >/dev/null 2>&1; echo $?)"

rm -rf "$filled"

# 5. An alternative planning source (`planning_requires:`) must be held to the SAME content bar.
#    It replaces WHICH paths are checked, never WHETHER they have to be real — a knob that let a
#    repo declare its way past the gate would be the fail-open this whole script exists to catch.
#    Run from inside the fixture (entries must be repo-relative), so the gate needs an ABS path.
alt="$(mktemp -d)"; mkdir -p "$alt/plan-src" "$alt/blank-src"
: > "$alt/blank-src/placeholder.md"
{
  echo "# 规划源"
  echo "本文件包含足够的实质内容,用于验证门禁在替代规划源下能够正常放行,而不是一律拒绝。"
  echo "第二段补充说明,确保真实内容超过最小字节阈值。"
} > "$alt/plan-src/tasks.md"
check "planning_requires: dir with real content accepted" 0 \
  "$(cd "$alt" && bash "$GATE_ABS" --planning-requires "plan-src" --strict >/dev/null 2>&1; echo $?)"
check "planning_requires: dir of blank files rejected" 1 \
  "$(cd "$alt" && bash "$GATE_ABS" --planning-requires "blank-src" --strict >/dev/null 2>&1; echo $?)"
check "planning_requires: absent path rejected" 1 \
  "$(cd "$alt" && bash "$GATE_ABS" --planning-requires "plan-src,nope" --strict >/dev/null 2>&1; echo $?)"
rm -rf "$alt"

# 6. The knob must not be usable to switch the gate OFF. Each of these would otherwise pass
#    unconditionally in any repo holding a single non-empty file.
check "planning_requires='.' refused"      2 "$(bash "$GATE" --planning-requires "." --strict >/dev/null 2>&1; echo $?)"
check "planning_requires='/' refused"      2 "$(bash "$GATE" --planning-requires "/" --strict >/dev/null 2>&1; echo $?)"
# The repo-root refusal must be by RESOLUTION, not by a table of spellings. A literal table let
# `.//`, `./.`, `././`, `.///` through — none is absolute, contains `..`, or globs — and the gate
# then reported "ready, safe to run unattended" on a repo with no planning documents at all.
# `.git` was the same trick with less typing: it exists in every git repo.
for spelling in ".//" "./." "././" ".///" ".//." ".git"; do
  check "planning_requires='$spelling' refused" 2 \
    "$(bash "$GATE" --planning-requires "$spelling" --strict >/dev/null 2>&1; echo $?)"
done
# NOT `.git/refs`, and NOT an unconditional `.GIT`. Both looked like stronger assertions and both
# were environment-dependent — the same class of defect they were asserting against:
#   * in a LINKED WORKTREE (`.git` is a file, which is pilot's own one-task-one-worktree shape)
#     `.git/refs` does not exist, so the entry is merely MISSING → rc=1 and the assertion goes red
#     without anything being wrong;
#   * `.GIT` only exists on a case-insensitive filesystem (macOS default), so asserting it
#     unconditionally would fail on a case-sensitive CI runner for the same non-reason.
# `.git` itself resolves correctly in both shapes. The case variant is asserted only where the
# filesystem actually makes it reachable.
if [ -e ".GIT" ]; then
  check "planning_requires='.GIT' refused (case-insensitive fs)" 2 \
    "$(bash "$GATE" --planning-requires ".GIT" --strict >/dev/null 2>&1; echo $?)"
fi
check "planning_requires absolute refused" 2 "$(bash "$GATE" --planning-requires "/etc" --strict >/dev/null 2>&1; echo $?)"
# A glob is refused rather than expanded: word-splitting an unquoted list ALSO globs, so `backlog/*`
# used to arrive pre-expanded as the paths it matched and the literal check never saw a `*`.
check "planning_requires glob refused"     2 "$(bash "$GATE" --planning-requires "backlog/*" --strict >/dev/null 2>&1; echo $?)"

# 7. --no-config must actually isolate the fixture from this repo's declaration. If someone drops
#    the flag from run() above, THIS is the assertion that goes red instead of the suite silently
#    testing backlog/ while claiming to test pristine templates.
check "--no-config ignores repo declaration" 1 "$(bash "$GATE" --no-config --docs-dir "$tmp" --strict >/dev/null 2>&1; echo $?)"

# 8. The .pilot.yml parser must read the form this skill's OWN docs use — YAML allows a trailing
#    `# comment` on the key line and on every item, and the first parser matched neither. It failed
#    SILENTLY: declaration dropped, gate falls back to the seven filenames, repo told "NOT ready" —
#    the exact false negative the feature exists to remove, delivered by the feature.
yml="$(mktemp -d)"; mkdir -p "$yml/plan-src"
(cd "$yml" && git init -q .)
{ echo "# 规划源"; echo "这是一份真实内容,用于验证解析器能读到本 skill 文档里那种带行尾注释的写法。"; echo "第二段确保超过阈值。"; } > "$yml/plan-src/tasks.md"

printf 'base_branch: main\nplanning_requires:           # 可选。规划已在别处时声明\n  - plan-src                 # 条目也可以带注释\n' > "$yml/.pilot.yml"
check "config: key+item comments parsed" 0 "$(cd "$yml" && bash "$GATE_ABS" --strict >/dev/null 2>&1; echo $?)"

printf 'planning_requires: [plan-src]   # 行内数组也允许注释\n' > "$yml/.pilot.yml"
check "config: inline array + comment parsed" 0 "$(cd "$yml" && bash "$GATE_ABS" --strict >/dev/null 2>&1; echo $?)"

#    Declared-but-unparseable must be LOUD. A silent fallback here is indistinguishable from the bug.
printf 'planning_requires:\n' > "$yml/.pilot.yml"
check "config: declared but empty aborts" 2 "$(cd "$yml" && bash "$GATE_ABS" --strict >/dev/null 2>&1; echo $?)"
printf 'planning_requires: []\n' > "$yml/.pilot.yml"
check "config: explicit empty list aborts" 2 "$(cd "$yml" && bash "$GATE_ABS" --strict >/dev/null 2>&1; echo $?)"

#    No key at all is NOT an error — it is the documented default (check the seven docs).
printf 'base_branch: main\n' > "$yml/.pilot.yml"
check "config: no key falls back to docs" 1 "$(cd "$yml" && bash "$GATE_ABS" --strict >/dev/null 2>&1; echo $?)"

# 9. Other VALID YAML spellings must parse, not abort. The "declared but unparseable" abort added
#    in the previous round only accepted indented block lists, so a zero-indent sequence (valid
#    YAML, and what several formatters emit) and the scalar form became a HARD STOP telling the
#    operator their working config was malformed — the mirror image of the bug being fixed.
printf 'planning_requires:\n- plan-src\n' > "$yml/.pilot.yml"
check "config: zero-indent block sequence parsed" 0 "$(cd "$yml" && bash "$GATE_ABS" --strict >/dev/null 2>&1; echo $?)"
printf 'planning_requires: plan-src\n' > "$yml/.pilot.yml"
check "config: scalar form parsed" 0 "$(cd "$yml" && bash "$GATE_ABS" --strict >/dev/null 2>&1; echo $?)"

# 10. One config must mean ONE thing regardless of the directory the gate runs from. Resolving
#     entries against the CWD (while the config is found from the toplevel) made `- .` refused at
#     the root but ACCEPTED from a subdirectory, and a valid entry rc=0 at the root but rc=1 below.
mkdir -p "$yml/sub"
cp "$yml/plan-src/tasks.md" "$yml/sub/filler.md"
printf 'planning_requires:\n  - plan-src\n' > "$yml/.pilot.yml"
check "config: valid entry, from repo root" 0 "$(cd "$yml"     && bash "$GATE_ABS" --strict >/dev/null 2>&1; echo $?)"
check "config: valid entry, from subdir"    0 "$(cd "$yml/sub" && bash "$GATE_ABS" --strict >/dev/null 2>&1; echo $?)"
printf 'planning_requires:\n  - .\n' > "$yml/.pilot.yml"
check "config: repo root refused, from root"   2 "$(cd "$yml"     && bash "$GATE_ABS" --strict >/dev/null 2>&1; echo $?)"
check "config: repo root refused, from subdir" 2 "$(cd "$yml/sub" && bash "$GATE_ABS" --strict >/dev/null 2>&1; echo $?)"

# 11. A symlinked FILE pointing out of the repo must be refused too. Only the parent directory used
#     to be resolved, so `planfile -> /etc/passwd` passed the containment check and the content test
#     then read straight through it. Directory symlinks were already caught — that half was fine.
ln -sf /etc/passwd "$yml/planfile"
check "config: symlinked file out of repo refused" 2 \
  "$(cd "$yml" && bash "$GATE_ABS" --planning-requires "planfile" --strict >/dev/null 2>&1; echo $?)"
ln -sfn /etc "$yml/outlink"
check "config: symlinked dir out of repo refused" 2 \
  "$(cd "$yml" && bash "$GATE_ABS" --planning-requires "outlink" --strict >/dev/null 2>&1; echo $?)"
rm -rf "$yml"
rm -rf "$filled"

echo
if [ "$fails" -ne 0 ]; then
  echo "$fails assertion(s) failed — the planning-docs gate is not fail-closed." >&2
  exit 1
fi
echo "All assertions passed — the gate rejects bad input and blank templates, and accepts real docs."
