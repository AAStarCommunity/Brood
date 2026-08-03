# Phase: run — 单轮开发循环（可被 /loop 反复调用）

**一次调用 = 推进「一个」东西一步。** 设计成可被 `/loop 10m pilot run` 反复调用，跑通宵。
每一轮先处理待办 PR（回执优先），再考虑开新 task。绝不并行动多个 task。

前置：`docs/agent/{roadmap,tasks,progress}.md` 已存在（否则先 `pilot plan`）。
读 `.pilot.yml` 取 `base_branch`、`integration_branch`、`remote`；**若无 `.pilot.yml` 但有旧的 `.repo-pilot.yml`，读旧文件并警告迁移**（见 SKILL.md「迁移兜底」——静默忽略会用错集成分支）。

## 每一轮的决策顺序（从上到下，命中即执行，然后结束本轮）

### 0. 安全前置
- `git status` 看当前分支与改动。若在主干（main/master）且有未提交改动 → 停下报告，不自动处理。
- 绝不 `git add -A`；绝不直推主干；一个 task 一个分支一个 PR。
- **暂存/推送/合并三个危险动作一律走 `scripts/git-guard.sh`**（脚本层硬拦截），不要裸用 `git add`/`git push`/`gh pr merge`。
- **把本仓库受保护分支用 `--protect` 传给 git-guard 的每次 push/merge-pr 调用**（默认列表之外的 `base_branch`/`integration_branch`/`protect_patterns` 也被拦）。**不要用 `export PILOT_PROTECTED`**——env 不跨独立的分步 Bash 调用存活，护栏会静默退化成只剩内置默认。记住这个 csv，**每次调用都带上**：
  ```bash
  PROT="<base_branch>,<integration_branch>,<protect_patterns 逗号分隔>"   # 从 .pilot.yml 取
  # 之后每次危险动作都在 subcommand 前加 --protect "$PROT":
  #   bash <skill>/scripts/git-guard.sh --protect "$PROT" push <remote> <branch>
  #   bash <skill>/scripts/git-guard.sh --protect "$PROT" merge-pr <n> --integration <b> --squash
  ```
  （git-guard 内置 main/master/develop/preview/integration/release/hotfix，前缀匹配；`--protect` 把仓库实际值补进去。）

### 1. 有 PR 已被 review → 先处理回执
运行 `bash <skill>/scripts/pr-monitor.sh`，对我的每个 open PR：
- **`decision=APPROVED` 且 checks 通过** → 合并进**集成分支**（不是主干）：
  `bash <skill>/scripts/git-guard.sh --protect "$PROT" merge-pr <n> --integration <integration_branch> --squash`
  （git-guard 会先校验 PR base == `integration_branch`，base 是主干或其它分支会被拒绝；**不加 `--delete-branch`**——远程分支删除统一交给 §合并后的 safe-cleanup，受 `allow_remote_cleanup` 与 dirty-worktree 检查约束）。
  合并后：把对应 Task 在 `tasks.md` 标 `DONE`、更新 `progress.md`，运行
  `bash <skill>/scripts/safe-cleanup.sh --integration <integration_branch> [--protect "<protect_patterns>"] [--remote-name <remote>] --apply`
  清掉本地已合并分支/worktree（**必须显式带上与 `.pilot.yml` 一致的 `--integration`/`--protect`/`--remote-name`，不要依赖脚本猜默认值**；要连带删远程，且 `allow_remote_cleanup: true` 时，再加 `--remote`）。**本轮结束。**
- **`decision=CHANGES_REQUESTED`** → 读全部 review 意见（`gh pr view <n> --comments`），**先做中立 triage（见 `reference/review-triage.md`）**：装上本仓库业务上下文（CLAUDE.md / docs/agent / 领域文档），把每条意见分成 A 该修 / B 不重要 / C 缺业务上下文判错了 / D 过激 nitpick。评审 daemon 是独立进程、没有业务背景,你有——**既不盲改也不盲拒**。
  - **A（+trivial 的 D）** → 在该 PR 分支修复 → 自测 → 自审 → `git-guard.sh add <显式路径>` + commit + `git-guard.sh --protect "$PROT" push <remote> <branch>`（新 commit 触发 daemon 再评审）。
  - **B（真问题但不阻塞）/ 非 trivial 的 D 里决定要做的** → **记进跟进账本,绝不丢**：
    `bash <skill>/scripts/followups.sh add --docs-dir <docs_dir> --class B --source "PR#<n>" --desc "<要做什么>"`。
    **不在本 PR 里做**——留到主线全清后批量合成一个 cleanup PR（见 §2.5）。
  - **C / 不做的 D** → **不改**，`gh pr comment <n>` 回一条讲清业务理由（让 daemon 下一轮和人类都看到）。
  - 把 Task 标 `CHANGES_REQUESTED→IN_PROGRESS`，更新 progress.md。**把 followups.md 一起 `git-guard.sh add` 进本次 commit**（账本随分支合并落库,不留在工作区）。**本轮结束。**
