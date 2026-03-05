---
id: TASK-8
title: '[Feature] Paymaster V4 - Self-Operated & Stablecoin'
status: Done
assignee: []
created_date: '2026-02-28 11:15'
updated_date: '2026-03-05 05:14'
labels:
  - feature
  - paymaster
  - backend
milestone: 'Phase 1: Genesis Launch'
dependencies:
  - TASK-6
references:
  - 'https://github.com/AAStarCommunity/SuperPaymaster/tree/v4-refine-stablecoin'
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement Paymaster V4 (Pre-paid) and SuperPaymaster (Credit-based) in a unified project.

### 📊 进度报告 (2026-03-04 扫描)

**🚀 预估进度: 60%** | 近 30 天 29 次提交，最近一次 2026-03-04

**✅ AC 完成情况**:
- ✅ Implement Paymaster V4 with pre-paid model — V4 已部署 OP mainnet，V4.3 新增 Token 管理系统
- 🔧 Implement SuperPaymaster with credit/reputation mapping — reg-repu-refine 分支存在，开发中
- ⬜ Support repayment logic for SuperPaymaster — 未找到相关记录
- ✅ Integrate Chainlink Oracle for gas price — Chainlink price cache 已在测试中验证，staleness threshold 已配置
- ✅ Add interface to add and remove token address — V4.3 完整实现 (removeToken/getSupportedTokens/isTokenSupported/getSupportedTokensInfo)
- ✅ pre-config USDC, USDT for multichain — stablecoins.json 覆盖 7 条链 (Ethereum/OP/Arbitrum/Base/Polygon/Sepolia)
- ✅ Test USDC, USDT deposit and gasless tx — 10 单元测试 + 13 Sepolia 链上测试 (12 pass, 1 skip)

**📝 近期动态** (本地 docs/Changes.md + git log):
- 03-04: V4.3 合并 — Token 管理 + 稳定币支持 + 部署脚本 + 安全审查 (0 Critical/High/Medium)
- 03-02: claude re init 项目结构
- 02-15: paymasterv4 staleness threshold 调整至 4200s
- 02-13~14: OP mainnet 测试脚本调试 (7 轮迭代)
- 02-11: 发布至 OP mainnet + 验证报告生成脚本
- 02-10: Foundry Keystore 安全部署重构 + create2 部署策略

💡 V4 pre-paid 模型和稳定币支持已完成 (V4.3)，已部署 OP mainnet。剩余 40% 主要是 SuperPaymaster credit/reputation 映射和 repayment 逻辑。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Implement Paymaster V4 with pre-paid model,Implement SuperPaymaster with credit/reputation mapping,Support repayment logic for SuperPaymaster,Integrate Chainlink Oracle for gas price
- [ ] #2 Add interface to add and remove token address
- [ ] #3 pre-config USDC, USDC for multichain?(if they are the same addr crosschain)
- [ ] #4 Test USDC, USDT deposit and gasless tx
<!-- AC:END -->
