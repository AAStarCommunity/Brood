---
id: TASK-32
title: CommunityFi
status: In Progress
assignee: []
created_date: '2026-03-07 13:08'
labels: []
milestone: m-r
dependencies: []
references:
  - 'https://github.com/jhfnetboy/DSR-Research-Flow'
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
DSR repo；
完成三个论文，一步步完成.

| Paper | Title | DSR Stage | P7 Phase | Next Action |
|:---|:---|:---:|:---:|:---|
| **Paper3** | SuperPaymaster: AOA in ERC-4337 | P6 Done | Step 3 done | Step 1 audit + Step 4 投稿准备 |
| **Paper4** | AirAccount: D2D MultiSig | Not started | Not started | Not started |
| **Paper5** | SocialRecovery | Not started | Not started | Not started |
| **Paper6** | Gasless EOA Bridge (7702) | Not started | N/A | Not started |
| **Paper7** | CommunityFi: Reputation-Backed Credit | P6 Done | Step 3 done | Step 3 P1 fixes + Step 4 投稿准备 |

https://github.com/jhfnetboy/DSR-Research-Flow/blob/main/writing/progress.md

### 📊 进度报告 (2026-06-12 扫描)

**🚀 预估进度: 30%** | aastar-sdk 仓库 community/research 子目录有 Paper7 实质性进展：**v7 long-horizon dynamics** + **Sankey budget-flow 可视化** + 可复现 artifacts

**✅ AC 完成情况**:
- ✅ Paper7 第一版：CommunityFi DSR P1-P6 全部 Done，JBBA 投稿包就绪
- 🔧 **Paper7 第二版（v7）数据收集**：long-horizon dynamics (churn / burnout / recruitment) 已建模
- ✅ **Paper7 可复现 artifacts** 已建立
- ✅ **Sankey budget-flow 可视化** 已成型
- 🔧 投稿：JBBA 投稿包等待第二版数据完成后正式提交
- ⬜ 链上信用系统合约：等 SuperPaymaster v5.4 issue 推进（#215 P1-35 recordDebt cumulative cap + TTL）

**📝 近期动态** (AAStarCommunity/aastar-sdk community/research):
- 2026-06-08: feat(CommunityFi): v7 long-horizon dynamics - churn, burnout, recruitment
- 2026-06-05: feat(community/research): add Sankey budget-flow visualization for paper7
- 2026-06-03: feat(community/research): add CommunityFi paper7 reproducible artifacts

💡 Paper7 第二版工程化推进顺利（v7 动力学 + 可视化 + 可复现），剩余 70% 主要为期刊投稿提交 + v5.4 链上信用系统整合。
