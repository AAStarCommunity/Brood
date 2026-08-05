# Brood Tasks — 执行台账

> ⚠️ **本文件是视图，不是事实来源。** 任务的事实来源是 `backlog/tasks/*.md`（backlog.md CLI），
> 每个任务自带 `status` / `milestone` / `dependencies` / `references` / Acceptance Criteria。
> **改任务请改 `backlog/`，不要改这里。** 本文件只说明「怎么读它、怎么挑下一个」。

## 怎么看任务

```bash
ls backlog/tasks/                       # 全部任务文件
npx backlog task list                   # CLI 视图
grep -l "^status: In Progress" backlog/tasks/*.md   # 在做的
```

站点视图：`pnpm run build` 后 `dist/`，或已部署的 BroodBrain 页面。

## 状态机

`To Do` → `In Progress` → `Done`。这是 backlog.md CLI 的三态，**不是** pilot
`reference/task-schema.md` 里的 READY/PR_OPEN/BLOCKED 五态。两套状态并存是事实，
pilot 侧把 `To Do` 当 READY 读、`In Progress` 当在途读即可，不要试图在 backlog 里造新状态。

## 当前分布（2026-08-05 实测）

| 状态 | 数量 |
|:---|---:|
| To Do | 27 |
| In Progress | 15 |
| Done | 7 |
| **合计** | **49** |

按里程碑看 In Progress：M1 五个（主战场）、M-R 五个、M3 三个、M2 两个。

## 怎么挑下一个

1. 优先 **M1** 的 `To Do`——它是当前重心（见 `roadmap.md`）。
2. 该任务必须能写出**机器可验证的验收命令**；写不出说明还太大，先拆。
3. 有 `dependencies:` 且依赖未 Done 的，跳过。
4. 涉及产品方向 / 验收标准 / 架构的未知 → 标 BLOCKED 记下问题，**不猜**（SKILL.md 硬约束 7）。

## 本仓库自己的任务（pilot / CI 方向）

这些是 Brood 作为「工具仓库」自己的活，和生态业务任务并列在 `backlog/` 里：

- **TASK-40** — pilot PreToolUse hook 机械拦截 `git add -A` / 推主干。**SKILL.md 自称这是首要强制手段，但状态仍是 To Do**，也就是最强的那句承诺目前实现为空。
- **TASK-39** — sync-progress 的 gh api 校验，防伪造进度
- **TASK-47** — 文档类 PR 对照真实代码 + JSON lint
- **TASK-43** — 涉钱/gas 任务的机器可验证验收

## 不阻塞的跟进项

见 `followups.md`（append-only 账本，`scripts/followups.sh` 维护）。
