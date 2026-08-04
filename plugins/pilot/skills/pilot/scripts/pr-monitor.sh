#!/usr/bin/env bash
# pr-monitor.sh — report review state of MY open PRs on this repo, compactly.
#
# pilot does NOT review its own PRs — an external review service does, under the contract in
# reference/review-contract.md: a PR is queued within ~5-10 min and a verdict lands within ~5-10
# more, so ~20 min end to end (large PRs excepted). What that service *is*, where it runs, and
# which repos it covers are operational details pilot deliberately does not know about.
#
# This script is only the "did my PR get a verdict yet?" probe — one query, no loop of its own.
# Poll it every 3-5 min after opening a PR (via the Monitor tool or /loop), then act on the verdict.
#
# reviewDecision values: APPROVED | CHANGES_REQUESTED | REVIEW_REQUIRED | (empty)
#
# Usage: pr-monitor.sh [--pr <number>]   (omit --pr to list all of my open PRs)
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "PR_MONITOR: gh-not-installed"; exit 0
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "PR_MONITOR: gh-not-authenticated"; exit 0
fi

pr=""
[ "${1:-}" = "--pr" ] && pr="${2:-}"

fields="number,title,headRefName,reviewDecision,mergeable,isDraft,url,statusCheckRollup"

if [ -n "$pr" ]; then
  gh pr view "$pr" --json "$fields" --jq '
    "PR #\(.number) [\(.headRefName)] \(.title)\n" +
    "  reviewDecision=\(.reviewDecision // "PENDING")  mergeable=\(.mergeable)  draft=\(.isDraft)\n" +
    "  checks=\([.statusCheckRollup[]? | .conclusion // .state] | join(",") | if . == "" then "none" else . end)\n" +
    "  \(.url)"'
  exit 0
fi

echo "PR_MONITOR: my open PRs on this repo"
count="$(gh pr list --author "@me" --state open --json number --jq 'length')"
if [ "$count" = "0" ]; then
  echo "  (none open)"
  exit 0
fi
gh pr list --author "@me" --state open --json "$fields" --jq '.[] |
  "PR #\(.number) [\(.headRefName)]  decision=\(.reviewDecision // "PENDING")  draft=\(.isDraft)\n" +
  "  checks=\([.statusCheckRollup[]? | .conclusion // .state] | join(",") | if . == "" then "none" else . end)  \(.url)"'
