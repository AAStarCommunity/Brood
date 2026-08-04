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
# ~120 bytes ≈ 40 Chinese chars ≈ two real sentences. A pristine template scores ~0 here
# (every line still carries a slot), so template-detection works at any threshold; this
# number only sets "how much substance counts as filled in". Kept modest because progress.md
# is legitimately terse — too high a bar would block a run over a doc that IS answered.
MIN_BYTES="${PILOT_DOC_MIN_BYTES:-120}"

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
  elif [ "$(real_content_bytes "$f")" -lt "$MIN_BYTES" ]; then
    empty="$empty $d"
  else
    ok=$((ok + 1))
  fi
done

total=$(echo $DOCS | wc -w | tr -d ' ')
echo "PILOT_DOCS: mode=$mode dir=$docs_dir ok=$ok/$total"

if [ -z "$missing" ] && [ -z "$empty" ]; then
  echo "PILOT_DOCS: ready — planning layer complete, safe to run unattended."
  exit 0
fi

[ -n "$missing" ] && { echo "  MISSING (file absent):"; for d in $missing; do echo "    - $docs_dir/$d.md"; done; }
[ -n "$empty" ]   && { echo "  EMPTY (still the template / under ${MIN_BYTES}B of real content):"; for d in $empty; do echo "    - $docs_dir/$d.md"; done; }
echo "PILOT_DOCS: NOT ready — run \`pilot plan\` to fill these in before an unattended run."
echo "  (a human-supervised run can proceed with --minimal: roadmap + tasks + progress)"
exit 1
