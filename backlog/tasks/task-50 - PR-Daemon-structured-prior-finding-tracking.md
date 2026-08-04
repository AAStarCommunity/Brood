---
id: TASK-50
title: PR-Daemon: structured prior-finding tracking (root-fix 10-round convergence)
status: To Do
assignee: []
created_date: '2026-08-04 03:26'
labels:
  - pr-daemon
  - review-quality
dependencies: []
priority: high
ordinal: 18000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**目标仓库:PR-Daemon**。Codex 对抗分析判定:desync/超时是失败态修补,**真正最大的赢是结构化 finding 追踪**——治的是 #28 那种 10 轮收敛(review-loop convergence latency,不是单次延迟)。现在每轮 review 从 markdown 重新啃上下文、重新发现 prior blocker。改法:给每个 blocker 稳定 ID + {file,path,line,trigger,fix,status} 结构化存储;下一轮 prompt **先只核实 prior blocker 改没改**(diff 了才重评),只有碰到的代码/风险要求时才 broaden。这样修一个 PR 从'每轮全量重评 20 分钟 × 10'降到'每轮只核增量'。已完成的两个前置(本会话):desync 修复(last_reviewed 记 review 实际 commit,不循环)+ Codex 挂起 14→6min。相关 [[TASK-46]](SQLite finalize 事务)。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 每个 finding 有稳定 ID + 结构化字段(file/line/trigger/fix/status)持久化
- [ ] #2 增量重评:prompt 先核实 prior blocker 是否在新 diff 里被改,未改的直接确认、不重新全量挖
- [ ] #3 同一 PR 多轮的总 review 时间显著下降(不再每轮全量 20 分钟)
<!-- AC:END -->
