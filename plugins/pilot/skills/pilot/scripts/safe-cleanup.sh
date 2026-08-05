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
# ---8<--- end of header ---8<---
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
# Counting arity is not enough: `--protect --apply` passed the arity test and swallowed --apply,
# so the script printed mode=DRY-RUN and exited 0 while the caller believed it had run. Same
# silent-swallow class B2 exists to close.
need_val() {
  [ "$2" -ge 2 ] || { echo "safe-cleanup: '$1' requires a value" >&2; exit 2; }
  case "$3" in
    -*) echo "safe-cleanup: '$1' requires a value, got flag '$3'" >&2; exit 2 ;;
    "") echo "safe-cleanup: '$1' requires a non-empty value" >&2; exit 2 ;;
  esac
}
while [ $# -gt 0 ]; do
  case "$1" in
    --integration)   need_val "$1" $# "${2:-}"; integration="$2"; shift 2 ;;
    --protect)       need_val "$1" $# "${2:-}"; protect_csv="${protect_csv},$2"; shift 2 ;;
    --remote-name)   need_val "$1" $# "${2:-}"; remote_name="$2"; shift 2 ;;
    --apply)         apply=1; shift ;;
    --squash-merged) squash_merged=1; shift ;;
    --remote)        do_remote=1; shift ;;
    # `grep '^#'` keeps comment lines — but the sentinel IS a comment line, so it was printed
    # verbatim at the end of every --help. Drop it explicitly.
    -h|--help)       sed -n '2,/^# ---8<--- end of header ---8<---$/p' "$0" | grep '^#' | grep -v '^# ---8<---'; exit 0 ;;
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
# Use the FULL ref everywhere the integration branch is resolved. As a bare name it is subject to
# the same tag-beats-branch precedence as any other: with a tag also called `main`, `git branch -r
# --merged main` answered about the TAG's commit and listed `origin/unmerged-precious` as merged —
# and §3 (`--remote`) has no `-d` safety net, so `--apply` destroyed it server-side. The ambiguity
# warning git prints was being swallowed by `2>/dev/null`, so nothing surfaced.
integration_ref="refs/heads/$integration"

is_protected() {
  local name="$1"
  [ "$name" = "$current_branch" ] && return 0
  [ "$name" = "$integration" ] && return 0
  # Split with `read -ra`, not word-splitting, and trim with parameter expansion, not `echo | xargs`.
  # xargs parses SHELL QUOTING, so it mangled exactly the names that most need protecting:
  # `a\b` came back as `ab`, and `keep'me` (a legal refname) killed xargs on an unterminated quote,
  # yielding an empty string that the `continue` below silently dropped — the branch then fell
  # through to the `-D` path. Measured: `--protect "keep'me"` printed `would delete keep'me`.
  # `set -f` so a pattern like `rel*` is compared literally instead of being glob-expanded against
  # the working directory.
  local -a pats=(); local p
  set -f
  IFS=',' read -ra pats <<< "$protect_csv"
  set +f
  for p in "${pats[@]}"; do
    p="${p#"${p%%[![:space:]]*}"}"   # trim leading whitespace
    p="${p%"${p##*[![:space:]]}"}"   # trim trailing whitespace
    p="${p%/}"                       # tolerate trailing slash (e.g. "hotfix/")
    [ -z "$p" ] && continue
    [ "$name" = "$p" ] && return 0
    # Boundary set copied VERBATIM from git-guard.sh's is_protected. The two scripts ship in the
    # same skill and must not disagree about what "protected" means: with the old `"$p"/*` a
    # `release-1.2` that git-guard REFUSES to push to was still offered here as a deletion
    # candidate. Harmless while this script only used `-d`; this PR added `-D`, which turns the
    # divergence into data loss. `[-_/.0-9]` (not `*`) so `main` cannot swallow `mainline`.
    case "$name" in "$p"[-_/.0-9]*) return 0 ;; esac
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
#
# Takes a resolved SHA, not a ref name. The caller resolves it once and keeps it, so the evidence
# and the sha that authorises the deletion are the SAME object by construction — there is no second
# resolution that could land on a different commit (or, before this round, on a same-named TAG).
merged_pr_for() {  # merged_pr_for <sha>
  local sha="$1" out rc
  gh_init
  [ "$gh_state" = "ready" ] || { printf 'ERR'; return 0; }
  [ -n "$sha" ] || return 0
  # $integration goes in as DATA via $ENV, never interpolated into the jq program. Building the
  # program by string substitution let a git-legal branch name rewrite the predicate: with
  # `x"or(true)or"` the comparison becomes `.base.ref == "x"or(true)or""` — constantly true — and
  # a merged PR whose base was some other branch then counted as evidence, ending in an
  # irreversible `git branch -D`. That is the exact failure class the base check was added to
  # close, re-entering through the check itself.
  # `rc=0; … || rc=$?` instead of a bare `$?`: under `set -e` a failing command substitution only
  # survives because bash suspends errexit inside `$( )` and `inherit_errexit` is off by default.
  # Verified: convert either call site to a non-cmdsub form and the script exits 1 silently right
  # after printing the section header, truncating the report with no error. This form keeps the
  # real status AND survives `shopt -s inherit_errexit` or a future non-cmdsub caller.
  rc=0
  out="$(PILOT_INTEG="$integration" gh api "repos/$gh_repo/commits/$sha/pulls" \
         --jq '[.[] | select(.merged_at != null and .base.ref == $ENV.PILOT_INTEG) | .number] | first // empty' 2>/dev/null)" || rc=$?
  # A failed CALL is not the same as an empty ANSWER. Rate limiting is the most likely failure
  # here precisely because this feature spends one API call per branch.
  [ "$rc" -ne 0 ] && { printf 'ERR'; return 0; }
  case "$out" in
    '') return 0 ;;            # 200 with no matching PR → genuinely no evidence
    *[!0-9]*) printf 'ERR' ;;  # 200 but unparseable → treat as unknown, never as "no"
    *) printf '%s' "$out" ;;
  esac
}

