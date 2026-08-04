#!/usr/bin/env bash
# grade-change.sh — compute the self-review risk grade MECHANICALLY from what changed.
#
#   grade-change.sh [--base <branch>] [--quiet]
#
# The grade decides how much adversarial review a change needs before it may become a PR
# (see reference/pre-pr-review.md). It must NOT be a self-declaration: a model that is about to
# skip review is exactly the one that will grade its own change as "just docs". Real case in this
# repo — a PR touching .github/workflows plus two CI-executed scripts was self-declared grade D;
# the reviewer escalated it to A and found 6 real defects, two of them capable of wiping the live
# site. So the grade is derived from paths and diff size, which the author cannot argue with.
#
# Grades (highest match wins — a single A-class path makes the whole change A):
#   A  money/assets · security/secrets · data deletion/migration · ANY file consumed by automation
#      (CI workflows, guard/gate scripts, build & deploy scripts, hooks, dependency manifests)
#   B  >100 net changed lines, or ≥3 top-level areas touched
#   C  contains executable code but is neither A nor B
#   D  documentation only — .md / .txt and nothing else
#
# Output (stdout, stable and parseable):
#   GRADE=<A|B|C|D>
#   REASON=<why>
#   ROUNDS=<required adversarial rounds>
#   FILES=<n> LINES=<n>
# Exit: 0 always (unless usage error 2) — this reports, it does not block. git-guard enforces.
set -uo pipefail

base=""
quiet=0
while [ $# -gt 0 ]; do
  case "$1" in
    --base) [ $# -ge 2 ] || { echo "ERROR: --base needs a branch" >&2; exit 2; }; base="$2"; shift 2 ;;
    --quiet) quiet=1; shift ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "ERROR: unknown arg: $1" >&2; exit 2 ;;
  esac
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "ERROR: not a git repo" >&2; exit 2; }

# Pick a base to diff against: explicit flag, then .pilot.yml's integration/base branch, then main.
if [ -z "$base" ]; then
  for cfg in .pilot.yml .repo-pilot.yml; do
    [ -f "$cfg" ] || continue
    b="$(sed -n 's/^integration_branch:[[:space:]]*//p' "$cfg" | head -1 | tr -d '"'"'"' ')"
    [ -z "$b" ] && b="$(sed -n 's/^base_branch:[[:space:]]*//p' "$cfg" | head -1 | tr -d '"'"'"' ')"
    [ -n "$b" ] && { base="$b"; break; }
  done
fi
[ -z "$base" ] && base="main"
git show-ref --verify --quiet "refs/heads/$base" || base="origin/$base"

# Changed files vs the merge-base, plus anything staged/unstaged — a change is a change whether or
# not it has been committed yet; grading only committed work would let an author dodge by waiting.
mb="$(git merge-base HEAD "$base" 2>/dev/null || echo "")"
{
  [ -n "$mb" ] && git diff --name-only "$mb"...HEAD 2>/dev/null
  git diff --name-only HEAD 2>/dev/null
  git diff --name-only --cached 2>/dev/null
  # UNTRACKED files must be included. `git diff` in all its forms only reports files git already
  # tracks, so a brand-new .github/workflows/*.yml — the highest-risk thing someone can add — was
  # invisible and the change graded D. Verified by reverse test: eight distinct A-class files, each
  # created fresh, all graded "documentation only". A grader blind to new files fails OPEN on
  # exactly the case it exists to catch.
  git ls-files --others --exclude-standard 2>/dev/null
} | awk 'NF' | sort -u > /tmp/pilot-graded-files.$$
files="/tmp/pilot-graded-files.$$"
trap 'rm -f "$files"' EXIT

# `grep -c` exits 1 on zero matches, so `$(grep -c . f || echo 0)` yields the string "0\n0" — which
# is not equal to "0", so the empty-change branch never fired and execution fell through to the
# doc-only check. Count with wc instead, which always exits 0.
n_files=$(wc -l < "$files" | tr -d ' ')
if [ "$n_files" = "0" ]; then
  echo "GRADE=D"; echo "REASON=no changes detected vs $base"; echo "ROUNDS=0"
  echo "FILES=0 LINES=0"
  exit 0
fi

