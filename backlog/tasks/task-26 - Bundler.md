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

### 📊 进度报告 (2026-08-17 扫描)

**🚀 预估进度: 45%** | `AAStarCommunity/UltraRelay-AAStar` 重新活跃：近30天 14 次提交 — Redis 内存泄漏系列修复 + wallet-pool 自愈 + beneficiary fee clamp + RPC 观测性日志

**✅ AC 完成情况**:
- ✅ Accept standard ERC-4337 useroperation — 基础 bundler 能力稳定
- ✅ bundle submission 加固：max-bundle-count/max-executors + partial-failure continue（2026-05-06）
- ✅ 生产化健壮性：Redis 双内存泄漏修复（#41/#42/#44）+ sender-manager wallet pool 自愈 + simulated beneficiary fee clamp（#48）
- ⬜ Accept aPNTs and ETH to pay the service — 未启动
- 🔧 Accept EIP-7702 request — authorizationList 维护中
- ⬜ Be any relay server with permission service — 未启动

**📝 近期动态**:
- 2026-08-14: fix: clamp simulated beneficiary fees to the EntryPoint's max refund (#48)
- 2026-08-11: feat: RPC 日志补 endpoint origin / chainId / response headers (#45)
- 2026-08-06: feat: descriptive logging + per-userop correlation + I/O timing (#31)
- 2026-07-24~08-05: Redis 内存泄漏三连修（outstanding-store / mempool stores / conflicting-nonce hash）+ wallet pool 自愈

💡 从静默转入生产化加固期（内存/自愈/观测性），运行稳定性显著提升；但 aPNTs 支付路径仍未启动——Phase 2 依赖项，需规划启动时机。
<!-- SECTION:DESCRIPTION:END -->
