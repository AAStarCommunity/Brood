---
id: TASK-13
title: '[Feature] Cos72 - Core Modules (MyTask, MyShop, MyVote)'
status: In Progress
assignee: []
created_date: '2026-02-28 11:15'
updated_date: '2026-04-26 23:56'
labels:
  - feature
  - cos72
  - frontend
milestone: m-1
dependencies:
  - TASK-6
references:
  - 'https://github.com/AAStarCommunity/Cos72'
  - 'https://github.com/MushroomDAO/MyTask'
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the three core modules for Cos72 Chrome Plugin.

### 📊 进度报告 (2026-04-27 扫描)

**🚀 预估进度: 35%** | MushroomDAO/MyTask 近期有新提交（license 合规 04-27），Sprint 1 核心功能已完成并 merge

**✅ AC 完成情况**:
- 🔧 #1 MyTask: Community tasks execution — **MushroomDAO/MyTask** Sprint 1 完成：x402/hono SDK 集成、EIP-3009 真实签名验证、Jury 合约（callback + gas 保护）、PR #5 + PR #4 合并，license 合规
- ⬜ #3 MyVote: Snapshot-based governance voting — 无相关仓库，未启动
- ✅ #4 MyShop: Redeem points for goods/services — MushroomDAO/MyShop（TASK-23）M1 功能完整

**📝 近期动态** (MushroomDAO/MyTask):
- 04-27: chore: Apache 2.0 license badge fix（#7 PR）
- 04-27: chore: license unification（#6 PR merge）
- 04-05: refactor(jury): Task storage 拆分为 core + TaskExtension mapping
- 04-04: refactor(api-server): 替换为官方 @x402/hono SDK
- 04-03: fix(api-server): EIP-3009 真实签名验证 + idempotency

💡 MyTask Sprint 1 已完成并 merge（x402 支付 + Jury 仲裁），MyShop M1 完整。MyVote 未启动。整体进度 30%，下一步启动 Sprint 2 或 MyVote 模块。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 MyTask: Community tasks execution,MyShop: Redeem points for goods/services,MyVote: Snapshot-based governance voting
- [ ] #2 1. MyTask
- [ ] #3 2.  MyVote
- [ ] #4 3. MyShop
<!-- AC:END -->
