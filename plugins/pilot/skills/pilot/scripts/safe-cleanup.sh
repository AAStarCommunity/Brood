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

# Unknown arguments are REFUSED, not skipped. `*) shift ;;` silently dropped a typo like
# `--integraton main`, and `integration` then fell back to a guess from origin/HEAD — so
# `--apply` would delete against a baseline the caller never asked for. `--integration` is the
# one argument whose typo is unrecoverable, and run.md requires callers to pass it explicitly.
# (Same reasoning that turned git-guard's flag denylist into a refuse-unknown allowlist in this
# very commit; it applies here for identical reasons.)
need_val() { [ "$2" -ge 2 ] || { echo "safe-cleanup: '$1' requires a value" >&2; exit 2; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --integration)   need_val "$1" $#; integration="$2"; shift 2 ;;
    --protect)       need_val "$1" $#; protect_csv="${protect_csv},$2"; shift 2 ;;
    --remote-name)   need_val "$1" $#; remote_name="$2"; shift 2 ;;
    --apply)         apply=1; shift ;;
    --squash-merged) squash_merged=1; shift ;;
    --remote)        do_remote=1; shift ;;
    -h|--help)       sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "safe-cleanup: unknown argument '$1'" >&2
       echo "  usage: safe-cleanup.sh [--integration <b>] [--protect \"a,b\"] [--apply] [--squash-merged] [--remote] [--remote-name <r>]" >&2
       exit 2 ;;
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

# Echo one of three things, and the difference matters:
#   <number>  a MERGED PR whose BASE is $integration introduced this branch's tip commit
#   ERR       the lookup itself failed (rate limit, 5xx, missing scope) — verdict UNKNOWN
#   (empty)   the lookup succeeded and found no such PR — no evidence
#
# `.base.ref == $integration` is load-bearing, not decoration. Without it the test is merely
# "some merged PR touched this tip", which a STACKED PR satisfies: child merged into a parent
# feature branch, parent's own PR later closed unmerged — the child's tip then carries merge
# evidence forever while its work never reached the integration branch. Measured in a sandbox:
# a commit `git merge-base --is-ancestor … main` calls unreachable was still offered for
# deletion. Brood happens to have integration == default == main, which masks this entirely;
# pilot's documented default shape is `preview != main`, where it bites.
#
# NB: an `--is-ancestor $sha $integration` test is deliberately NOT added on top. In a
# squash-merge repo the tip is BY CONSTRUCTION never an ancestor of the integration branch —
# that is the whole reason this function exists. Requiring it would return the feature to the
# dead-code state it was written to fix. Base convergence is the correct narrowing; ancestry
# is not available here.
merged_pr_for() {
  local b="$1" sha out rc
  gh_init
  [ "$gh_state" = "ready" ] || { printf 'ERR'; return 0; }
  sha="$(git rev-parse --verify --quiet "$b^{commit}" 2>/dev/null)" || return 0
  [ -n "$sha" ] || return 0
  # $integration goes in as DATA via $ENV, never interpolated into the jq program. Building the
  # program by string substitution let a git-legal branch name rewrite the predicate: with
  # `x"or(true)or"` the comparison becomes `.base.ref == "x"or(true)or""` — constantly true — and
  # a merged PR whose base was some other branch then counted as evidence, ending in an
  # irreversible `git branch -D`. That is the exact failure class the base check was added to
  # close, re-entering through the check itself.
  out="$(PILOT_INTEG="$integration" gh api "repos/$gh_repo/commits/$sha/pulls" \
         --jq '[.[] | select(.merged_at != null and .base.ref == $ENV.PILOT_INTEG) | .number] | first // empty' 2>/dev/null)"
  rc=$?
  # A failed CALL is not the same as an empty ANSWER. Rate limiting is the most likely failure
  # here precisely because this feature spends one API call per branch.
  [ "$rc" -ne 0 ] && { printf 'ERR'; return 0; }
  case "$out" in
    '') return 0 ;;            # 200 with no matching PR → genuinely no evidence
    *[!0-9]*) printf 'ERR' ;;  # 200 but unparseable → treat as unknown, never as "no"
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
sq_errors=0
while IFS= read -r b; do
  b="$(echo "$b" | sed 's/^[* +] *//')"
  [ -z "$b" ] && continue
  is_protected "$b" && continue
  is_in_worktree "$b" && continue
  # Anything git already calls merged was handled above.
  git branch --merged "$integration" 2>/dev/null | sed 's/^[* +] *//' | grep -Fqx "$b" && continue
  pr="$(merged_pr_for "$b")"
  # Count PER-BRANCH lookup failures separately. gh_state only records init-level failure;
  # a 403/5xx on an individual branch used to land in the same "no evidence" bucket, so a
  # rate-limited run printed a byte-identical "(none)" to a genuinely clean repo — and a
  # partially failed run silently dropped the branches it could not check. status.md (added in
  # this same PR) tells the model to say "could not verify, not nothing"; it needs this signal
  # to be able to.
  if [ "$pr" = "ERR" ]; then sq_errors=$((sq_errors + 1)); continue; fi
  [ -z "$pr" ] && continue
  sq_names+=("$b"); sq_prs+=("$pr")
