---
name: pilot
description: 仓库级开发操作系统。三阶段驱动一个仓库从「盘点 → 规划 → 持续开发」全流程。status=汇报进展+安全清理已合并分支/worktree；plan=建立/汇报 Milestone→Feature→Task 三级规划；run=单轮开发循环（挑 READY task→开发→自测→对抗 review→PR→合并 preview），可被 /loop 反复调用跑通宵。当用户说 pilot / 整理仓库 / 汇报进展 / 清理分支 / 规划里程碑 / 持续开发 / 跑通宵开发时使用。
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task, TodoWrite
---

# Pilot — 仓库级开发操作系统

一个 skill、三个阶段，把「一个仓库」从盘点带到持续开发。可移植到 Claude Code 与 Codex。

```
pilot status   # 汇报进展 + 安全清理已合并分支/worktree（默认 dry-run）
pilot plan     # Milestone(M1) → Feature(F1.1) → Task(T1.1.1) 三级规划
pilot run      # 单轮开发循环，可被 /loop 反复调用
pilot resume   # run 的别名：优先处理待办 PR，再挑新 task
pilot doctor   # 检查本仓库是否具备自动运行条件
```

## 分派（第一步永远先做这件事）

从用户输入解析第一个词作为**子命令**，其余作为 flag：

| 子命令 | 打开并严格执行 | 说明 |
|:---|:---|:---|
| `status`（默认） | `phases/status.md` | 无子命令时默认走 status |
| `plan` | `phases/plan.md` | |
| `run` / `resume` | `phases/run.md` | 单轮迭代 |
| `doctor` | 见下方 §doctor | 轻量自检，不改动仓库 |
| `review-status` | 见下方 §review-status | 汇报 PR-Daemon 评审进度（只读，任意仓库可调）|

解析后**必须先 Read 对应的 `phases/*.md`**，按其步骤执行；本文件只定义分派与全局硬约束。

## 全局硬约束（任何阶段都不可违反）

这些是「有经验的程序员」的底线，写死在这里，任何子命令都遵守。**约束 1/2/4 不只靠自觉——`scripts/git-guard.sh` 在脚本层硬拦截 `add -A`、直推主干、合并 base≠集成分支；`scripts/safe-cleanup.sh` 在脚本层保证只 `-d` 删已合并+干净。危险动作一律走这两个脚本，不裸用 git/gh。**

1. **绝不 `git add -A` / `git add .`**。只 `git-guard.sh add <显式路径>`（裸 `git add -A` 会被 git-guard 拒绝）。理由：`-A` 会把未确认是否该跟踪的文件（密钥、`.env`、构建产物、临时文件）一起提交，是最危险的日常动作。提交前先 `git status` 看清，逐一列出要提交的路径。
2. **绝不直接 push 到主干（main/master），绝不直接合并自己的 PR 到主干**。push 走 `git-guard.sh push`、合并走 `git-guard.sh merge-pr --integration <b>`（推主干 / 合并 base≠集成分支都会被硬拒绝）。所有代码变更走：feature 分支 → PR → review → 合并到**集成分支**（默认 `preview`，见 `.pilot.yml`）。主干只由集成分支经受控流程进入。
3. **一个 task = 一个分支 = 一个（可选）worktree = 一个 PR**。不在一个分支里顺手做别的 task。
4. **删除分支只用 `git branch -d`，永不 `-D`**；删除只针对「已合并 + 干净」的分支/worktree；一切经 `scripts/safe-cleanup.sh`，默认 dry-run。
5. **PR 之前必须自审 + 对抗 review**（见 `reference/pr-quality.md`）。没过 review 的代码不进 PR，没 approve 的 PR 不合并。
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
pr_daemon_root: ~/Dev/tools/PR-Daemon  # 外部 PR 评审 daemon 根目录（也可用 $PILOT_PR_DAEMON_ROOT）
```

读取方式：用 Read 工具读该文件，把值作为 flag 传给脚本（脚本本身不解析 YAML，保持简单确定）。文件不存在时用上表默认值，并提示用户运行 `pilot doctor` 生成。

## doctor（内联，不改仓库）

轻量自检，只读并汇报，供用户判断能否开启无人值守：

1. `git rev-parse --is-inside-work-tree` — 是否 git 仓库。
2. `.pilot.yml` 是否存在；不存在则**询问用户**是否用默认值创建（复制 `templates/pilot.example.yml`，把 `base_branch`/`integration_branch` 填真实值）。
3. `docs/agent/` 是否存在，`roadmap.md`/`tasks.md`/`progress.md` 是否齐全 —— 缺失则建议 `pilot plan`。
4. 是否有集成分支（`git show-ref refs/heads/<integration>`）；无则提示先建。
5. `gh auth status` 是否可用（PR 流程需要）。
5b. **git hook 是否真的在生效**（别假设 commit 有保护）：`bash <skill>/scripts/check-hooks.sh`。常见坑：`core.hooksPath` 指到**另一个 clone** 的 hooks 目录 → pre-commit 密钥扫描根本没跑,commit 裸奔却无人察觉。报 `BYPASSED` 就红着提示,并说明「**不要自动切回 `.githooks`**——扫描器有历史误报会让每次 commit 卡死,得先给已知误报加 baseline/allowlist 降噪,再手动开钩子」。只报告,不擅自 rewire。
6. **PR 评审 daemon 是否在线**：`bash <skill>/scripts/ensure-pr-daemon.sh check`。`not running` 就提示——本仓库的 PR 提了也没人 review,需要拉起（`status` 阶段会自动拉起）。根目录默认 `~/Dev/tools/PR-Daemon`，可用 `pr_daemon_root` / `$PILOT_PR_DAEMON_ROOT` 覆盖。
7. 汇报一张「就绪 / 待补」清单，不擅自修改。

## review-status（内联，只读，任意仓库可调）

汇报外部 PR-Daemon 的评审进度，不改任何仓库：

1. 定位 daemon 根目录：`.pilot.yml` 的 `pr_daemon_root` / `$PILOT_PR_DAEMON_ROOT` / 默认 `~/Dev/tools/PR-Daemon`。
2. 运行 `bash <root>/watch.sh queue`（各状态计数 + 待评队列 + 最近同步时间）。
3. 若存在 `<root>/reviews/review-eval.tsv`，读其尾部若干行，汇报最近几个 PR 的**耗时 / 后端(2轮deepseek / 4轮real) / rc**。
4. 三句话内汇报：daemon 在线否、待评队列多少、最近评审节奏。**只读，绝不改仓库。**

> 命令行等价物（无需进 Claude 会话）：shell 别名 `review-status`（= `bash <root>/watch.sh queue`）。

## 阶段间关系

```
status  ── 知道现在在哪、清干净战场
   ↓
plan    ── 知道要去哪（M→F→T）、补齐规划层文档
   ↓
run ↺   ── 一轮一个 READY task 推进，直到无 READY 或触发停止条件
```

`run` 依赖 `plan` 产出的 `docs/agent/` 文档做 check/对照；`plan` 依赖 `status` 给出的真实仓库状态。三者可单独调用，但首次接手一个仓库建议按序走一遍。
