#!/usr/bin/env bash
# safe-cleanup.sh — delete ONLY merged + clean branches/worktrees. Safe by design.
#
# Guarantees (do not weaken these):
#   * Dry-run by default. Nothing is deleted unless --apply is passed.
#   * Local branches: only `git branch -d` (git refuses to delete unmerged). NEVER `-D`.
#   * Never touch: the current branch, the integration branch, or any protected branch.
#   * Worktrees: removed only if their working tree is CLEAN and their branch is merged.
#   * Remote branches: only deleted with --remote (opt-in) AND only if merged + not protected.
#   * A dirty worktree — and its remote branch — is always left completely alone.
#
# Known limitation (intentional, conservative): squash-merged branches are not
# detected by `git branch --merged`, so they are SKIPPED, not deleted. Missing a
# cleanup is safe; a wrong deletion is not. Delete those by hand if you want them gone.
#
# Usage:
#   safe-cleanup.sh [--integration <branch>] [--protect "a,b,c"] [--apply] [--remote] [--remote-name origin]
set -euo pipefail

integration=""
protect_csv="main,master,develop,preview,integration,release,hotfix"
apply=0
do_remote=0
remote_name="origin"

while [ $# -gt 0 ]; do
  case "$1" in
    --integration) integration="${2:-}"; shift 2 ;;
    --protect)     protect_csv="${protect_csv},${2:-}"; shift 2 ;;
    --apply)       apply=1; shift ;;
    --remote)      do_remote=1; shift ;;
    --remote-name) remote_name="${2:-origin}"; shift 2 ;;
    *) shift ;;
  esac
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "not-a-git-repo"; exit 0
fi

current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo DETACHED)"

if [ -z "$integration" ]; then
  if git symbolic-ref --quiet refs/remotes/origin/HEAD >/dev/null 2>&1; then
    integration="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
  fi
  [ -z "$integration" ] && for c in main master; do
    git show-ref --verify --quiet "refs/heads/$c" && { integration="$c"; break; }
  done
fi
if ! git show-ref --verify --quiet "refs/heads/$integration"; then
  echo "ERROR: integration branch '$integration' not found locally; refusing to guess. Pass --integration." >&2
  exit 1
fi

