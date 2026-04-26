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

### 📊 进度报告 (2026-04-26 扫描)

**🚀 预估进度: 72%** | 近 30 天以 Apache 2.0 license 为主，最近功能提交 2026-03-26（v0.16.8）

**✅ AC 完成情况**:
- ✅ Hide private key management from user — WebAuthn passkey 实现，TX 描述隐私遮蔽（v0.16.6），Apache 2.0 license 合规
- 🔧 Support social login/recovery — multi-origin WebAuthn（v0.16.0），rpId 配置化（v0.16.4）；guardian 恢复在合约层完成，服务层集成待验证
- 🔧 Seamless integration with Chrome Extension — KMS/TEE 后端 v0.16.8 稳定（TA panic 修复 + HTTP 500 错误处理），Chrome Plugin 侧集成未验证

**📝 近期动态** (AAStarCommunity/AirAccount):
- 04-15: chore: Apache 2.0 license + NOTICE + TRADEMARK（全量 license 合规）
- 03-26: **fix: v0.16.8 — TA panic crash + HTTP 500 for TEE errors**（稳定性修复）
- 03-13: merge: KMS v0.16.7 → main（TX history stats）
- 03-12: feat: v0.16.6 — tx tracing logs + Description privacy mask

💡 v0.16.8 稳定，Apache 2.0 license 完成，近期无新功能开发。剩余 28%：Chrome Plugin 前端集成（与 airaccount-contract M7 对接）+ 社交恢复完整端到端验证。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Support social login/recovery,Hide private key management from user,Seamless integration with Chrome Extension
<!-- AC:END -->
