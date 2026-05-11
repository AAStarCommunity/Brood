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

### 📊 进度报告 (2026-05-07 扫描)

**🚀 预估进度: 40%** | 主仓库 `AAStarCommunity/UltraRelay-AAStar` (aastar-dev 分支)，近 30 天 31 次提交，最近 2026-05-06

**✅ AC 完成情况**:
- ✅ Accept standard ERC-4337 useroperation — 基础 bundler 能力稳定，多个 fix 入主线（PR #26 entry point deposit）
- ⬜ Accept aPNTs and ETH to pay the service — 未见相关实现
- 🔧 Accept EIP-7702 request and be a relay server — authorizationList 在 estimateGas 中持续维护
- ⬜ Be any relay server with permission service — 未见相关实现
- 🔧 More feats inherited from ultrabundler — geometric retry escalation、mempool replacement、max-executors/wallets 验证、debug handler bundle 提交保护

**📝 近期动态** (aastar-dev 分支):
- 2026-05-06: 最近一次提交（活跃迭代）
- chore: bump viem 2.27.0 → 2.37.7
- fix: geometric retry escalation 保证 mempool replacement 有效
- fix: non-sponsored estimate via EntryPoint deposit override (#26)
- fix: 多个 bundle/wallets/executors 边界条件
- merge: upstream zerodevapp/ultra-relay gas_optimization 分支

💡 aastar-dev 分支持续吸收 upstream 优化 + 自主修复，已具备生产可用度。剩余 60% 主要为 aPNTs 支付集成 + 权限化 relay 设计。
<!-- SECTION:DESCRIPTION:END -->
