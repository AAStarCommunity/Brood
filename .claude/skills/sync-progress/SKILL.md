---
name: sync-progress
description: 扫描所有 "In Progress" 任务关联的 GitHub 仓库，通过本地 git commit 历史和 CHANGELOG 分析开发进度，再将结果同步写回任务文件并部署。当用户想了解项目进展、更新任务进度时使用。
allowed-tools: Bash(git *), Bash(find *), Bash(mkdir *), Bash(cd * && pnpm run build *), Bash(bash *update-task*), Bash(echo *), Bash(python3 *), Read, Glob, Grep, Edit, Write
---

# Sync Progress — 进度扫描 + 同步

你是一个项目进度分析师。本 skill 分两个阶段：

**扫描阶段**（Phase 0 ～ 第五步）：读取生态地图 → 找本地仓库 → 拉取最新 commit → 对照 AC 评估进度百分比。这一阶段只读不写。

**同步阶段**（第六步 ～ 第八步）：将扫描结果用 Edit 工具写入每个任务文件 → 强制验证所有任务的扫描日期已更新为今天 → 更新 doc-7 → build + commit + deploy。

> ⚠️ **"扫描"≠"完成"**。扫描阶段结束只是有了数据，必须完成同步阶段才算一次完整的 sync-progress。没有写入 + 验证的扫描没有任何意义。

## 本地目录 → 组织约定（固定映射）

**这是整个生态的约定**：所有仓库按所属组织存放在固定的本地目录下：

| 本地目录 | GitHub 组织 | 说明 |
|:---|:---|:---|
| `~/Dev/aastar/` | `AAStarCommunity` | 区块链基础设施（SuperPaymaster、AirAccount、SuperRelay 等） |
| `~/Dev/auraai/` | `AuraAIHQ` | AI 基础设施（iDoris、Agent24、agent-speaker 等） |
| `~/Dev/mycelium/` | `MushroomDAO` | 社区/个人/城市 OS（Sin90、Cos72、CometENS、Expresser 等） |

当用户在 GitHub 新建仓库并 clone 到本地时，**必须**放在对应组织的目录下。例如：
- `git clone git@github.com:AAStarCommunity/NewRepo.git ~/Dev/aastar/NewRepo`
- `git clone git@github.com:AuraAIHQ/NewRepo.git ~/Dev/auraai/NewRepo`
- `git clone git@github.com:MushroomDAO/NewRepo.git ~/Dev/mycelium/NewRepo`

Clone 备用目录（未找到本地仓库时临时 clone）：`~/Dev/tmp/`

## 前置：动态路径检测

```bash
# 1. 项目根目录（Brood 所在位置）
REPO_ROOT=$(git rev-parse --show-toplevel)

# 2. 三大组织固定本地目录
DIR_AASTAR="$HOME/Dev/aastar"
DIR_AURAAI="$HOME/Dev/auraai"
DIR_MYCELIUM="$HOME/Dev/mycelium"

# 3. Clone 备用目录
CLONE_DIR="$HOME/Dev/tmp"
```

**运行时**：先执行上述命令，打印确认：

```
📍 项目根目录: /Users/xxx/Dev/Brood
🗂️  AAStarCommunity: ~/Dev/aastar/
🗂️  AuraAIHQ:        ~/Dev/auraai/
🗂️  MushroomDAO:     ~/Dev/mycelium/
📦 Clone 备用:       ~/Dev/tmp/
```

## 执行流程

严格按以下步骤执行。**扫描阶段和同步阶段都必须完成**，缺一不可。

---

## 🔍 扫描阶段（Phase 0 ～ 第五步）

> 目标：收集所有 In Progress 任务的关联仓库数据，评估每个任务的完成进度百分比。
> 本阶段只读不写，结果保留在内存中供同步阶段使用。

### Phase 0：生态仓库地图扫描与更新

