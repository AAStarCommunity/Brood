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

### 📊 进度报告 (2026-04-27 扫描)

**🚀 预估进度: 65%** | 近 30 天 20+ 次提交，最近一次 2026-04-27（Apache 2.0 license badge），v0.5.0 里程碑完成

**✅ AC 完成情况**:
- ✅ Deploy ENS resolver on Sepolia/OP — OPResolver + Bedrock 状态证明脚手架（C1/C2）已部署，签名/证明双模式
- ✅ Support default subdomain allocation — FreePlugin/WhitelistPlugin/FlatFeePlugin 三种插件，L2RecordsV3 ERC-721 子域所有权
- 🔧 Map internet domains to on-chain addresses — D6 多根域名支持完成（multi-root UI + parent injection 安全修复）；.cv/.box/.zparty 实际映射待验证

**✅ DoD 完成情况**:
- 🔧 #1 .box 解析 — OPResolver 持续尝试中
- 🔧 #2 注册 cv 新域名，forest 自动解析 — D6 multi-root 支持，具体域名注册进行中
- 🔧 #3 .zparty.eth 自动解析 — 架构就绪，配置待完成

**📝 近期动态** (MushroomDAO/CometENS CHANGELOG v0.5.0, 2026-04-04):
- 04-27: D6 multi-root domain support + fix parent injection（security）
- 04-04: v0.5.0 — L2RecordsV3 ERC-721 子域 + IRegistrarPlugin 插件架构 + OPResolver + 3轮 Codex 安全审核通过
- 04-03: M1 验收测试用例 + 132 TS + 182 Foundry tests all pass
- 04-02: C3/C4 Bedrock storage proof resolver + gateway proof mode

💡 核心架构（合约+API+前端+测试）已完整，D6 多根域名完成，安全审计通过。剩余 35%：.cv/.box/.zparty 实际域名映射验证 + mushroom.cv/forest.mushroom.cv 自动授予功能上线。
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
