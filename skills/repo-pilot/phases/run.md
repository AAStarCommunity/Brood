# Phase: run — 单轮开发循环（可被 /loop 反复调用）

**一次调用 = 推进「一个」东西一步。** 设计成可被 `/loop 10m repo-pilot run` 反复调用，跑通宵。
每一轮先处理待办 PR（回执优先），再考虑开新 task。绝不并行动多个 task。

前置：`docs/agent/{roadmap,tasks,progress}.md` 已存在（否则先 `repo-pilot plan`）。
读 `.repo-pilot.yml` 取 `base_branch`、`integration_branch`、`remote`。

## 每一轮的决策顺序（从上到下，命中即执行，然后结束本轮）

### 0. 安全前置
- `git status` 看当前分支与改动。若在主干（main/master）且有未提交改动 → 停下报告，不自动处理。
- 绝不 `git add -A`；绝不直推主干；一个 task 一个分支一个 PR。

### 1. 有 PR 已被 review → 先处理回执
运行 `bash <skill>/scripts/pr-monitor.sh`，对我的每个 open PR：
- **`decision=APPROVED` 且 checks 通过** → 合并进**集成分支**（不是主干）：
  `gh pr merge <n> --squash --delete-branch`（合并目标须为 `integration_branch`；若 PR base 是主干，先改 base 或按仓库约定，绝不把未受控代码直接进主干）。
  合并后：把对应 Task 在 `tasks.md` 标 `DONE`、更新 `progress.md`，运行 `safe-cleanup.sh --apply` 清掉该已合并分支/worktree。**本轮结束。**
- **`decision=CHANGES_REQUESTED`** → 读全部 review 意见（`gh pr view <n> --comments`），在该 PR 的分支上修复 → 自测 → 自审 → `git add <显式路径>` + commit + push（**新 commit 会被 pr-daemon 自动再 review**）。把 Task 标 `CHANGES_REQUESTED→IN_PROGRESS`，更新 progress.md。**本轮结束。**
- **`decision=PENDING`**（还没被 review）→ 不动它，交给外部 pr-daemon。见 §PR 监控节奏。

> review 由**外部 pr-daemon** 做（见 `reference/pr-review-loop.md`），本 skill 不自评自审 PR 的最终裁决。我只负责：开好 PR、按回执修、approve 后合并。

### 2. 无待处理回执 → 挑一个新 READY task 开工
从 `tasks.md` 选**优先级最高、依赖已满足**的 `READY` task（一次只选一个）：
1. 标 `READY→IN_PROGRESS`，更新 progress.md。
2. **建分支 + worktree**：`git worktree add ../<repo>-<taskid> -b <type>/<taskid>-<slug> <integration_branch>`（一个 task 一个 worktree，隔离并行）。简单仓库可只建分支不建 worktree。
3. **实现**：对照 `architecture.md`/`spec.md` 写代码，范围严格限制在该 task 的「开发范围」，不顺手做别的。
4. **自测**：先针对性测试，再 lint → typecheck → build → 集成测试。有失败就修到全绿。
5. **对抗式 review**（PR 前必做，见 `reference/pr-quality.md`）：换新上下文/子 agent 或 Codex（`/codex:rescue`），以「找 race/安全/错误处理/边界/生产失败」的挑剔视角审这段 diff。有阻塞问题 → 修 → 重新自测 → 再挑战，直到无阻塞。
6. **自审 diff**：`git diff` 逐块看，确认没有调试代码、密钥、无关改动。
7. **提交**：`git status` → **`git add <逐个显式路径>`**（绝不 `-A`/`.`）→ `git commit`（conventional commit）→ `git push -u <remote> <branch>`。
8. **开 PR**：`gh pr create --base <integration_branch> --title ... --body ...`（body 写清 task、验收命令、自测结果）。**绝不 `--admin` 直合，绝不推主干。**
9. 把 Task 标 `IN_PROGRESS→PR_OPEN`，在 tasks.md/progress.md 记 PR 链接。**本轮结束**，等 pr-daemon review。

### 3. 无 READY task 且无待办 PR → 停止条件
报告「本轮无可推进项」。若由 /loop 驱动：说明所有 task 已 DONE 或在 PR_OPEN/BLOCKED，建议停止 loop 或等待 review。不要制造无意义的空 commit。

## PR 监控节奏（提交 PR 后怎么等回执）

外部 pr-daemon 默认 **10 分钟**一轮（提交频繁可 5 分钟）。所以：
- 用 `/loop 10m repo-pilot run` 驱动时，每 10 分钟的一轮天然就是一次监控——`run` 开头的 §1 会用 `pr-monitor.sh` 扫回执并行动。这已满足「5/10/15 分钟扫一下是否被 review」的诉求。
- 若想更细的一次性监控（刚开完一个 PR、想盯 5/10/15 分钟），可用 Monitor 工具或 `/loop 5m repo-pilot run`，每轮 pr-monitor 一次。
- 本仓库**必须在 pr-daemon 的轮询列表里**，回执才会来；`doctor` 会检查。不在列表 → 提示用户把本仓库加入 pr-daemon 列表，否则 PR 不会被自动 review。

## 无人值守纪律
- 遇到影响产品方向/验收/架构的未知 → 把 task 标 `BLOCKED` + 在 progress.md 记待决问题，跳过它做别的，**绝不替用户拍板**。
- 每一步都落到 `tasks.md` + `progress.md`；宁可文档啰嗦，不可与仓库真实状态脱节。
- 任何一轮都不得违反全局硬约束（见 SKILL.md）：不 `add -A`、不直推/直合主干、一 task 一分支一 PR、删分支只 `-d` 且只删已合并+干净。
