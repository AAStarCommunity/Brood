#!/usr/bin/env bash
# git-guard.sh — enforce pilot's three dangerous-op rails at the SCRIPT layer,
# not merely as prose the model is asked to obey. Use this INSTEAD of raw git/gh for:
#   * staging   — refuses `git add -A` / `.` / `--all` and any flag; explicit paths only
#   * pushing   — refuses pushing to a protected/base branch (main/master/...)
#   * PR merge  — refuses merging a PR whose base is not the integration branch
#
# Usage:
#   git-guard.sh add <path> [<path>...]
#   git-guard.sh push <remote> <branch>
#   git-guard.sh merge-pr <n> --integration <branch> [extra gh args...]
#
# Exit codes: 2 = usage error, 3 = BLOCKED by a rail. On success it execs the real command.
set -euo pipefail

# Optional `--protect <csv>` flag BEFORE the subcommand: the caller passes the repo's real
# protected branches (base_branch/integration_branch/protect_patterns from .pilot.yml) HERE,
# in the same invocation. Preferred over the $PILOT_PROTECTED env, which an `export` in an
# earlier step does NOT carry into a later, separately-invoked shell — silently degrading the
# rail to the hardcoded defaults with no warning.
flag_protect=""
while [ $# -gt 0 ]; do
  case "$1" in
    --protect) [ $# -ge 2 ] || { echo "git-guard: --protect needs a comma-separated branch list" >&2; exit 2; }; flag_protect="$2"; shift 2 ;;
    *) break ;;
  esac
done

# Branches that must never be pushed to / merged onto directly. Extended by --protect (preferred)
# and/or $PILOT_PROTECTED (the pre-rename $REPO_PILOT_PROTECTED still honored as a fallback).
_extra="${flag_protect:+$flag_protect,}${PILOT_PROTECTED:-${REPO_PILOT_PROTECTED:-}}"
if [ -z "${PILOT_PROTECTED:-}" ] && [ -n "${REPO_PILOT_PROTECTED:-}" ]; then
  echo "git-guard: note: REPO_PILOT_PROTECTED is deprecated — rename it to PILOT_PROTECTED" >&2
fi
PROTECTED="main,master,develop,preview,integration,release,hotfix${_extra:+,$_extra}"

die() { echo "git-guard: BLOCKED: $*" >&2; exit 3; }

is_protected() {
  local name="$1" p IFS=','
  for p in $PROTECTED; do
    [ -z "$p" ] && continue
    [ "$name" = "$p" ] && return 0
    # Prefix match too, so a `release`/`hotfix`/… entry also covers `release-1.2`, `hotfix/x`,
    # `preview.2`, `release2`. Boundary set [-_/.0-9] stops `main` from swallowing `mainline`.
    case "$name" in "$p"[-_/.0-9]*) return 0 ;; esac
  done
  return 1
}