# ---- the ONE exit for `-D` ---------------------------------------------------------------------
# Both destructive call sites (loose branches in §1b, worktree branches in §2) go through here.
# They have now taken a HALF fix three rounds running — round 2 fixed the recovery handle only in
# the branch loop, round 3 fixed ref resolution only in handle_wt, and round 4 found the branch loop
# had meanwhile RE-INTRODUCED the very tag hijack round 3 fixed. One shared function is what makes
# the next half-fix structurally impossible.
#
# `git update-ref -d <fullref> <expected-sha>` instead of `git branch -D <name>`:
#   1. FULL REF, so git never applies its bare-name lookup rules — under those, `refs/tags/x` wins
#      over `refs/heads/x`, which is how evidence gathered from a TAG came to authorise deleting a
#      same-named unmerged BRANCH (measured: branch decoy=3661392 vs tag decoy=fece62f).
#   2. EXPECTED-OLD-VALUE, making it an atomic compare-and-swap: if the tip moved between evidence
#      and deletion, the delete FAILS instead of destroying newer work. That closes the TOCTOU
#      window without the second `gh` round-trip the previous round added — so this also puts the
#      cost back at one API call per branch, as the docs claim.
#   3. The sha it swaps against is the one the evidence was gathered for, printed as the recovery
#      handle. Same object end to end.
destroy_branch() {  # destroy_branch <refs/heads/name> <expected-sha> <label>
  local ref="$1" expect="$2" label="$3" short="${ref#refs/heads/}"
  if git update-ref -d "$ref" "$expect" 2>/dev/null; then
    # %q-quote the name in the restore hint: `feat/x$(id)` is a legal refname, and an unquoted
    # hint is a command substitution the moment someone pastes it.
    printf '  deleted  %s  (%s)  was=%s  → restore: git branch %q %s\n' \
      "$short" "$label" "$expect" "$short" "$expect"
    return 0
  fi
  # Two ways to get here and both mean "do not delete": the CAS found a different tip (someone
  # committed since the evidence was collected), or the ref is already gone.
  printf '  SKIP (tip moved since evidence was collected, or ref already gone)  %s\n' "$short"
  return 1
}

# Membership tests without a pipeline. `producer | grep -Fqx` looks harmless but `grep -q` exits at
# the first match, the producer takes SIGPIPE, and with `set -o pipefail` the whole pipeline returns
# 141 — a MATCH reported as a failure. Reproduced with a 5000-line producer (`MATCH-LOST rc=141`);
# at :349 that silently demoted a git-native merged worktree branch from the `-d` path to the `-D`
# path. Pure bash matching has no producer to kill.
list_has() {  # list_has <newline-separated-list> <needle>
  case $'\n'"$1"$'\n' in
    *$'\n'"$2"$'\n'*) return 0 ;;
  esac
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
is_in_worktree() { list_has "$wt_branches" "$1"; }

