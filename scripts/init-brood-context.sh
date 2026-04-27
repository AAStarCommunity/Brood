#!/usr/bin/env bash
# init-brood-context.sh
# 为目标 repo 添加 Mycelium Protocol 生态上下文引用
# 用法: ./scripts/init-brood-context.sh [repo路径] [org-id]
# 示例: ./scripts/init-brood-context.sh ../aastar/AirAccount aastar
#
# org-id 可选: aastar | auraai | mycelium
#              默认: aastar

set -e

# ── 颜色输出 ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# ── 参数 ──────────────────────────────────────────────────────────────────────
REPO_PATH="${1:-.}"                  # 目标 repo 路径，默认当前目录
ORG_ID="${2:-aastar}"                # 组织 ID，默认 aastar

# ── 路径检测 ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BROOD_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Brood Context Initializer — Mycelium Protocol        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

info "BroodBrain 路径: ${BROOD_ROOT}"
info "目标 repo:       $(cd "${REPO_PATH}" && pwd)"
info "组织 ID:         ${ORG_ID}"
echo ""

# ── 前置检查 ──────────────────────────────────────────────────────────────────
# 1. 检查 Brood 路径
[ -d "${BROOD_ROOT}/protocol" ]              || err "Brood protocol/ 目录不存在: ${BROOD_ROOT}/protocol"
[ -d "${BROOD_ROOT}/orgs/${ORG_ID}" ]        || err "组织目录不存在: ${BROOD_ROOT}/orgs/${ORG_ID}\n  可用 org-id: $(ls ${BROOD_ROOT}/orgs/ | grep -v template | tr '\n' ' ')"
[ -f "${BROOD_ROOT}/protocol/MISSION.md" ]   || err "缺少 protocol/MISSION.md"

PROFILE_FILE="${BROOD_ROOT}/orgs/${ORG_ID}/PROFILE.md"
INTERFACES_FILE="${BROOD_ROOT}/orgs/${ORG_ID}/INTERFACES.md"

[ -f "${PROFILE_FILE}" ]     || err "缺少 orgs/${ORG_ID}/PROFILE.md"
[ -f "${INTERFACES_FILE}" ]  || warn "orgs/${ORG_ID}/INTERFACES.md 不存在（将只引用 MISSION.md 和 PROFILE.md）"

ok "Brood 文件检查通过"

# 2. 检查目标 repo
[ -d "${REPO_PATH}" ]          || err "目标 repo 路径不存在: ${REPO_PATH}"
cd "${REPO_PATH}"
[ -d ".git" ]                  || err "目标路径不是 git 仓库: $(pwd)"
REPO_ABS="$(pwd)"

ok "目标 repo 检查通过: ${REPO_ABS}"

# ── 生成 @-include 片段 ────────────────────────────────────────────────────────
HAS_INTERFACES=false
[ -f "${INTERFACES_FILE}" ] && HAS_INTERFACES=true

SNIPPET="## Mycelium Protocol 生态上下文
> 本 repo 属于 ${ORG_ID} 组织，参与 Mycelium Protocol 生态建设。
> 上下文来源: github.com/AAStarCommunity/Brood — 更新时自动同步

@${BROOD_ROOT}/protocol/MISSION.md
@${BROOD_ROOT}/orgs/${ORG_ID}/PROFILE.md"

if $HAS_INTERFACES; then
  SNIPPET="${SNIPPET}
@${BROOD_ROOT}/orgs/${ORG_ID}/INTERFACES.md"
fi

# ── 处理 CLAUDE.md ────────────────────────────────────────────────────────────
CLAUDE_MD="${REPO_ABS}/CLAUDE.md"

if [ ! -f "${CLAUDE_MD}" ]; then
  # 创建新的 CLAUDE.md
  info "CLAUDE.md 不存在，创建新文件..."
  cat > "${CLAUDE_MD}" << HEREDOC
# CLAUDE.md

${SNIPPET}

## Project Overview

> TODO: 描述本 repo 的用途、架构和开发指引
HEREDOC
  ok "已创建 ${CLAUDE_MD}"

