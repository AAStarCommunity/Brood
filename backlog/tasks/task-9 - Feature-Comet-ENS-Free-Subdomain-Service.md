---
id: TASK-9
title: '[Feature] Comet ENS - Free Subdomain Service'
status: In Progress
assignee: []
created_date: '2026-02-28 11:15'
updated_date: '2026-04-27 00:00'
labels:
  - feature
  - ens
  - frontend
milestone: m-1
dependencies:
  - TASK-6
references:
  - 'https://github.com/MushroomDAO/CometENS'
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Provide users with free ENS subdomains (e.g., user.comet.eth) and internet domain mapping.

1. ENS项目完成OP解析，完成自动授予某个地址一个ENS+开源的解析显示页面.
2. mushroom.cv, forest.mushroom.cv: 自动授予二级域名给注册的社区，基于cloudflare，页面由sdk自动生成，缓存加刷新机制；来自于IPFS和链上配置等

### 📊 进度报告 (2026-07-07 扫描)

**🚀 预估进度: 85%** | 近30天 0 次新提交（最近一次 2026-06-18）；**v0.7.0 testnet GA** 稳定运行中，暂无新功能发布

**✅ AC 完成情况**:
- ✅ Deploy ENS resolver on Sepolia/OP — HybridResolver + OPFaultVerifier 已部署（OP Sepolia）
- ✅ Support default subdomain allocation — FreePlugin/WhitelistPlugin/FlatFeePlugin 全量
- ✅ CCIP-Read 端到端 verified + HybridResolver 混合解析 E2E PASS
- ✅ **v0.7.0 testnet GA**：312 测试全通；DNSSEC runbook + identity-pages plan + DNS 集成 plan 就绪
- 🔧 Map internet domains — .cv/.box/.zparty 实际域名 mainnet 接入（runbook 就位，待执行）

**📝 近期动态** (MushroomDAO/CometENS):
- 2026-06-18: docs/dnssec-verify-runbook (#20) — DNSSEC Phase 1 gate runbook（最新提交）
- 本期无新提交，开发静默 ≥ 19 天

💡 v0.7.0 testnet GA 稳定，但已静默 19 天。剩余 15%：.cv/.box/.zparty 实际域名主网接入 + identity-pages 落地部署。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Deploy ENS resolver on Sepolia/OP,Support default subdomain allocation,Map internet domains to on-chain addresses
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 .box 解析持续尝试
- [ ] #2 注册cv新域名，提供forest和自动解析功能
- [ ] #3 .zparty.eth自动解析
<!-- DOD:END -->