在分析进度之前，先同步生态仓库全景图（`docs/ECOSYSTEM_MAP.md`）。目的：
- 建立本地路径 → GitHub remote URL 的实时映射（供第三步直接使用）
- 发现新克隆的仓库（自动加入地图）
- 为新发现的仓库匹配 backlog 任务，补全 `references:` 字段
- 标记 dormant 仓库状态变更

**执行步骤**：

#### 步骤 0-1：扫描三大固定目录

使用以下 Python 脚本扫描三个固定目录，构建 remote→本地路径映射表：

```python
import os, subprocess

# 固定目录 → 组织映射
ORG_DIRS = {
    os.path.expanduser("~/Dev/aastar"):    "AAStarCommunity",
    os.path.expanduser("~/Dev/auraai"):    "AuraAIHQ",
    os.path.expanduser("~/Dev/mycelium"): "MushroomDAO",
}

found_repos = []  # [(local_path, remote_url, org, last_commit)]

for base_dir, org in ORG_DIRS.items():
    if not os.path.isdir(base_dir):
        print(f"⚠️  目录不存在: {base_dir}")
        continue
    for name in sorted(os.listdir(base_dir)):
        path = os.path.join(base_dir, name)
        git_dir = os.path.join(path, ".git")
        if not os.path.isdir(git_dir):
            continue
        # 获取 remote URL
        r = subprocess.run(["git", "-C", path, "remote", "get-url", "origin"],
                           capture_output=True, text=True)
        if r.returncode != 0:
            continue
        remote = r.stdout.strip()
        # 标准化 URL
        remote = remote.removesuffix(".git")
        remote = remote.replace("git@github.com:", "https://github.com/")
        # 仅保留三大 org 的仓库
        if not any(f"github.com/{o}/" in remote for o in ORG_DIRS.values()):
            continue
        # 最近提交日期
        r2 = subprocess.run(["git", "-C", path, "log", "-1", "--format=%ad", "--date=short"],
                             capture_output=True, text=True)
        last_commit = r2.stdout.strip() or "unknown"
        found_repos.append((path, remote, org, last_commit))
        print(f"  ✓ {org}/{name} | {last_commit}")

print(f"\n✅ 三大目录共发现 {len(found_repos)} 个仓库")
```

将 `found_repos` 列表保留在内存中，后续步骤复用，避免重复扫描。

#### 步骤 0-2：与 ECOSYSTEM_MAP.md 对比，发现新增仓库

读取 `$REPO_ROOT/docs/ECOSYSTEM_MAP.md`，提取其中已有的所有 GitHub URL（`github.com/ORG/REPO` 格式）。

对每个在 `found_repos` 中但不在地图里的仓库：
- 打印 `🆕 新发现: {path} → {remote}`
- 标记为 `new_repos` 列表，进入步骤 0-3 处理

对地图中存在但本地目录不存在的仓库：
- 打印 `❓ 本地缺失: {repo}（尚未 clone）`

#### 步骤 0-3：新仓库自动加入地图

对每个新发现仓库，用 **Edit 工具**将其追加到 `ECOSYSTEM_MAP.md` 对应 org 区块的核心产品表格末尾：

```markdown
| **{RepoName}** | （待补充定位描述） | `../aastar/{RepoName}` 或 `../auraai/...` 或 `../mycelium/...` | [{Org}/{RepoName}]({remote_url}) | ✓ 已克隆 |
```

同时更新文件顶部"最后更新"日期为今天。

#### 步骤 0-4：为新仓库匹配 backlog 任务，补全 references

对每个新发现的仓库，在 backlog 任务中搜索可能关联的任务：

