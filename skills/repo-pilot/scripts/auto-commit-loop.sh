#!/usr/bin/env bash
# auto-commit-loop.sh — drive auto-commit.sh on a short interval so 定量 triggers
# (>3 files / >200-line single-file change) fire within ~$POLL seconds, and the 定时
# 10-min timer is honored. Run it in the repo you're working in; detach with nohup.
#
#   nohup bash <skill>/scripts/auto-commit-loop.sh >/tmp/pilot-autocommit.log 2>&1 &
#   # stop:  pkill -f auto-commit-loop.sh
#
# One loop per repo. Never pushes, never touches main (auto-commit.sh refuses protected branches).
set -euo pipefail
POLL="${PILOT_AUTOCOMMIT_POLL:-120}"   # check every 2 min → 定量 fires within ~2 min
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "auto-commit-loop: started (poll=${POLL}s, interval=${PILOT_AUTOCOMMIT_INTERVAL:-600}s) in $(pwd)"
while true; do
  bash "$here/auto-commit.sh" || true
  sleep "$POLL"
done