is_protected() {
  local name="$1"
  [ "$name" = "$current_branch" ] && return 0
  [ "$name" = "$integration" ] && return 0
  local IFS=','
  for p in $protect_csv; do
    p="$(echo "$p" | xargs)"   # trim whitespace
    p="${p%/}"                 # tolerate trailing slash (e.g. "hotfix/")
    [ -z "$p" ] && continue
    [ "$name" = "$p" ] && return 0
    case "$name" in "$p"/*) return 0 ;; esac   # e.g. release/* protects release/1.2
  done
  return 1
}

mode="DRY-RUN (pass --apply to execute)"
[ "$apply" = "1" ] && mode="APPLY"
echo "== pilot safe-cleanup =="
echo "integration=$integration  current=$current_branch  mode=$mode  remote=$([ $do_remote = 1 ] && echo on || echo off)"
echo

# Branches currently checked out in a worktree — handled by section 2, never section 1.
wt_branches=""
while IFS= read -r line; do
  case "$line" in
    branch\ refs/heads/*) wt_branches="${wt_branches}${line#branch refs/heads/}"$'\n' ;;
  esac
done < <(git worktree list --porcelain 2>/dev/null)
is_in_worktree() { printf '%s' "$wt_branches" | grep -Fqx "$1"; }

# ---- 1. Merged local branches ------------------------------------------------
echo "## Local merged branches"
merged_list=()
while IFS= read -r b; do
  b="$(echo "$b" | sed 's/^[* +] *//')"
  [ -z "$b" ] && continue
  if is_protected "$b"; then continue; fi
  if is_in_worktree "$b"; then continue; fi   # leave worktree branches to section 2
  merged_list+=("$b")
done < <(git branch --merged "$integration" 2>/dev/null)

if [ "${#merged_list[@]}" -eq 0 ]; then
  echo "  (none)"
else
  for b in "${merged_list[@]}"; do
    if [ "$apply" = "1" ]; then
      # -d refuses unmerged; safe even if state changed since listing.
      if git branch -d -- "$b" 2>/dev/null; then echo "  deleted  $b"; else echo "  SKIP (not safely merged)  $b"; fi
    else
      echo "  would delete  $b"
    fi
  done
fi
echo

# ---- 2. Worktrees: clean + merged only --------------------------------------
echo "## Worktrees (clean + merged only)"
main_root="$(git rev-parse --show-toplevel)"
# `git worktree list --porcelain` emits blocks separated by blank lines.
wt_path=""; wt_branch=""
handle_wt() {
  local path="$1" branch="$2"
  [ -z "$path" ] && return
  [ "$path" = "$main_root" ] && return           # never the primary worktree
  local short="${branch#refs/heads/}"
  if [ -z "$branch" ]; then short="(detached)"; fi   # porcelain omits 'branch' line when detached
  # dirty check — never abort on a locked/stale/unreadable worktree; when in doubt, KEEP.
  local dirty rc
  set +e
  dirty="$(git -C "$path" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  rc=$?
  set -e
  if [ "$rc" -ne 0 ]; then
    echo "  KEEP (worktree status unavailable)  $path  [$short]"
    return
  fi
  if [ "$dirty" != "0" ]; then
    echo "  KEEP (dirty, $dirty changes)  $path  [$short]"
    return
  fi
  # merged check
  if [ "$short" = "(detached)" ] || is_protected "$short" || ! git branch --merged "$integration" 2>/dev/null | sed 's/^[* +] *//' | grep -Fqx "$short"; then
    echo "  KEEP (not a merged feature branch)  $path  [$short]"
    return
  fi
  if [ "$apply" = "1" ]; then
    if git worktree remove "$path" 2>/dev/null; then
      echo "  removed  $path  [$short]"
      git branch -d -- "$short" 2>/dev/null && echo "    + deleted branch $short" || true
    else
      echo "  SKIP (remove failed)  $path  [$short]"
    fi
  else
    echo "  would remove  $path  [$short]  (+ delete branch $short)"
  fi
}
while IFS= read -r line; do
  case "$line" in
    worktree\ *) wt_path="${line#worktree }" ;;
    branch\ *)   wt_branch="${line#branch }" ;;
    "")          handle_wt "$wt_path" "$wt_branch"; wt_path=""; wt_branch="" ;;
  esac
done < <(git worktree list --porcelain 2>/dev/null; echo "")
echo

# ---- 3. Remote merged branches (opt-in) -------------------------------------
if [ "$do_remote" = "1" ]; then
  echo "## Remote merged branches ($remote_name)"
  # Only mutate on --apply: even `fetch --prune` rewrites remote-tracking refs, so dry-run never fetches.
  if [ "$apply" = "1" ]; then git fetch --prune "$remote_name" >/dev/null 2>&1 || true; fi
  any=0
  while IFS= read -r rb; do
    rb="$(echo "$rb" | sed 's/^[* +] *//')"
    case "$rb" in
      "$remote_name/HEAD"*|"") continue ;;
      "$remote_name/"*) : ;;   # this remote only
      *) continue ;;           # skip other remotes entirely (e.g. upstream/*) — never delete cross-remote
    esac
    short="${rb#"$remote_name"/}"
    if is_protected "$short"; then continue; fi
    if is_in_worktree "$short"; then continue; fi   # never delete the remote of a checked-out/dirty worktree branch
    any=1
    if [ "$apply" = "1" ]; then
      if git push "$remote_name" --delete -- "$short" >/dev/null 2>&1; then echo "  deleted  $remote_name/$short"; else echo "  SKIP (delete failed)  $remote_name/$short"; fi
    else
      echo "  would delete  $remote_name/$short"
    fi
  done < <(git branch -r --merged "$integration" 2>/dev/null)
  [ "$any" = "0" ] && echo "  (none)"
  echo
fi

echo "== done ($mode) =="