sub="${1:-}"
[ $# -gt 0 ] && shift

case "$sub" in
  add)
    [ $# -gt 0 ] || die "add needs explicit path(s); refusing an empty 'git add'"
    for a in "$@"; do
      case "$a" in
        -*)            die "refusing flag '$a' — explicit file paths only (never -A/--all/-u/-p)" ;;
        .|./|..|../|/) die "refusing '$a' — stages a whole tree; pass explicit files" ;;
        :*)            die "refusing pathspec magic '$a' (e.g. ':(top)', ':/', ':!') — explicit file paths only" ;;
        *'*'*|*'?'*|*'['*) die "refusing glob '$a' — explicit file paths only" ;;
      esac
      [ -d "$a" ] && die "refusing directory '$a' — stages its whole subtree; pass explicit files"
    done
    exec git add -- "$@"
    ;;
  push)
    remote="${1:-}"; branch="${2:-}"
    { [ -n "$remote" ] && [ -n "$branch" ]; } || die "usage: git-guard.sh push <remote> <branch>"
    [ $# -eq 2 ] || die "push takes exactly <remote> <branch> — refusing extra refspecs/flags"
    case "$branch" in -*) die "refusing flag-like ref '$branch'" ;; esac
    # Reject wildcard/glob refspecs: `push origin 'refs/heads/*:refs/heads/*'` resolves below to a
    # literal `*` that is_protected can't match and would push (or force-rewrite) EVERY branch incl.
    # main. A script-driven push here has no legitimate use for a glob.
    case "$branch" in *'*'*|*'?'*|*'['*) die "refusing wildcard/glob refspec '$branch' — pass one plain branch name" ;; esac
    # Validate the REMOTE (1st arg) too — leaving it unchecked lets flag injection defeat the
    # rail: `push --force origin` (remote=--force, branch=origin, which isn't protected) would
    # exec `git push -u --force origin` and force-overwrite the CURRENT branch (e.g. main).
    # `--all`/`--mirror` are worse. Refuse flag-like remotes, and require a real configured remote
    # name (not a URL) so a typo'd/hostile remote can't push or exfiltrate the repo past the rail.
    case "$remote" in -*) die "refusing flag-like remote '$remote' (e.g. --force/--all/--mirror) — pass a real remote name" ;; esac
    git remote | grep -qxF -- "$remote" || die "unknown remote '$remote' — not a configured \`git remote\`; refusing"
    # Resolve the DESTINATION ref from any refspec form (src:dst, +dst, refs/heads/dst) so
    # `push origin HEAD:main` can't smuggle a protected branch past an exact-name check.
    dst="${branch##*:}"; dst="${dst#+}"; dst="${dst#refs/heads/}"
    # `HEAD`/`@` (incl. a bare `push origin HEAD`) resolve to the CURRENT branch — check that real
    # name, else being on `main` + `push origin HEAD` would smuggle a trunk push past the guard.
    case "$dst" in
      HEAD|@) dst="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)" ;;
    esac
    # Whitelist the resolved destination: it must be a plain branch name. Anything with leftover
    # refspec punctuation / glob chars never had a legitimate single-branch form and is refused.
    case "$dst" in
      ''|*[!A-Za-z0-9._/@+-]*) die "refusing non-plain push destination '$dst' (from '$branch') — pass a simple branch name" ;;
    esac
    is_protected "$dst" && die "refusing to push to protected branch '$dst' (from '$branch') — open a PR from a feature branch"
    exec git push -u -- "$remote" "$branch"
    ;;
  merge-pr)
    n="${1:-}"; [ $# -gt 0 ] && shift
    integration=""
    args=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --integration)
          [ $# -ge 2 ] || die "--integration requires a value"
          integration="$2"; shift 2 ;;
        # Refuse flags that defeat the rail: --admin bypasses branch protection; --repo/-R
        # would point the merge at a different repo than the base check validated.
        # Prefix/attached-value forms bypass an exact-string blocklist: --admin=true, --repo=o/r,
        # -Ro/r all defeat the rail, so match those shapes too.
        --admin|--admin=*|--repo|--repo=*|-R|-R*) die "refusing '$1' on merge-pr — it would bypass the safety rail" ;;
        # --delete-branch/-d deletes the PR's HEAD branch after merge; a PR with head=main would
        # delete trunk. The head-branch protected-check below is the real guard; also refuse the
        # flag outright so branch cleanup stays an explicit, separate safe-cleanup.sh decision.
        -d|--delete-branch|--delete-branch=*) die "refusing '$1' on merge-pr — deletes the PR head branch; clean up branches via safe-cleanup.sh" ;;
        *) args+=("$1"); shift ;;
      esac
    done
    [ -n "$n" ] || die "usage: git-guard.sh merge-pr <n> --integration <branch> [gh args]"
    [ -n "$integration" ] || die "merge-pr requires --integration <branch>"
    # The integration target must NOT be trunk. `.pilot.yml` falls back integration→base_branch,
    # and a stale `.repo-pilot.yml` can carry integration=master — either would merge PRs straight
    # into trunk (violating "绝不直接合并到主干"). PRs merge into an integration branch (preview),
    # never main/master/develop/release/hotfix.
    case "$integration" in
      main|master|develop|release|release*|hotfix|hotfix*) die "integration '$integration' is a trunk branch — merge PRs into an integration branch (e.g. preview), not trunk" ;;
    esac
    command -v gh >/dev/null 2>&1 || die "gh not installed"
    # Pin the repo so the base check and the actual merge target the SAME repo.
    repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)"
    [ -n "$repo" ] || die "cannot resolve current repo (gh auth / not inside a gh repo?)"
    base="$(gh pr view "$n" --repo "$repo" --json baseRefName --jq .baseRefName 2>/dev/null || true)"
    [ -n "$base" ] || die "cannot read PR #$n base branch (gh auth / wrong number?)"
    [ "$base" = "$integration" ] || die "PR #$n base is '$base', not integration '$integration' — refusing merge into an unintended branch"
    # Also validate the HEAD branch: a PR opened with head=a protected branch (e.g. head=main,
    # base=preview) passes the base check, and merging/cleaning it up could damage trunk.
    head_ref="$(gh pr view "$n" --repo "$repo" --json headRefName --jq .headRefName 2>/dev/null || true)"
    [ -n "$head_ref" ] && is_protected "$head_ref" && die "PR #$n head branch '$head_ref' is protected — refusing (merging/deleting a protected head is unsafe)"
    # ${args[@]+...} guards the empty-array-under-set-u case on bash 3.2 (macOS default).
    exec gh pr merge "$n" --repo "$repo" ${args[@]+"${args[@]}"}
    ;;
  *)
    echo "git-guard.sh: add <path...> | push <remote> <branch> | merge-pr <n> --integration <b> [gh args]" >&2
    exit 2 ;;
esac
