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

### 📊 进度报告 (2026-03-17 扫描) 🤖 reference 由本地仓库名匹配补全

**🚀 预估进度: 70%** | 近 30 天 16 次提交，最近一次 2026-03-13（v0.16.7 合并 main）

**✅ AC 完成情况**:
- ✅ Hide private key management from user — WebAuthn passkey 实现，TX 描述隐私遮蔽（v0.16.6）
- 🔧 Support social login/recovery — multi-origin WebAuthn（v0.16.0），rpId 配置化（v0.16.4）；guardian 恢复在合约层完成，服务层集成待验证
- 🔧 Seamless integration with Chrome Extension — KMS 后端 v0.16.7 稳定，Chrome Plugin 侧集成状态未知

**📝 近期动态** (AAStarCommunity/AirAccount):
- 03-13: **merge: KMS v0.16.7 → main** — TX history stats 统计功能上线
- 03-12: feat: v0.16.7 — TX history stats on stats page
- 03-11: feat: v0.16.6 — tx tracing logs + Description privacy mask（隐私增强）
- 03-11: feat: add tx tracing logs to all TEE handlers
- 03-04: feat: v0.16.4 — live stats dashboard as default page

💡 AirAccount KMS/TEE 后端持续迭代（v0.16.7），TX 追踪和隐私保护完善。Chrome Plugin 前端集成和社交恢复完整验证是剩余 30%。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Support social login/recovery,Hide private key management from user,Seamless integration with Chrome Extension
<!-- AC:END -->
