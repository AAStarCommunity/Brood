#!/usr/bin/env bash
# local-sync-cron.sh
# 本地自动运行 /sync-progress skill
# 由 macOS launchd 每 2 天调用一次
# 不需要 sudo，不需要远程 agent，直接使用本地 repos

set -e

BROOD_DIR="/Users/jason/Dev/Brood"
LOG_DIR="${BROOD_DIR}/logs"
LOG_FILE="${LOG_DIR}/sync-progress-$(date +%Y-%m-%d).log"

mkdir -p "${LOG_DIR}"

echo "======================================" | tee -a "${LOG_FILE}"
echo "sync-progress 开始: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "======================================" | tee -a "${LOG_FILE}"

cd "${BROOD_DIR}"

# 检查 claude CLI 是否存在
if ! command -v claude &>/dev/null; then
  echo "❌ claude CLI 未找到，请确认已安装 Claude Code" | tee -a "${LOG_FILE}"
  exit 1
fi

# 运行 sync-progress skill（非交互模式，跳过权限确认）
claude --dangerously-skip-permissions -p "/sync-progress" 2>&1 | tee -a "${LOG_FILE}"

echo "" | tee -a "${LOG_FILE}"
echo "✅ sync-progress 完成: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"

# 保留最近 14 天的日志，删除更早的
find "${LOG_DIR}" -name "sync-progress-*.log" -mtime +14 -delete 2>/dev/null || true
