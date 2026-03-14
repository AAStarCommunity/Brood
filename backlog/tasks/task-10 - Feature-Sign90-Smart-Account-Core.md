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

### 📊 进度报告 (2026-03-14 扫描)

**🚀 预估进度: 80%** | 近 30 天 45+ 次提交，M5 已合并 main，最近一次 2026-03-14（今天）

**✅ AC 完成情况**:
- ✅ #1 Implement custom SCA — AirAccount 非升级型 ERC-4337 SCA，passkey 认证 + 三层安全（Tier1/2/DVT），M3/M4/M5 全部完成
- ✅ Support 2/3 multi-sig logic — M3: 社交恢复 2-of-3 guardian 完成；M5.3: guardian acceptance signatures 验证
- ✅ Compatible with ERC-4337 EntryPoint — ERC-4337 原生兼容，EntryPoint 集成完整
- 🔧 Upgradability — 合约本身 non-upgradable（设计选择），但安全参数可收紧（guard-only-tighten 模式）

**📝 近期动态** (airaccount-contract main branch):
- 03-14: **fix: require non-zero community guardian in deploy scripts**（今天 — M5 合并后安全加固）
- 03-13: **feat: merge M5** — weight-based multi-sig, BLS aggregator, gasless E2E 合并 main
- 03-13: **M5 Milestone COMPLETE** — 280/280 单测通过，Sepolia E2E 15/15 PASS
- 新增 `codex/review-code` 分支（AI 代码审查分支）

💡 M5 已合并 main，今天有 post-M5 安全修复（guardian 非零校验）。核心 SCA 生产就绪，M6（Session Key、Will、Privacy）是下一里程碑，占剩余 20%。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Implement custom SCA with upgradability,Support 2/3 multi-sig logic by default,Compatible with ERC-4337 EntryPoint
<!-- AC:END -->
