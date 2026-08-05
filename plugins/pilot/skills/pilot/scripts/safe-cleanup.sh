#!/usr/bin/env bash
# safe-cleanup.sh — delete ONLY merged + clean branches/worktrees. Safe by design.
#
# Guarantees (do not weaken these):
#   * Dry-run by default. Nothing is deleted unless --apply is passed.
#   * Local branches: `git branch -d` only (git itself refuses to delete unmerged work).
#     The single exception is a branch with SERVER-SIDE proof it was squash-merged — see
#     "Squash-merged branches" below. It needs --squash-merged, --apply, and the proof.
#   * Never touch: the current branch, the integration branch, or any protected branch.
#   * Worktrees: removed only if their working tree is CLEAN and their branch is merged.
#   * Remote branches: only deleted with --remote (opt-in) AND only if merged + not protected.
#   * A dirty worktree — and its remote branch — is always left completely alone.
#
# Squash-merged branches (--squash-merged, opt-in):
#   In a squash-merge repo `git branch --merged` returns NOTHING, ever — the squash rewrites the
#   patch so the original commits are not ancestors of the integration branch. Measured here:
#   28 local branches, `git branch --merged main` → 0. That made this script unable to clean
#   anything at all in its own home repo, and an unusable guard gets replaced by hand-run `-D`,
#   which is strictly worse than the guard existing.
#
#   So `--squash-merged` adds a SECOND source of merge evidence, and it is a real one, not a
#   loosening: GitHub's `/commits/{sha}/pulls` says which PR introduced a commit to the
#   repository. A branch qualifies only when that endpoint names a PR with `merged_at != null`
#   for the branch's tip commit.
#
#   Why keyed on the COMMIT and not the branch name — both directions of the name-based mistake
#   are real and were hit here:
#     * miss  — `work-pr18` / `worktree-agent-*` were never any PR's head branch, yet their tips
#               were the merged heads of #18 / #23. A name lookup calls them unmerged.
#     * WRONG DELETE — branch names are reusable. Delete a branch, recreate it with unrelated
#               work, and the old MERGED PR still matches the name. A name lookup deletes it.
#   The commit-keyed check has neither failure mode. Verified against all four shapes:
#   squash-merged head ✓, mid-branch commit ✓, closed-but-unmerged → no evidence ✓,
#   never-had-a-PR → no evidence ✓.
#
#   Deleting these needs `git branch -D` (`-d` refuses, correctly — git cannot see the merge).
#   That is the ONLY place -D is ever used, it requires --squash-merged AND --apply, and it
#   requires the evidence above. No evidence, no gh, no auth → the branch is KEPT.
#
# Usage:
#   safe-cleanup.sh [--integration <branch>] [--protect "a,b,c"] [--apply] [--squash-merged]
#                   [--remote] [--remote-name origin]
set -euo pipefail

integration=""
protect_csv="main,master,develop,preview,integration,release,hotfix"
apply=0
squash_merged=0
do_remote=0
remote_name="origin"

while [ $# -gt 0 ]; do
  case "$1" in
    --integration) integration="${2:-}"; shift 2 ;;
    --protect)     protect_csv="${protect_csv},${2:-}"; shift 2 ;;
    --apply)       apply=1; shift ;;
    --squash-merged) squash_merged=1; shift ;;
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

# ---- squash-merge evidence (read-only; no fetch, no ref writes, so dry-run stays read-only) ----
# Resolved once, lazily: most repos never need it, and `gh` may not be installed at all.
gh_state="unknown"   # unknown | ready | unavailable
gh_repo=""
gh_init() {
  [ "$gh_state" = "unknown" ] || return 0
  gh_state="unavailable"
  command -v gh >/dev/null 2>&1 || return 0
  gh auth status >/dev/null 2>&1 || return 0
  gh_repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)"
  [ -n "$gh_repo" ] && gh_state="ready"
  return 0
}

# Echo the number of a MERGED PR that introduced this branch's tip commit, or nothing.
# Nothing = no evidence = keep the branch. Every failure path (no gh, no auth, API error,
# unparseable answer) lands on "nothing" — the check can only ever ADD permission to delete.
merged_pr_for() {
  local b="$1" sha out
  gh_init
  [ "$gh_state" = "ready" ] || return 0
  sha="$(git rev-parse --verify --quiet "$b^{commit}" 2>/dev/null)" || return 0
  [ -n "$sha" ] || return 0
  out="$(gh api "repos/$gh_repo/commits/$sha/pulls" \
         --jq '[.[] | select(.merged_at != null) | .number] | first // empty' 2>/dev/null || true)"
  case "$out" in
    ''|*[!0-9]*) return 0 ;;   # empty, error text, or anything non-numeric → no evidence
    *) printf '%s' "$out" ;;
  esac
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

# ---- 1b. Squash-merged local branches (evidence-based; opt-in) ---------------
# Separate section on purpose: these need `-D`, so they must never be confused with the
# `-d`-safe list above. A branch appears here ONLY with a merged-PR number attached.
echo "## Squash-merged local branches"
# Probe HERE, in the main shell. `merged_pr_for` is only ever called as `$( ... )`, which runs in
# a SUBSHELL — anything it assigns to gh_state is discarded on return. Relying on that left the
# "cannot verify" branch permanently unreachable, so a missing/unauthenticated gh printed the
# same "(none)" as a genuinely clean repo. "Could not check" must never look like "nothing found".
gh_init
sq_names=()
sq_prs=()
while IFS= read -r b; do
  b="$(echo "$b" | sed 's/^[* +] *//')"
  [ -z "$b" ] && continue
  is_protected "$b" && continue
  is_in_worktree "$b" && continue
  # Anything git already calls merged was handled above.
  git branch --merged "$integration" 2>/dev/null | sed 's/^[* +] *//' | grep -Fqx "$b" && continue
  pr="$(merged_pr_for "$b")"
  [ -z "$pr" ] && continue
  sq_names+=("$b"); sq_prs+=("$pr")
done < <(git branch --format='%(refname:short)' 2>/dev/null)

if [ "${#sq_names[@]}" -eq 0 ]; then
  if [ "$gh_state" = "unavailable" ]; then
    echo "  (cannot verify — gh not installed/authenticated, or repo not resolvable; branches KEPT)"
  else
    echo "  (none)"
  fi
else
  i=0
  while [ "$i" -lt "${#sq_names[@]}" ]; do
    b="${sq_names[$i]}"; pr="${sq_prs[$i]}"
    if [ "$squash_merged" = "1" ] && [ "$apply" = "1" ]; then
      # -D, justified by the merged-PR evidence just gathered for THIS tip commit.
      if git branch -D -- "$b" >/dev/null 2>&1; then echo "  deleted  $b  (merged via PR #$pr)"
      else echo "  SKIP (delete failed)  $b"; fi
    elif [ "$squash_merged" = "1" ]; then
      echo "  would delete  $b  (merged via PR #$pr)"
    else
      echo "  candidate  $b  (merged via PR #$pr) — pass --squash-merged to include"
    fi
    i=$((i + 1))
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