# Computed ONCE, from the full integration ref, and reused by every "is this already merged?" test
# below. Previously each test re-ran `git branch --merged | sed | grep -q` — three separate chances
# to hit the SIGPIPE/pipefail bug and the bare-name ambiguity, per branch.
git_merged_names="$(git branch --format='%(refname:short)' --merged "$integration_ref" 2>/dev/null || true)"

# ---- 1. Merged local branches ------------------------------------------------
echo "## Local merged branches"
merged_list=()
while IFS= read -r b; do
  [ -z "$b" ] && continue
  if is_protected "$b"; then continue; fi
  if is_in_worktree "$b"; then continue; fi   # leave worktree branches to section 2
  merged_list+=("$b")
done <<< "$git_merged_names"

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
# COST GATE. ONE gh call per candidate, in both dry-run and apply. (Round 4 briefly made apply 2N
# by re-querying to close the TOCTOU window; `update-ref`'s expected-old-value does that atomically
# instead, so the number below is accurate again — rate limiting is this feature's most likely
# failure mode and doubling the calls made it twice as easy to hit.) A plain `pilot status` dry-run measured
# 25 calls / 20.6s on this repo, and status.md step 4 runs exactly that. Without --squash-merged
# spend ZERO calls and say so — silence would be indistinguishable from "nothing found", the very
# confusion B3 exists to prevent.
if [ "$squash_merged" != "1" ]; then
  echo "  (not checked — one gh API call per branch; pass --squash-merged to check)"
  echo "   NB: in a squash-merge repo the section above is USUALLY (none) — squashed work is"
  echo "       not an ancestor — so cleanable branches usually appear HERE, not there."
else
gh_init
sq_refs=()
sq_shas=()
sq_prs=()
sq_errors=0
# Iterate over FULL refs. The previous round stripped them back to bare names with sed, which threw
# away the disambiguation `%(refname:short)` performs and handed every later step a name that git
# resolves tag-first — the Critical this round.
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  b="${ref#refs/heads/}"
  # Say WHY a branch never appears. Silently skipping protected names made e.g. `integration-tests`
  # permanently uncleanable with zero visible reason once the boundary set widened.
  if is_protected "$b"; then
    # Only surface PATTERN-protected names. The integration branch and the branch you are standing
    # on are structurally protected and saying so every run is noise; what needed a visible reason
    # is the third kind — e.g. `integration-tests` swept up by the widened boundary set, which
    # otherwise vanishes from every section with nothing explaining why.
    # Printed in APPLY too. Gating it on dry-run hid the reason in the exact invocation run.md:78
    # defines as the standard post-merge command (`--squash-merged … --apply`) — i.e. the fix for
    # "say why a branch never appears" was invisible in the only call that matters.
    if [ "$b" != "$integration" ] && [ "$b" != "$current_branch" ]; then
      echo "  KEEP (protected by name/pattern)  $b"
    fi
    continue
  fi
  is_in_worktree "$b" && continue
  # Anything git already calls merged was handled above.
  list_has "$git_merged_names" "$b" && continue
  # Resolve the tip ONCE, from the full ref, and carry it: this sha is what the evidence is about
  # and what authorises the delete.
  sha="$(git rev-parse --verify --quiet "$ref^{commit}" 2>/dev/null || true)"
  [ -n "$sha" ] || continue
  pr="$(merged_pr_for "$sha")"
  # Count PER-BRANCH lookup failures separately. gh_state only records init-level failure;
  # a 403/5xx on an individual branch used to land in the same "no evidence" bucket, so a
  # rate-limited run printed a byte-identical "(none)" to a genuinely clean repo — and a
  # partially failed run silently dropped the branches it could not check. status.md (added in
  # this same PR) tells the model to say "could not verify, not nothing"; it needs this signal
  # to be able to.
  if [ "$pr" = "ERR" ]; then sq_errors=$((sq_errors + 1)); continue; fi
  [ -z "$pr" ] && continue
  sq_refs+=("$ref"); sq_shas+=("$sha"); sq_prs+=("$pr")
done < <(git branch --format='%(refname)' 2>/dev/null)

if [ "${#sq_refs[@]}" -eq 0 ]; then
  if [ "$gh_state" = "unavailable" ]; then
    echo "  (cannot verify — gh not installed/authenticated, or repo not resolvable; branches KEPT)"
  elif [ "$sq_errors" -gt 0 ]; then
    echo "  ($sq_errors branch(es) could not be verified — KEPT. NOT the same as 'nothing to clean'.)"
  else
    echo "  (none)"
  fi
