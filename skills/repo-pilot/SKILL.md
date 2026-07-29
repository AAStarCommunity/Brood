---
name: repo-pilot
description: 仓库级开发操作系统。三阶段驱动一个仓库从「盘点 → 规划 → 持续开发」全流程。status=汇报进展+安全清理已合并分支/worktree；plan=建立/汇报 Milestone→Feature→Task 三级规划；run=单轮开发循环（挑 READY task→开发→自测→对抗 review→PR→合并 preview），可被 /loop 反复调用跑通宵。当用户说 repo-pilot / 整理仓库 / 汇报进展 / 清理分支 / 规划里程碑 / 持续开发 / 跑通宵开发时使用。
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task, TodoWrite
---

# Repo Pilot — 仓库级开发操作系统

一个 skill、三个阶段，把「一个仓库」从盘点带到持续开发。可移植到 Claude Code 与 Codex。

```
repo-pilot status   # 汇报进展 + 安全清理已合并分支/worktree（默认 dry-run）
repo-pilot plan     # Milestone(M1) → Feature(F1.1) → Task(T1.1.1) 三级规划
repo-pilot run      # 单轮开发循环，可被 /loop 反复调用
repo-pilot resume   # run 的别名：优先处理待办 PR，再挑新 task
repo-pilot doctor   # 检查本仓库是否具备自动运行条件
```

## 分派（第一步永远先做这件事）

从用户输入解析第一个词作为**子命令**，其余作为 flag：

| 子命令 | 打开并严格执行 | 说明 |
|:---|:---|:---|
| `status`（默认） | `phases/status.md` | 无子命令时默认走 status |
| `plan` | `phases/plan.md` | |
| `run` / `resume` | `phases/run.md` | 单轮迭代 |
| `doctor` | 见下方 §doctor | 轻量自检，不改动仓库 |

解析后**必须先 Read 对应的 `phases/*.md`**，按其步骤执行；本文件只定义分派与全局硬约束。

## 全局硬约束（任何阶段都不可违反）

这些是「有经验的程序员」的底线，写死在这里，任何子命令都遵守：

1. **绝不 `git add -A` / `git add .`**。只 `git add <显式路径>`。理由：`-A` 会把未确认是否该跟踪的文件（密钥、`.env`、构建产物、临时文件）一起提交，是最危险的日常动作。提交前先 `git status` 看清，逐一列出要提交的路径。
2. **绝不直接 push 到主干（main/master），绝不直接合并自己的 PR 到主干**。所有代码变更走：feature 分支 → PR → review → 合并到**集成分支**（默认 `preview`，见 `.repo-pilot.yml`）。主干只由集成分支经受控流程进入。
3. **一个 task = 一个分支 = 一个（可选）worktree = 一个 PR**。不在一个分支里顺手做别的 task。
4. **删除分支只用 `git branch -d`，永不 `-D`**；删除只针对「已合并 + 干净」的分支/worktree；一切经 `scripts/safe-cleanup.sh`，默认 dry-run。
5. **PR 之前必须自审 + 对抗 review**（见 `reference/pr-quality.md`）。没过 review 的代码不进 PR，没 approve 的 PR 不合并。
6. **状态即文档**。每推进一步都更新 `docs/agent/tasks.md` 与 `docs/agent/progress.md`；宁可慢，不可让文档与仓库真实状态脱节。
7. **无人值守时不猜产品决策**。遇到影响产品方向/验收/架构的未知，把相关 task 标 `BLOCKED` 并记录待决问题，继续做不受影响的 task；绝不擅自替用户拍板。

> 详细的 git 安全规则见 `reference/git-safety.md`；PR 质量与 review 流程见 `reference/pr-quality.md`；task 状态机与字段见 `reference/task-schema.md`。子命令会在需要时指引你读它们。

## 配置：`.repo-pilot.yml`

每个仓库根目录一份（`doctor`/`plan` 会在缺失时创建）。关键字段：

```yaml
base_branch: main            # 主干，受保护，禁止直推
integration_branch: preview  # PR 合并进这里；不存在则回退到 base_branch
protect_patterns: [release, hotfix]   # 额外保护的分支前缀
remote: origin
allow_remote_cleanup: false  # 删除远程已合并分支需显式置 true
docs_dir: docs/agent         # 规划/运行态文档目录
```

读取方式：用 Read 工具读该文件，把值作为 flag 传给脚本（脚本本身不解析 YAML，保持简单确定）。文件不存在时用上表默认值，并提示用户运行 `repo-pilot doctor` 生成。

## doctor（内联，不改仓库）

轻量自检，只读并汇报，供用户判断能否开启无人值守：

1. `git rev-parse --is-inside-work-tree` — 是否 git 仓库。
2. `.repo-pilot.yml` 是否存在；不存在则**询问用户**是否用默认值创建（复制 `templates/repo-pilot.example.yml`，把 `base_branch`/`integration_branch` 填真实值）。
3. `docs/agent/` 是否存在，`roadmap.md`/`tasks.md`/`progress.md` 是否齐全 —— 缺失则建议 `repo-pilot plan`。
4. 是否有集成分支（`git show-ref refs/heads/<integration>`）；无则提示先建。
5. `gh auth status` 是否可用（PR 流程需要）。
6. 是否存在 PR review 机器人/流程（如本机的 pr-daemon-loop / pr-fix skill）；有则 `run` 会与之衔接。
7. 汇报一张「就绪 / 待补」清单，不擅自修改。

## 阶段间关系

```
status  ── 知道现在在哪、清干净战场
   ↓
plan    ── 知道要去哪（M→F→T）、补齐规划层文档
   ↓
run ↺   ── 一轮一个 READY task 推进，直到无 READY 或触发停止条件
```

`run` 依赖 `plan` 产出的 `docs/agent/` 文档做 check/对照；`plan` 依赖 `status` 给出的真实仓库状态。三者可单独调用，但首次接手一个仓库建议按序走一遍。
