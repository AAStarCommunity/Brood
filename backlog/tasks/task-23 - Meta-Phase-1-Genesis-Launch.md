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

### 📊 进度报告 (2026-07-07 扫描)

**🚀 预估进度: 95%** | 近30天 13 次提交，最近一次 2026-06-24；本期主要变化：**relayer 日购买上限移除**（审计修复 #8）+ sale open/close ops 脚本完整落地；无新功能，sale 合约已就绪等待主网部署

**✅ AC 完成情况**:
- ✅ Shop contract and web interface — MushroomDAO/MyShop M1 全量完成
- ✅ GToken launch contract — SaleContractV2 audit-hardened 版重新部署
- ✅ buyTokensFor/buyAPNTsFor + EIP-3009 receiveWithAuth + relayer 白名单集合
- ✅ sale 发布门 hardening（gasless cap 豁免 + CEI + recipient event）
- ✅ ops 开/关脚本 + 文档 + README 链接（#29）
- ✅ **chore(relayer): 移除从未执行的日购买上限声明**（审计 #8, #28）
- 🔧 主网正式部署 — 最后 5%，audit-hardened 版本待 GA 执行

**📝 近期动态** (MushroomDAO/launch):
- 2026-06-24: chore(relayer): 移除从未执行的日购买上限声明 (审计 #8) (#28)
- 2026-06-24: chore(redeploy): 仓库地址指向审计修复后新栈 (#27)
- 2026-06-24: feat(ops): sale 开/关脚本 + 文档（#29，最新提交）
- 本期无新提交（静默 ≥ 13 天）

💡 sale 合约审计修复完整，ops 工具链就绪。剩余 5%：主网 GA 正式部署（等待时机/资金/上线计划）。
<!-- SECTION:DESCRIPTION:END -->