done < <(git branch --format='%(refname:short)' 2>/dev/null)

if [ "${#sq_names[@]}" -eq 0 ]; then
  if [ "$gh_state" = "unavailable" ]; then
    echo "  (cannot verify — gh not installed/authenticated, or repo not resolvable; branches KEPT)"
  elif [ "$sq_errors" -gt 0 ]; then
    echo "  ($sq_errors branch(es) could not be verified — KEPT. NOT the same as 'nothing to clean'.)"
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
  # A partial result must never read as a complete one.
  [ "$sq_errors" -gt 0 ] && echo "  ($sq_errors more branch(es) could not be verified — KEPT; this list is INCOMPLETE)"
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
  # merged check — git-native first, then the same squash evidence section 1b uses.
  # Using ONLY `git branch --merged` here would have left worktrees permanently uncleanable in a
  # squash repo: that predicate returns 0 rows by construction, which is the entire premise of
  # this PR. Missing it meant the fix stopped at loose branches while `SKILL.md`'s own doctrine
  # ("一个 task = 一个分支 = 一个 worktree = 一个 PR") makes the worktree the dominant unit, and
  # `phases/status.md` reports worktree cleanup on every `pilot status`.
  local wt_pr="" via=""
  if [ "$short" = "(detached)" ] || is_protected "$short"; then
    echo "  KEEP (not a merged feature branch)  $path  [$short]"
    return
  fi
  if git branch --merged "$integration" 2>/dev/null | sed 's/^[* +] *//' | grep -Fqx "$short"; then
    via="git"
  else
    wt_pr="$(merged_pr_for "$short")"
    if [ "$wt_pr" = "ERR" ]; then
      echo "  KEEP (could not verify — lookup failed, NOT 'unmerged')  $path  [$short]"
      return
    fi
    if [ -z "$wt_pr" ]; then
      echo "  KEEP (not a merged feature branch)  $path  [$short]"
      return
    fi
    if [ "$squash_merged" != "1" ]; then
      echo "  KEEP (squash-merged via PR #$wt_pr) — pass --squash-merged to include  $path  [$short]"
      return
    fi
    via="squash-PR#$wt_pr"
  fi
  if [ "$apply" = "1" ]; then
    if git worktree remove "$path" 2>/dev/null; then
      echo "  removed  $path  [$short]  ($via)"
      # -d for git-native evidence; -D only where a merged PR with base=$integration proves it.
      if [ "$via" = "git" ]; then
        git branch -d -- "$short" 2>/dev/null && echo "    + deleted branch $short" || true
      else
        git branch -D -- "$short" 2>/dev/null && echo "    + deleted branch $short ($via)" || true
      fi
    else
      echo "  SKIP (remove failed)  $path  [$short]"
    fi
  else
    echo "  would remove  $path  [$short]  ($via)  (+ delete branch $short)"
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
