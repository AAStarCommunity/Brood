---
id: TASK-42
title: PR-Daemon: R1 prompt add rename-identifier repo-wide grep step
status: To Do
assignee: []
created_date: '2026-08-03 12:33'
labels:
  - pr-daemon
  - review-quality
dependencies: []
priority: medium
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
DeepSeek R1 在改名/上下文类 PR 上反复漏报:改名(如 AuraAIHQ→iDoris-ai)只改了部分文件,残留引用还会让 sync-progress dedup 追加重复 URL(功能 bug)。Brood#22、#29 两次 review 都明确建议:R1 的 prompt 加一步'对被改的标识符做 grep -r <old-name> 全仓扫,检查是否有未更新的引用'。低成本、堵住 R1 每次都漏的这一类。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 R1 prompt 含 rename-identifier 全仓 grep 检查步
- [ ] #2 对改名类 PR 能报出残留旧引用
<!-- AC:END -->
