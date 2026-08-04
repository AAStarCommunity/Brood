#!/usr/bin/env bash
# check-docs.sh — gate: is the planning layer complete enough to run UNATTENDED?
#
#   bash scripts/check-docs.sh [--docs-dir docs/agent] [--strict|--minimal]
#
# Unattended delivery means nobody is around to answer "what did you mean here?".
# Every gap in the planning layer becomes a guess the model makes alone at 3am, so this
# gate is FAIL-CLOSED: missing or placeholder-only docs stop `run` before it writes code.
#
#   --strict  (default) ALL 7 docs must exist and be filled in. Use for unattended runs.
#   --minimal roadmap + tasks + progress only — the bare minimum `run` needs to act at all.
#             Use when a human is watching and can answer questions.
#
# A doc counts as MISSING when absent, and as EMPTY when it still looks like the raw
# template: under MIN_BYTES of content, or every remaining line is a heading/placeholder
# (`<...>` angle-bracket slots the templates ship with). Shipping a template with the
# slots unfilled is worse than no doc — it reads as answered when it isn't.
#
# Exit: 0 = ready, 1 = gaps found (list printed), 2 = usage error.
set -uo pipefail

docs_dir="docs/agent"
mode="strict"
# ~120 bytes ≈ 40 Chinese chars ≈ two real sentences.
#
# Measured scores of the SHIPPED pristine templates (scaffolding text that carries no `<...>`
# slot still counts): research=42 acceptance=73 architecture=0 spec=26 roadmap=0 tasks=99
# progress=32. So 120 currently blocks all seven — but the margin on tasks.md is only 21 bytes.
# Raise this floor, don't lower it, and re-measure if the templates gain prose.
#
# Kept modest because progress.md is legitimately terse — too high a bar would block a run over
# a doc that IS answered.
MIN_BYTES="${PILOT_DOC_MIN_BYTES:-120}"

# Validate the knob BEFORE any comparison uses it. `[ x -lt abc ]` is a runtime ERROR, not a
# false comparison; under `set -uo pipefail` (no -e) an error inside an `elif` condition merely
# makes that branch false, so every doc would fall through to the `else` and be counted OK —
# the gate would report "ready" on seven blank templates. A gate that fails OPEN is worse than
# no gate, because it reports safety it did not verify. Verified: PILOT_DOC_MIN_BYTES=abc (or
# a typo like "120B") previously yielded ok=7/7 + exit 0 on a directory of untouched templates.
case "$MIN_BYTES" in
  ''|*[!0-9]*)
    echo "ERROR: PILOT_DOC_MIN_BYTES must be a non-negative integer, got: '$MIN_BYTES'" >&2
    exit 2 ;;
esac
# 0 would pass any file that merely exists — that is disabling the gate, not tuning it. If you
# genuinely want no gate, don't run this script; don't silently neuter it via an env var.
if [ "$MIN_BYTES" -eq 0 ]; then
  echo "ERROR: PILOT_DOC_MIN_BYTES=0 disables the gate (any existing file would pass). Refusing." >&2
  exit 2
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --docs-dir) [ $# -ge 2 ] || { echo "ERROR: --docs-dir needs a path" >&2; exit 2; }; docs_dir="$2"; shift 2 ;;
    --strict)  mode="strict";  shift ;;
    --minimal) mode="minimal"; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "ERROR: unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Ordered by the information flow in plan.md: research → acceptance → architecture+spec
# → roadmap → tasks → progress. Earlier docs constrain later ones, so report them in order.
STRICT_DOCS="research acceptance architecture spec roadmap tasks progress"
MINIMAL_DOCS="roadmap tasks progress"
[ "$mode" = "minimal" ] && DOCS="$MINIMAL_DOCS" || DOCS="$STRICT_DOCS"

# Real content = lines that are not blank / heading / blockquote / table-rule / hrule
# AND contain NO `<...>` placeholder anywhere on the line.
#
# The "anywhere on the line" part is the whole trick. The templates put their slots INLINE
# ("目标：<这个阶段要达成的业务价值>", "- **F1.1 <Feature名>** — <覆盖什么>"), so a filter
# that only drops whole-line `<...>` slots lets a pristine, 100%-unfilled template through
# as "ready" — the exact failure this gate exists to prevent. A line still carrying a slot
# is by definition unanswered, so it contributes nothing. Filling a doc means writing lines
# with no slots left, which is precisely what gets counted here.
real_content_bytes() {
  sed -e 's/^[[:space:]]*//' "$1" 2>/dev/null \
    | grep -vE '^$|^#|^>|^-{3,}$|^\|[[:space:]:|-]*\|?$' \
    | grep -vE '<[^>]*>' \
    | wc -c | tr -d ' '
}

missing=""; empty=""; ok=0
for d in $DOCS; do
  f="$docs_dir/$d.md"
  if [ ! -f "$f" ]; then
    missing="$missing $d"
    continue
  fi
  bytes="$(real_content_bytes "$f")"
  # Treat an unreadable measurement as EMPTY, never as OK. Same reasoning as the MIN_BYTES
  # validation above: if the count is not a plain integer the comparison would error, the
  # branch would read false, and the doc would be silently counted as filled in.
  case "$bytes" in ''|*[!0-9]*) empty="$empty $d"; continue ;; esac
  if [ "$bytes" -lt "$MIN_BYTES" ]; then
    empty="$empty $d"
  else
    ok=$((ok + 1))
  fi
done

total=$(echo $DOCS | wc -w | tr -d ' ')
# Echo the effective threshold on EVERY outcome, including success. PILOT_DOC_MIN_BYTES can
# weaken the gate from outside the repo; if the passing line never showed it, a loosened gate
# would leave no trace in the run's report.
echo "PILOT_DOCS: mode=$mode dir=$docs_dir min_bytes=$MIN_BYTES ok=$ok/$total"

if [ -z "$missing" ] && [ -z "$empty" ]; then
  echo "PILOT_DOCS: ready — planning layer complete, safe to run unattended."
  exit 0
fi

[ -n "$missing" ] && { echo "  MISSING (file absent):"; for d in $missing; do echo "    - $docs_dir/$d.md"; done; }
[ -n "$empty" ]   && { echo "  EMPTY (still the template / under ${MIN_BYTES}B of real content):"; for d in $empty; do echo "    - $docs_dir/$d.md"; done; }
echo "PILOT_DOCS: NOT ready — run \`pilot plan\` to fill these in before an unattended run."
echo "  (a human-supervised run can proceed with --minimal: roadmap + tasks + progress)"
exit 1
