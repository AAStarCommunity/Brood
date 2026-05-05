---
id: TASK-5
title: '[Project] AL Account (AirAccount) - Abstract Account Layer'
status: In Progress
assignee: []
created_date: '2026-02-28 11:15'
updated_date: '2026-04-26 23:58'
labels:
  - project
  - 'org:AAStar'
milestone: m-1
dependencies:
  - TASK-2
  - TASK-3
references:
  - 'https://github.com/AAStarCommunity/YetAnotherAA'
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
User account abstraction layer (AirAccount) providing seamless onboarding and interaction.

注：本仓库 reference 指向 AAStarCommunity/YetAnotherAA（用户确认：以 AAStar 版本为主，jhfnetboy 版本已停止更新）

### 📊 进度报告 (2026-05-03 扫描)

**🚀 预估进度: 65%** | 近 30 天 20 次提交，最近一次 2026-04-29；v0.6.0 lazy KMS wallet creation 发布

**✅ AC 完成情况**:
- 🔧 #1 Support Social Login — WebAuthn passkey 框架存在，social login 集成进行中；v0.6.0 新增 lazy KMS 钱包创建
- 🔧 Implement Session Keys — AgentSessionKey 在 airaccount-contract 中实现，YetAnotherAA 层持续推进
- ⬜ Enable Cross-Chain Operations — 未启动

**📝 近期动态** (AAStarCommunity/YetAnotherAA):
- 近 30 天 20 次提交，含 license/CLA chore 及功能性更新
- CHANGELOG v0.6.0: lazy KMS wallet creation（按需创建钱包，降低 onboarding 门槛）
- 最近一次提交：2026-04-29

💡 v0.6.0 lazy wallet 大幅改善 onboarding 体验，开发活跃。Cross-Chain Operations 仍未启动，是剩余主要缺口。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Support Social Login,Implement Session Keys,Enable Cross-Chain Operations
<!-- AC:END -->
