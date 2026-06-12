# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 🧠 本仓库的角色：生态 Orchestrator（生态大脑）

Brood 是 Mycelium Protocol 的**生态调度者**，不是普通 repo。在 `~/Dev/Brood/` 启动 Claude Code，**有责任也有能力**读三个 sibling org 目录（`~/Dev/aastar/`、`~/Dev/auraai/`、`~/Dev/mycelium/`）下的所有仓库。

### 三层生态结构（必读）

```
┌─────────────────────────────────────────────────────────────┐
│  愿景层 / Vision     Mycelium = 协作网络 + 数字公共物品      │
│  ────────────       让普通人享受数字基础设施带来的福祉       │
├─────────────────────────────────────────────────────────────┤
│  基础设施层 / Infra  AAstar    = Web3 账户/支付/Gas 抽象      │
│  ────────────       AuraAI    = AI agent/skill/通信层        │
├─────────────────────────────────────────────────────────────┤
│  协议/网络层         MushroomDAO = 治理、协议、社区/城市 OS    │
│  Protocol & Network  Park / Spores / OpenPNTs / PGL          │
└─────────────────────────────────────────────────────────────┘
```

**叙事接口**：通过「数字公共物品」与现实世界对接。开源免费的工具 + 低成本的产品化封装 → 让普通人无门槛使用。

**两层成本**（决定生态可持续性）：
1. **运营成本**：gasless 垫付、域名/服务器/CDN、维护性投入 → 需要协议层收取最低运营费维持
2. **商业规模成本**：扩大协作网络帮助更多人 → 需要 HyperCapital 这类合规商业实体承担

详见 `protocol/MISSION.md`。

### Orchestrator 的五项核心职责

1. **状态把脉**（task + repo 双视角）—— 知道每个仓库在做什么，哪些活跃、哪些静默
2. **节奏感**（季度 → 周）—— 提醒"这个仓库本周必须启动，否则 Q3 目标兜不住"
3. **里程碑依赖识别** —— 业务里程碑依赖哪些工具，工具未启动要预警
4. **跨仓库分析与对比** —— 接口变更影响范围、技术栈冲突、重复造轮子
5. **探索性思考** —— 不只汇报，要主动指出"现在最划算的事是什么"

### 三层调度纪律（不可破）

| 层 | 总是 OK | 严格禁止 |
|:---|:---|:---|
| **地图层** | 读本仓库的 `docs/ECOSYSTEM_MAP.md`、`protocol/MISSION.md`、`orgs/*/PROFILE.md`、`orgs/*/INTERFACES.md` | — |
| **摘要层** | 读 `docs/REPO_STATUS.md`、`backlog/docs/doc-7`、各 sibling repo 的 `CLAUDE.md` / `README.md`（一页内）| — |
| **委派层** | 跨多文件追代码 → **派 Explore subagent** 指向 sibling repo 绝对路径，只接摘要 | ❌ 主对话内 grep 整个 org 目录 / Read 大量源码 / 循环读几十个 CLAUDE.md |

**例行扫描**：用 Python/Bash 脚本（如 `sync-progress`、`scan-repo-status.sh`），脚本压缩输出再喂回主对话；**禁止主对话内循环 Read**。

### 何时主动追问

当用户问任意「项目」「进度」「状态」「下一步」「该做什么」时：

1. 先读 `docs/REPO_STATUS.md` + `backlog/docs/doc-7`
2. 用 `introduce-suggestion` skill 三段式响应（介绍 → review → focus 建议）
3. 用「季度目标 ⇄ 仓库激活时机」推导出 1-3 个本周/本两周可显著推进的点
4. 主动指出**静默超 30/90/365 天**的仓库与目标的关系

---

## Project Overview

BroodBrain is a static, read-only project backlog publishing system for the Mycelium Protocol ecosystem. It uses the `backlog` CLI (via npx) to manage tasks/docs/decisions as markdown files, then exports them as a fully static SPA with JSON API files. There is no backend — the deployed site is pure HTML/CSS/JS/JSON served from CDN.

