---
id: TASK-43
title: Money/gas tasks: machine-verifiable acceptance criteria
status: To Do
assignee: []
created_date: '2026-08-03 12:33'
labels:
  - review-quality
  - process
dependencies: []
priority: medium
ordinal: 11000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
YetAnotherAA#450 的 gas-retry 任务验收只有 type-check/lint,review 指出应有硬断言(如'重试 gas ≤ N× cap')。凡是碰钱/gas/额度的任务,acceptance criteria 要写成机器可验证的断言而非'编译通过',否则 review 无法客观判定、容易放过资金风险逻辑。来源:reviews/AAStarCommunity-YetAnotherAA-450-approve-99fb4b6.md
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 在 `.claude/skills/pilot/templates/`(或 backlog 任务模板)新增/扩展"涉钱任务"模板,含'机器可验证断言'字段
- [ ] #2 至少一个可执行的数值边界检查(如 gas 上限),以断言脚本或测试形式落地、可在 CI 跑
<!-- AC:END -->
