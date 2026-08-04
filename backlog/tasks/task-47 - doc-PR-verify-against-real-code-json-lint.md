---
id: TASK-47
title: "doc PR: verify against real code + curl JSON-lint + arch from real routes"
status: To Do
assignee: []
created_date: '2026-08-03 13:47'
labels:
  - review-quality
  - process
dependencies: []
priority: medium
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**目标:Brood + review 流程**。digest:docs refresh 反复断言端口/路径/endpoint/JSON 与真实代码不符(#18 幻影 UI:8080、非法 JSON、frps 表述)。建立约定 + 自检:文档里的 curl body 过 JSON-lint;引用真实代码的端口/路径/endpoint 必须对源码核对;架构图从真实路由生成而非凭印象。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 PR 自检脚本对 docs 里的 JSON 片段做 lint
- [ ] #2 涉及真实接口的文档改动附上源码引用(file:line)
<!-- AC:END -->
