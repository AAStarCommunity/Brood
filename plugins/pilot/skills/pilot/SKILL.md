---
name: pilot
version: 1.1.0
description: 仓库级开发操作系统。三阶段驱动一个仓库从「盘点 → 规划 → 持续开发」全流程。status=汇报进展+安全清理已合并分支/worktree；plan=建立/汇报 Milestone→Feature→Task 三级规划；run=先交出一条填好的 /goal 交付契约(说清怎么用 plan 的文档、怎么验证、PR 由外部评审服务裁决要怎么等、什么时候才算交付),再照它连续迭代做到交付;起跑前强制检查规划文档齐全。当用户说 pilot / 整理仓库 / 汇报进展 / 清理分支 / 规划里程碑 / 持续开发 / 跑通宵开发时使用。
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task, TodoWrite, Monitor, ScheduleWakeup
---

# pilot — 仓库级开发操作系统

一个 skill、三个阶段，把「一个仓库」从盘点带到持续开发。可移植到 Claude Code 与 Codex。

```
pilot status   # 汇报进展 + 安全清理已合并分支/worktree（默认 dry-run）
pilot plan     # Milestone(M1) → Feature(F1.1) → Task(T1.1.1) 三级规划
pilot run      # 交出一条填好的 /goal 交付契约,然后照它一路做到交付(起跑前文档门禁)
pilot resume   # run 的别名:优先处理待办 PR,再挑新 task
pilot doctor   # 自检本地就绪度（config/docs/分支/gh/hook）——**不含**外部评审服务
```

## 分派（第一步永远先做这件事）

从用户输入解析第一个词作为**子命令**，其余作为 flag：

| 子命令 | 打开并严格执行 | 说明 |
|:---|:---|:---|
| `status`（默认） | `phases/status.md` | 无子命令时默认走 status |
| `plan` | `phases/plan.md` | |
| `run` / `resume` | `phases/run.md` | **发 `/goal` 契约 + 无人值守交付循环**:跑到交付为止,不是一轮就停 |
| `doctor` | 见下方 §doctor | 轻量自检，不改动仓库 |

解析后**必须先 Read 对应的 `phases/*.md`**，按其步骤执行；本文件只定义分派与全局硬约束。

## 全局硬约束（任何阶段都不可违反）

这些是「有经验的程序员」的底线，写死在这里，任何子命令都遵守。

**分层强制（谁才是真正的保证）**：
- **机械强制层（不可绕过、非劝告）= 真正的保证**：① GitHub **分支保护**（服务端兜底：主干需 PR + 审批，`enforce_admins`）；② 待建的 Claude Code plugin **PreToolUse hook**（在工具边界拦截模型真正要跑的 `git add -A`/推主干/危险合并，用真运行时判断、让 git 自己解析，模型忘不了也绕不过——见 backlog **TASK-40**，本 skill 的**首要强制手段**）。
- **便利包装 + 纵深防御一层（best-effort）= `scripts/git-guard.sh` / `safe-cleanup.sh`**：覆盖常见危险形状（`add -A`、直推主干、合并 base≠集成分支、只 `-d` 删已合并+干净），日常危险动作**优先走这两个脚本**。但它们是 bash 劝告式包装——**不承诺对抗式滴水不漏**（bash 解析有害字符串本质上有边角），真正兜底靠上面的机械层。

危险动作优先走 git-guard/safe-cleanup，不裸用 git/gh。

1. **绝不 `git add -A` / `git add .`**。只 `git-guard.sh add <显式路径>`（裸 `git add -A` 会被 git-guard 拒绝）。理由：`-A` 会把未确认是否该跟踪的文件（密钥、`.env`、构建产物、临时文件）一起提交，是最危险的日常动作。提交前先 `git status` 看清，逐一列出要提交的路径。
2. **绝不直接 push 到主干（main/master），绝不直接合并自己的 PR 到主干**。push 走 `git-guard.sh push`、**开 PR 走 `git-guard.sh pr-create`**(先 `preflight.sh run` 让本仓库的检查真跑过)、合并走 `git-guard.sh merge-pr --integration <b>`（推主干 / 合并 base≠集成分支都会被硬拒绝）。所有代码变更走：feature 分支 → PR → review → 合并到**集成分支**（默认 `preview`，见 `.pilot.yml`）。主干只由集成分支经受控流程进入。
3. **一个 task = 一个分支 = 一个（可选）worktree = 一个 PR**。不在一个分支里顺手做别的 task。
4. **删除分支只用 `git branch -d`，永不 `-D`**；删除只针对「已合并 + 干净」的分支/worktree；一切经 `scripts/safe-cleanup.sh`，默认 dry-run。
5. **PR 之前必须自审 + 对抗 review**（怎么审见 `reference/pr-quality.md`，**审几轮由 `scripts/grade-change.sh` 机械定级，见 `reference/pre-pr-review.md`**——A/B 级 3 轮，不是作者自己说了算）。没过 review 的代码不进 PR，没 approve 的 PR 不合并。
6. **状态即文档**。每推进一步都更新 `docs/agent/tasks.md` 与 `docs/agent/progress.md`；宁可慢，不可让文档与仓库真实状态脱节。
7. **无人值守时不猜产品决策**。遇到影响产品方向/验收/架构的未知，把相关 task 标 `BLOCKED` 并记录待决问题，继续做不受影响的 task；绝不擅自替用户拍板。

