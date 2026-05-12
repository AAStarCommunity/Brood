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

### 📊 进度报告 (2026-05-12 扫描)

**🚀 预估进度: 70%** | 近 30 天 15 次提交，最近一次 2026-05-03；**Milestone C 已完成**：proof mode CCIP-Read 端到端 PASS

**✅ AC 完成情况**:
- ✅ Deploy ENS resolver on Sepolia/OP — OPResolver + Bedrock 状态证明已部署，签名/证明双模式
- ✅ Support default subdomain allocation — FreePlugin/WhitelistPlugin/FlatFeePlugin 三种插件，L2RecordsV3 ERC-721 子域所有权
- ✅ **CCIP-Read 端到端 verified** — Milestone C 验证通过，proof mode 全链路 PASS
- 🔧 Map internet domains to on-chain addresses — multi-signer 架构就绪 + 安全加固（parent domain 白名单 + lookup 并发硬化）；.cv/.box/.zparty 实际映射待上线

**✅ DoD 完成情况**:
- 🔧 #1 .box 解析 — OPResolver + proof mode 已就绪，待生产映射
- 🔧 #2 注册 cv 新域名，forest 自动解析 — multi-signer 架构支持多签管理员，域名注册待推进
- 🔧 #3 .zparty.eth 自动解析 — 架构就绪，配置待完成

**📝 近期动态** (MushroomDAO/CometENS):
- 2026-05-03: 最近一次提交
- feat: Milestone C verified — proof mode CCIP-Read end-to-end PASS
- fix(security): parent domain 白名单 + lookup 并发硬化
- 完整 license-compliance 工作完成（Apache 2.0 五件套）

💡 **Milestone C CCIP-Read 端到端验证通过**，核心技术风险解锁。剩余 30% 集中在生产域名映射上线（.cv/.box/.zparty）。
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