```python
import glob, re

tasks_dir = os.path.join(REPO_ROOT, "backlog/tasks")
repo_name = os.path.basename(new_repo_path).lower()

for task_file in sorted(glob.glob(tasks_dir + "/*.md")):
    content = open(task_file).read()
    # 检查任务是否已有 references 指向该 repo
    if new_repo_remote in content:
        continue  # 已存在，跳过
    # 在任务标题、描述中搜索仓库名关键词（不区分大小写）
    if repo_name in content.lower() or repo_name.replace("-", "") in content.lower():
        # 提取 task ID 用于日志
        tid = re.search(r'^id:\s*(.+)', content, re.M)
        tid = tid.group(1).strip().strip("'\"") if tid else task_file
        print(f"  🤖 任务匹配: {tid} ↔ {repo_name}（名称关键词匹配）")
        # 检查 frontmatter references 字段
        # 如果 references: [] 或不存在，追加新 URL
        # (具体 Edit 操作见第一步·五的写入规则)
```

如果有匹配，用 **Edit 工具**按第一步·五的规则将新仓库 URL 写入任务 frontmatter 的 `references:` 字段。

打印操作日志：
```
🤖 references 补全: TASK-XX ← https://github.com/MushroomDAO/NewRepo（仓库名关键词匹配）
```

#### 步骤 0-5：输出扫描摘要

```
📡 生态地图扫描完成
   三大目录已有仓库: {N} 个
     ~/Dev/aastar/:    {N} 个（AAStarCommunity）
     ~/Dev/auraai/:    {N} 个（AuraAIHQ）
     ~/Dev/mycelium/:  {N} 个（MushroomDAO）
   🆕 新发现: {N} 个（已加入地图 + 搜索任务匹配）
   ❓ 本地缺失: {N} 个（未 clone）
   地图已更新: docs/ECOSYSTEM_MAP.md
```

**注意**：Phase 0 的 `found_repos` 列表在内存中保留，供**第三步（定位本地仓库）**直接使用，避免重复扫描。

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

**优先**复用 Phase 0 已建立的 `found_repos` 映射表（`remote_url → local_path`），无需重复扫描。

匹配规则：
- 将 remote URL 标准化（去掉 `.git` 后缀，统一 `git@github.com:` 和 `https://github.com/` 格式）
- 用任务 references 中的 `owner/repo` 去匹配 `found_repos` 中的条目

```python
# 从 Phase 0 的 found_repos 构建查找表
url_to_path = {}
for (path, remote, org, last_commit) in found_repos:
    # 提取 owner/repo 作为 key
    key = "/".join(remote.rstrip("/").split("/")[-2:]).lower()
    url_to_path[key] = path

# 匹配任务 reference
def find_local_repo(github_url):
    key = "/".join(github_url.rstrip("/").split("/")[-2:]).lower()
    return url_to_path.get(key)
```

**如果本地未找到仓库**（Phase 0 三大目录都没有）：
```bash
mkdir -p "$HOME/Dev/tmp"
git clone <github_url> "$HOME/Dev/tmp/<repo_name>"
```

**注意**：三大固定目录 `~/Dev/aastar`、`~/Dev/auraai`、`~/Dev/mycelium` 覆盖了绝大多数情况；`tmp/` 仅用于不属于三大 org 的 jhfnetboy 个人仓库或外部仓库。

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

---

## ✍️ 同步阶段（第六步 ～ 第八步）

> 目标：将扫描阶段的评估结果写入任务文件，验证写入成功，更新报告，构建并部署上线。
> **本阶段是 sync-progress 的核心输出。没有同步阶段，扫描阶段的数据毫无意义。**

### 第六步：同步写入任务文件

> ⚠️ **"同步"的定义：用 Edit 工具写入文件 + 跑验证脚本确认每个文件的扫描日期已更新为今天。**
> 只生成了分析文字而没有调用 Edit 工具 = 没有同步。
> **已发生事故（2026-05-02）**：运行产生了终端输出，汇报"12 个任务已写入"，
> 但 Edit 工具从未被调用，文件内容未变，任务扫描日期停留在 4-27。
> 根因：把"生成了分析文字"误当成"完成了写入"，且没有跑验证脚本。

