---
id: TASK-45
title: serial-run.py 输出机器可读的 per-command 结果
status: To Do
assignee: []
created_date: '2026-08-03 12:34'
labels:
  - pr-daemon
  - infra
dependencies: []
priority: low
ordinal: 13000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
AirAccount#193 review:serial-run.py 一次改成输出机器可读的 per-command 结果(nonce/分隔符界定)可一次关掉 3 个 blocking bug(输出解析歧义)。让每条命令的 result 结构化、可被上游可靠解析。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 每条命令输出 nonce 分隔的结构化结果
- [ ] #2 上游解析不再靠 marker/echo 猜测
<!-- AC:END -->