- **`decision=APPROVED` 但带 review comments** → 先按上面 APPROVED 分支**合并**（comment 不阻塞合并）。合并后对每条 comment 过 triage：A/B 用 `followups.sh add --docs-dir <docs_dir>` 记进账本；C/D 在 PR 上回一句说明即可，不在已合并分支补提。**本轮结束。**
- **`decision=PENDING`**（还没被 review）→ 说明还没轮到或 daemon 没在跑。**先确保 daemon 在线**：`bash <skill>/scripts/ensure-pr-daemon.sh ensure`（没在跑就拉起，在跑就 no-op），然后按 §PR 监控节奏等 5–10 分钟再看回执。不要在 PENDING 的 PR 上瞎改。

> review 由**外部 pr-daemon** 做（见 `reference/pr-review-loop.md`），本 skill 不自评自审 PR 的最终裁决。我只负责：开好 PR、按回执修、approve 后合并。

### 2. 无待处理回执 → 挑一个新 READY task 开工
从 `tasks.md` 选**优先级最高、依赖已满足**的 `READY` task（一次只选一个）：
1. 标 `READY→IN_PROGRESS`，更新 progress.md。
2. **建分支 + worktree**：`git worktree add ../<repo>-<taskid> -b <type>/<taskid>-<slug> <integration_branch>`（一个 task 一个 worktree，隔离并行）。简单仓库可只建分支不建 worktree。
3. **实现**：对照 `architecture.md`/`spec.md` 写代码，范围严格限制在该 task 的「开发范围」，不顺手做别的。
4. **自测**：先针对性测试，再 lint → typecheck → build → 集成测试。有失败就修到全绿。
5. **对抗式 review**（PR 前必做，见 `reference/pr-quality.md`）：换新上下文/子 agent 或 Codex（`/codex:rescue`），以「找 race/安全/错误处理/边界/生产失败」的挑剔视角审这段 diff。有阻塞问题 → 修 → 重新自测 → 再挑战，直到无阻塞。
6. **自审 diff**：`git diff` 逐块看，确认没有调试代码、密钥、无关改动。**别指望 pre-commit 钩子兜底**——先 `bash <skill>/scripts/check-hooks.sh`,若报 `BYPASSED`(hooksPath 指到别处/空目录),commit 时的密钥扫描根本没跑,这一步的人肉排查就是**唯一防线**,务必逐字节看清无密钥/token/`.env`/私钥。
7. **提交**：`git status` → **`bash <skill>/scripts/git-guard.sh add <逐个显式路径>`**（绝不 `-A`/`.`，git-guard 会硬拒绝）→ `git commit`（conventional commit）→ **`bash <skill>/scripts/git-guard.sh push <remote> <branch>`**（推主干会被硬拒绝）。
8. **开 PR**：`gh pr create --base <integration_branch> --title ... --body ...`（body 写清 task、验收命令、自测结果）。**绝不 `--admin` 直合，绝不推主干。**
9. 把 Task 标 `IN_PROGRESS→PR_OPEN`，在 tasks.md/progress.md 记 PR 链接。**开完 PR 立刻确保评审 daemon 在线**：`bash <skill>/scripts/ensure-pr-daemon.sh ensure`（否则没人 review，PR 会一直挂着）。**本轮结束**，进入 §PR 监控节奏等回执。

### 2.5 无 READY task 了 → 批量清跟进账本（主线做完才做，绝不提前）
**只有当 §2 没有可开工的主线 READY task**（都 DONE 或在 PR_OPEN/BLOCKED）时，才处理跟进账本：
1. `n=$(bash <skill>/scripts/followups.sh count-open --docs-dir <docs_dir>)`。为 0 → 跳到 §3。
2. `>0` → **把这些小项合并成一个 cleanup PR 一次做掉**（不是一项一个 PR）：
   - `followups.sh list --open --docs-dir <docs_dir>` 拿到全部 OPEN 项；建一个分支 `chore/followups-<date>`（从集成分支）。
   - 逐条修复（都是小/非阻塞项）；一个 commit 或按主题分几个 commit，`git-guard.sh add` 显式路径（**含 followups.md**）。
   - 对每条修好的 `followups.sh done FU-<n> --pr <本PR号> --docs-dir <docs_dir>` 标掉（append-only,只翻 [x] 不删行）。
   - `git-guard.sh push` → `gh pr create`（title 如 `chore: batch followup fixes (FU-3, FU-7…)`，body 列清每条对应的原 PR/comment）→ 走正常评审→合并。
   - **判断力**：某条其实是真 feature/bug 规模的 → 不塞进批量,**提升为 tasks.md 里的正常 READY task**,走单独流程。批量只装小/相关的。
