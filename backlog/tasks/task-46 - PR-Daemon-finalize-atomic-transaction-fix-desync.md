---
id: TASK-46
title: PR-Daemon: finalize as atomic transaction (root-fix SQLite dup-review)
status: To Do
assignee: []
created_date: '2026-08-03 13:47'
labels:
  - pr-daemon
  - infra
dependencies: []
priority: medium
ordinal: 14000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**目标仓库:PR-Daemon(~/Dev/tools/PR-Daemon)**。digest item 4:SQLite 单写锁竞争(56 次 database is locked)导致 post 完 review 后本地 last_reviewed_head_oid 的 UPDATE 偶尔失败 → PR 卡在 needs_review → 同 head 重复 dispatch。修:把 post 后的 finalize(UPDATE pr_watch_targets + 归档 md)做成不可被 SIGTERM 打断的短事务、并 promptly commit;手动单-PR review 前先查 current-review.json/运行中 PID 防自撞。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 post review 后 finalize 在一个短事务内完成并立即 commit
- [ ] #2 SIGTERM 不会在 post 与 finalize 之间中断
- [ ] #3 同 head 不再重复 dispatch(压测锁竞争下 0 重复)
<!-- AC:END -->
