# pilot — 仓库级开发操作系统（可安装 skill）

一个 skill、三个阶段，把**一个仓库**从「盘点 → 规划 → 持续开发」带到底。可移植到 **Claude Code** 与 **Codex**。

```
pilot status   # 汇报进展 + 安全清理已合并分支/worktree（默认 dry-run）
pilot plan     # 建立/汇报 Milestone(M1) → Feature(F1.1) → Task(T1.1.1)
pilot run      # 单轮开发循环，可被 /loop 反复调用跑通宵
pilot doctor   # 自检：是否具备自动运行条件
```

## 为什么用它
把「有经验程序员的默认」固化成流程，且**危险动作确定性可控**：

- **安全清理**：只删「已合并进集成分支 + 干净」的分支/worktree；只 `git branch -d`（永不 `-D`）；默认 dry-run，`--apply` 才动手；护住主干/集成/当前/protected/脏 worktree。逻辑全在 `scripts/safe-cleanup.sh`，不靠模型临场判断。
- **PR 纪律**：绝不 `git add -A`；绝不直推/直合主干；一个 task = 一个分支 = 一个 worktree = 一个 PR；PR 前必自测 + 对抗式 review。
- **外部 review 回路（已生产验证）**：pilot 不自评 PR——开好 PR 后调 `scripts/ensure-pr-daemon.sh`（**幂等**：在跑 no-op、没跑才拉起，从任意仓库触发都只有一个实例）启动 PR-Daemon。daemon 按风险分流：琐碎（docs/依赖）走 DeepSeek 2 轮、涉代码/安全走**真 Opus R2/R4 + Codex R3** 的 4 轮 PK；draft 与 `[WIP]`/`PAUSED` 自动跳过；`head` 去重不重评。本仓库只收回执 + approve 后合并（见 `reference/pr-review-loop.md`）。
- **可被 /loop 驱动跑通宵**：`pilot run` 是单轮迭代，`/loop 10m pilot run` 即可持续推进 READY tasks。

## 能力总览

| 子命令 | 干什么 | 确定性保障 |
|:--|:--|:--|
| `status`（默认） | 汇报进展 + 安全清理已合并分支/worktree | 只 `-d` 删「已合并+干净」；默认 dry-run，`--apply` 才动手；护主干/集成/protected/脏 worktree |
| `plan` | 建 M→F→T 三级规划 + 补齐 `docs/agent` 文档 | 缺 `.pilot.yml`/文档会代生成 |
| `run` / `resume` | 单轮循环：挑 READY task → 开发 → 自测 → 对抗 review → PR → 合并 preview | 一 task 一分支一 PR；不 `add -A`；不直推主干；PR 前必自审 |
| `doctor` | 只读自检：能否无人值守 | 不改仓库，只报「就绪/待补」 |

危险动作全走脚本层硬拦截（`git-guard.sh` 拒 `add -A`/直推主干/合错 base；`safe-cleanup.sh` 只删已合并+干净），不靠模型临场判断。

## 使用建议

- **首次接手**：`doctor` → `status` → `plan`，人工过目 roadmap/READY tasks 后再开 `run`。
- **有人看着推进**：直接 `pilot run` 一轮一轮开，你审每个 PR 的回执。
- **通宵无人值守**：`/loop 10m pilot run`——每轮先处理待办 PR 回执、再挑新 task；配合 PR-Daemon 后台自动 review。
- **review 后端成本**：PR-Daemon 跑真 Opus/Codex 会占用你的 Claude 订阅额度、并和交互式使用抢限流。忙时限并发（实测 ~2–3 并发即触发 Max 限流）或设时间窗口；琐碎 PR 走 DeepSeek 2 轮几乎零成本。
- **不适合**：一次改多个不相关 task；需人拍板的产品/架构决策（pilot 会把这类 task 标 `BLOCKED`，绝不擅自替你决定）。

## 安装

### Claude Code（全局，推荐 symlink 持续更新）
```bash
git clone https://github.com/AAStarCommunity/Brood.git
bash Brood/skills/pilot/install.sh            # 软链到 ~/.claude/skills/pilot
# 之后 Brood 里更新 skill，全局自动跟着更新
```
或在已 clone 的 Brood 内直接：`bash skills/pilot/install.sh`

### Codex（全局）
```bash
bash Brood/skills/pilot/install.sh --codex    # 软链到 ~/.codex/skills/pilot
```
> Codex 也支持项目级 `.agents/skills/`。若你的 Codex 版本 skills 目录不同，用 `--copy` 手动放到对应目录即可。

### 单个仓库内安装（提交进该仓库、随仓库分发）
```bash
bash Brood/skills/pilot/install.sh --project /path/to/your-repo
# 同时装到该仓库的 .claude/skills/ 与 .agents/skills/
```

### 分发到没有 Brood 源的机器
```bash
bash install.sh --copy         # 复制而非软链，脱离源仓库独立存在
```

卸载：`bash install.sh --uninstall [--claude|--codex|--both|--project <path>]`

## 首次接手一个仓库
```bash
pilot doctor     # 看缺什么（.pilot.yml / docs / 集成分支 / gh / pr-daemon 列表）
pilot status     # 盘点 + 清理战场
pilot plan       # 建立/补齐 M→F→T 规划与文档
# 人工过目 roadmap 与 READY tasks 后：
/loop 10m pilot run   # 持续开发，跑通宵
```

## 配置
仓库根目录放 `.pilot.yml`（`doctor`/`plan` 可代生成，模板见 `templates/pilot.example.yml`）：
```yaml
base_branch: main
integration_branch: preview   # PR 合并进这里，不是主干
protect_patterns: [release, hotfix]
remote: origin
allow_remote_cleanup: false
docs_dir: docs/agent
```

## 目录结构
```
pilot/
├── SKILL.md                 # 分派 + 全局硬约束
├── phases/{status,plan,run}.md
├── scripts/                 # 确定性核心（read-only 扫描 / 安全清理 / PR 监控）
│   ├── repo-scan.sh  safe-cleanup.sh  pr-monitor.sh
├── reference/               # git-safety / pr-quality / pr-review-loop / task-schema
├── templates/               # roadmap/tasks/progress/acceptance/architecture/spec/research + .pilot.yml
├── install.sh
└── README.md
```

## 文档信息流
```
research → acceptance → architecture + spec → roadmap → tasks → progress
（为什么做  给谁·标准    骨架·契约      数据·状态   M→F      逐条落地  实时状态）
```
上层是下层前置约束，越往下越可执行。`run` 最少需要 `roadmap + tasks + progress`。

> skill 文档持续维护；更新后已 symlink 安装的会自动生效，`--copy` 安装的重跑 install.sh 即可。
