---
id: TASK-44
title: Move executable ops tools out of docs/ to scripts/
status: To Do
assignee: []
created_date: '2026-08-03 12:33'
labels:
  - process
  - repo-hygiene
dependencies: []
priority: low
ordinal: 12000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
AirAccount#193 review 指出:可执行运维脚本塞在 docs/ 下会逃过 lint/CI/review 覆盖。凡 docs/ 里的 .sh/.py 等可执行工具应移到 scripts/ 或 <component>/tools/,纳入 lint/CI。做一次全生态扫描(docs/ 下的可执行文件)+ 迁移 + 建约定。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 docs/ 下不再有可执行脚本
- [ ] #2 迁移后的脚本纳入 CI/lint
<!-- AC:END -->
