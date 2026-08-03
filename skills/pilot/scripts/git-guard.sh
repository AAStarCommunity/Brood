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

# Branches that must never be pushed to directly. Callers may extend via $PILOT_PROTECTED
# (comma-separated) so a repo's real base/integration branches are covered too. The pre-rename
# name $REPO_PILOT_PROTECTED is still honored as a fallback (with a one-time deprecation notice)
# so a shell that exported the old name doesn't silently lose protection after the rename.
_extra="${PILOT_PROTECTED:-${REPO_PILOT_PROTECTED:-}}"
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
    # Validate the REMOTE (1st arg) too — leaving it unchecked lets flag injection defeat the
    # rail: `push --force origin` (remote=--force, branch=origin, which isn't protected) would
    # exec `git push -u --force origin` and force-overwrite the CURRENT branch (e.g. main).
    # `--all`/`--mirror` are worse. Refuse flag-like remotes, and require a real configured remote
    # name (not a URL) so a typo'd/hostile remote can't push or exfiltrate the repo past the rail.
    case "$remote" in -*) die "refusing flag-like remote '$remote' (e.g. --force/--all/--mirror) — pass a real remote name" ;; esac
    git remote | grep -qx -- "$remote" || die "unknown remote '$remote' — not a configured \`git remote\`; refusing"
    # Resolve the DESTINATION ref from any refspec form (src:dst, +dst, refs/heads/dst) so
    # `push origin HEAD:main` can't smuggle a protected branch past an exact-name check.
    dst="${branch##*:}"; dst="${dst#+}"; dst="${dst#refs/heads/}"
    # `HEAD`/`@` (incl. a bare `push origin HEAD`) resolve to the CURRENT branch — check that real
    # name, else being on `main` + `push origin HEAD` would smuggle a trunk push past the guard.
    case "$dst" in
      HEAD|@) dst="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)" ;;
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
        *) args+=("$1"); shift ;;
      esac
    done
    [ -n "$n" ] || die "usage: git-guard.sh merge-pr <n> --integration <branch> [gh args]"
    [ -n "$integration" ] || die "merge-pr requires --integration <branch>"
    command -v gh >/dev/null 2>&1 || die "gh not installed"
    # Pin the repo so the base check and the actual merge target the SAME repo.
    repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)"
    [ -n "$repo" ] || die "cannot resolve current repo (gh auth / not inside a gh repo?)"
    base="$(gh pr view "$n" --repo "$repo" --json baseRefName --jq .baseRefName 2>/dev/null || true)"
    [ -n "$base" ] || die "cannot read PR #$n base branch (gh auth / wrong number?)"
    [ "$base" = "$integration" ] || die "PR #$n base is '$base', not integration '$integration' — refusing merge into an unintended branch"
    # ${args[@]+...} guards the empty-array-under-set-u case on bash 3.2 (macOS default).
    exec gh pr merge "$n" --repo "$repo" ${args[@]+"${args[@]}"}
    ;;
  *)
    echo "git-guard.sh: add <path...> | push <remote> <branch> | merge-pr <n> --integration <b> [gh args]" >&2
    exit 2 ;;
esac
