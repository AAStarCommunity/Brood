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

GATE_ABS="$PWD/$GATE"
# --no-config on every fixture call: these assertions are about the gate's own logic, and this
# script runs from the repo root. Without it, a repo declaring `planning_source: external` would
# make every assertion below exit 0 while still printing "ok".
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

# 5. `planning_source:` — a DECLARATION, so the only things to assert are that each value routes
#    where it says, that an unrecognised value aborts rather than guessing, and that the external
#    path is unmistakably labelled as "not checked". There is no criterion here to subvert, which
#    is the entire point of it being a declaration; the previous design (a configurable path to
#    verify) needed nine assertions just for the ways a path can lie.
ps="$(mktemp -d)"; (cd "$ps" && git init -q .)
psrun() { printf '%s\n' "$1" > "$ps/.pilot.yml"; (cd "$ps" && bash "$GATE_ABS" --strict >/dev/null 2>&1); echo $?; }
check "planning_source: external → pass"    0 "$(psrun 'planning_source: external')"
check "planning_source: docs → checks docs" 1 "$(psrun 'planning_source: docs')"
check "planning_source: unknown → abort"    2 "$(psrun 'planning_source: backlog')"
check "no planning_source → checks docs"    1 "$(psrun 'base_branch: main')"
check "trailing comment tolerated"          0 "$(psrun 'planning_source: external   # 规划在 backlog/')"
check "quoted value tolerated"              0 "$(psrun 'planning_source: "external"')"
#    Malformed YAML must fall CLOSED, never open. The declaration removes the criterion but not the
#    sed that reads it, and that sed had the same fail-open shape as the validator it replaced:
#    each of these was read as `external` — i.e. gate off — and none is what it looks like.
#      no space  → to YAML this is a plain scalar string; there is no key at all
#      tab       → yaml.safe_load raises ScannerError (YAML does not accept a tab there)
#      ex"ter"nal→ the value really is ex"ter"nal and must be REFUSED, not mangled into external
check "no space after colon → checks docs"  1 "$(psrun 'planning_source:external')"
check "tab after colon → checks docs"       1 "$(printf 'planning_source:\texternal\n' > "$ps/.pilot.yml"; (cd "$ps" && bash "$GATE_ABS" --strict >/dev/null 2>&1); echo $?)"
check "inner quotes → abort, not guess"     2 "$(psrun 'planning_source: ex"ter"nal')"
#    The external path MUST say it checked nothing — a "ready" here would be a lie the run report
#    would then repeat.
#    Capture to a variable and match in bash — NOT `… | grep -q`. `grep -q` exits at the first
#    match while the gate still has 4 lines to print, so the gate takes SIGPIPE and exits 141;
#    `set -o pipefail` (line 12) promotes that to the pipeline's status and the `if` takes the
#    ELSE branch — the banner printed correctly and the assertion failed anyway. Measured on the
#    previous commit: 5 red out of 15 full runs, each claiming "the planning-docs gate is not
#    fail-closed" on a `docs-gate` job with no continue-on-error. This is the same SIGPIPE/pipefail
#    trap safe-cleanup.sh has a helper (`list_has`) to avoid; I wrote that helper and then walked
#    into it again here, in the same batch of PRs.
printf 'planning_source: external\n' > "$ps/.pilot.yml"
_psout="$(cd "$ps" && bash "$GATE_ABS" --strict 2>&1)"
case "$_psout" in
  *"NOTHING WAS CHECKED"*) echo "  ok   external run states it verified nothing" ;;
  *) echo "  FAIL external run does not say it verified nothing" >&2; fails=$((fails + 1)) ;;
esac
#    And --no-config must ignore the declaration, or every assertion above this line is vacuous.
check "--no-config ignores declaration" 1 \
  "$(cd "$ps" && bash "$GATE_ABS" --strict --no-config >/dev/null 2>&1; echo $?)"
rm -rf "$ps"

echo
if [ "$fails" -ne 0 ]; then
  echo "$fails assertion(s) failed — the planning-docs gate is not fail-closed." >&2
  exit 1
fi
echo "All assertions passed — the gate rejects bad input and blank templates, and accepts real docs."
