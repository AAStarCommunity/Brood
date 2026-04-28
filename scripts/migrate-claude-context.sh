#!/usr/bin/env bash
# migrate-claude-context.sh
# 迁移 Claude Code 项目上下文（memory + sessions）到新目录路径
#
# 用法:
#   ./migrate-claude-context.sh <旧目录> <新目录>
#
# 示例:
#   ./migrate-claude-context.sh \
#     /Users/jason/Dev/mycelium/my-exploration/projects/SuperPaymaster \
#     /Users/jason/Dev/aastar/SuperPaymaster
#
# 注意: 仅复制 memory/ 子目录（最有价值的部分）。
#       对话历史（.jsonl 文件）体积大且多为临时内容，默认不复制。
#       加 --full 参数可复制全部内容。

set -e

CLAUDE_PROJECTS="$HOME/.claude/projects"

if [ $# -lt 2 ]; then
  echo "用法: $0 <旧目录绝对路径> <新目录绝对路径> [--full]"
  echo ""
  echo "示例:"
  echo "  $0 /Users/jason/Dev/old/SuperPaymaster /Users/jason/Dev/aastar/SuperPaymaster"
  exit 1
fi

OLD_PATH="$1"
NEW_PATH="$2"
FULL_COPY="${3:-}"

# 路径转 Claude Code 目录名：/ → -
path_to_dirname() {
  echo "$1" | sed 's|^/|-|' | sed 's|/|-|g'
}

OLD_DIR=$(path_to_dirname "$OLD_PATH")
NEW_DIR=$(path_to_dirname "$NEW_PATH")

OLD_CONTEXT="${CLAUDE_PROJECTS}/${OLD_DIR}"
NEW_CONTEXT="${CLAUDE_PROJECTS}/${NEW_DIR}"

echo "📍 旧上下文: ${OLD_CONTEXT}"
echo "📍 新上下文: ${NEW_CONTEXT}"
echo ""

# 检查旧上下文是否存在
if [ ! -d "$OLD_CONTEXT" ]; then
  echo "❌ 旧路径没有 Claude Code 上下文: ${OLD_CONTEXT}"
  echo "   可能该目录从未在 Claude Code 中打开过。"
  exit 1
fi

# 检查新上下文是否已存在
if [ -d "$NEW_CONTEXT" ]; then
  echo "⚠️  新路径已有 Claude Code 上下文: ${NEW_CONTEXT}"
  echo "   现有内容:"
  ls -la "$NEW_CONTEXT/"
  echo ""
  read -p "是否合并（memory 会被覆盖）？[y/N] " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "已取消。"
    exit 0
  fi
fi

# 创建新上下文目录
mkdir -p "$NEW_CONTEXT"

if [ "$FULL_COPY" = "--full" ]; then
  echo "📦 复制全部上下文（memory + sessions + conversations）..."
  cp -R "$OLD_CONTEXT/"* "$NEW_CONTEXT/" 2>/dev/null || true
else
  echo "📦 复制 memory/（最有价值的部分）..."
  if [ -d "$OLD_CONTEXT/memory" ]; then
    cp -R "$OLD_CONTEXT/memory" "$NEW_CONTEXT/"
    echo "   ✅ memory/ 已复制"
  else
    echo "   ⚠️  旧上下文没有 memory/ 目录"
  fi

  # 复制 CLAUDE.md（项目级指令）如果存在
  if [ -f "$OLD_CONTEXT/CLAUDE.md" ]; then
    cp "$OLD_CONTEXT/CLAUDE.md" "$NEW_CONTEXT/"
    echo "   ✅ CLAUDE.md 已复制"
  fi
fi

echo ""
echo "✅ 迁移完成！"
echo ""
echo "旧上下文保留在: ${OLD_CONTEXT}"
echo "新上下文已就绪: ${NEW_CONTEXT}"
echo ""
echo "提示: 确认新目录工作正常后，可删除旧上下文:"
echo "  rm -rf \"${OLD_CONTEXT}\""