#### 6a. 回写预估进度到任务文件（关键！）

**必须用 Edit 工具**（不是 sed，rtk hook 会拦截）将评估得到的进度百分比回写到任务文件中的 `预估进度: N%` 标记。这是 build 脚本 `computeMilestoneProgress()` 计算首页进度条的数据源。

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

### 第七步·零：文件写入验证（强制，不可跳过）

**在输出第七步汇总表之前，必须先跑以下验证脚本**，确认每个 In Progress 任务的扫描日期已变为今天。如果有任务日期未更新，说明第六步的 Edit 工具调用失败或被跳过，必须重新执行写入，直到全部日期为今天。

```python
import os, re, glob
from datetime import date

TODAY = str(date.today())
tasks_dir = f'{REPO_ROOT}/backlog/tasks'
fail = []

for f in sorted(glob.glob(tasks_dir + '/*.md')):
    content = open(f).read()
    fm = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not fm: continue
    status = re.search(r'^status:\s*(.+)', fm.group(1), re.M)
    if not status or 'In Progress' not in status.group(1): continue
    tid = re.search(r'^id:\s*(.+)', fm.group(1), re.M).group(1).strip().strip("'\"")
    scan = re.search(r'进度报告\s*\((\d{4}-\d{2}-\d{2})\s*扫描\)', content)
    date_in_file = scan.group(1) if scan else "无"
    if date_in_file != TODAY:
        fail.append(f'{tid}: {date_in_file}（应为 {TODAY}）')
        print(f'❌ {tid}: 扫描日期未更新 ({date_in_file})')
    else:
        print(f'✅ {tid}: {date_in_file}')

if fail:
    print(f'\n⛔ {len(fail)} 个任务写入失败，必须重新执行第六步再继续：')
    for f in fail: print(f'  {f}')
    raise SystemExit('写入验证失败，禁止继续！')
else:
    print(f'\n✅ 所有 In Progress 任务扫描日期已更新为 {TODAY}，可继续第七步')
```

**只有验证全部通过（无 ❌）才能继续后续步骤。**

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

> ⚠️ **绝对不能跳过此步骤。**
> 任务文件写入进度后，`dist/` 不会自动更新，线上看板显示的仍是上一次 build 的旧数据。
> **已发生事故（2026-05-02）**：sync-progress 运行后漏掉第八步，导致线上任务仍显示"2026-04-27 扫描"的旧进度报告，用户反馈才发现。根因：把"写入任务文件"误当做"完成"，忘记 build + deploy 才让内容上线。

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
- **build 输出必须出现两个 ✅**：`Patched Kanban column progress formula` 和 `Patched right-panel milestone progress formula`。任一缺失说明 backlog.md 升级后 JS minified 名变了，build 脚本应已自动抛错；如果 build 通过但缺少 patch 日志，说明脚本被绕过，**禁止继续部署**。
- `pnpm run deploy:cf` 可能因 proxy 卡住或网络问题失败：先尝试 `unset http_proxy https_proxy all_proxy && pnpm run deploy:cf`；超过 3 分钟无输出视为挂死，`kill` 掉 wrangler 进程后重试一次
- 如果二次重试仍失败，打印失败信息但不中断流程，告知用户手动执行 `pnpm run deploy:cf`

### 第八步·四：线上验证（强制，不可跳过）

> ⚠️ **事故教训（2026-05-12）**：build 脚本里的 JS patch 字符串被 backlog.md v1.45 minified 变量名变更破坏，patch 静默失败但 build 仍成功输出 dist/。CF 部署也成功，但页面 Phase 进度回退到 `doneCount/total` 简单计数（46/0/0 而不是 67/7/9）。用户访问 kanban 才发现错误。
> 教训：commit + deploy 成功 ≠ 上线数据正确。**必须 fetch 部署 URL 并断言关键数据正确**。

完成第八步部署后，立刻 fetch 线上 URL 验证三件事：