elif grep -q "Mycelium Protocol 生态上下文" "${CLAUDE_MD}" 2>/dev/null; then
  # 已有引用，检查是否需要更新
  EXISTING_PATH=$(grep -E "^@.*/MISSION\.md" "${CLAUDE_MD}" | head -1 | sed 's/^@//')
  # 用 realpath 或 stat 规范化路径（处理大小写 macOS 差异）
  normalize_path() {
    local p="$1"
    if [ -e "$p" ]; then
      # 文件存在则取真实路径
      cd "$(dirname "$p")" 2>/dev/null && echo "$(pwd)/$(basename "$p")" || echo "$p"
    else
      echo "$p"
    fi
  }
  EXISTING_NORM=$(normalize_path "${EXISTING_PATH}")
  CURRENT_NORM=$(normalize_path "${BROOD_ROOT}/protocol/MISSION.md")

  if [ "${EXISTING_NORM}" = "${CURRENT_NORM}" ]; then
    ok "CLAUDE.md 已包含正确的 Brood 上下文引用，无需更新"
    ALREADY_DONE=true
  else
    warn "CLAUDE.md 已有 Brood 引用，但路径不同"
    info "  现有路径: ${EXISTING_PATH}"
    info "  当前路径: ${BROOD_ROOT}/protocol/MISSION.md"
    echo ""
    read -p "是否更新路径? [y/N] " -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      OLD_BROOD=$(echo "${EXISTING_PATH}" | sed 's|/protocol/MISSION.md||')
      sed -i '' "s|${OLD_BROOD}|${BROOD_ROOT}|g" "${CLAUDE_MD}"
      ok "路径已更新"
    fi
  fi

else
  # 在 CLAUDE.md 开头（# CLAUDE.md 之后）插入片段
  info "在 CLAUDE.md 中插入 Brood 上下文引用..."

  # 找到第一个非注释、非空行后的位置
  TMPFILE=$(mktemp)

  awk -v snippet="${SNIPPET}" '
    NR==1 && /^# CLAUDE/ { print; print ""; print snippet; print ""; next }
    NR==1 { print snippet; print ""; print; next }
    { print }
  ' "${CLAUDE_MD}" > "${TMPFILE}"

  mv "${TMPFILE}" "${CLAUDE_MD}"
  ok "已更新 ${CLAUDE_MD}"
fi

# ── 验证结果 ──────────────────────────────────────────────────────────────────
echo ""
echo "── 验证结果 ──────────────────────────────────────────────────────"

PASS=0; FAIL=0

check() {
  local desc="$1"; local file="$2"
  if grep -q "$(basename "${file}")" "${CLAUDE_MD}" 2>/dev/null; then
    ok "${desc}"
    ((PASS++)) || true
  else
    warn "${desc} — 未找到引用"
    ((FAIL++)) || true
  fi
}

check "MISSION.md 已引用"    "${BROOD_ROOT}/protocol/MISSION.md"
check "PROFILE.md 已引用"    "${PROFILE_FILE}"
$HAS_INTERFACES && check "INTERFACES.md 已引用" "${INTERFACES_FILE}"

echo ""
if [ $FAIL -eq 0 ]; then
  ok "所有检查通过 (${PASS}/${PASS})"
else
  warn "${FAIL} 项未通过，请检查 ${CLAUDE_MD}"
fi

# ── 使用说明 ──────────────────────────────────────────────────────────────────
if [ "${ALREADY_DONE:-false}" != "true" ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║                      下一步                                  ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
  info "1. 在 ${REPO_ABS} 目录打开 Claude Code:"
  echo "     cd ${REPO_ABS} && claude"
  echo ""
  info "2. 测试上下文是否生效（输入以下问题）:"
  echo "     \"你是否了解 Mycelium Protocol？SuperPaymaster 在生态中的位置是什么？\""
  echo ""
  info "3. 详细验证步骤参见:"
  echo "     ${BROOD_ROOT}/docs/brood-context-verify-steps.md"
  echo ""
fi

echo ""
echo "完成 🍄"
echo ""
