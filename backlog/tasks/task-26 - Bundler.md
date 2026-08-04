---
id: TASK-26
title: Bundler
status: In Progress
assignee:
  - DavidXu
created_date: '2026-03-05 12:00'
updated_date: '2026-03-07 12:28'
labels:
  - bundler
milestone: m-2
dependencies: []
references:
  - 'https://github.com/AAStarCommunity/UltraRelay-AAStar/tree/aastar-dev'
priority: medium
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
zerodev的bundler（ultrabundler？），modify version from pimlico的Alto，nodejs；
we should run a open source and permissionless bundler to provide permissionless gasless service.

enhance a close integration with AAStar infrastructure.

1. Accept standard ERC-4337 useroperation
2. Accept aPNTs and ETH to pay the service
3. Accept EIP-7702 request and be a relay server
4. Be any relay server with permission service
5. More feats inherited from ultrabundler

### 📊 进度报告 (2026-07-07 扫描)

**🚀 预估进度: 40%** | `AAStarCommunity/UltraRelay-AAStar` (aastar-dev) 静默约 34 天（最近 2026-06-03 chore: add @clestons as code owner）；UltraRelay bundle submission 加固已合入

**✅ AC 完成情况**:
- ✅ Accept standard ERC-4337 useroperation — 基础 bundler 能力稳定
- ✅ bundle submission 加固：max-bundle-count/max-executors + partial-failure continue（2026-05-06）
- ⬜ Accept aPNTs and ETH to pay the service — 未启动
- 🔧 Accept EIP-7702 request — authorizationList 维护中
- ⬜ Be any relay server with permission service — 未启动

**📝 近期动态**:
- 2026-06-03: chore: add @clestons as code owner（治理调整，无 feature 进展）
- 2026-05-06: fix: guard bundle submission + max-bundle-count/max-executors cap（debug handler）

💡 ⚠️ 静默约 34 天，Phase 2 aPNTs 支付路径依赖 Bundler，建议优先评估是否需要重新激活。
<!-- SECTION:DESCRIPTION:END -->
