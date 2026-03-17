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

### 📊 进度报告 (2026-03-17 扫描)

**🚀 预估进度: 85%** | 近 30 天 25+ 次提交，最近一次 2026-03-16（昨天），M6 gas 优化启动

**✅ AC 完成情况**:
- ✅ #1 Implement custom SCA — AirAccount 非升级型 ERC-4337 SCA，passkey 认证 + 三层安全（Tier1/2/DVT），M3/M4/M5 全部完成
- ✅ Support 2/3 multi-sig logic — 2-of-3 guardian 完成，packed guardian storage（M6 gas opt）
- ✅ Compatible with ERC-4337 EntryPoint — ERC-4337 原生兼容，EntryPoint 集成完整
- 🔧 M6 安全加固 — P256 tier 降级（0x03→Tier1），msgPoint 绑定 userOpHash，高-s 拒绝（EIP-2）

**📝 近期动态** (airaccount-contract):
- 03-16: **fix: M5 security hardening + M6 gas opt** — P256 tier fix, msgPoint binding, packed guardian（32字节槽优化）
- 03-16: **test: add unit tests** for factory default tokens, messagePoint binding, packed guardian
- 03-14: fix: require non-zero community guardian in deploy scripts
- 03-13: feat: merge M5 — M5 里程碑全量合并 main

💡 M5 生产就绪，M6 gas 优化已开始（packed guardian storage）。剩余 15% 主要是 M6 完整功能（Session Key、Will、Privacy）及 Sign90 层集成。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Implement custom SCA with upgradability,Support 2/3 multi-sig logic by default,Compatible with ERC-4337 EntryPoint
<!-- AC:END -->