The project language is bilingual (Chinese/English). README and UI toast messages are in Chinese.

## Commands

```bash
pnpm run build       # Export static site to dist/ (spawns local backlog server, scrapes it, injects read-only protection)
pnpm run preview     # Serve dist/ locally on port 3000
pnpm run deploy:cf   # Deploy dist/ to Cloudflare Pages via wrangler
```

There are no dependencies in package.json — everything runs via `npx`. There is no test framework.

## Build Architecture

The build process (`scripts/export-backlog.js`) works as follows:

1. Spawns a local `backlog` CLI server on port 8422 (`npx backlog browser --no-open`)
2. Fetches `index.html` and parses it for static asset URLs (CSS, JS, images)
3. Downloads all assets to `dist/`
4. **Injects read-only protection script** into `index.html` before `</head>`:
   - Intercepts POST/PUT/DELETE/PATCH fetch calls → shows Chinese toast notification
   - Appends `.json` suffix to `/api/` fetch URLs (avoids Unix directory/file collision)
   - Spoofs empty `[]` for failed or HTML-fallback API responses
   - Mocks `EventSource` and `WebSocket` to suppress "Server disconnected" errors
   - Hides delete buttons via CSS injection
5. Downloads all API endpoints as JSON files into `dist/api/`
6. Fetches individual docs, decisions, and milestones as separate JSON files
7. Writes deployment config files (`_headers`, `_redirects`, `_routes.json`, `vercel.json`)
8. Kills the local server

**Key design principle**: Local build, direct push. `dist/` is committed to git. GitHub Actions deploys it as-is with no cloud build step.

## Deployment

- **GitHub Pages** (default): Automatic via `.github/workflows/deploy.yml` on push to `main`. Simply commits `dist/` and pushes.
- **Cloudflare Pages**: Either `pnpm run deploy:cf` (CLI) or connect repo in CF dashboard with build output dir `dist` and empty build command.

## Content Structure

All content lives in `backlog/` as markdown with YAML frontmatter:

- `backlog/config.yml` — Project config (statuses, task prefix, port, etc.)
- `backlog/tasks/task-N - [Type] Name.md` — Task files with id, title, status, assignee, labels, milestone, dependencies, priority
- `backlog/docs/doc-N.md` — Documentation files
- `backlog/decisions/decision-N.md` — Architecture Decision Records (Context/Decision/Consequences format)
- `backlog/archive/` — Archived tasks, drafts, milestones

Task statuses: `To Do`, `In Progress`, `Done`. Task prefix: `task`. IDs use format `TASK-N`.

## Static API

The exported `dist/api/` contains JSON files mirroring the backlog CLI's REST API:

- `tasks.json`, `docs.json`, `decisions.json`, `milestones.json` — List endpoints
- `docs/{id}.json`, `decisions/{id}.json`, `milestones/{encodedTitle}.json` — Individual items
- `config.json`, `statistics.json`, `search.json`, `status.json`, `statuses.json`, `version.json`

The injected fetch interceptor in `index.html` automatically appends `.json` to `/api/` requests at runtime.

## Custom Skills

### `/sync-progress` — GitHub 仓库进度扫描

扫描所有 "In Progress" 任务，通过本地 git commit 历史和 CHANGELOG 分析开发进度，估算完成百分比并更新任务文件。

- 任务需要在 `references:` frontmatter 中包含 `github.com` URL
- **本地目录约定**（固定映射，所有生态仓库必须按此存放）：
  - `~/Dev/aastar/` → `AAStarCommunity` 旗下所有仓库
  - `~/Dev/auraai/` → `AuraAIHQ` 旗下所有仓库
  - `~/Dev/mycelium/` → `MushroomDAO` 旗下所有仓库
  - `~/Dev/tmp/` → 不属于三大 org 的临时 clone
