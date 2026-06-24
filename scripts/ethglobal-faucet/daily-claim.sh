#!/bin/bash
# daily-claim.sh — ETHGlobal faucet cron wrapper
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$DIR/logs"
LOG="$DIR/logs/claim-$(date +%Y%m%d-%H%M%S).log"
cd "$DIR"
echo "=== $(date) ===" | tee -a "$LOG"
[ ! -d node_modules ] && pnpm install 2>&1 | tee -a "$LOG"
node claim.js 2>&1 | tee -a "$LOG"
echo "Exit: ${PIPESTATUS[0]} — $(date)" | tee -a "$LOG"
find "$DIR/logs" -name "claim-*.log" -mtime +30 -delete
