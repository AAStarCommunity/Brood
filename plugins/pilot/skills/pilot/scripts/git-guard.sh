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
#   git-guard.sh merge-pr <n> --integration <branch> [--allow-trunk] [allowlisted gh flags]
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
  pr-create)
    # Opening a PR is the moment work becomes someone else's problem, so it is the right place to
    # require that the repo's own checks actually ran on THIS commit. `preflight.sh` writes a stamp
    # bound to the HEAD sha; no stamp, or a stamp for different code, means the checks were never
    # run against what is about to be published — refuse rather than let CI (or a human reviewer)
    # discover it 20 minutes later. Every review round burned in this repo started exactly here.
    here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ "${PILOT_SKIP_PREFLIGHT:-0}" = "1" ]; then
      # Deliberate, visible escape hatch. It prints to stderr and names itself so an override can
      # never be silent — an override nobody can see is indistinguishable from a missing check.
      echo "git-guard: WARNING — PILOT_SKIP_PREFLIGHT=1, opening PR without verified checks" >&2
    else
      if ! bash "$here/preflight.sh" check >/dev/null 2>&1; then
        # `|| true` matters: under `set -e -o pipefail` this pipeline inherits preflight's non-zero
        # status and would abort the script HERE — refusing correctly, but without ever printing the
        # `die` message that says what to run. The refusal is useless if it doesn't say how to fix it.
        bash "$here/preflight.sh" check 2>&1 | sed 's/^/  /' >&2 || true
        die "refusing to open a PR: this commit's checks have not passed.
  Run:  bash $here/preflight.sh run
  Then re-run this command. (Override for a genuine emergency: PILOT_SKIP_PREFLIGHT=1)"
      fi
      # Surface the mechanically-derived grade so the required self-review depth is not a matter of
      # the author's own opinion. A/B demand three adversarial rounds before this PR is opened.
      grade="$(sed -n 's/^grade=//p' "$(git rev-parse --git-dir)/pilot-preflight" 2>/dev/null)"
      # Catch-all, not `A|B`: an empty or `unknown` grade means grade-change.sh could not run (e.g.
      # the integration branch is not fetched, so it refuses rather than downgrading to D). Only an
      # explicitly computed C/D may lower the bar — anything else gets the strictest requirement.
      case "$grade" in
        C|D) echo "git-guard: grade $grade" >&2 ;;
        *)   echo "git-guard: grade ${grade:-unknown} — reference/pre-pr-review.md requires 3 adversarial rounds before this PR." >&2 ;;
      esac
    fi
    exec gh pr create "$@"
    ;;
  merge-pr)
    n="${1:-}"; [ $# -gt 0 ] && shift
    integration=""
    allow_trunk=0
    args=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --integration)
          [ $# -ge 2 ] || die "--integration requires a value"
          integration="$2"; shift 2 ;;
        # Single-trunk repos (no integration branch) are a legitimate shape — this repo is one.
        # Without an escape hatch the rail is simply unusable there, and an unusable guard gets
        # routed around with a bare `gh pr merge`, which teaches people to route around guards.
        # So: opt in explicitly, and the opt-in still has to PROVE the danger is handled (below).
        --allow-trunk) allow_trunk=1; shift ;;
        # ---- ALLOWLIST, not a denylist -------------------------------------------------------
        # A denylist can only refuse the dangerous flags that exist TODAY. When `gh pr merge`
        # grows a new one that defeats branch protection, a denylist silently passes it through
        # and nothing here notices. An allowlist fails the other way: an unrecognised flag is
        # refused until someone deliberately adds it — which is the direction a guard should
        # fail. (The previously-denied `--admin` / `--repo` / `-R` / `--delete-branch` are simply
        # absent from the list below; the two that people actually reach for keep their specific
        # error messages so the refusal explains itself.)
        --squash|--merge|--rebase|--auto) args+=("$1"); shift ;;
        # Value-taking, in both the separate and attached forms.
        --body|-b|--body-file|-F|--subject|-t|--match-head-commit)
          [ $# -ge 2 ] || die "'$1' requires a value"
          args+=("$1" "$2"); shift 2 ;;
        --body=*|--body-file=*|--subject=*|--match-head-commit=*) args+=("$1"); shift ;;
        # Kept as named refusals purely for the message — the allowlist would reject them anyway.
        --admin|--admin=*|--repo|--repo=*|-R|-R*)
          die "refusing '$1' on merge-pr — it would bypass the safety rail" ;;
        -d|--delete-branch|--delete-branch=*)
          die "refusing '$1' on merge-pr — deletes the PR head branch; clean up branches via safe-cleanup.sh" ;;
        -*)
          die "refusing unrecognised flag '$1' on merge-pr — this is an ALLOWLIST.
  Permitted: --squash --merge --rebase --auto --body/-b --body-file/-F --subject/-t --match-head-commit
  If '$1' is genuinely safe, add it to the allowlist in git-guard.sh with a note on why." ;;
        *)
          die "refusing extra positional argument '$1' on merge-pr — the PR number is the first argument and there are no others" ;;
      esac
    done
    [ -n "$n" ] || die "usage: git-guard.sh merge-pr <n> --integration <branch> [--allow-trunk] [gh args]"
    [ -n "$integration" ] || die "merge-pr requires --integration <branch>"
    command -v gh >/dev/null 2>&1 || die "gh not installed"
    # Pin the repo so the base check and the actual merge target the SAME repo.
    repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)"
    [ -n "$repo" ] || die "cannot resolve current repo (gh auth / not inside a gh repo?)"
    # Trunk-ness by NAME plus by the repo's actual DEFAULT branch — the latter catches any trunk
    # name (`trunk`/`production`) the list misses. NB: is_protected() can't be used here — the
    # integration branch itself is in $PROTECTED (run.md §0 threads it in via --protect for
    # push-protection), so is_protected("$integration") would always be true.
    # `gh repo view` takes the repo as a POSITIONAL arg — it has no `--repo` flag (unlike `gh pr
    # view/merge`, which do). Passing `--repo` makes gh print its help to stdout and exit 1, so
    # this captured EMPTY and merge-pr died on the next line — for every repo and every
    # integration branch. The rail was not strict here, it was simply dead; verified against
    # gh 2.92.0. Keep the argument positional.
    def_branch="$(gh repo view "$repo" --json defaultBranchRef --jq .defaultBranchRef.name 2>/dev/null || true)"
    [ -n "$def_branch" ] || die "cannot resolve repo default branch — refusing merge-pr until the trunk check is verifiable"
    is_trunk=0
    case "$integration" in
      main|master|develop|release|release*|hotfix|hotfix*) is_trunk=1 ;;
    esac
    [ "$integration" = "$def_branch" ] && is_trunk=1
    # Default: refuse trunk. `.pilot.yml` falls back integration→base_branch, and a stale
    # `.repo-pilot.yml` can carry integration=master — either would merge PRs straight into trunk
    # (violating "绝不直接合并到主干"). PRs merge into an integration branch (preview), never trunk.
    if [ "$is_trunk" = "1" ] && [ "$allow_trunk" != "1" ]; then
      die "integration '$integration' is a trunk branch — merge PRs into an integration branch (e.g. preview), not trunk.
  Single-trunk repo with no integration branch? Pass --allow-trunk. It is NOT a bypass: the merge
  still only proceeds when branch protection requires an approving review AND this PR has one."
    fi
    if [ "$is_trunk" = "1" ]; then
      # --allow-trunk relaxes WHERE we may merge, never WHETHER the work was reviewed. The rail
      # exists to stop "self-merging into trunk unreviewed"; on a single-trunk repo that danger is
      # handled by GitHub branch protection, which is server-side and therefore stronger than this
      # script. So require PROOF of it rather than taking the flag's word — and fail CLOSED when
      # the proof cannot be read.
      #
      # NB: this deliberately does NOT check `enforce_admins`. It is not load-bearing here — the
      # `reviewDecision == APPROVED` check below is enforced by this script regardless of who is
      # merging, so an admin-bypassable branch still cannot get an unapproved PR through this
      # path. (Brood happens to enable it, but that is a property of one repo, not a guarantee
      # this rail relies on. Saying otherwise in a comment would make the argument rest on
      # something never verified.)
      # stdout ONLY. `gh api` puts BOTH the success object and the error body (which carries
      # `message`) on stdout, so one capture serves both paths. Do NOT fold in stderr: anything
      # else on it — a shell hook's diagnostics, gh's own "(HTTP 404)" line — lands inside the
      # captured text and makes the JSON unparseable, which silently degrades every branch below
      # to "cannot read protection". (Measured: merging stderr broke the working case.)
      prot="$(gh api "repos/$repo/branches/$integration/protection" 2>/dev/null || true)"
      # `2>&1` above keeps the API's error BODY (it carries `message`), so parse the captured text
      # rather than re-querying. Only a real protection object yields a number; anything else
      # (error JSON, empty, HTML) falls through to the fail-closed branch below.
      approvals="$(printf '%s' "$prot" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if isinstance(d, dict) and "required_pull_request_reviews" in d:
    print((d.get("required_pull_request_reviews") or {}).get("required_approving_review_count") or 0)
