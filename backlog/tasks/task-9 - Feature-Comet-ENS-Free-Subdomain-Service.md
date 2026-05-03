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

### 📊 进度报告 (2026-05-03 扫描)

**🚀 预估进度: 55%** | 近 30 天 20 次提交，最近一次 2026-04-29；multi-signer support + breaking constructor 变更

**✅ AC 完成情况**:
- ✅ Deploy ENS resolver on Sepolia/OP — OPResolver + Bedrock 状态证明已部署，签名/证明双模式
- ✅ Support default subdomain allocation — FreePlugin/WhitelistPlugin/FlatFeePlugin 三种插件，L2RecordsV3 ERC-721 子域所有权
- 🔧 Map internet domains to on-chain addresses — CHANGELOG 新增 multi-signer support（breaking constructor: addSigner/removeSigner API）；.cv/.box/.zparty 实际映射待上线

**✅ DoD 完成情况**:
- 🔧 #1 .box 解析 — OPResolver 持续迭代中
- 🔧 #2 注册 cv 新域名，forest 自动解析 — multi-signer 架构支持多签管理员，域名注册进行中
- 🔧 #3 .zparty.eth 自动解析 — 架构就绪，配置待完成

**📝 近期动态** (MushroomDAO/CometENS):
- 近 30 天 20 次提交，最近一次 2026-04-29
- CHANGELOG: multi-signer support（breaking change：构造函数改为 addSigner/removeSigner）
- 安全审计已通过，持续推进实际域名映射

💡 multi-signer 支持是重要架构里程碑（breaking change 表明成熟度提升）。核心合约+测试完整，剩余 45% 主要在实际域名注册与解析上线。
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
