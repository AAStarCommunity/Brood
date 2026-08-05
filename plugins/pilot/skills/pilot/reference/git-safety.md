# Git 安全规则（不可破）

有经验的程序员的底线。任何阶段、任何模式都遵守。

> **谁强制这些规则**：真正不可绕过的保证是 ① GitHub 分支保护 + ② 待建的 PreToolUse hook（TASK-40）。`git-guard.sh`/`safe-cleanup.sh` 是**便利包装 + 纵深防御一层**（best-effort，覆盖常见危险形状，不承诺 bash 层对抗式滴水不漏）。危险动作优先走它们，但别把它们当唯一防线。

## 提交
- **绝不 `git add -A` / `git add .` / `git add -u`**。只 `git add <显式路径>`。
  - 为什么：`-A` 会把未确认是否该跟踪的文件一起提交——`.env`、密钥、token、构建产物、临时文件、别人的改动。这是日常最危险的动作，一次误提交密钥可能不可逆。
  - 正确姿势：先 `git status` 看全貌 → 明确本次要提交哪些路径 → 逐个 `git add path/to/file`。
- 提交信息用 conventional commits（`feat:` / `fix:` / `docs:` / `chore:` …）。
- 提交前 `git diff --staged` 复核，确认无调试代码、无密钥、无越界改动。

## 分支与主干
- **绝不 `git push` 到主干（main/master）**。主干受保护。
- **绝不合并自己的 PR 到主干**，绝不 `gh pr merge --admin` 绕过 review。
- 所有变更：feature 分支 → PR → review → 合并到**集成分支**（默认 `preview`）。主干只由集成分支经受控流程进入。
- **单主干仓库**（没有集成分支，PR 直接开向 `main`）是合法形态。这时用
  `git-guard.sh merge-pr <n> --integration main --allow-trunk`。这个 flag **不放松「必须被 review」**，
  只放松「合到哪里」：它仍要求该分支的 GitHub 分支保护规则 `required_approving_review_count >= 1`
  **且**该 PR 的 `reviewDecision == APPROVED`；保护规则读不到就直接拒绝（fail-closed）。
  `--admin` 在任何情况下都仍然被拒。
  > 为什么要留这个口子：没有它，护栏在单主干仓库里根本用不了，人只能裸用 `gh pr merge` 绕过去——
  > **一个必须被绕过的护栏，比没有护栏更糟**，因为它教会人绕过护栏。
- 一个 task = 一个分支 = 一个（可选）worktree = 一个 PR。分支命名 `<type>/<taskid>-<slug>`，如 `feat/T1.3.2-admin-init`。

## 删除（清理）
- **删本地分支只用 `git branch -d`，永不 `-D`**。`-d` 会拒绝删除未合并分支，是安全网；`-D` 强删会丢未合并工作。
- 只删「已合并进集成分支 + 干净」的分支/worktree。
- 一切经 `scripts/safe-cleanup.sh`，默认 dry-run，`--apply` 才执行。**不要在对话里手工逐个删**，避免漏判保护分支。
- 删远程分支（`--remote`）需 `.pilot.yml` 里 `allow_remote_cleanup: true` + 用户明确同意；无人值守默认不删远程。
- 永不碰：当前分支、集成分支、主干、protected 前缀（release/hotfix…）、脏 worktree 及其远程分支。

## 危险操作一律先确认
- `git reset --hard`、`git clean -fd`、`git rebase`（改写已推送历史）、`git push --force` —— 除非用户明确要求，否则不做；做前先解释后果。
- force push 只允许 `--force-with-lease`，且只在自己的 feature 分支。
