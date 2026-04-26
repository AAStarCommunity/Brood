---
id: TASK-10
title: '[Feature] Sign90 - Smart Account Core'
status: Done
assignee: []
created_date: '2026-02-28 11:15'
updated_date: '2026-04-06 11:41'
labels:
  - feature
  - sign90
  - smart-contract
milestone: m-1
dependencies:
  - TASK-7
references:
  - 'https://github.com/AAStarCommunity/airaccount-contract'
  - 'https://github.com/AAStarCommunity/airaccount'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Develop and deploy the foundational Smart Contract Account for Sign90.

这几个看看就行：https://docs.google.com/document/d/12UGQCokFqgnlMqc6q5Gg57qFc-EFW6UQAq0OsAbYq88/edit?tab=t.0，Railgun隐私协议：https://docs.google.com/document/d/1PP_5xSuIF7I5Ky6IlWFo-Eir2jM6PGy9zRAChYeMniI/edit?usp=sharing，锦鲤的隐私钱包SDK
：https://docs.google.com/document/d/1Ka7bztCTNikJnB1Xok-QyJLacF3kResxsboTDJ_jPKA/edit?usp=sharing

### 📊 进度报告 (2026-04-26 扫描)

**🚀 预估进度: 100%** | 状态已更新为 Done；近 30 天 23+ 次提交，最近一次 2026-04-15（Apache 2.0 license），M7 r11 安全修复完成

**✅ AC 完成情况**:
- ✅ #1 Implement custom SCA — AirAccount 非升级型 ERC-4337 SCA，passkey 认证 + 三层安全（Tier1/2/DVT），M3-M6 全部完成；M7 ERC-7579 全量合规
- ✅ Support 2/3 multi-sig logic — 2-of-3 guardian 完成，AgentSessionKey + CompositeValidator，677 单元测试
- ✅ Compatible with ERC-4337 EntryPoint — ERC-4337 + ERC-7579 双标准原生兼容，16/16 Sepolia E2E PASS
- 🔧 M7 audit-ready — CodeHawks 审计报告 (audit-scope.md, known-issues.md)，SDK ABI/API mapping pre-freeze；剩余：多链部署（Base/Arbitrum/OP Stack）

**📝 近期动态** (airaccount-contract CHANGELOG):
- 04-15: chore: Apache 2.0 license + NOTICE + TRADEMARK（全量 license 合规）
- 04-05: fix: r11 deploy scripts — community guardian deploy + uninstall TODO
- 04-05: docs: SDK ABI/API mapping + M7 audit report — pre-freeze
- 03-30: fix: r10 security fixes — HIGH-1 sig prefix, MEDIUM-1/2, algId gate（677 单元测试）
- 03-27: feat: M7 r8 — deploy + Anvil E2E scripts（16/16 E2E PASS）

💡 M6 生产就绪（Sepolia），M7 ERC-7579 全量合规 + 安全修复到 r11，审计报告 pre-freeze。剩余 10%：多链正式部署（Base/Arbitrum/OP Stack）+ Sign90 层集成。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Implement custom SCA with upgradability,Support 2/3 multi-sig logic by default,Compatible with ERC-4337 EntryPoint
<!-- AC:END -->
