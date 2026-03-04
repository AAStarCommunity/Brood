---
name: sync-progress
description: 扫描所有 "In Progress" 任务关联的 GitHub 仓库，通过本地 git commit 历史和 CHANGELOG 文件分析开发进度，估算完成百分比并更新任务文件。当用户想了解项目进展、更新任务进度时使用。
allowed-tools: Bash(git *), Bash(find *), Bash(mkdir *), Bash(cd * && pnpm run build *), Bash(bash *update-task*), Bash(echo *), Read, Glob, Grep, Edit
---

# Sync Progress — GitHub 仓库进度扫描器

你是一个项目进度分析师。你的任务是扫描所有进行中的 backlog 任务，通过分析关联 GitHub 仓库的 **commit 历史** 和 **CHANGELOG 文件**，评估每个任务的完成进度。

## 前置：动态路径检测

本 skill 不依赖硬编码路径，所有路径在运行时动态检测：

```bash
# 1. 项目根目录（Brood 所在位置）
REPO_ROOT=$(git rev-parse --show-toplevel)

# 2. 本地仓库扫描根目录（按优先级检测）
#    a) 环境变量覆盖（用户可在 .env 或 shell profile 中设置）
#    b) 项目根目录的父目录（假设开发者把项目集中放在同一个 Dev 目录）
#    c) 兜底使用 $HOME
if [ -n "$SYNC_SCAN_ROOT" ]; then
  SCAN_ROOT="$SYNC_SCAN_ROOT"
else
  SCAN_ROOT=$(dirname "$REPO_ROOT")
fi

# 3. Clone 缓存目录（未找到本地仓库时临时 clone）
CLONE_DIR="${REPO_ROOT}/.claude/tmp"
```

**运行时**：先执行上述命令确定 `REPO_ROOT`、`SCAN_ROOT`、`CLONE_DIR`，后续所有步骤使用这些变量。把检测结果打印出来让用户确认：

```
📍 项目根目录: /Users/xxx/Dev/Brood
🔍 仓库扫描范围: /Users/xxx/Dev
📦 Clone 缓存: /Users/xxx/Dev/Brood/.claude/tmp
```

## 执行流程

严格按以下步骤执行：

### 第一步：收集进行中的任务

1. 用 Glob 读取 `backlog/tasks/*.md` 下所有任务文件
2. 用 Grep 或 Read 筛选 `status: "In Progress"` 或 `status: In Progress` 的任务
3. 对每个进行中的任务，检查 frontmatter 的 `references:` 字段是否包含 `github.com` URL
4. 跳过没有 GitHub 链接的任务（在最终汇总中注明"无关联仓库"）

### 第二步：解析 GitHub URL

从 `references:` 中提取 GitHub URL，解析出关键信息：

- **仓库地址**: `https://github.com/{owner}/{repo}` 部分
- **分支名** (可选): 如 URL 格式为 `https://github.com/{owner}/{repo}/tree/{branch}`，提取分支名
- **owner/repo**: 用于匹配本地仓库的 remote origin

一个任务可能有多个 GitHub references，全部处理。

### 第三步：定位本地仓库

在 `$SCAN_ROOT` 下扫描所有本地 git 仓库，构建 remote URL → 本地路径的映射：

```bash
find "$SCAN_ROOT" -maxdepth 4 -name ".git" -type d 2>/dev/null | while read gitdir; do
  repo_dir=$(dirname "$gitdir")
  remote=$(git -C "$repo_dir" remote get-url origin 2>/dev/null)
  if [ -n "$remote" ]; then
    echo "$repo_dir|$remote"
  fi
done
```

匹配规则：
- 将 remote URL 标准化（去掉 `.git` 后缀，统一 `git@github.com:` 和 `https://github.com/` 格式）
- 用任务 references 中的 `owner/repo` 去匹配

**如果本地未找到仓库**：
```bash
mkdir -p "$CLONE_DIR"
git clone <github_url> "$CLONE_DIR/<repo_name>"
```

### 第四步：拉取最新代码并采集数据

对每个定位到的本地仓库：

1. **拉取最新** (同步远程到本地):
```bash
git -C <repo_path> pull --rebase 2>/dev/null || git -C <repo_path> fetch --all
```

2. **获取 commit 历史** (近 30 天，使用本地分支):
```bash
git -C <repo_path> log --all --oneline --since="30 days ago" -50
```
如果 references URL 指定了分支，确保该分支在本地存在后：
```bash
git -C <repo_path> log <branch> -- --oneline --since="30 days ago" -50
```

3. **读取 CHANGELOG**: 先在根目录查找，再搜索子目录：
   ```bash
   # 根目录优先
   for f in CHANGELOG.md changelog.md CHANGES.md HISTORY.md; do
     [ -f "<repo_path>/$f" ] && echo "ROOT:$f" && break
   done
   # 子目录搜索（深度 2）
   find <repo_path> -maxdepth 2 -name "CHANGELOG.md" -o -name "changelog.md" -o -name "CHANGES.md" 2>/dev/null
   ```
   用 Read 工具读取找到的所有 CHANGELOG 文件。

4. **辅助信息** (可选): 如果 CHANGELOG 内容不够丰富，尝试读取 `<repo_path>/README.md` 中的 roadmap 或进度相关内容。

