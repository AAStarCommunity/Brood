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

### 📊 进度报告 (2026-08-17 扫描)

**🚀 预估进度: 95%** | 6 仓库近30天合计 ~156 次提交：**airaccount-contract v0.31.0**（CC-98 committee BLS 账户侧集成）+ **Validator v1.13.1 + CC-98 生产级 committee validator**（#237/#238）+ AirAccount updater/release-sign 多轮对抗评审安全收口（R5-R9）

**✅ AC 完成情况**:
- ✅ #1 Support Social Login — WebAuthn passkey Tier-2/3 完整实现；passkey-guardian 全链路
- ✅ **airaccount-contract v0.31.0**：CC-98 account-side per-proposal committee BLS 集成（accountId 注入防伪造 + mode-gated framing）；v0.30.0 CC-102 weighted-governance hardening
- ✅ **YetAnotherAA-Validator v1.13.1**：CC-89 aggregator 对齐 + fail-closed bootstrap；CC-98 生产级 AAStarCommitteeValidator（#237）+ keeper/Merkle proof 工具（#238）
- ✅ **AirAccount**：Phase2 Web 管理台 airaccount-admin（#195）+ release-sign 撤销墓碑机制（#196，防重放/防砖化）+ OOB 串口一键自助升级（#201）
- ✅ **aastar-sdk v0.43.0**：CC-37 kmsPopSigner（KMS-TEE key-less 节点接入）+ browser-bundle 回归修复 + CI 硬门
- ✅ **YetAnotherAA**：KMS+DVT 社区节点 onboarding 门户（CC-40）+ ethers→viem 全量迁移（CC-43）
- 🔧 Implement Session Keys — SessionKeyValidator 已统一为 algId 0x08；agent-session phantom 已清理
- ⬜ Enable Cross-Chain Operations — 未启动

**📝 近期动态** (6 仓库聚合):
- 08-17: airaccount-contract v0.31.0 — CC-98 committee BLS 账户侧集成；CC-102 weighted-governance DSR 循环收口
- 08-17: YetAnotherAA-Validator — CC-98 生产 per-proposal committee BLS validator (#237) + 部署/keeper/proof 工具链 (#238)
- 08-16: AirAccount — updater/release-sign 多轮对抗评审收口（R5-R9：回滚状态机、revoked 墓碑、防未签名驱动砖化）
- 08-15: AirAccount — OOB 串口自拉 release 升级 serial-selfupdate.sh (#201)
- 08-01/02: YetAnotherAA — CC-40 节点 onboarding 门户 + CC-33 xPNTs 信用披露页 + guardian/account 修复
- 08-02: aastar-sdk — check:addresses/check:stubs 提为 CI 硬门 + dvt3 独立节点链上注册证据脚本 (#316)

💡 主线已从功能开发转入发布工程与安全加固（升级/撤销/回滚闭环）+ CC-98 委员会 BLS 三端落地（contract + validator + account）。剩余 5%：Cross-Chain Operations + mainnet GA。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Support Social Login,Implement Session Keys,Enable Cross-Chain Operations
<!-- AC:END -->
