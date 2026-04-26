---
name: sync-progress
description: 扫描所有 "In Progress" 任务关联的 GitHub 仓库，通过本地 git commit 历史和 CHANGELOG 文件分析开发进度，估算完成百分比并更新任务文件。当用户想了解项目进展、更新任务进度时使用。
allowed-tools: Bash(git *), Bash(find *), Bash(mkdir *), Bash(cd * && pnpm run build *), Bash(bash *update-task*), Bash(echo *), Bash(python3 *), Read, Glob, Grep, Edit, Write
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

# 3. Clone 缓存目录（未找到本地仓库时临时 clone，放在 SCAN_ROOT 同级目录下）
CLONE_DIR="${SCAN_ROOT}"
```

**运行时**：先执行上述命令确定 `REPO_ROOT`、`SCAN_ROOT`、`CLONE_DIR`，后续所有步骤使用这些变量。把检测结果打印出来让用户确认：

```
📍 项目根目录: /Users/xxx/Dev/Brood
🔍 仓库扫描范围: /Users/xxx/Dev
📦 Clone 缓存: /Users/xxx/Dev（与 Brood 同级目录）
```

## 执行流程

严格按以下步骤执行：

### Phase 0：生态仓库地图扫描与更新

在分析进度之前，先同步生态仓库全景图（`docs/ECOSYSTEM_MAP.md`）。目的：
- 建立本地路径 → GitHub remote URL 的实时映射
- 发现新克隆的仓库（自动加入地图）
- 标记 dormant 仓库状态变更
- 为后续任务匹配提供准确的本地路径

**执行步骤**：

1. **扫描 `$SCAN_ROOT` 下所有 git 仓库**，构建 remote→本地路径映射表：

```bash
find "$SCAN_ROOT" -maxdepth 4 -name ".git" -type d 2>/dev/null | while read gitdir; do
  repo_dir=$(dirname "$gitdir")
  remote=$(git -C "$repo_dir" remote get-url origin 2>/dev/null | sed 's/\.git$//' | sed 's|git@github.com:|https://github.com/|')
  last_commit=$(git -C "$repo_dir" log -1 --format="%ad" --date=short 2>/dev/null)
  # 只输出属于三大 org 或 jhfnetboy 的仓库
  echo "$repo_dir|$remote|$last_commit"
done | grep -E 'github\.com/(AAStarCommunity|MushroomDAO|AuraAIHQ|jhfnetboy)/'
```

2. **读取 `$REPO_ROOT/docs/ECOSYSTEM_MAP.md`**，与扫描结果对比：
   - 如果扫描到新仓库（地图中不存在），打印 `🆕 新发现: {path} → {remote}`
   - 如果某仓库 last_commit 距今超过 12 个月且地图中标记为 Active，打印 `⚠️ 状态变更: {repo} 应标为 Dormant`
   - 如果某地图条目的本地路径不存在，打印 `❓ 本地缺失: {repo}`（说明未 clone）

3. **用 Edit 工具更新 ECOSYSTEM_MAP.md**（仅在有变化时）：
   - 更新文件顶部的"最后更新"日期
   - 对状态有变化的行，更新状态列（🟢/🟡/🔴）和最近提交列
   - 对新发现的三大 org 仓库，在对应 org 区块末尾追加新行

4. 输出扫描摘要：
```
📡 生态地图扫描完成
   本地已有仓库: {N} 个（三大 org + jhfnetboy）
   新发现: {N} 个 | 状态变更: {N} 个 | 本地缺失: {N} 个
   地图已更新: docs/ECOSYSTEM_MAP.md