else
  i=0
  while [ "$i" -lt "${#sq_refs[@]}" ]; do
    ref="${sq_refs[$i]}"; sha="${sq_shas[$i]}"; pr="${sq_prs[$i]}"
    if [ "$apply" = "1" ]; then
      # The CAS inside destroy_branch is the TOCTOU guard: evidence gathering costs ~0.8s per gh
      # call, so a 25-branch run leaves a ~20s window for a concurrent agent to commit. Previously
      # that was covered by re-calling `gh` per branch (doubling the cost and misreporting rate
      # limits as "tip changed"); the expected-old-value does it atomically, for free, and cannot
      # confuse a lookup failure with a moved tip.
      destroy_branch "$ref" "$sha" "merged via PR #$pr" || true
    else
      echo "  would delete  ${ref#refs/heads/}  (merged via PR #$pr)"
    fi
    i=$((i + 1))
  done
  # A partial result must never read as a complete one.
  [ "$sq_errors" -gt 0 ] && echo "  ($sq_errors more branch(es) could not be verified — KEPT; this list is INCOMPLETE)"
fi
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
  local wt_sha=""
  if list_has "$git_merged_names" "$short"; then
    via="git"
  elif [ "$squash_merged" != "1" ]; then
    # Same cost gate as section 1b: this ran BEFORE the flag check and was the bulk of the
    # 25-call / 20.6s plain dry-run.
    echo "  KEEP (not merged per git; pass --squash-merged to also check for a squash merge)  $path  [$short]"
    return
  else
    # Resolve via the FULL ref, never the bare short name: with a tag of the same name,
    # `git rev-parse decoy` picks the TAG, so evidence — and the recovery handle — would describe
    # the wrong commit. `$branch` is already refs/heads/<name> here.
    wt_sha="$(git rev-parse --verify --quiet "${branch:-refs/heads/$short}^{commit}" 2>/dev/null || true)"
    if [ -z "$wt_sha" ]; then
      echo "  KEEP (cannot resolve tip — NOT 'unmerged')  $path  [$short]"
      return
    fi
    wt_pr="$(merged_pr_for "$wt_sha")"
    if [ "$wt_pr" = "ERR" ]; then
      echo "  KEEP (could not verify — lookup failed, NOT 'unmerged')  $path  [$short]"
      return
    fi
    if [ -z "$wt_pr" ]; then
      echo "  KEEP (not a merged feature branch)  $path  [$short]"
      return
    fi
    via="squash-PR#$wt_pr"
  fi
  if [ "$apply" = "1" ]; then
    if git worktree remove "$path" 2>/dev/null; then
      echo "  removed  $path  [$short]  ($via)"
      # -d for git-native evidence; the shared CAS destroy for the evidence-based path.
      # `git worktree remove` refuses a DIRTY worktree but not a clean one whose tip advanced, so
      # this path needs the same compare-and-swap the loose-branch path has — it is the identical
      # destructive act on the identical kind of ref.
      if [ "$via" = "git" ]; then
        git branch -d -- "$short" 2>/dev/null && echo "    + deleted branch $short" || true
      else
        printf '  '   # keep destroy_branch's line aligned under the worktree it belongs to
        destroy_branch "${branch:-refs/heads/$short}" "$wt_sha" "$via" || true
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
  done < <(git branch -r --merged "$integration_ref" 2>/dev/null)
  if [ "$any" = "0" ]; then
    echo "  (none)"
    # Say what this section can and cannot see. It uses ONLY the git-native predicate, which in a
    # squash-merge repo returns 0 rows by construction — the same dead-end that made §1 useless and
    # is this feature's whole reason for existing. Printing a bare "(none)" here would repeat the
    # original sin one section further down: a guard that reports "nothing to do" when what it means
    # is "I cannot see anything from here". Remote squash-merged branches are NOT handled (FU-9).
    [ "$squash_merged" = "1" ] && \
      echo "   NB: this section uses only \`git branch -r --merged\`, which a squash-merge repo makes"
    [ "$squash_merged" = "1" ] && \
      echo "       return nothing. --squash-merged does NOT extend here — remote branches need manual"
    [ "$squash_merged" = "1" ] && \
      echo "       cleanup or GitHub's auto-delete-on-merge. This is 'not checked', not 'nothing found'."
  fi
  echo
fi

echo "== done ($mode) =="
