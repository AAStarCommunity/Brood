---
id: TASK-12
title: '[Feature] AirAccount - Invisible Crypto Account'
status: In Progress
assignee: []
created_date: '2026-02-28 11:15'
updated_date: '2026-03-07 12:09'
labels:
  - feature
  - airaccount
  - core
milestone: 'Phase 1: Genesis Launch'
dependencies:
  - TASK-6
references:
  - 'https://github.com/AAStarCommunity/AirAccount'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A standalone abstract account project embedded in Chrome Plugin, solving basic crypto account hurdles.

### 📊 进度报告 (2026-03-14 扫描) 🤖 reference 由本地仓库名匹配补全

**🚀 预估进度: 65%** | 近 30 天 10 次提交，最近一次 2026-03-04

**✅ AC 完成情况**:
- ✅ Hide private key management from user — WebAuthn passkey 实现，用户无需管理私钥；v0.16.x 全面完善
- 🔧 Support social login/recovery — WebAuthn multi-origin 支持（v0.16.0），rpId 配置化（v0.16.4）；guardian 恢复在合约层（TASK-10）完成，SDK 层集成待验证
- 🔧 Seamless integration with Chrome Extension — 服务后端活跃（stats dashboard, graceful deploy），前端 plugin 集成状态未知

**📝 近期动态** (AAStarCommunity/AirAccount):
- 03-04: docs: add .env auto-load for test scripts + rpId/origin security docs
- 03-04: feat: config-driven WebAuthn rpId (KMS_RP_ID=aastar.io,localhost)
- 03-01: feat: v0.16.4 — live stats dashboard as default page
- 03-01: feat: v0.16.3 — graceful deploy with queue drain + TA fmt
- 02-28: feat: v0.16.0 — multi-origin WebAuthn support

💡 AirAccount 后端服务（KMS/TEE）高度活跃，v0.16.4 已上线。Chrome Plugin 集成和 guardian 社交恢复是剩余主要工作（35%）。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Support social login/recovery,Hide private key management from user,Seamless integration with Chrome Extension
<!-- AC:END -->