3. 账本里还有 OPEN 项没清完 → 下一轮继续；**清空前不进 §3**。

### 3. 无 READY task、无待办 PR、且跟进账本已清空 → 停止条件
先确认 `followups.sh count-open --docs-dir <docs_dir>` 为 0（否则回 §2.5,**不许在有 OPEN 跟进项时宣布停止**）。都满足才报告「本轮无可推进项」。若由 /loop 驱动：说明所有 task 已 DONE 或在 PR_OPEN/BLOCKED、跟进账本已清空，建议停止 loop 或等待 review。不要制造无意义的空 commit。

## PR 监控节奏（提交 PR 后怎么等回执）

**核心规则：只要提了 PR，就要监控它自己的状态,直到拿到回执再决定下一步。** pilot 不自评 PR——
评审由外部 PR-Daemon 后台 loop 做（详见 `reference/pr-review-loop.md`）。它默认 **10 分钟**一轮
（提交频繁可 5 分钟），是一个脱离终端的 `nohup` 后台进程,独立于任何 Claude 对话存活。

开完一个 PR 之后的等待与升级流程：

1. **立刻确保 daemon 在线**：`bash <skill>/scripts/ensure-pr-daemon.sh ensure`。没在跑就拉起,在跑就 no-op。
   ——不需要跨对话唤醒魔法,daemon 就是个后台进程,拉起来它自己会评审三大组织下所有配置仓库的 open PR。
2. **盯回执——分清"评审者"和"监控者"两个角色**：评审由 daemon 做（step 1 已拉起）；**"我的 PR 拿到裁决没"由本 skill 自己盯**，脚本是 `pr-monitor.sh`（读 `reviewDecision`，只查一次，不驱动自己）。真正的监控 = 有东西按节奏反复调它、状态变了再唤醒你行动。按场景选驱动方式：

   - **默认（同一会话刚开完一个 PR、想立刻盯到回执）→ 用 Monitor 工具**：轮询 `bash <skill>/scripts/pr-monitor.sh --pr <n>`,退避间隔 5 分钟起,**直到 `reviewDecision` 不再是 `PENDING`（变成 `APPROVED`/`CHANGES_REQUESTED`）才唤醒**,然后回 §1 按结果行动。这是最省的路径——只在状态真的变了才起一整轮,和开 PR 的是同一个上下文。
   - **通宵推多个 task → `/loop 10m pilot run`**：每 10 分钟重跑一轮,`run` 开头的 §1 自动 `pr-monitor.sh` 扫所有 open PR 的回执并行动。适合"边等这个 PR 边开下一个 task",代价是每轮无论有无变化都起一整个 Claude 轮次。
   - 想比固定间隔更聪明地退避 → `ScheduleWakeup` 自排下次唤醒。

   > 别用裸 `sleep` 空转终端等回执——那样既占着会话又不省 token。要么 Monitor（条件唤醒）、要么 /loop（定时重跑）。
3. **等满 5–10 分钟仍 `PENDING`（没被 review）**：极可能是 daemon 挂了或本仓库不在轮询列表。
   - 先再 `ensure-pr-daemon.sh check`：若 `not running` → `ensure` 重新拉起。
   - 本仓库**必须在 PR-Daemon 的轮询列表里**回执才会来（`doctor` 会检查）。不在列表 → 提示用户把本仓库加入,否则 PR 永远不会被自动 review。
   - 拉起后继续下一轮等待,不要在 PENDING 的 PR 上瞎改。
4. **拿到回执后**回到 §1 按结果行动：APPROVED→合并 / APPROVED+comment→合并+跟进 task / CHANGES_REQUESTED→修改+重推(触发再评审)。

## 无人值守纪律
- 遇到影响产品方向/验收/架构的未知 → 把 task 标 `BLOCKED` + 在 progress.md 记待决问题，跳过它做别的，**绝不替用户拍板**。
- 每一步都落到 `tasks.md` + `progress.md`；宁可文档啰嗦，不可与仓库真实状态脱节。
- 任何一轮都不得违反全局硬约束（见 SKILL.md）：不 `add -A`、不直推/直合主干、一 task 一分支一 PR、删分支只 `-d` 且只删已合并+干净。

