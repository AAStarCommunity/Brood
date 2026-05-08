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

### 📊 进度报告 (2026-05-08 扫描)

**🚀 预估进度: 70%** | 近 30 天 13 次提交，最近一次 2026-05-03；Milestone C CCIP-Read 端到端验证通过

**✅ AC 完成情况**:
- ✅ Deploy ENS resolver on Sepolia/OP — OPResolver 已部署，Milestone C proof mode 验证通过
- ✅ Support default subdomain allocation — CCIP-Read end-to-end PASS，安全加固（父域白名单+并发硬化）
- 🔧 Map internet domains to on-chain addresses — 架构验证完毕，实际域名映射上线待完成

**📝 近期动态** (MushroomDAO/CometENS):
- 05-03: feat: Milestone C verified — proof mode CCIP-Read end-to-end PASS ✅
- 05-03: fix(security): parent domain whitelist + lookup concurrency hardening
- 04-29: license & CLA 合规完成

💡 Milestone C 通过是关键里程碑，CCIP-Read 链下查询验证完毕，剩余 30% 主要在实际域名映射上线和生产环境部署。
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
