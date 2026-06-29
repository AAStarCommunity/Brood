---
id: TASK-23
title: '[Meta] Phase 1: Genesis Launch'
status: In Progress
assignee: []
created_date: '2026-02-28 11:18'
updated_date: '2026-04-26 23:56'
labels:
  - milestone
  - phase-1
  - phase-1-genesis
  - Phase-1
milestone: m-1
dependencies: []
references:
  - 'https://github.com/MushroomDAO/launch'
priority: high
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A meta-task to group all Genesis Launch activities.
1. GToken launch contract
2. Shop contract and web interface

...

### 📊 进度报告 (2026-06-29 扫描)

**🚀 预估进度: 94%** | 近30天 18 次提交，最近一次 2026-06-24；**sale 全面审计修复 + buyTokensFor/buyAPNTsFor 上线**：EIP-3009 receiveWithAuth + balance-delta + CEI order + relayer 白名单集合

**✅ AC 完成情况**:
- ✅ Shop contract and web interface — MushroomDAO/MyShop M1 全量完成
- ✅ GToken launch contract — SaleContractV2 重新部署（audit-hardened 版本）
- ✅ **buyTokensFor/buyAPNTsFor**（#22）— self-pay with explicit recipient
- ✅ **EIP-3009 receiveWithAuth 审计修复**（#26）+ balance-delta + milestone advance
- ✅ **relayer 单地址 → 可增删白名单集合**（#24 dvt#5 方案A）
- ✅ **sale 发布门 hardening**（#23）— gasless cap 豁免 + 防呆 + CEI + recipient event
- ✅ **ops 开/关脚本**（#29）+ 文档 + README 链接
- ✅ 2% 滑点保护 minOut for GToken buy (gasless + self-pay)
- 🔧 主网正式部署 — audit hardened 版就绪，待 GA 执行

**📝 近期动态** (MushroomDAO/launch):
- 2026-06-24: feat(ops): sale 开/关脚本 + 文档 (#29)
- 2026-06-24: chore(redeploy): 仓库地址指向审计修复后新栈 (#27)
- 2026-06-24: fix(audit): EIP-3009 receiveWithAuth + balance-delta (#26)
- 2026-06-23: feat(BuyHelper): relayer 白名单集合 (#24)

💡 sale 合约经过完整审计轮（EIP-3009 + CEI + hardening），buyTokensFor 自付款通道上线，relayer 白名单机制完善。剩余 6%：主网 GA 正式部署。
<!-- SECTION:DESCRIPTION:END -->
