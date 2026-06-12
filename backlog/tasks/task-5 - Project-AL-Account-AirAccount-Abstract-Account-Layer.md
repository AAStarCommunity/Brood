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

### 📊 进度报告 (2026-06-12 扫描)

**🚀 预估进度: 70%** | 关联仓库 `AirAccount` 近期最新提交 2026-06-11；**2026-06-11 全量安全审计 P0 + High findings 全部修复** + MX93 硬件适配 + 备份系统上线

**✅ AC 完成情况**:
- 🔧 #1 Support Social Login — WebAuthn passkey + v0.6.0 lazy KMS（已完成）
- ✅ **安全审计 2026-06-11**：所有 P0 + High findings 修复，Challenger-confirmed review C-1..4, H-3..6, M-1,3,4,5 处理完毕
- ✅ MX93 硬件适配：REE-FS fallback + on-hardware fixes + MX93 build pipeline
- ✅ 备份系统：comprehensive KMS CA/TA + metadata 备份，BACKUP-GUIDE.md（含 full/incremental + 恢复步骤）
- 🔧 Implement Session Keys — AgentSessionKey 在 airaccount-contract 中实现
- ⬜ Enable Cross-Chain Operations — 未启动

**📝 近期动态** (AAStarCommunity/AirAccount):
- 2026-06-11: feat(mx93): REE-FS fallback + on-hardware fixes + MX93 build pipeline
- 2026-06-10: security: fix all P0 + High findings from 2026-06-11 full audit
- 2026-06-09: fix: address challenger-confirmed review findings (C-1..4, H-3..6, M-1,3,4,5)
- 2026-06-05: docs: add BACKUP-GUIDE.md with full/incremental mechanism, restore steps
- 2026-06-02: feat: comprehensive backup system for KMS CA/TA and metadata

💡 安全审计 + 硬件适配 + 备份系统三个工程化里程碑同时落地，AirAccount 接近生产就绪。剩余 30% 主要为 Cross-Chain Operations 启动 + onboarding 流程联调。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Support Social Login,Implement Session Keys,Enable Cross-Chain Operations
<!-- AC:END -->
