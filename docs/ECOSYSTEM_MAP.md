# Ecosystem Repository Map

> 维护者: auto + manual | 最后更新: 2026-04-14
> 三大组织（AAStarCommunity / MushroomDAO / AuraAIHQ）+ 个人核心仓库的全量 repo 清单。
> `sync-progress` skill 的 Phase 0 步骤会自动扫描本文件并与本地 `~/Dev` 目录对齐。

---

## 状态说明 / Status Legend

| 状态 | 含义 |
|:---|:---|
| 🟢 Active | 近 90 天内有提交 |
| 🟡 Moderate | 3~12 个月内有提交 |
| 🔴 Dormant | 超过 12 个月无提交 |
| ⚪ Design | 设计/思考阶段，无代码仓库 |

---

## AAStarCommunity (AAStar)

> 以太坊基础设施 & Account Abstraction 建设组

| Repo | 本地路径 | GitHub URL | 最近提交 | 状态 | 说明 |
|:---|:---|:---|:---:|:---:|:---|
| airaccount-contract | `/Dev/mycelium/my-exploration/projects/airaccount-contract` | https://github.com/AAStarCommunity/airaccount-contract | 2026-04-10 | 🟢 | Sign90 智能账户合约，M6 开发中 |
| AirAccount | `/Dev/aastar/AirAccount` | https://github.com/AAStarCommunity/AirAccount | 2026-03-26 | 🟢 | AirAccount 隐形账户前端 v0.16.x |
| SuperPaymaster | `/Dev/aastar/SuperPaymaster` | https://github.com/AAStarCommunity/SuperPaymaster | 2026-03-04 | 🟢 | Paymaster SDK & API 服务 |
| Brood | `/Dev/Brood` | https://github.com/AAStarCommunity/Brood | 2026-03-28 | 🟢 | BroodBrain 静态 backlog 发布系统（本仓库） |
| unruggable-gateways (CometENS) | `/Dev/aastar/CometENS` | https://github.com/AAStarCommunity/unruggable-gateways-ens-resolution-demos | 2026-02-21 | 🟢 | CometENS，ENS 解析演示 |
| SuperPaymaster-Contract | `/Dev/aastar/SuperPaymaster-Contract` | https://github.com/AAStarCommunity/SuperPaymaster-Contract | 2025-04-11 | 🟡 | SuperPaymaster 合约（旧，已有新 SP 替代） |
| Cos72 | `/Dev/mycelium/my-exploration/projects/Cos72` | https://github.com/AAStarCommunity/Cos72 | 2025-11-11 | 🟡 | 社区 OS 核心模块（停滞中） |
| demo (AAStarCommunity) | `/Dev/mycelium/my-exploration/projects/demo` | https://github.com/AAStarCommunity/demo | 2025-10-10 | 🟡 | Cos72 Cards/Points/Perks demo |
| AAStar_SDK | `/Dev/aastar-sdk/AAStar_SDK` | https://github.com/AAStarCommunity/AAStar_SDK | 2025-06-12 | 🔴 | AAStar JS SDK（已停止维护） |
| Research | `/Dev/aastar/Research` | https://github.com/AAStarCommunity/Research | 2025-06-24 | 🔴 | 研究文档汇总 |
| AAStar-Demo | `/Dev/aastar/AAStar-Demo` | https://github.com/AAStarCommunity/AAStar-Demo | 2025-05-11 | 🔴 | 演示应用（停滞） |
| Mycelium-dashboard | `/Dev/all-website/mycelium-dashboard` | https://github.com/AAStarCommunity/Mycelium-dashboard | 2024-11-26 | 🔴 | 仪表盘旧版（已停用） |
| aastar-start | `/Dev/aastar/aastar-start` | https://github.com/AAStarCommunity/aastar-start | — | 🔴 | 脚手架工具（停滞） |
| aastar-docs | `/Dev/mycelium/my-exploration/projects/aastar-docs` | https://github.com/AAStarCommunity/aastar-docs | — | 🔴 | 旧文档站 |
| aastar-website | `/Dev/all-website/aastar-website` | https://github.com/AAStarCommunity/aastar-website | — | 🔴 | 官网（停滞） |
| SP-v2 | `/Dev/aastar/SP-v2` | — | — | 🔴 | SuperPaymaster v2 旧版 |

### Freeze（暂停维护）
- `SuperPaymaster` + `AirAccount` 的 AA 合约层已冻结（Freeze SP+AA），主力迁移到 `airaccount-contract`

---

## MushroomDAO

> Mycelium Protocol 应用层 & 社区治理工具

