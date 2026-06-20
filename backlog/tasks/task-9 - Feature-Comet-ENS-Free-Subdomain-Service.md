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

### 📊 进度报告 (2026-06-21 扫描)

**🚀 预估进度: 82%** | 9 天 30+ 次提交，最近一次 2026-06-18；**DNS / DNSSEC 集成进入文档化生产准备**：DNSSEC verify runbook + identity-pages plan（社区 → 个人域）+ DNS-domain integration plan 三连合入

**✅ AC 完成情况**:
- ✅ Deploy ENS resolver on Sepolia/OP — OPResolver + Bedrock 状态证明已部署
- ✅ Support default subdomain allocation — FreePlugin/WhitelistPlugin/FlatFeePlugin
- ✅ CCIP-Read 端到端 verified — Milestone C 通过
- ✅ 生产 KV bindings + multicoin addr ABI + /lookup ownership + 单钱包限制 + fail-closed nonce
- ✅ **DNSSEC verification runbook (Phase 1 gate)**（PR #20）
- ✅ **identity-pages plan**：社区 mushroom.cv → 个人 xiaoheishu.xyz（PR #19）
- ✅ **DNS-domain integration plan**（PR #18）
- 🔧 Map internet domains to on-chain addresses — 生产化文档基线就位，.cv/.box/.zparty 实际域名上线即可推进

**📝 近期动态** (MushroomDAO/CometENS):
- 2026-06-18: Merge #20 docs/dnssec-verify-runbook
- 2026-06-?: docs DNSSEC verification runbook (Phase 1 gate, follow-along)
- 2026-06-?: Merge #19 docs/identity-pages-plan
- 2026-06-?: docs identity-pages plan (community mushroom.cv → personal xiaoheishu.xyz)
- 2026-06-?: Merge #18 docs/dns-domain-integration

💡 短短 9 天连入 3 个 docs PR，把 DNS / DNSSEC 与 ENS 整合的产品化路径文档化为可执行 runbook，是.cv/.box 上线前的最后一公里准备。剩余 18% 为实际域名 mainnet 接入 + identity-pages 落地。
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
