# Phase: status — 汇报进展 + 安全清理

目标：一屏看清「这个仓库现在在哪」，并把已合并的战场清干净。**只读优先，清理默认 dry-run。**

## 步骤

1. **读配置**：Read `.repo-pilot.yml`（不存在则用默认 `base=main` / `integration=preview`，并在末尾提示可运行 `repo-pilot doctor` 生成）。取出 `integration_branch`、`protect_patterns`、`remote`。

2. **扫描**（只读）：运行
   ```
   bash <skill>/scripts/repo-scan.sh --integration <integration_branch>
   ```
   拿到：当前分支、脏文件数、未跟踪数、本地/远程/worktree 数、已合并候选、当前分支 vs 集成分支的 ahead/behind。

3. **读运行态**：若 `docs/agent/progress.md` 存在，Read 它，提取「正在开发的 Feature / Task、阻塞项」。若不存在，说明还没 `plan` 过。

4. **汇报**（三段式，简明）：
   - **当前进展**：正在开发的 Feature/Task（来自 progress.md）；当前分支 + 是否有未提交改动。
   - **仓库盘点**：本地 N 个分支 / 远程 M 个分支 / K 个 worktree；其中 X 个本地分支已合并进 `<integration>`（可清理）。
   - **清理计划**：运行
     ```
     bash <skill>/scripts/safe-cleanup.sh --integration <integration_branch> [--protect "<patterns>"]
     ```
     （**dry-run**，只打印 would-delete / would-remove / KEEP）。把结果原样呈现。

5. **征询清理**：把 dry-run 计划给用户，**问是否执行**。得到确认后才加 `--apply`：
   ```
   bash <skill>/scripts/safe-cleanup.sh --integration <integration_branch> --apply
   ```
   - 要连带删远程已合并分支：仅当 `.repo-pilot.yml` 的 `allow_remote_cleanup: true`，且用户明确同意，才加 `--remote`。
   - 无人值守模式（由 /loop 调用且用户已预先授权清理）：可直接 `--apply`，但**永远不加 `--remote`** 除非配置显式开启。

6. **建议下一步**：基于 progress.md 指出「下一个该做的 READY task」；若没有规划文档，建议 `repo-pilot plan`。

## 纪律

- 清理的所有安全判断在 `safe-cleanup.sh` 里确定性执行（只删已合并+干净、只 `-d`、护住 main/集成/当前/protected/脏 worktree）。**不要在对话里手工 `git branch -d`** —— 走脚本，避免漏判。
- 绝不 `-D`，绝不删未合并分支，绝不碰脏 worktree 或其远程分支。
- 汇报前若对某个数字存疑，重跑 `repo-scan.sh` 核对，不要凭记忆报数。
