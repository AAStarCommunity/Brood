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
  - 'https://github.com/AAStarCommunity/aastar-sdk'
  - 'https://github.com/AAStarCommunity/YetAnotherAA-Validator'
  - 'https://github.com/AAStarCommunity/aastar-docs'
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
User account abstraction layer (AirAccount) providing seamless onboarding and interaction.

注：本仓库 reference 指向 AAStarCommunity/YetAnotherAA（用户确认：以 AAStar 版本为主，jhfnetboy 版本已停止更新）

### 📊 进度报告 (2026-06-21 扫描)

**🚀 预估进度: 88%** | 关联 5 仓库（AirAccount + YetAnotherAA + aastar-sdk + YetAnotherAA-Validator + aastar-docs）9 天累计 **440+ 次提交**；**SDK 主干 v0.20.9 → v0.24.1 五连发** + **aNode DVT v1.5.0 testnet always-on** + **passkey-guardian 端到端 UI/recovery**

**✅ AC 完成情况**:
- 🔧 #1 Support Social Login — WebAuthn passkey + v0.6.0 lazy KMS（已完成）
- ✅ **passkey-guardian 完整流程上线**（YetAnotherAA #332-336）：UI account creation + backend recovery (proposeRecoveryWithSig, relayed) + WebAuthn ceremony 中继 + in-UI guide + ETH 限额 presets
- ✅ **aastar-sdk v0.24.1 GA-ready**：DVT through-EntryPoint + validator-router + default nodes + Gap B deployAndWireValidator（一调部署 + setValidator on-chain e2e）+ DVT pin v1.5.0
- ✅ **YetAnotherAA-Validator v1.5.0 (aNode DVT)**：testnet always-on + clone-and-deploy + dvt-testnet.sh（管理 3 testnet 节点 + cloudflared tunnel）+ prod-node E2E verifier（3 独立节点 → 链上 validate===0）
- ✅ **aastar-docs SDK 文档站持续 sync**：0.20.9 → 0.22.0 → 0.23.0 → 0.24.0 同步完毕 + SDK release runbook 入仓
- ✅ **AirAccount v0.23.1 + v0.23.2 (Beta5)** 发布：API key 强制 + operator-configurable RP + api-key CLI scriptable + #102 guardian KMS 依赖风险 + P-256 迁移路径文档
- 🔧 Implement Session Keys — AgentSessionKey 在 airaccount-contract 中实现
- ⬜ Enable Cross-Chain Operations — 未启动

**📝 近期动态** (5 仓库聚合):
- aastar-sdk 2026-06-20: v0.24.1 (Gap B deployAndWireValidator one-call deploy + wire) + v0.24.0 (DVT through-EntryPoint + validator-router + default nodes; DVT pin v1.5.0)
- YetAnotherAA-Validator 2026-06-20: v1.5.0 testnet always-on DVT + clone-and-deploy + dvt-testnet.sh + prod-node E2E verifier
- aastar-docs 2026-06-20: sync SDK 0.24.0 + SDK release runbook in CLAUDE.md
- AirAccount 2026-06-20: release v0.23.2 (Beta5) api-key CLI scriptable + KMS deps risk docs
- YetAnotherAA #332-336 (2026-06-20): passkey-guardian end-to-end UI + backend + recovery

💡 Account 全栈（合约 + SDK + DVT 节点 + 文档 + UI）在 9 天内集中突破：SDK 进入 0.24.x，aNode DVT 进入 always-on testnet 可复制部署，passkey-guardian 全链路打通。剩余 12% 为 Cross-Chain Operations 启动 + Session Keys 收口 + mainnet GA。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Support Social Login,Implement Session Keys,Enable Cross-Chain Operations
<!-- AC:END -->
