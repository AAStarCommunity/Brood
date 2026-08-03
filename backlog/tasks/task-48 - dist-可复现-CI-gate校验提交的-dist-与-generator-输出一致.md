---
id: TASK-48
title: dist/ 可复现 CI gate(校验提交的 dist 与 generator 输出一致)
status: To Do
assignee: []
created_date: '2026-08-03 13:48'
labels:
  - infra
  - ci
dependencies: []
priority: low
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**目标:Brood**。digest item:dist/ 有意提交进 git(local build 模式),但无自动校验它是否可从 generator 复现(#21 靠人肉 byte-diff)。加 CI gate:重跑 build,diff 提交的 dist/ 与生成结果,不一致则 fail;剔除已知的每-build 时间戳类非确定性差异。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 CI 重跑 build 并 byte-diff dist/,漂移即 fail
- [ ] #2 时间戳类非确定性字段在比对前归一化
<!-- AC:END -->
