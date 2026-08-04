#!/usr/bin/env bash
# pr-monitor.sh — has MY PR received an ACTIONABLE verdict yet?
#
# pilot does NOT review its own PRs — an external review service does, under the contract in
# reference/review-contract.md: queued within ~5-10 min, verdict within ~5-10 more, ~20 min end to
# end (large PRs excepted). What that service *is*, where it runs, and which repos it covers are
# operational details pilot deliberately does not know.
#
#   pr-monitor.sh                          list my open PRs on this repo (one shot)
#   pr-monitor.sh --pr <n>                 one shot, single PR
#   pr-monitor.sh --pr <n> --wait-for-verdict [--max-min 30]
#                                          stay silent until a FRESH verdict exists, print once
#
# Two things this script exists to get right, both learned the hard way:
#
# 1. FRESHNESS. GitHub keeps `reviewDecision=CHANGES_REQUESTED` across pushes — a push dismisses
#    approvals at most, never a changes-requested review. So "decision != PENDING" cannot tell a
#    fresh verdict from one about code you already replaced; an agent acting on it re-triages
#    findings it already fixed, forever. Only `review_sha == head_sha` proves the verdict describes
#    what is on the branch now. That SHA must come from the REST reviews endpoint:
#    `gh pr view --json latestReviews` returns an EMPTY `commit.oid` (verified — REST returns the
#    real SHA for the very same review), so a check built on it silently degrades to "never fresh".
#
# 2. WAITABILITY. The one-shot form prints immediately, so wrapping it in the Monitor tool fires on
#    the first sample within seconds and stops — the documented 3-5 min cadence and the 30-min cap
#    never happen at all. `--wait-for-verdict` stays SILENT while pending and prints exactly once,
#    when a fresh verdict lands or the cap is hit. That is what makes waiting real.
#
# `wait_min` (not `age_min`) drives the timeout rule: age_min counts from PR creation, so on any
# re-review round it is already far past the cap the moment waiting starts, and the "no review
# service" branch would fire on a PR that is being actively reviewed.
#
# Exit: 0 = printed (fresh verdict, or one-shot report), 3 = --wait-for-verdict hit the cap.
set -uo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "PR_MONITOR: gh-not-installed"; exit 0
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "PR_MONITOR: gh-not-authenticated"; exit 0
fi

pr=""
wait_mode=0
max_min="${PILOT_VERDICT_MAX_MIN:-30}"
poll_sec="${PILOT_VERDICT_POLL_SEC:-240}"
while [ $# -gt 0 ]; do
  case "$1" in
    --pr)               pr="${2:-}"; shift 2 ;;
    --wait-for-verdict) wait_mode=1; shift ;;
    --max-min)          max_min="${2:-30}"; shift 2 ;;
    *) shift ;;
  esac
done

FIELDS="number,title,headRefName,reviewDecision,mergeable,isDraft,url,statusCheckRollup,createdAt,headRefOid"

# Print one PR's status, resolving verdict freshness against the REST reviews endpoint.
report_one() {
  local n="$1" repo raw reviews
  repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)" || repo=""
  raw="$(gh pr view "$n" --json "$FIELDS" 2>/dev/null)" || return 1
  [ -n "$raw" ] || return 1
  reviews="[]"
  if [ -n "$repo" ]; then
    reviews="$(gh api "repos/$repo/pulls/$n/reviews" --paginate 2>/dev/null || echo '[]')"
  fi
  PR_JSON="$raw" REVIEWS_JSON="$reviews" python3 <<'PY'
import json, os
from datetime import datetime, timezone

def mins_since(ts):
    try:
        return int((datetime.now(timezone.utc)
                    - datetime.fromisoformat(ts.replace("Z", "+00:00"))).total_seconds() // 60)
    except Exception:
        return -1

pr = json.loads(os.environ["PR_JSON"])
try:
    reviews = json.loads(os.environ.get("REVIEWS_JSON") or "[]")
except Exception:
    reviews = []
if not isinstance(reviews, list):
    reviews = []
reviews = [r for r in reviews if isinstance(r, dict) and r.get("commit_id")]
last = reviews[-1] if reviews else {}

head = pr.get("headRefOid") or ""
rsha = last.get("commit_id") or ""
rsub = last.get("submitted_at") or ""

raw_decision = pr.get("reviewDecision") or ""
if raw_decision in ("", "REVIEW_REQUIRED"):
    raw_decision = "PENDING"

# A verdict counts only when it was posted ON the current head.
verdict = raw_decision if (raw_decision != "PENDING" and rsha and rsha == head) else "PENDING"

wait_min = mins_since(rsub) if rsub else mins_since(pr.get("createdAt") or "")
age_min = mins_since(pr.get("createdAt") or "")
checks = [c.get("conclusion") or c.get("state") for c in (pr.get("statusCheckRollup") or [])]

print(f'PR #{pr.get("number")} [{pr.get("headRefName")}] {pr.get("title","")}')
print(f'  verdict={verdict}  raw_decision={raw_decision}  '
      f'head_sha={head[:7]}  review_sha={rsha[:7] or "-"}')
print(f'  wait_min={wait_min}  age_min={age_min}  '
      f'mergeable={pr.get("mergeable")}  draft={pr.get("isDraft")}')
print(f'  checks={",".join(x for x in checks if x) or "none"}')
print(f'  {pr.get("url")}')
PY
}

if [ -n "$pr" ] && [ "$wait_mode" = "1" ]; then
  deadline=$(( $(date +%s) + max_min * 60 ))
  while :; do
    out="$(report_one "$pr" 2>/dev/null || true)"
    case "$out" in
      *"verdict=APPROVED"*|*"verdict=CHANGES_REQUESTED"*)
        printf '%s\n' "$out"; exit 0 ;;
    esac
    if [ "$(date +%s)" -ge "$deadline" ]; then
      # Say why we stopped — silence would be indistinguishable from "still waiting".
      echo "PR_MONITOR: TIMEOUT after ${max_min}m — no verdict on the current head."
      printf '%s\n' "$out"
      echo "  → Read as: no review service is covering this repo right now. Tell the user,"
      echo "    move on to the next task, and NEVER self-approve or --admin around it."
      exit 3
    fi
    sleep "$poll_sec"
  done
fi

if [ -n "$pr" ]; then
  report_one "$pr"
  exit 0
fi

echo "PR_MONITOR: my open PRs on this repo"
nums="$(gh pr list --author "@me" --state open --json number --jq '.[].number' 2>/dev/null)"
if [ -z "$nums" ]; then
  echo "  (none open)"
  exit 0
fi
for n in $nums; do
  report_one "$n"
done
