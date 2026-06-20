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

### 📊 进度报告 (2026-06-21 扫描)

**🚀 预估进度: 78%** | YetAnotherAA 9 天 30+ 次提交 + AirAccount v0.23.2 (Beta5) 发布；**passkey-guardian 端到端 UI/recovery 上线** + **API key auth 进入正式 release** + **KMS 依赖风险与 P-256 迁移路径文档化**

**✅ AC 完成情况**:
- 🔧 #1 Support Social Login — WebAuthn passkey + v0.6.0 lazy KMS（已完成）
- ✅ **passkey-guardian 完整流程上线**（YetAnotherAA #332-336）：UI account creation + backend recovery (proposeRecoveryWithSig, relayed) + recovery UI WebAuthn ceremony + in-UI guide + 每日 ETH 限额 presets
- ✅ **AirAccount v0.23.1 + v0.23.2 (Beta5)** 发布：API key 强制 + operator-configurable RP + api-key CLI scriptable
- ✅ **TRUST 文档**：硬件安全基础（enclave）6 点 + PSA 说明
- ✅ #102 guardian KMS-dependency 风险 + DR/trust 澄清 + P-256 迁移路径文档（PR #103）
- ✅ RELEASE-CHECKLIST 文档化：lib 变更需重建并部署 CLI 二进制（api-key / kms-admin）
- 🔧 Implement Session Keys — AgentSessionKey 在 airaccount-contract 中实现
- ⬜ Enable Cross-Chain Operations — 未启动

**📝 近期动态**:
- AirAccount 2026-06-20: release v0.23.2 (Beta5) + api-key CLI scriptable + KMS deps risk docs
- AirAccount 2026-06-?: docs API key auth + management CLI（generate/list/revoke）in README
- YetAnotherAA #336 2026-06-20: feat(account) clarify daily limit is native-ETH + suggested presets
- YetAnotherAA #335 2026-06-?: feat(account) in-UI passkey-guardian guide + pre-filled daily limit
- YetAnotherAA #334 2026-06-?: feat(recovery) passkey-guardian recovery UI (WebAuthn → relayed)
- YetAnotherAA #333 2026-06-?: feat(guardian) backend passkey-guardian recovery proposeRecoveryWithSig
- YetAnotherAA #332 2026-06-?: feat(account) passkey-guardian account creation in UI (default path)

💡 passkey-guardian 从合约 → 后端 → UI 整链路打通，AirAccount Beta5 API-key 进入正式 release 节奏。安全 + 硬件 + 备份 + Guardian recovery 四里程碑齐全。剩余 22% 为 Cross-Chain Operations 启动 + Session Keys 收口。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Support Social Login,Implement Session Keys,Enable Cross-Chain Operations
<!-- AC:END -->
