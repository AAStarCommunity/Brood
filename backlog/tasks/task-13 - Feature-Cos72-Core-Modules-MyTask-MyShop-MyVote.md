---
id: TASK-13
title: '[Feature] Cos72 - Core Modules (MyTask, MyShop, MyVote)'
status: In Progress
assignee: []
created_date: '2026-02-28 11:15'
updated_date: '2026-03-07 12:29'
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
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the three core modules for Cos72 Chrome Plugin.

### 📊 进度报告 (2026-04-26 扫描)

**🚀 预估进度: 25%** | MushroomDAO/MyTask 14 次提交（近 60 天），最近一次 2026-04-05

**✅ AC 完成情况**:
- 🔧 #1 MyTask: Community tasks execution — **MushroomDAO/MyTask** 活跃开发中：x402 API server（Hono.js + EIP-3009 验证）、Jury 合约（callback + gas 保护）、DeployLocal + Anvil E2E、CODEOWNERS 建立
- ⬜ #3 MyVote: Snapshot-based governance voting — 无相关仓库，未启动
- 🔧 #4 MyShop: Redeem points for goods/services — MushroomDAO/MyShop（TASK-23）M1 功能完整，已覆盖此 AC

**📝 近期动态** (MushroomDAO/MyTask):
- 04-05: refactor(jury): Task storage 拆分为 core + TaskExtension mapping
- 04-04: feat(api-server): x402 API server Sprint 1 T04（Hono.js）
- 04-03: fix: EIP-3009 真实签名验证 + idempotency 修复
- 04-02: feat(jury): 通用 context + callback，多场景 dispute 支持

💡 MyTask 模块独立为 MushroomDAO/MyTask 仓库，已有 x402 支付 + Jury 仲裁合约的初步实现（Sprint 1）。MyShop 已完成（TASK-23），MyVote 未启动。整体从"停滞"转为"重启活跃"。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 MyTask: Community tasks execution,MyShop: Redeem points for goods/services,MyVote: Snapshot-based governance voting
- [ ] #2 1. MyTask
- [ ] #3 2.  MyVote
- [ ] #4 3. MyShop
<!-- AC:END -->
