---
id: TASK-23
title: '[Meta] Phase 1: Genesis Launch'
status: In Progress
assignee: []
created_date: '2026-02-28 11:18'
updated_date: '2026-04-26 23:56'
labels:
  - milestone
  - phase-1
  - phase-1-genesis
  - Phase-1
milestone: m-1
dependencies: []
references:
  - 'https://github.com/MushroomDAO/launch'
priority: high
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A meta-task to group all Genesis Launch activities.
1. GToken launch contract
2. Shop contract and web interface

...

### 📊 进度报告 (2026-06-12 扫描)

**🚀 预估进度: 90%** | 近 30 天 30 次提交，最近一次 2026-06-07；**gasless EIP-7702 三流 UX 上线** + relayer v2 chainId/buyer 校验

**✅ AC 完成情况**:
- ✅ Shop contract and web interface — MushroomDAO/MyShop M1 全量完成
- ✅ GToken launch contract — SaleContractV2 已部署、roles ticket prices 配置完成
- ✅ 5-18 Hangzhou roadshow 完成
- ✅ **gasless EIP-7702 三流 UX**：join-gasless.html (P3, on top of #8) 上线
- ✅ **gasless-eoa-enhance** 分支 E2E 测试 + RUNBOOK + ACCEPTANCE 全套就绪
- 🔧 主网部署 — 待执行
- 🔧 ACN-Agent on Pi 技术规划 — Paper3 后续工程化进行中

**📝 近期动态** (MushroomDAO/launch):
- 2026-06-07: feat(gasless-e2e): rebase E2E tests + RUNBOOK + ACCEPTANCE onto gasless-eoa-enhance
- 2026-06-03: feat(site): join-gasless.html — 3-flow EIP-7702 gasless UX (P3) (#9)
- 2026-05-30: fix(relayer/v2): validate chainId + buyer address before rate limit
- 2026-05-26: ACN-Agent technical plan on Pi base
- 2026-05-25: Pi (pi-mono) architecture research findings

💡 EIP-7702 gasless 三流 UX 完成 + E2E 体系就绪，是 5-18 路演后的重要工程化收尾。剩余 10% 为主网部署执行。
<!-- SECTION:DESCRIPTION:END -->
