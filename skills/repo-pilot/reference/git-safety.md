# Git 安全规则（不可破）

有经验的程序员的底线。任何阶段、任何模式都遵守。

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
- 一个 task = 一个分支 = 一个（可选）worktree = 一个 PR。分支命名 `<type>/<taskid>-<slug>`，如 `feat/T1.3.2-admin-init`。

## 删除（清理）
- **删本地分支只用 `git branch -d`，永不 `-D`**。`-d` 会拒绝删除未合并分支，是安全网；`-D` 强删会丢未合并工作。
- 只删「已合并进集成分支 + 干净」的分支/worktree。
- 一切经 `scripts/safe-cleanup.sh`，默认 dry-run，`--apply` 才执行。**不要在对话里手工逐个删**，避免漏判保护分支。
- 删远程分支（`--remote`）需 `.repo-pilot.yml` 里 `allow_remote_cleanup: true` + 用户明确同意；无人值守默认不删远程。
- 永不碰：当前分支、集成分支、主干、protected 前缀（release/hotfix…）、脏 worktree 及其远程分支。

## 危险操作一律先确认
- `git reset --hard`、`git clean -fd`、`git rebase`（改写已推送历史）、`git push --force` —— 除非用户明确要求，否则不做；做前先解释后果。
- force push 只允许 `--force-with-lease`，且只在自己的 feature 分支。