- Phase 0 扫描三大目录，自动发现新 clone 的仓库并更新 `docs/ECOSYSTEM_MAP.md`，同时为匹配的 backlog 任务补全 `references:` 字段
- 进度写入任务文件的 Description section（`<!-- SECTION:DESCRIPTION:BEGIN/END -->` 标记内）

Skill 定义: `.claude/skills/sync-progress/SKILL.md`

### `/sync-context-reverse` — 生态上下文反向同步

扫描所有生态 repo，将变更反向回流到 Brood 的 L0/L1 上下文文件：

- **@-include 健康检查**：验证所有 repo 的 CLAUDE.md 引用完整性，自动修复缺失/过时引用
- **版本号同步**：从 repo 提取实际版本，更新 PROFILE.md 和 INTERFACES.md
- **接口变更检测**：对比 repo 代码与 INTERFACES.md 的接口定义，输出变更建议
- **依赖关系验证**：检查 PROFILE.md 的 `depends_on:` 与实际代码依赖是否一致
- **生态地图刷新**：更新 ECOSYSTEM_MAP.md 中各 repo 的状态和最近提交日期

Skill 定义: `.claude/skills/sync-context-reverse/SKILL.md`

### `/license-update` — License 合规同步

扫描所有活跃 repo 的 License 三件套（Apache 2.0 LICENSE + NOTICE + TRADEMARK.md）合规状态：

- **缺失初始化**：新 repo 缺少 license 文件时，从 `protocol/license-templates/` 模板创建
- **模板同步**：TRADEMARK 政策或 LICENSE 内容变更时，批量更新所有 repo
- **NOTICE 参数化**：第一行自动填入 `Mycelium Protocol — {RepoName}`

模板来源: `protocol/license-templates/`（LICENSE, NOTICE.template, TRADEMARK.md）
Skill 定义: `.claude/skills/license-update/SKILL.md`

## Mycelium Protocol 生态上下文 / Ecosystem Context

BroodBrain 本身是 Mycelium Protocol 的神经系统。本仓库存放三层上下文：

**L0 协议层** (`protocol/`):
- `protocol/MISSION.md` — 菌丝协议使命愿景
- `protocol/ECOSYSTEM_MAP.md` — 组织全景图
- `protocol/HOW_TO_JOIN.md` — 如何加入协议
- `protocol/REPO_REGISTRY.md` — 仓库能力注册表

**L1 组织层** (`orgs/`):
- `orgs/aastar/PROFILE.md` + `INTERFACES.md` — AAstar 组织名片和接口规范
- `orgs/auraai/PROFILE.md` + `INTERFACES.md` — AuraAI 组织名片和接口规范
- `orgs/mycelium/PROFILE.md` + `INTERFACES.md` — MushroomDAO 组织名片和接口规范
- `orgs/template/PROFILE.md` — 新组织加入模板

**其他 repo 如何引入本仓库的生态上下文**：见 `CONTEXT-INHERIT.md`

**仓库级生态地图**（含本地路径 + 状态）：`docs/ECOSYSTEM_MAP.md`

## 本地仓库目录约定 / Local Repo Directory Convention

所有生态仓库按组织存放在固定目录下（**必须遵守**，sync-progress 等 skill 依赖此约定）：

| 本地目录 | GitHub 组织 |
|:---|:---|
| `~/Dev/aastar/` | `AAStarCommunity` |
| `~/Dev/auraai/` | `AuraAIHQ` |
| `~/Dev/mycelium/` | `MushroomDAO` |
| `~/Dev/tmp/` | 临时 clone（非三大 org） |

新建仓库 clone 示例：`git clone git@github.com:MushroomDAO/NewRepo.git ~/Dev/mycelium/NewRepo`

## Git Workflow

- Single `main` branch, direct commits
- Commit style: conventional commits (`fix:`, `chore():`, `docs():`)
- `dist/` is tracked in git (intentionally — no cloud build)
- `update-task.sh` is a convenience script that stages, commits with `fix: update task`, and pushes
