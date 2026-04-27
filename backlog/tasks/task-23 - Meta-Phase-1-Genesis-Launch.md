---
id: TASK-23
title: '[Meta] Phase 1: Genesis Launch'
status: In Progress
assignee: []
created_date: '2026-02-28 11:18'
updated_date: '2026-04-26 23:56'
labels:
  - milestone
  - phase-1
  - phase-1-genesis
  - Phase-1
milestone: m-1
dependencies: []
references:
  - 'https://github.com/MushroomDAO/launch'
priority: high
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A meta-task to group all Genesis Launch activities.
1. GToken launch contract
2. Shop contract and web interface

...

### 📊 进度报告 (2026-04-27 扫描)

**🚀 预估进度: 70%** | 近 30 天 20+ 次提交，最近一次 2026-04-26（roadshow prep）；launch 仓库新增 gasless GToken 购买页 + Cloudflare Worker relayer

**✅ AC 完成情况**:
- ✅ Shop contract and web interface — MushroomDAO/MyShop M1 全量完成（C1-C11 合约 + F1-F8 前端 + W1-W5 Worker + Codex/Slither 安全审计）
- 🔧 GToken launch contract — **MushroomDAO/launch** 新增 gasless GToken 购买页（launch.html）+ Cloudflare Worker relayer（gasless purchase），x402 集成；GToken 合约本体待部署

**📝 近期动态** (MushroomDAO/launch):
- 04-26: prep(5-18): Hangzhou roadshow prep — R1 Q1.1 backfill + critical questions
- 04-26: docs: MILESTONES.md（canonical）+ gasless-buy-plan.md
- 04-26: feat(site): launch.html — gasless GToken purchase page
- 04-26: feat(relayer): Cloudflare Worker gasless purchase relayer
- 04-26: fix(relayer): buyer address + RPC errors + infra gate（2-round review）

💡 MyShop M1 完整，launch 站点新增 gasless 购买流程（Worker relayer + 前端页）。GToken 合约本体是剩余 30% 的关键，Hangzhou roadshow 5-18 为近期里程碑。
<!-- SECTION:DESCRIPTION:END -->