### 第五步：评估进度

**核心方法**: 将 CHANGELOG + commits 的内容与任务的 Acceptance Criteria 做语义匹配。

评估步骤：
1. 读取任务的 `## Acceptance Criteria`（AC）和 `## Definition of Done`（DoD）列表
2. 逐条分析 AC，对照 changelog 和 commit messages 判断每条的状态：
   - `[x]` 已完成 — changelog 或 commits 中有明确对应的完成记录
   - `[~]` 进行中 — 有相关的 WIP commit 或部分完成的记录
   - `[ ]` 未开始 — 没有找到相关记录
3. 计算基础进度：`(已完成数 + 进行中数×0.5) / 总AC数 × 100%`
4. 用以下信号修正：
   - commit 活跃度（近期有频繁提交说明开发活跃）
   - changelog 最新条目的时间和内容
   - 如果有 DoD 条目，也纳入评估
5. 最终进度取整到 5% 的倍数（如 35%、50%、75%）

**如果 AC 条目很少或很笼统**（比如只有一条），则主要依据 changelog 和 commits 的内容量来估算：
- 仅有初始 commit / 项目框架 → 10-20%
- 有多个功能性 commit → 30-60%
- changelog 显示大部分功能已完成 → 60-85%
- 有发布相关的 commit (release, v1.0 等) → 85-100%

### 第六步：更新任务文件

将进度信息写入任务的 **Description** section（`<!-- SECTION:DESCRIPTION:BEGIN/END -->` 标记内），因为 backlog web UI 只渲染已知 section，自定义 section 不会在页面上显示。

**写入规则**:
1. 保留 Description 中原有的描述内容
2. 在原有内容后追加 `### 进度报告` 子标题和进度数据
3. 如果 Description 中已有 `### 进度报告`，替换该子标题及其后面的全部内容（直到 `<!-- SECTION:DESCRIPTION:END -->`）

**格式模板** (追加在 Description 原有内容之后，`<!-- SECTION:DESCRIPTION:END -->` 之前):
```markdown

### 📊 进度报告 ({YYYY-MM-DD} 扫描)

**🚀 预估进度: {N}%** | 近 30 天 {N} 次提交，最近一次 {日期}

**✅ AC 完成情况**:
- ✅ {AC条目1} — {依据简述}
- 🔧 {AC条目2} — {进行中，相关 commit}
- ⬜ {AC条目3} — 未开始

**📝 近期动态** ({changelog来源}):
- {MM-DD}: {版本/动态1}
- {MM-DD}: {版本/动态2}
- {MM-DD}: {版本/动态3}

💡 {一句话总结当前阶段和剩余工作}
```

### 第七步：输出汇总

在终端用表格格式打印所有扫描结果的概览：

```
=== BroodBrain 进度扫描报告 ===
扫描时间: {YYYY-MM-DD HH:MM}

| 任务 | 进度 | 仓库 | 最近提交 | 摘要 |
|------|------|------|----------|------|
| TASK-18 KMS/TEE | 75% | AirAccount (KMS) | 今天 | v0.16.4 stable beta |
| TASK-8 Paymaster V4 | 60% | SuperPaymaster | 今天 | V4.3 稳定币已合并 |
| TASK-9 Comet ENS | — | 无关联仓库 | — | 跳过 |
```

### 第八步：构建并提交更新

先重新构建静态站点（让 web 版展示最新内容），再提交推送：

```bash
cd "$REPO_ROOT" && pnpm run build && bash "$REPO_ROOT/update-task.sh"
```

注意：`pnpm run build` 需要一定时间（启动本地 backlog server → 抓取 → 生成 dist/），使用 Bash 工具时设置 `timeout: 120000`（2 分钟）以确保不会超时中断。

## 重要注意事项

- **严格本地优先**：先 `git pull`/`git fetch` 将远程同步到本地，之后所有分析（git log、读文件等）只使用本地分支和本地文件，禁止使用 `origin/` 前缀的远程引用。不调用 GitHub API。
- `git pull` 失败不要中断流程，改用 `git fetch` 然后继续分析本地已有数据
- `git log` 使用本地分支名（不加 `origin/` 前缀），用 `--all` 参数确保覆盖所有本地分支
- 如果 CHANGELOG 不存在，仅依据 commits 分析，并在报告中注明"该仓库无 CHANGELOG"
- 进度评估要保守诚实，宁可低估不要高估。如果信息不足以判断，明确说明
- 输出语言使用中文

## 安装指南

如果你 clone 了本项目想使用此 skill：

1. 确保已安装 [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
2. skill 文件位于 `.claude/skills/sync-progress/SKILL.md`，Claude Code 会自动识别
3. 在项目目录下运行 `claude` 后输入 `/sync-progress` 即可执行
4. **可选配置**：如果你的项目仓库不在 Brood 的同级目录下，设置环境变量指定扫描范围：
   ```bash
   export SYNC_SCAN_ROOT="$HOME/projects"  # 你的开发目录根路径
   ```
   也可以写入 `~/.zshrc` / `~/.bashrc` 持久生效。
5. 任务的 `references:` 字段需包含 GitHub 仓库 URL（通过 backlog web 界面的 Add References 添加）