# Net changed lines, excluding generated output and lockfiles — those inflate the count without
# adding review surface. (Lockfiles still count for grade A below, via the manifest rule.)
lines=$( { [ -n "$mb" ] && git diff --numstat "$mb"...HEAD -- . ':(exclude)dist' ':(exclude)*.lock' ':(exclude)*-lock.json' ':(exclude)pnpm-lock.yaml' 2>/dev/null; \
           git diff --numstat HEAD -- . ':(exclude)dist' ':(exclude)*.lock' ':(exclude)*-lock.json' ':(exclude)pnpm-lock.yaml' 2>/dev/null; } \
         | awk '{a+=$1; d+=$2} END {print (a+d)+0}' )

# --- A: automation-consumed or high-stakes paths -------------------------------------------------
# "Automation-consumed" is the criterion that keeps being underestimated: these files are not run by
# a human who would notice them misbehaving. When they break they break SILENTLY, taking the whole
# pipeline's credibility with them — a guard that is wrong is worse than one that is absent.
a_hit=""
while IFS= read -r f; do
  case "$f" in
    .github/workflows/*|.github/actions/*) a_hit="$f (CI workflow)"; break ;;
    scripts/ci/*|*/scripts/ci/*)           a_hit="$f (CI script)"; break ;;
    *git-guard.sh|*safe-cleanup.sh|*check-docs.sh|*check-hooks.sh|*grade-change.sh|*preflight.sh)
                                           a_hit="$f (enforcement/guard script)"; break ;;
    *export-backlog.js|*deploy*.sh|*deploy*.yml|Dockerfile|*/Dockerfile)
                                           a_hit="$f (build/deploy script)"; break ;;
    .githooks/*|.git/hooks/*|*/hooks/pre-commit|*/hooks/pre-push)
                                           a_hit="$f (git hook)"; break ;;
    package.json|*/package.json|pnpm-lock.yaml|package-lock.json|yarn.lock|Cargo.toml|go.mod|requirements*.txt|pyproject.toml)
                                           a_hit="$f (dependency manifest)"; break ;;
    *.env|*.env.*|*secret*|*credential*|*keystore*|*.pem|*.key)
                                           a_hit="$f (secret material)"; break ;;
    *contracts/*|*Paymaster*|*payment*|*billing*|*gas*|*wallet*)
                                           a_hit="$f (money/assets)"; break ;;
    *auth*|*Auth*|*permission*|*signature*|*crypto*|*Crypto*)
                                           a_hit="$f (security surface)"; break ;;
    *migration*|*migrations/*)             a_hit="$f (data migration)"; break ;;
  esac
done < "$files"

if [ -n "$a_hit" ]; then
  echo "GRADE=A"; echo "REASON=touches $a_hit"; echo "ROUNDS=3"
  echo "FILES=$n_files LINES=$lines"
  [ "$quiet" = "1" ] || echo "# A-grade: adversarial review x3, each round a different lens." >&2
  exit 0
fi

# --- D: documentation only -----------------------------------------------------------------------
# Deliberately strict: .yml/.json/.sh are NOT documentation even when they read like config, because
# something executes them. Only prose qualifies.
non_doc=$(grep -vE '\.(md|txt|rst)$' "$files" | head -1)
if [ -z "$non_doc" ]; then
  echo "GRADE=D"; echo "REASON=documentation only (.md/.txt/.rst)"; echo "ROUNDS=1"
  echo "FILES=$n_files LINES=$lines"
  exit 0
fi

# --- B: large or broad ---------------------------------------------------------------------------
areas=$(sed 's#/.*##' "$files" | sort -u | grep -c . || echo 0)
if [ "$lines" -gt 100 ] || [ "$areas" -ge 3 ]; then
  echo "GRADE=B"
  if [ "$lines" -gt 100 ]; then echo "REASON=$lines net changed lines (>100)"
  else echo "REASON=spans $areas top-level areas (>=3)"; fi
  echo "ROUNDS=3"
  echo "FILES=$n_files LINES=$lines"
  exit 0
fi

echo "GRADE=C"; echo "REASON=executable changes, below B thresholds ($lines lines, $areas areas)"
echo "ROUNDS=1"
echo "FILES=$n_files LINES=$lines"
