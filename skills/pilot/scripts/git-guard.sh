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

# SELF-CONTAINED protection: read the repo's real protected branches from .pilot.yml (or the old
# .repo-pilot.yml) DIRECTLY. run.md is executed as separate per-step Bash calls that share neither
# variables nor env, so a caller-threaded --protect/$PILOT_PROTECTED silently vanishes between
# steps — reading the config here means the rail can't degrade that way. --protect/env still ADD.
_cfg_extra=""
_top="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
for _f in "$_top/.pilot.yml" "$_top/.repo-pilot.yml"; do
  [ -f "$_f" ] || continue
  _bb="$(sed -n 's/^base_branch:[[:space:]]*//p' "$_f" | head -1 | tr -d " \"'[]")"
  _ib="$(sed -n 's/^integration_branch:[[:space:]]*//p' "$_f" | head -1 | tr -d " \"'[]")"
  _pp="$(sed -n 's/^protect_patterns:[[:space:]]*//p' "$_f" | head -1 | tr -d " \"'[]")"
  _cfg_extra="${_bb:+$_bb,}${_ib:+$_ib,}${_pp}"
  break
done

# Branches that must never be pushed to / merged onto directly. Built from the hardcoded defaults +
# .pilot.yml config + --protect (preferred) + $PILOT_PROTECTED ($REPO_PILOT_PROTECTED as fallback).
_extra="${flag_protect:+$flag_protect,}${_cfg_extra:+$_cfg_extra,}${PILOT_PROTECTED:-${REPO_PILOT_PROTECTED:-}}"
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
    # Strip every ref-prefix form git accepts for a branch dst — `refs/heads/main`, the SHORT
    # `heads/main`, and a plain `main` — so all normalize to the bare branch name before the
    # protected check. Missing `heads/` let `+refs/heads/x:heads/main` force-overwrite/delete main.
    dst="${branch##*:}"; dst="${dst#+}"; dst="${dst#refs/heads/}"; dst="${dst#heads/}"
    # `HEAD`/`@` (incl. a bare `push origin HEAD`) resolve to the CURRENT branch — check that real
    # name, else being on `main` + `push origin HEAD` would smuggle a trunk push past the guard.
    case "$dst" in
      HEAD|@) dst="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)" ;;
    esac
    # Reject only the DANGEROUS shapes in the resolved destination — glob (`*?[`), leftover
    # refspec punctuation (`: ~ ^ \`), whitespace, or empty. A denylist (not a strict ASCII
    # allowlist) so legitimate branch names git itself allows — `fix/issue-#42`, `feat(scope)`,
    # CJK slugs like `feat/中文分支` (run.md §2 builds `<type>/<taskid>-<slug>` in a 中文 project) —
    # are NOT hard-blocked, while every refspec/wildcard bypass shape still is.
    case "$dst" in
      ''|*'*'*|*'?'*|*'['*|*':'*|*'~'*|*'^'*|*'\'*|*[[:space:]]*) die "refusing non-plain push destination '$dst' (from '$branch') — pass one simple branch name (no refspec/glob)" ;;
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
    # Also refuse if integration IS the repo's DEFAULT (trunk) branch — catches ANY trunk name
    # (e.g. `trunk`/`production`), not just the hardcoded list above. NB: is_protected() can't be
    # used for this — the integration branch itself is in $PROTECTED (run.md §0 threads it in via
    # --protect for push-protection), so is_protected("$integration") would always be true.
    def_branch="$(gh repo view --repo "$repo" --json defaultBranchRef --jq .defaultBranchRef.name 2>/dev/null || true)"
    [ -n "$def_branch" ] || die "cannot resolve repo default branch — refusing merge-pr until the trunk check is verifiable"
    [ "$integration" = "$def_branch" ] && die "integration '$integration' is the repo's default (trunk) branch — merge PRs into an integration branch, not trunk"
    base="$(gh pr view "$n" --repo "$repo" --json baseRefName --jq .baseRefName 2>/dev/null || true)"
    [ -n "$base" ] || die "cannot read PR #$n base branch (gh auth / wrong number?)"
    [ "$base" = "$integration" ] || die "PR #$n base is '$base', not integration '$integration' — refusing merge into an unintended branch"
    # Also validate the HEAD branch: a PR opened with head=a protected branch (e.g. head=main,
    # base=preview) passes the base check, and merging/cleaning it up could damage trunk.
    head_ref="$(gh pr view "$n" --repo "$repo" --json headRefName --jq .headRefName 2>/dev/null || true)"
    [ -n "$head_ref" ] || die "cannot read PR #$n head branch — refusing until verifiable"
    is_protected "$head_ref" && die "PR #$n head branch '$head_ref' is protected — refusing (merging/deleting a protected head is unsafe)"
    # ${args[@]+...} guards the empty-array-under-set-u case on bash 3.2 (macOS default).
    exec gh pr merge "$n" --repo "$repo" ${args[@]+"${args[@]}"}
    ;;
  *)
    echo "git-guard.sh: add <path...> | push <remote> <branch> | merge-pr <n> --integration <b> [gh args]" >&2
    exit 2 ;;
esac