```

**注意**：Phase 0 扫描结果的路径映射表在内存中保留，供第三步（定位本地仓库）直接使用，避免重复 find 扫描。

---

### 第一步：收集进行中的任务

1. 用 Glob 读取 `backlog/tasks/*.md` 下所有任务文件
2. 用 Grep 或 Read 筛选 `status: "In Progress"` 或 `status: In Progress` 的任务
3. 对每个进行中的任务，检查 frontmatter 的 `references:` 字段是否包含 `github.com` URL
4. **没有** frontmatter GitHub 链接的任务，进入第一步·五智能匹配；匹配后仍无链接的，在最终汇总中注明"无关联仓库"

### 第一步·五：智能 GitHub 匹配（自动补全 references）

对 **frontmatter 中没有 github.com references** 的 In Progress 任务，扫描全文提取 GitHub URL 并自动写入 frontmatter，扩大扫描覆盖范围。

**执行步骤**：

1. 用 Bash 从整个任务文件中提取所有 GitHub URL：
   ```bash
   grep -oE 'https://github\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+(/[^[:space:]"'"'"'>)]*)?'  "<task_file>"
   ```

2. 标准化每个 URL，提取 repo 根地址或保留有价值的分支信息：
   - `https://github.com/owner/repo/blob/branch/file.md` → `https://github.com/owner/repo`（去掉 blob 路径）
   - `https://github.com/owner/repo/tree/branch` → 保留完整（含分支信息）
   - `https://github.com/owner/repo/issues/...` → `https://github.com/owner/repo`（只保留 repo）
   - `https://github.com/owner/repo` → 保留

3. 去重，过滤掉 Brood 仓库自身的 URL（即 `Brood` repo）

4. 如果提取到有效 URL，用 **Edit 工具**将其写入 frontmatter `references:` 字段：
   - 如果 frontmatter 已有 `references:` 行但内容为 `[]` 或空，替换为列表格式
   - 如果 frontmatter 完全没有 `references:` 行，在 `priority:` 或 `---` 结束行前插入

5. 打印操作日志（带 🤖 标记区分自动行为）：
   ```
   🤖 智能匹配: TASK-32 ← https://github.com/jhfnetboy/DSR-Research-Flow（从 description body 提取）
   🤖 智能匹配: TASK-34 ← https://github.com/jhfnetboy/AuraAI（从 description body 提取）
   ```

6. 对自动补全了 references 的任务，继续后续第二步～第六步的完整分析流程

**注意事项**：
- 只处理 frontmatter 中**完全没有** github.com URL 的任务，已有 references 的任务不触碰
- 如果一个任务 body 里有多个不同 repo URL，全部加入 references（每个单独分析）
- 自动写入后，在第七步汇总中用 🤖 标注该 reference 是智能匹配补全的

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

#### 6a. 回写预估进度到任务文件（关键！）

**必须执行**：将评估得到的进度百分比回写到任务文件中的 `预估进度: N%` 标记。这是 build 脚本 `computeMilestoneProgress()` 计算首页进度条的数据源。

```bash
# 将任务文件中的 "预估进度: XX%" 替换为新值
sed -i '' "s/预估进度: [0-9]*%/预估进度: ${NEW_PROGRESS}%/" "<task_file>"
```

如果任务文件中没有 `预估进度:` 标记，在进度报告区块的第一行添加。

**如果不执行此步骤，首页和看板的进度条不会更新！**

#### 6b. 写入进度报告到 Description section

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

### 第七步·四：计算各 Phase 加权进度

在更新 doc-7 之前，先计算 Phase 1/2/3 的真实进度。**核心思想：Phase 进度 = 该 Phase 所有任务的完成度加权平均，而非简单的「已完成任务数 / 总任务数」**。

**进度取值规则**（按优先级）：
- `status: Done` → **100%**（已完成，不论进度报告里写多少）
- `status: In Progress` + 有「预估进度: N%」→ **取 N%**
- `status: In Progress` + 无进度估算 → **保守取 10%**（有开始但无数据）
- `status: To Do` → **0%**（未开始）

**Milestone → Phase 映射规则**：
- `m-1` / `Phase 1: Genesis Launch` / `'Phase 1: Genesis Launch'` → **Phase 1**
- `m-2` / `Phase 2: Community Expansion` → **Phase 2**
- `m-3` / `Phase 3: Ecosystem Maturity` → **Phase 3**
- `m-r` / 其他 → **Research/Other**（不计入 Phase）

**计算方法**：用以下 Python 脚本（在 Bash 工具中运行）：

```python
import os, re, glob

tasks_dir = f'{REPO_ROOT}/backlog/tasks'
files = glob.glob(tasks_dir + '/*.md')

tasks = []
for f in sorted(files):
    content = open(f).read()
    fm_match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not fm_match: continue
    fm = fm_match.group(1)

    tid = re.search(r'^id:\s*(.+)', fm, re.M)
    status = re.search(r'^status:\s*(.+)', fm, re.M)
    milestone = re.search(r'^milestone:\s*(.+)', fm, re.M)
    if not tid or not status or not milestone: continue

    tid = tid.group(1).strip().strip("'\"")
    status_raw = status.group(1).strip().strip("'\"")
    milestone = milestone.group(1).strip().strip("'\"")

    # Determine progress
    prog_match = re.search(r'预估进度:\s*(\d+)%', content)
    if 'done' in status_raw.lower():
        progress = 100
    elif 'in progress' in status_raw.lower():
        progress = int(prog_match.group(1)) if prog_match else 10
    else:  # To Do
        progress = 0

    # Map to phase
    m = milestone.lower()
    if 'm-1' in m or 'phase 1' in m or 'genesis' in m:
        phase = 'Phase 1'
    elif 'm-2' in m or 'phase 2' in m or 'community' in m:
        phase = 'Phase 2'
    elif 'm-3' in m or 'phase 3' in m or 'ecosystem' in m:
        phase = 'Phase 3'
    else:
        phase = 'Research'

    tasks.append({'id': tid, 'status': status_raw, 'phase': phase, 'progress': progress})

# Calculate phase averages
for phase in ['Phase 1', 'Phase 2', 'Phase 3']:
    ptasks = [t for t in tasks if t['phase'] == phase]
    if ptasks:
        avg = sum(t['progress'] for t in ptasks) / len(ptasks)
        print(f"{phase}: {avg:.1f}% ({len(ptasks)} tasks)")
```

将计算结果保存为变量，在下一步写入 doc-7。

### 第七步·五：更新 Progress Report 文档（doc-7）

将本次扫描结果写入 `$REPO_ROOT/backlog/docs/doc-7 - 📊-Progress-Report.md`，使进度数据在 backlog 左侧文档栏中可见。

**写入规则**：
1. 更新 frontmatter 中的 `updated_date` 为今天的日期
2. **替换 `## Phase 进度 / Phase Progress` 区块**（如不存在则在总览表之前新增），写入三个 Phase 的加权进度
3. 替换 `## 总览 / Overview` 表格中所有行，使用本次扫描的最新数据
4. 替换 `## 详细报告 / Detailed Reports` 各任务段落，使用本次各任务的进度报告摘要
5. 在 `## 历史扫描记录 / Scan History` 表格**顶部**追加一行新记录（格式：`| YYYY-MM-DD | N | 本次关键变化摘要 |`）
6. **不要删除**历史扫描记录中已有的历史行

**doc-7 文件路径**：`$REPO_ROOT/backlog/docs/doc-7 - 📊-Progress-Report.md`

**Phase 进度区块格式模板**（每次全量替换该区块内容）：
```markdown
## Phase 进度 / Phase Progress

| Phase | 加权进度 | 任务数 | 说明 |
|:---|:---:|:---:|:---|
| **Phase 1**: Genesis Launch | **{N}%** | {n}个任务 | Done={d}, In Progress={ip}, To Do={td} |
| **Phase 2**: Community Expansion | **{N}%** | {n}个任务 | Done={d}, In Progress={ip}, To Do={td} |
| **Phase 3**: Ecosystem Maturity | **{N}%** | {n}个任务 | Done={d}, In Progress={ip}, To Do={td} |

> 进度算法：Done=100%，In Progress=取进度报告实际估算值，To Do=0%；对该 Phase 所有任务取算术平均。
```

**总览表格式模板**（每次全量替换）：
```markdown
| 任务 | 标题 | 进度 | 仓库 | 最近提交 | 状态摘要 |
|:---|:---|:---:|:---|:---:|:---|
| TASK-XX | {标题} | **{N}%** | {仓库} | {日期} | {一句话} |
| TASK-YY | {标题} | **—** | 无关联仓库 | — | {说明} |
```

### 第八步：构建、提交并部署

先重新构建静态站点，提交推送，再部署到 Cloudflare Pages：

```bash
# Step 8-1: 构建（timeout 120s）
cd "$REPO_ROOT" && pnpm run build

# Step 8-2: 提交推送
bash "$REPO_ROOT/update-task.sh"

# Step 8-3: 部署 Cloudflare Pages（带一次 retry）
cd "$REPO_ROOT" && pnpm run deploy:cf || (sleep 5 && pnpm run deploy:cf)
```

注意事项：
- `pnpm run build` 需要约 30-60 秒（启动本地 backlog server → 抓取 → 生成 dist/），Bash 工具设置 `timeout: 120000`
- `pnpm run deploy:cf` 可能因网络问题失败，失败后等 5 秒重试一次
- 如果二次重试仍失败，打印失败信息但不中断流程，告知用户手动执行 `pnpm run deploy:cf`

**验证清单**（完成后逐项确认）：
- [ ] `backlog/tasks/` 中的任务文件已更新（包含 `### 📊 进度报告` 和 `预估进度: N%`）
- [ ] `backlog/docs/doc-7 - 📊-Progress-Report.md` 的 Phase 进度表和总览表已更新
- [ ] `docs/ECOSYSTEM_MAP.md` 的状态和日期已更新
- [ ] `dist/` 重新生成，含最新内容
- [ ] Cloudflare Pages 部署成功（或提示用户手动重试）

## 重要注意事项

- **严格本地优先**：先 `git pull`/`git fetch` 将远程同步到本地，之后所有分析（git log、读文件等）只使用本地分支和本地文件，禁止使用 `origin/` 前缀的远程引用。不调用 GitHub API。
- `git pull` 失败不要中断流程，改用 `git fetch` 然后继续分析本地已有数据
- `git log` 使用本地分支名（不加 `origin/` 前缀），用 `--all` 参数确保覆盖所有本地分支
- 如果 CHANGELOG 不存在，仅依据 commits 分析，并在报告中注明"该仓库无 CHANGELOG"
- 进度评估要保守诚实，宁可低估不要高估。如果信息不足以判断，明确说明
- 输出语言使用中文

## 安装指南

详见 `skills/sync-progress/README.md`。快速安装：

```bash
# 在你自己的 backlog 项目中安装此 skill
mkdir -p .claude/skills/sync-progress
curl -o .claude/skills/sync-progress/SKILL.md \
  https://raw.githubusercontent.com/AAStarCommunity/Brood/main/skills/sync-progress/SKILL.md
```

可选配置：`export SYNC_SCAN_ROOT="$HOME/projects"` 指定仓库扫描范围。