```bash
# 拿到部署 URL（从 deploy:cf 输出中提取）— 也可以直接用主域 https://kanban.mushroom.cv/
DEPLOY_URL="https://kanban.mushroom.cv/"

# 验证 1：__milestoneProgress 数据存在且与本地计算的 Phase 进度一致
curl -sf "$DEPLOY_URL" | grep -oE "__milestoneProgress[^;]{0,300}"
# 预期输出：__milestoneProgress = {"m-1":N,"lane:milestone:m-1":N,"m-2":N,...}
# 如果没有输出或值是 {}，说明 index.html 没有注入 milestone 数据 → build 失败或部署未刷新

# 验证 2：JS bundle 中存在 patch 后的 milestoneProgress 引用
JS_URL=$(curl -sf "$DEPLOY_URL" | grep -oE "chunk-[a-z0-9]+\.js" | head -1)
curl -sf "${DEPLOY_URL}${JS_URL}" | grep -c "__milestoneProgress"
# 预期 >= 2（kanban patch + right-panel patch 各引用一次）
# 如果是 0，说明 JS bundle patch 没生效，UI 会回退到错误的简单计数

# 验证 3：抽查一个 In Progress 任务的进度报告扫描日期是今天
TODAY=$(date +%Y-%m-%d)
curl -sf "${DEPLOY_URL}api/tasks.json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
tasks = data.get('tasks', data) if isinstance(data, dict) else data
ip = [t for t in tasks if t.get('status') == 'In Progress']
print(f'In Progress tasks online: {len(ip)}')
if ip:
    print(f'Sample task: {ip[0].get(\"id\")}: {ip[0].get(\"title\", \"\")[:40]}')
"
```

**强制断言**：
- [ ] `__milestoneProgress` 在 index.html 中存在且至少包含 `m-1` / `m-2` / `m-3` 三个键
- [ ] JS chunk 中 `__milestoneProgress` 引用 >= 2
- [ ] api/tasks.json 中 In Progress 任务数与本地一致

**任一断言失败时**：必须在终端用红色文字明确告警，列出失败项，并提示「请检查 build 输出 / 重新 deploy / 等待 CF 缓存刷新（最多 30 秒）」。**不要假装成功**。

**验证清单**（完成后逐项确认，必须全部打勾才算完成）：
- [ ] `backlog/tasks/` 中的任务文件已更新（包含 `### 📊 进度报告` 和 `预估进度: N%`）
- [ ] `backlog/docs/doc-7 - 📊-Progress-Report.md` 的 Phase 进度表和总览表已更新
- [ ] `docs/ECOSYSTEM_MAP.md` 的状态和日期已更新
- [ ] `dist/` 重新生成，含最新内容（`pnpm run build` 成功，**包含两个 ✅ Patched 日志**）
- [ ] `update-task.sh` commit + push 成功
- [ ] Cloudflare Pages 部署成功，输出 deployment URL（或提示用户手动重试）
- [ ] **线上验证（8·四）三项断言全部通过**：`__milestoneProgress` 存在 + JS bundle 含 patch + tasks.json 数据对齐

## 重要注意事项

- **第八步不可跳过**：写入任务文件 ≠ 上线。必须 `pnpm run build` → `update-task.sh` → `pnpm run deploy:cf` 三步全部完成，内容才会在线上可见。漏掉任意一步，用户看到的仍是上次 build 的旧数据。（2026-05-02 事故教训）
- **第八步·四线上验证不可跳过**：deploy 成功 ≠ 上线数据正确。backlog.md CLI 升级可能让 build 脚本里的 JS patch 静默失败（minified 变量名变了），dist/ 仍能生成但 kanban UI 上 Phase 进度会错（回退到 doneCount/total 简单计数）。必须 fetch 部署 URL 断言 `__milestoneProgress` 存在 + JS bundle 含 patch 引用。（2026-05-12 事故教训）
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
