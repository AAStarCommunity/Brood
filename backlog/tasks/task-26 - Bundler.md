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

### 📊 进度报告 (2026-05-08 扫描)

**🚀 预估进度: 35%** | aastar-dev 分支新增核心修复，最近提交 2026-05-06

**✅ AC 完成情况**:
- 🔧 Accept standard ERC-4337 useroperation — fix: compute real userOpHash in binary search for executeUserOp calls (#22)
- ⬜ Accept aPNTs and ETH to pay the service — 未见相关实现
- 🔧 Accept EIP-7702 request and be a relay server — 持续迭代中
- ⬜ Be any relay server with permission service — 未见相关实现
- 🔧 More feats inherited — feat: included retry attempts + gas values in event message (#25)

**📝 近期动态** (aastar-dev 分支):
- 05-06: feat: retry attempts + gas values in event message (#25)
- 05-06: fix: compute real userOpHash in binary search (#22)
- 04-29: chore: add Mycelium Protocol CLAUDE.md context

💡 核心 userOpHash 计算修复是重要质量提升。aastar-dev 持续活跃，基础 ERC-4337 能力稳步完善。
<!-- SECTION:DESCRIPTION:END -->
