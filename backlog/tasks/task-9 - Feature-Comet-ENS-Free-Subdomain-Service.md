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

### 📊 进度报告 (2026-06-12 扫描)

**🚀 预估进度: 75%** | 近 30 天 4 次提交，最近一次 2026-06-09；**生产化安全工作重启** + KV bindings 上线 + ownership 检查

**✅ AC 完成情况**:
- ✅ Deploy ENS resolver on Sepolia/OP — OPResolver + Bedrock 状态证明已部署
- ✅ Support default subdomain allocation — FreePlugin/WhitelistPlugin/FlatFeePlugin 三种插件
- ✅ **CCIP-Read 端到端 verified** — Milestone C 通过
- ✅ **生产 KV bindings 上线**（取消注释，进入生产路径）
- ✅ multicoin addr ABI 修正
- ✅ /lookup ownership 检查 + 响应格式
- ✅ One-wallet 链上限制
- ✅ fail-closed nonce + sanitize error responses（安全加固）
- 🔧 Map internet domains to on-chain addresses — 生产化基础就位，.cv/.box/.zparty 实际映射仍待上线

**📝 近期动态** (MushroomDAO/CometENS):
- 2026-06-09: fix: consumeNonce fail-closed, /lookup ownership check + response format
- 2026-06-07: fix: multicoin addr ABI, KV cache scoping, SDK apiUrl, one-wallet on-chain limit
- 2026-06-05: fix(security): fail-closed nonce, sanitize error responses, uncomment production KV bindings

💡 项目重启活跃（5 周静默后），从研究态进入生产态。安全 + 生产 KV + ownership 校验三项重要里程碑同时落地。剩余 25% 主要为实际域名映射上线（.cv/.box/.zparty）。
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