> 详细的 git 安全规则见 `reference/git-safety.md`；PR 质量与 review 流程见 `reference/pr-quality.md`；task 状态机与字段见 `reference/task-schema.md`；**收到评审回执后怎么中立裁决（不盲从/不盲拒、按业务上下文判 comment 对错）见 `reference/review-triage.md`；判为「不阻塞」的跟进项怎么记进账本、绝不丢、主线做完后批量做掉见 `reference/followup-ledger.md`**。子命令会在需要时指引你读它们。

## 配置：`.pilot.yml`

每个仓库根目录一份（`doctor`/`plan` 会在缺失时创建）。关键字段：

```yaml
base_branch: main            # 主干，受保护，禁止直推
integration_branch: preview  # PR 合并进这里；不存在则回退到 base_branch
protect_patterns: [release, hotfix]   # 额外保护的分支前缀
remote: origin
allow_remote_cleanup: false  # 删除远程已合并分支需显式置 true
docs_dir: docs/agent         # 规划/运行态文档目录
```

读取方式：用 Read 工具读该文件，把值作为 flag 传给脚本（脚本本身不解析 YAML，保持简单确定）。文件不存在时用上表默认值，并提示用户运行 `pilot doctor` 生成。

**迁移兜底（重要）**：本 skill 曾用 `.repo-pilot.yml`。读配置时：**先读 `.pilot.yml`；若不存在但 `.repo-pilot.yml` 存在，则读旧文件并明确警告用户「`.repo-pilot.yml` 已弃用，请 `git mv .repo-pilot.yml .pilot.yml`」**。绝不静默忽略旧文件——某些仓库的 `.repo-pilot.yml` 里 `integration_branch` 是真实的（如 `master`），静默忽略会让 `run` 用错集成分支、甚至无人值守时把 外部评审的 APPROVE 直合进主干。**若两个文件同时存在且 `integration_branch` 不一致，视为危险，停下让用户先合并/删除旧文件（见 doctor 第 2b 步）。**

## doctor（内联，不改仓库）

轻量自检，只读并汇报。**只覆盖本地可验证的条件**——外部评审服务是否真的会来评审,doctor 无从探测(那正是解耦的代价与目的),所以它的结论只能是「本地就绪」,**不等于「PR 一定会被自动评审」**。汇报时必须把这条界限说清楚,不要让用户以为万事俱备:

1. `git rev-parse --is-inside-work-tree` — 是否 git 仓库。
2. `.pilot.yml` 是否存在；不存在则**询问用户**是否用默认值创建（复制 `templates/pilot.example.yml`，把 `base_branch`/`integration_branch` 填真实值）。
2b. **配置迁移硬检查**：若旧文件 `.repo-pilot.yml` 存在——
    - 只有旧文件、无 `.pilot.yml`：红字提示「`.repo-pilot.yml` 已弃用，运行 `git mv .repo-pilot.yml .pilot.yml`」；在迁移前 `run`/`status` 会读旧文件兜底。
    - **两个文件都在、且 `integration_branch` 不一致：`FAIL`（阻断）**——因为哪个生效不确定、错的那个可能把 PR 直合进主干。要求用户先删掉/合并旧文件再继续，`doctor` 不擅自改。
3. **规划文档齐全度**（`run` 无人值守的硬前提）：`bash <skill>/scripts/check-docs.sh --docs-dir <docs_dir> --strict`。
   报 MISSING/EMPTY 就照实列出并建议 `pilot plan` 补齐——`run` 会在同一道门禁上 fail-closed 拒跑，
   在这里先看见比半夜被拦住强。（脚本会识别「文件在但还是原样模板」：占位符没填等于没答。）
4. 是否有集成分支（`git show-ref refs/heads/<integration>`）；无则提示先建。
5. `gh auth status` 是否可用（PR 流程需要）。
5b. **git hook 是否真的在生效**（别假设 commit 有保护）：`bash <skill>/scripts/check-hooks.sh`。常见坑：`core.hooksPath` 指到**另一个 clone** 的 hooks 目录 → pre-commit 密钥扫描根本没跑,commit 裸奔却无人察觉。报 `BYPASSED` 就红着提示,并说明「**不要自动切回 `.githooks`**——扫描器有历史误报会让每次 commit 卡死,得先给已知误报加 baseline/allowlist 降噪,再手动开钩子」。只报告,不擅自 rewire。
6. **评审契约提醒**（不探测、不启动任何外部服务）：本仓库的 PR 由**外部评审服务**裁决，
   契约见 `reference/review-contract.md`——开 PR 后约 20 分钟内出裁决。pilot 只负责盯自己 PR 的状态。
   汇报时提示一句：若开 PR 后长时间没有裁决，说明该服务这会儿没覆盖本仓库，需要人工 review，
   **这不是 pilot 能修的，也不要自己给自己 approve**。
7. 汇报一张「就绪 / 待补」清单，不擅自修改。**措辞要诚实**:说「本地就绪」,不要说「可以无人值守跑到底」——外部评审是否会来,doctor 查不到;PR 长时间无裁决时按 `reference/review-contract.md` 的超时路径处理。

## 阶段间关系

```
status  ── 知道现在在哪、清干净战场
   ↓
plan    ── 知道要去哪（M→F→T）、补齐规划层文档
   ↓
run ↺   ── 连续推进 READY task(一次一个,一个接一个),直到交付条件全满足
```

`run` 依赖 `plan` 产出的 `docs/agent/` 文档做 check/对照；`plan` 依赖 `status` 给出的真实仓库状态。三者可单独调用，但首次接手一个仓库建议按序走一遍。
