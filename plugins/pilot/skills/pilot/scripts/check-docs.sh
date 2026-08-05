#!/usr/bin/env bash
# check-docs.sh — gate: is the planning layer complete enough to run UNATTENDED?
#
#   bash scripts/check-docs.sh [--docs-dir docs/agent] [--strict|--minimal]
#                              [--planning-requires <path[,path...]>] [--no-config]
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
# TWO SHAPES OF PLANNING LAYER
#   Default: the seven `docs_dir/*.md` files `pilot plan` produces.
#   Alternative: a repo that already plans in backlog.md / an issue tracker / anything else
#   declares `planning_requires:` in `.pilot.yml` (or passes --planning-requires), and THOSE
#   paths are checked instead (`--no-config` ignores the declaration and checks the seven docs
#   regardless — for testing the gate itself). Rationale: the fixed seven filenames made the gate unable to
#   see an equivalent — often richer — planning source, so `run` fail-closed on repos that
#   were in fact ready, while plan.md §A.3 simultaneously says "already planned → do not
#   re-create". Both rules could not be obeyed at once. A path is checked with the SAME
#   content test as a doc; a directory passes when at least one file under it passes.
#
# Exit: 0 = ready, 1 = gaps found (list printed), 2 = usage error.
# ---8<--- end of help
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

planning_requires=""
planning_src="flag"
read_config=1

while [ $# -gt 0 ]; do
  case "$1" in
    --docs-dir) [ $# -ge 2 ] || { echo "ERROR: --docs-dir needs a path" >&2; exit 2; }; docs_dir="$2"; shift 2 ;;
    --planning-requires)
      [ $# -ge 2 ] || { echo "ERROR: --planning-requires needs a comma-separated path list" >&2; exit 2; }
      planning_requires="$2"; shift 2 ;;
    # Test/inspection escape hatch: check ONLY the seven docs under --docs-dir, ignoring whatever
    # the repo declares. Needed because reading .pilot.yml would otherwise silently hijack a
    # deliberate `--docs-dir <fixture>` — scripts/ci/check-docs-gate.sh runs exactly that shape from
    # the repo root, and without this flag every one of its assertions would quietly stop testing
    # what it says it tests the moment this repo declared planning_requires.
    --no-config) read_config=0; shift ;;
    --strict)  mode="strict";  shift ;;
    --minimal) mode="minimal"; shift ;;
    # Print to the sentinel below rather than a hardcoded line range: a range drifts the moment
    # anyone adds a line to the header, and it drifts SILENTLY (measured on git-guard.sh: a 4-line
    # overrun printed `set -euo pipefail` as if it were help text).
    -h|--help) sed -n '2,/^# ---8<--- end of help/p' "$0" | grep -v '^# ---8<---'; exit 0 ;;
    *) echo "ERROR: unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Read `planning_requires:` from .pilot.yml when the caller did not pass it.