' 2>/dev/null || true)"
      case "$approvals" in
        ''|*[!0-9]*)
          # Split the two causes — they need opposite fixes (rotate the token vs. protect the
          # branch), and the API already tells us which one it is in its `message` field.
          why="$(printf '%s' "$prot" | python3 -c 'import json,sys
try:
    print((json.load(sys.stdin) or {}).get("message") or "")
except Exception:
    print("")
' 2>/dev/null || true)"
          case "$why" in
            *"Branch not protected"*|*"Branch not found"*)
              die "--allow-trunk: branch '$integration' has no protection rule (GitHub said: $why) — refusing.
  Protect the branch and require at least one approving review first; without that, merging into
  trunk really is an unreviewed self-merge." ;;
            *)
              die "--allow-trunk: cannot read branch protection for '$integration'${why:+ (GitHub said: $why)} — refusing.
  Reading protection needs admin rights on the repo; re-run with a token that has them.
  Refusing rather than assuming, because unverified protection is the same as none." ;;
          esac ;;
      esac
      [ "$approvals" -ge 1 ] || die "--allow-trunk: branch '$integration' does not require an approving review (required_approving_review_count=$approvals) — refusing.
  Protect the branch first; otherwise merging into trunk really is unreviewed self-merge."
      decision="$(gh pr view "$n" --repo "$repo" --json reviewDecision --jq '.reviewDecision // ""' 2>/dev/null || true)"
      [ "$decision" = "APPROVED" ] || die "--allow-trunk: PR #$n reviewDecision is '${decision:-unknown}', not APPROVED — refusing.
  Wait for the verdict (see reference/review-contract.md). Never self-approve, never --admin."
      echo "git-guard: --allow-trunk on '$integration' — protection requires $approvals approval(s), PR #$n is APPROVED" >&2
    fi
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
    echo "git-guard.sh: add <path...> | push <remote> <branch> | merge-pr <n> --integration <b> [--allow-trunk] [gh args]" >&2
    exit 2 ;;
esac
