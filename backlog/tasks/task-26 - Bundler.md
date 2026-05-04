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

### 📊 进度报告 (2026-05-04 扫描)

**🚀 预估进度: 30%** | 主仓库 `AAStarCommunity/UltraRelay-AAStar` (aastar-dev 分支)，15 次提交，最近 2026-02-25

**✅ AC 完成情况**:
- 🔧 Accept standard ERC-4337 useroperation — UltraRelay 基于 Alto fork，aastar-dev 分支有 upstream merge + gas estimation 修复
- ⬜ Accept aPNTs and ETH to pay the service — 未见相关实现
- 🔧 Accept EIP-7702 request and be a relay server — feat: add authorizationList to estimateGas (PR #13)
- ⬜ Be any relay server with permission service — 未见相关实现
- 🔧 More feats inherited from ultrabundler — /wallets endpoint (#15), RPC basic auth (#14), structured JSON logging, CI/ECR push

**📝 近期动态** (aastar-dev 分支):
- 02-25: feat: /wallets endpoint + RPC basic auth support
- 02-20: feat: authorizationList for EIP-7702 gas estimation
- 02-15: upstream merge from alto (#5) + Biome formatting
- 02-10: structured JSON logging + revert reason decoding

💡 实际 bundler 开发已迁移到 UltraRelay-AAStar (aastar-dev)。基础 ERC-4337 能力已有，EIP-7702 初步支持。旧 jhfnetboy/bundler 已废弃。
<!-- SECTION:DESCRIPTION:END -->