#
# Same reasoning as git-guard.sh's self-contained protection list: run.md executes as separate
# Bash calls that share no variables, so a caller-threaded flag silently vanishes between steps.
# Here the stakes are the mirror image of git-guard's — forgetting the flag makes this gate MORE
# strict (it falls back to the seven filenames and refuses to run), which is safe but is exactly
# the false "NOT ready" this feature exists to remove. So read the config directly; the flag stays
# available as an override.
#
# Accepts both YAML shapes:  planning_requires: [a, b]   and a block list of `- a` lines.
if [ -z "$planning_requires" ] && [ "$read_config" = "1" ]; then
  _top="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
  for _f in "$_top/.pilot.yml" "$_top/.repo-pilot.yml"; do
    [ -f "$_f" ] || continue
    # YAML permits a trailing `# comment` on the key line AND on every item. The first version of
    # this parser matched `^planning_requires:[[:space:]]*$`, so the form documented in this very
    # skill — `planning_requires:   # 可选…` — never matched: `inlist` stayed 0, the declaration was
    # dropped SILENTLY, and the gate fell back to the seven filenames. That is precisely the false
    # "NOT ready" this feature exists to remove, arriving through the feature itself. Item comments
    # were worse: the shipped template's `- docs/agent/progress.md   # 运行态…` became the literal
    # path `docs/agent/progress.md#运行态…` once whitespace was stripped.
    # Strip only WHITESPACE-PRECEDED `#`, which is what YAML calls a comment, so a path that
    # legitimately contains `#` survives.
    planning_requires="$(awk '
      function clean(s) {
        sub(/[[:space:]]+#.*$/, "", s)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
        return s
      }
      { line = $0; sub(/[[:space:]]+#.*$/, "", line) }
      line ~ /^planning_requires:[[:space:]]*\[/ {
        v = line; sub(/^[^[]*\[/, "", v); sub(/\].*$/, "", v)
        n = split(v, a, ",")
        for (i = 1; i <= n; i++) { t = clean(a[i]); if (t != "") printf "%s,", t }
        exit
      }
      line ~ /^planning_requires:[[:space:]]*$/ { inlist = 1; next }
      inlist {
        # A block list ends at the first line that is not an indented `- item`.
        if (line ~ /^[[:space:]]+-[[:space:]]*[^[:space:]]/) {
          item = line; sub(/^[[:space:]]*-[[:space:]]*/, "", item)
          t = clean(item); if (t != "") printf "%s,", t
          next
        }
        if (line ~ /^[[:space:]]*$/) next
        exit
      }
    ' "$_f" | tr -d "\"'" | sed 's/,$//')"
    if [ -n "$planning_requires" ]; then
      planning_src="$(basename "$_f")"
    elif grep -qE '^planning_requires:' "$_f" 2>/dev/null; then
      # The key is THERE but nothing parsed out of it. Never fall back silently: a quiet fallback
      # reports "NOT ready, go write the seven docs" to a repo that did declare its planning source,
      # which is indistinguishable from the bug this feature fixes. Fail loudly instead.
      echo "ERROR: $_f declares 'planning_requires:' but no usable entries parsed out of it." >&2
      echo "  Expected either  planning_requires: [a, b]  or an indented block list of '- path' lines." >&2
      echo "  Refusing to silently fall back to the default docs — that would report NOT ready for a repo that DID declare a source." >&2
      exit 2
    fi
    break
  done
fi

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

# Does this path hold real content? A file must pass real_content_bytes itself; a directory
# passes when at least ONE file under it does. Directories are the normal case for the
# alternative source (`backlog/tasks/` holds one file per task), and requiring every file to
# pass would fail on the tracker's own scaffolding (empty archive dirs, drafts).
path_has_content() {
  local p="$1" f b
  if [ -f "$p" ]; then
    b="$(real_content_bytes "$p")"
    case "$b" in ''|*[!0-9]*) return 1 ;; esac
    [ "$b" -ge "$MIN_BYTES" ] && return 0
    return 1
  fi
  if [ -d "$p" ]; then
    # -print -quit stops at the first hit, so a huge tracker directory costs one file read.
    while IFS= read -r f; do
      b="$(real_content_bytes "$f")"
      case "$b" in ''|*[!0-9]*) continue ;; esac
      [ "$b" -ge "$MIN_BYTES" ] && return 0
    done <<EOF
$(find "$p" -type f 2>/dev/null | head -200)
EOF
    return 1
  fi
  return 1
}

missing=""; empty=""; ok=0

if [ -n "$planning_requires" ]; then
  # ---- alternative planning source -----------------------------------------------------------
  # This replaces the seven filenames; it does not relax the content test. Each declared path is
  # held to the same MIN_BYTES / no-unfilled-`<...>`-slots bar a doc is.
  #
  # Refuse paths that would make the gate meaningless by matching the whole repo. `planning_requires: [.]`
  # passes trivially in ANY repo with one non-empty file, which is not "configured", it is "off" —
  # same reasoning as refusing PILOT_DOC_MIN_BYTES=0 above. The knob is for pointing at a real
  # planning source, not for opting out of the gate.
  # `set -f` is load-bearing, not tidiness. Word-splitting an unquoted $planning_requires ALSO
  # glob-expands it, and that happens BEFORE the loop body — so a `backlog/*` entry silently
  # became the nine paths it matched and the glob check below never saw a `*` at all (measured:
  # ok=7/9 from a single declared entry). With globbing off, the entry arrives literal and the
  # check can refuse it. Restored right after the split.
  set -f
  OLDIFS="$IFS"; IFS=','
  for p in $planning_requires; do
    IFS="$OLDIFS"
    # Trim whitespace only. Trailing-slash removal comes AFTER the checks below — stripping first
    # turned a bare "/" into "" and it fell out of the loop as "empty list", reporting the wrong
    # reason for a refusal that should name what was actually passed.
    p="$(printf '%s' "$p" | sed -e 's|^[[:space:]]*||' -e 's|[[:space:]]*$||')"
    [ -z "$p" ] && continue
    case "$p" in
      /*|*..*)
        echo "ERROR: planning_requires entry '$p' must be a repo-relative path without '..' — refusing." >&2
        exit 2 ;;
      # A glob would be expanded by whoever wrote it (or not at all, becoming a literal path that
      # is simply MISSING) — either way the gate would be checking something other than what the
      # config appears to say. Require literal paths so the declaration means one fixed thing.
      *'*'*|*'?'*|*'['*)
        echo "ERROR: planning_requires entry '$p' contains a glob — pass literal paths so the declaration checks exactly what it says." >&2
        exit 2 ;;
    esac
    p="${p%/}"
    # RESOLVE, then compare — do not try to enumerate the ways to spell ".". The first version
    # matched a literal table (`. ./ .. ../ / ~`) and `.//`, `./.`, `././`, `.///` sailed straight
    # through it: not absolute, no `..`, no glob. `${p%/}` then normalised them and the whole repo
    # became the "planning source" — measured on a repo with NO planning docs at all:
    #   (unconfigured)            → rc=1  ok=0/7  NOT ready
    #   planning_requires: [.//]  → rc=0  ok=1/1  "ready — safe to run unattended"
    # `.git` did the same in any git repo whatsoever. One resolve-and-compare closes that entire
    # family (including symlinks, which is why -P) instead of waiting for the next spelling.
    _abs=""
    if [ -d "$p" ]; then _abs="$(cd "$p" 2>/dev/null && pwd -P || true)"
    elif [ -e "$p" ]; then _abs="$(cd "$(dirname "$p")" 2>/dev/null && pwd -P || true)/$(basename "$p")"
    fi
    if [ -n "$_abs" ]; then
      _root="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"
      _rootp="$(cd "$_root" 2>/dev/null && pwd -P || printf '%s' "$_root")"
      if [ "$_abs" = "$_rootp" ]; then
        echo "ERROR: planning_requires entry '$p' resolves to the repository root ($_abs) — that disables the gate rather than configuring it. Point it at the actual planning source (e.g. backlog/tasks)." >&2
        exit 2
      fi
      case "$_abs" in
        "$_rootp"/.git|"$_rootp"/.git/*)
          echo "ERROR: planning_requires entry '$p' points inside .git — it would pass in ANY git repo and proves nothing about planning. Refusing." >&2
          exit 2 ;;
        "$_rootp"/*) : ;;   # inside the repo, as required
        *)
          echo "ERROR: planning_requires entry '$p' resolves outside the repository ($_abs) — refusing." >&2
          exit 2 ;;
      esac
    fi
    REQ_LIST="${REQ_LIST:-} $p"
    IFS=','
  done
  IFS="$OLDIFS"
  set +f
  [ -n "${REQ_LIST:-}" ] || { echo "ERROR: planning_requires is set but resolved to an empty list — refusing (an empty list would pass unconditionally)." >&2; exit 2; }

  for p in $REQ_LIST; do
    if [ ! -e "$p" ]; then
      missing="$missing $p"
    elif path_has_content "$p"; then
      ok=$((ok + 1))
    else
      empty="$empty $p"
    fi
  done
  total=$(echo $REQ_LIST | wc -w | tr -d ' ')
  echo "PILOT_DOCS: mode=$mode source=planning_requires($planning_src) min_bytes=$MIN_BYTES ok=$ok/$total"
  echo "  declared planning source:$REQ_LIST"
else
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
fi

if [ -z "$missing" ] && [ -z "$empty" ]; then
  echo "PILOT_DOCS: ready — planning layer complete, safe to run unattended."
  exit 0
fi

# In planning_requires mode the entries ARE paths already — prefixing them with $docs_dir would
# print a path that does not exist and send whoever reads it to the wrong place.
if [ -n "$planning_requires" ]; then
  [ -n "$missing" ] && { echo "  MISSING (path absent):"; for d in $missing; do echo "    - $d"; done; }
  [ -n "$empty" ]   && { echo "  EMPTY (no file with ${MIN_BYTES}B+ of real content under it):"; for d in $empty; do echo "    - $d"; done; }
  echo "PILOT_DOCS: NOT ready — the planning source declared in .pilot.yml is incomplete."
  echo "  Fix the source itself, or correct \`planning_requires:\` if it points at the wrong paths."
  echo "  (do NOT switch back to the seven docs just to get past this — that re-creates planning that already exists elsewhere; see plan.md §A.3)"
  exit 1
fi

[ -n "$missing" ] && { echo "  MISSING (file absent):"; for d in $missing; do echo "    - $docs_dir/$d.md"; done; }
[ -n "$empty" ]   && { echo "  EMPTY (still the template / under ${MIN_BYTES}B of real content):"; for d in $empty; do echo "    - $docs_dir/$d.md"; done; }
echo "PILOT_DOCS: NOT ready — run \`pilot plan\` to fill these in before an unattended run."
echo "  (a human-supervised run can proceed with --minimal: roadmap + tasks + progress)"
echo "  (already plan in backlog.md / an issue tracker? declare \`planning_requires:\` in .pilot.yml so this gate checks THAT instead — see the header of this script)"
exit 1