| Repo | 本地路径 | GitHub URL | 最近提交 | 状态 | 说明 |
|:---|:---|:---|:---:|:---:|:---|
| MyShop | `/Dev/tmp/MushroomDAO-MyShop` | https://github.com/MushroomDAO/MyShop | 2026-04-04 | 🟢 | 社区积分兑换 Shop，Phase 1 核心 |
| Doris | `/Dev/mycelium/mushroom-protocols-dev/Doris` | https://github.com/MushroomDAO/Doris | 2025-06-26 | 🔴 | iDoris AI 框架后端 |
| OpenPNTs | `/Dev/mycelium/mushroom-protocols-dev/OpenPNTs` | https://github.com/MushroomDAO/OpenPNTs | 2025-07-11 | 🔴 | 开放积分协议 |
| docs (mushroom-docs) | `/Dev/mycelium/mushroom-docs` | https://github.com/MushroomDAO/docs | 2025-07-15 | 🔴 | MushroomDAO 文档 |
| Spores | `/Dev/tmp/Spores` | https://github.com/MushroomDAO/Spores | 2025-11-15 | 🟡 | Spores SDK（仅 README） |
| mushroom.github.io | `/Dev/mycelium/mushroom.github.io` | https://github.com/MushroomDAO/mushroom.github.io | — | 🔴 | 官网静态页（旧） |
| mycelium-protocol-reserach | `/Dev/mycelium/mycelium-protocol-reserach` | https://github.com/HyperCapitalHQ/mycelium-protocol | 2025-07-19 | 🔴 | 协议研究（HyperCapitalHQ org 下） |
| 7702 | `/Dev/mycelium/my-exploration/projects/7702` | — | — | 🔴 | EIP-7702 实验 |
| ArcadiaV3 | `/Dev/mycelium/my-exploration/projects/ArcadiaV3` | — | — | 🔴 | Arcadia v3 游戏（停滞） |

---

## AuraAIHQ

> AI 层 & 课程平台

| Repo | 本地路径 | GitHub URL | 最近提交 | 状态 | 说明 |
|:---|:---|:---|:---:|:---:|:---|
| courses | `/Dev/AuraAI/courses` | https://github.com/AuraAIHQ/courses | 2026-03-08 | 🟢 | AI 课程框架，5 门课程 |
| AuraAI (jhfnetboy) | `/Dev/crypto-projects/AuraAI` | https://github.com/jhfnetboy/AuraAI | 2026-03-04 | 🟢 | AuraAI 核心（个人 repo，功能开发中） |

---

## 个人核心仓库 (jhfnetboy)

> 跨组织的研究与实验仓库

| Repo | 本地路径 | GitHub URL | 最近提交 | 状态 | 说明 |
|:---|:---|:---|:---:|:---:|:---|
| DSR-Research-Flow | `/Dev/tmp/DSR-Research-Flow` | https://github.com/jhfnetboy/DSR-Research-Flow | 2026-03-23 | 🟢 | 研究论文流（Paper3 SuperPaymaster, Paper7 CommunityFi） |
| bundler | `/Dev/Projects/bundler` | https://github.com/jhfnetboy/bundler | 2023-02-21 | 🔴 | ERC-4337 Bundler（基于废弃 Goerli，需重建） |

---

## Backlog 任务 ↔ 仓库对照

| TASK | 标题 | 关联仓库 | 状态 |
|:---|:---|:---|:---|
| TASK-10 | Sign90 Smart Account Core | AAStarCommunity/airaccount-contract | 🟢 In Progress |
| TASK-12 | AirAccount 隐形账户 | AAStarCommunity/AirAccount | 🟢 In Progress |
| TASK-4 | SuperPaymaster 合约 | AAStarCommunity/SuperPaymaster | 🟢 In Progress |
| TASK-23 | Meta Phase 1 Genesis Launch | MushroomDAO/MyShop | 🟢 In Progress |
| TASK-31 | Paper3: SuperPaymaster 论文 | jhfnetboy/DSR-Research-Flow | 🟢 In Progress |
| TASK-32 | Paper7: CommunityFi 论文 | jhfnetboy/DSR-Research-Flow | 🟢 In Progress |
| TASK-34 | AuraAI | jhfnetboy/AuraAI | 🟡 In Progress |
| TASK-35 | AuraAI Courses | AuraAIHQ/courses | 🟡 In Progress |
| TASK-13 | Cos72 Core Modules | AAStarCommunity/Cos72 | 🔴 In Progress |
| TASK-2 | Cos72 Cards/Points/Perks | AAStarCommunity/demo | 🔴 In Progress |
| TASK-19 | Spores SDK | MushroomDAO/Spores | 🔴 In Progress |
| TASK-26 | Bundler | jhfnetboy/bundler | 🔴 In Progress |
| TASK-28 | OpenCrab Agent | 无关联仓库 | ⚪ 设计阶段 |
| TASK-29 | Asset3 Protocol | 无关联仓库 | ⚪ 设计阶段 |

---

## 扫描说明 / Scan Notes

- 本文件由 `sync-progress` skill 的 Phase 0 步骤自动维护
- 扫描范围：`~/Dev`（深度 4）
- 三大 org 的远程仓库通过 GitHub API 或手动补充
- Dormant 仓库（超过 12 个月）不参与进度分析，仅保留记录
- 本地路径前缀 `/Dev/` = `/Users/jason/Dev/`
