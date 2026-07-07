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
  - 'https://github.com/AAStarCommunity/AirAccount'
  - 'https://github.com/AAStarCommunity/YetAnotherAA'
  - 'https://github.com/AAStarCommunity/aastar-sdk'
  - 'https://github.com/AAStarCommunity/YetAnotherAA-Validator'
  - 'https://github.com/AAStarCommunity/aastar-docs'
  - 'https://github.com/AAStarCommunity/airaccount-contract'
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
User account abstraction layer (AirAccount) providing seamless onboarding and interaction.

注：本仓库 reference 指向 AAStarCommunity/YetAnotherAA（用户确认：以 AAStar 版本为主，jhfnetboy 版本已停止更新）

### 📊 进度报告 (2026-07-07 扫描)

**🚀 预估进度: 95%** | 关联 6 仓库（含新增 airaccount-contract）近30天极度活跃：**airaccount-contract v0.24.0→v0.27.0**（DVT validator unification）+ **aastar-sdk v0.37.2→v0.39.0**（DVT registration API）+ YetAnotherAA DVT wizard + Validator BLS gossip quorum live

**✅ AC 完成情况**:
- ✅ #1 Support Social Login — WebAuthn passkey Tier-2/3 完整实现；passkey-guardian 全链路
- ✅ **airaccount-contract v0.27.0**：DVT validator unification — 挂载 authoritative BLS validator 于 algId 0x01；900 tests + E2E 31/31 + 4/4 real UserOp PASS；Sepolia 已部署 (`0xf25621DF…`)
- ✅ **aastar-sdk v0.39.0**：DVT operator registration SDK API (`buildDvtPop` + `dvtOperatorActions`)；agent-session phantom deprecation（fail-closed）
- ✅ **YetAnotherAA-Validator**：live gossip BLS quorum co-signer (#179 CC-13 inc-2)；ownerAuth tag fix + CC-22 hardening
- ✅ **YetAnotherAA**：DVT node-registration wizard + tier-setup self-pay + create-with-tier-profile
- 🔧 Implement Session Keys — SessionKeyValidator 已统一为 algId 0x08；agent-session phantom 已清理
- ⬜ Enable Cross-Chain Operations — 未启动

**📝 近期动态** (6 仓库聚合):
- 07-07: AirAccount — DVT BLS TEE 托管 Variant B 成型（blst TA + KMS+DVT joint deploy）
- 07-05: airaccount-contract v0.27.0 — DVT validator unification，Sepolia `0xf25621DF` 部署
- 07-06: aastar-sdk v0.39.0 — agent-session phantom 清理；v0.38.0 DVT registerWithProof API
- 07-07: YetAnotherAA-Validator — BLS gossip quorum co-signer live (PR #179)
- 07-06: YetAnotherAA — DVT wizard + @aastar/sdk 0.38.0 接入 (CC-17)
- 07-07: airaccount-contract v0.26.0 — HIGH-1 module-route tier fix；v0.24.0 security hardening

💡 6 仓库全线突破性进展：DVT validator 生态统一完成（airaccount-contract + SDK + UI + Validator 四端对齐），BLS TEE 托管路径打通。剩余 5%：Cross-Chain Operations + mainnet GA。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Support Social Login,Implement Session Keys,Enable Cross-Chain Operations
<!-- AC:END -->
