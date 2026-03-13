---
id: TASK-10
title: '[Feature] Sign90 - Smart Account Core'
status: In Progress
assignee: []
created_date: '2026-02-28 11:15'
updated_date: '2026-03-13 14:38'
labels:
  - feature
  - sign90
  - smart-contract
milestone: m-1
dependencies:
  - TASK-7
references:
  - 'https://github.com/AAStarCommunity/airaccount-contract/tree/M5'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Develop and deploy the foundational Smart Contract Account for Sign90.

这几个看看就行：https://docs.google.com/document/d/12UGQCokFqgnlMqc6q5Gg57qFc-EFW6UQAq0OsAbYq88/edit?tab=t.0，Railgun隐私协议：https://docs.google.com/document/d/1PP_5xSuIF7I5Ky6IlWFo-Eir2jM6PGy9zRAChYeMniI/edit?usp=sharing，锦鲤的隐私钱包SDK
：https://docs.google.com/document/d/1Ka7bztCTNikJnB1Xok-QyJLacF3kResxsboTDJ_jPKA/edit?usp=sharing

### 📊 进度报告 (2026-03-13 扫描)

**🚀 预估进度: 75%** | 近 30 天 42 次提交（M5 分支），最近一次 2026-03-13（今天）

**✅ AC 完成情况**:
- ✅ #1 Implement custom SCA — AirAccount 非升级型 ERC-4337 SCA，passkey 认证 + 三层安全（Tier1/2/DVT），M3/M4/M5 全部完成
- ✅ Support 2/3 multi-sig logic — M3: 社交恢复 2-of-3 guardian 完成；M5.3: guardian acceptance signatures 验证
- ✅ Compatible with ERC-4337 EntryPoint — ERC-4337 原生兼容，EntryPoint 集成完整
- 🔧 Upgradability — 合约本身 non-upgradable（设计选择），但安全参数可收紧（guard-only-tighten 模式）

**📝 近期动态** (M5 CHANGELOG v0.14.0):
- 03-13: **M5 Milestone COMPLETE** — 280/280 单测通过，Sepolia E2E 15/15 PASS
- 03-13: Factory 部署 Sepolia: `0x1ffa949fc5fa34a36ba2466ac3556d961951c3b9`
- 03-13: BLS aggregator (F67/F70) + CI gate (forge test on all PRs) 上线
- 03-13: M5.8 ALG_COMBINED_T1 零信任 Tier1、M5.1 ERC20 Guard 全部验证

💡 M5 今天完成，核心 SCA（ERC-4337 + 2-of-3 guardian + passkey）生产就绪。M6（Session Key、Will、Privacy）已规划，是后续增量。当前 AC 基本达成，剩余 25% 主要是 Sign90 层集成和主网部署。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Implement custom SCA with upgradability,Support 2/3 multi-sig logic by default,Compatible with ERC-4337 EntryPoint
<!-- AC:END -->
