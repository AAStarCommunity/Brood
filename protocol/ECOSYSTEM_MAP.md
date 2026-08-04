# Mycelium Protocol — 生态地图 / Ecosystem Map

> 最后更新: 2026-03-24
> 路径约定：相对于 `~/Dev/Brood/`（本仓库）
> 数据来源：gh CLI 扫描 GitHub 所有分支 + 本地 repo 检查

---

## 生态全景

```
                    🍄 Mycelium Protocol
                  Park · Spores · OpenNest
                      MushroomDAO 治理
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
    🌐 AAstar         🤖 iDoris.ai       🏙️ MushroomDAO
  区块链基础设施      AI 基础设施     社区/个人/城市OS
```

---

## 核心产品速览 / Product Overview

| 产品 | 组织 | 十词定位 |
|-----|------|---------|
| **SuperPaymaster** | AAstar | Gasless transactions and micropayments for Web3 agents |
| **AirAccount** | AAstar | Your daily Web3 account: fingerprint login, no ETH needed |
| **SuperRelay** | AAstar | ERC-4337 企业级 bundler 网关·双签名 TEE 零入侵架构 |
| **Cos72** | MushroomDAO | 社区操作系统：Onboarding + 正反馈激励 + 治理 |
| **Sin90** | MushroomDAO | 个人操作系统：表达者·创作者·建设者的数字自我 |
| **iDoris** | iDoris.ai | 隐私优先·Token Free·边缘计算·多端自进化开源 AI 模型 |
| **Agent24-Desktop** | iDoris.ai | 跨平台 Electron 框架·可插拔能力模块·AI 解耦适配 |
| **CityOS** | MushroomDAO | AI + Blockchain 城市操作系统 |

---

## AAstar — 区块链基础设施

**GitHub Org**: https://github.com/AAStarCommunity
**路径约定**: `../aastar/` (相对 Brood)

### 核心产品

| 产品 | 十词定位 | 相对路径 | GitHub | 本地状态 |
|-----|---------|---------|--------|---------|
| **SuperPaymaster** | Gasless transactions and micropayments for Web3 agents | `../aastar/SuperPaymaster` | [AAStarCommunity/SuperPaymaster](https://github.com/AAStarCommunity/SuperPaymaster) | ✓ 已克隆 |
| **AirAccount** | Your daily Web3 account: fingerprint login, no ETH needed | `../aastar/AirAccount` | [AAStarCommunity/AirAccount](https://github.com/AAStarCommunity/AirAccount) | ✓ 已克隆 |
| **airaccount-contract** | AirAccount 核心智能合约·M5完成·M6进行中 | `../aastar/airaccount-contract` | [AAStarCommunity/airaccount-contract](https://github.com/AAStarCommunity/airaccount-contract) | ✗ 未克隆 |
| **SuperRelay** | ERC-4337 企业级 bundler 网关·双签名 TEE 架构 | `../aastar/super-relay` | [AAStarCommunity/SuperRelay](https://github.com/AAStarCommunity/SuperRelay) | ✓ 已克隆 |
| **AAStar SDK** | 封装 AirAccount+SuperPaymaster+CometENS 的开发者 SDK | `../aastar-sdk/AAStar_SDK` | [AAStarCommunity/AAStar_SDK](https://github.com/AAStarCommunity/aastar-sdk) | ✓ 已克隆 |
| **YetAnotherAA-Validator** | BLS 签名聚合·ERC-4337 账户抽象验证合约 | `../aastar/YetAnotherAA-Validator` | [AAStarCommunity/YetAnotherAA-Validator](https://github.com/AAStarCommunity/YetAnotherAA-Validator) | ✗ 未克隆 |
| **UltraRelay** | （描述待补充） | `../aastar/UltraRelay-AAStar` | [AAStarCommunity/UltraRelay-AAStar](https://github.com/AAStarCommunity/UltraRelay-AAStar) | ✗ 未克隆 |

### 活跃分支（近一年，GitHub 所有分支）

| repo | 活跃分支 | 最近推送 | 提交数/年 |
|-----|---------|---------|---------|
| AirAccount | `KMS`(主力), `KMS-stm32`, `feat/passkey` | 11天前 | 161 |
| airaccount-contract | `M6`(主力), `M7`(预研), `main` | 3天前 | — |
| SuperPaymaster | `main`, `feature/uups-migration` | 3天前 | 603 |
| super-relay | `main`, `relay-dev`, `feat/web-interface-EP0.6` | 7个月前 | 144 |
| YetAnotherAA | `main` | 5天前 | 88 |
| YetAnotherAA-Validator | `main` | 10天前 | — |
| InnovateCrab | `main` | 5天前 | 156 |

### 克隆命令（按约定路径）

```bash
git clone git@github.com:AAStarCommunity/AirAccount.git              ../aastar/AirAccount
git clone git@github.com:AAStarCommunity/airaccount-contract.git     ../aastar/airaccount-contract
git clone git@github.com:AAStarCommunity/SuperPaymaster.git           ../aastar/SuperPaymaster
git clone git@github.com:AAStarCommunity/SuperRelay.git               ../aastar/super-relay
git clone git@github.com:AAStarCommunity/AAStar_SDK.git               ../aastar-sdk/AAStar_SDK
git clone git@github.com:AAStarCommunity/YetAnotherAA-Validator.git  ../aastar/YetAnotherAA-Validator
git clone git@github.com:AAStarCommunity/UltraRelay-AAStar.git        ../aastar/UltraRelay-AAStar
```

---

## iDoris.ai — AI 基础设施

> **命名说明**：2026-07 组织完成改名——显示名 **iDoris.ai**，GitHub org slug 由 `AuraAIHQ` 改为 **`iDoris-ai`**，子仓库 git remote 已更新。**本地目录仍为 `~/Dev/auraai/`**（物理目录名未改）。仓库 `iDoris-ai/AuraAI` 保留原仓库名。

**GitHub Org**: https://github.com/iDoris-ai
**路径约定**: `../auraai/` (相对 Brood)

### 核心产品

| 产品 | 定位 | 相对路径 | GitHub | 本地状态 |
|-----|------|---------|--------|---------|
| **iDoris** | 隐私优先·Token Free·边缘计算·多端自进化开源 AI 模型 | `../auraai/iDoris` | [iDoris-ai/iDoris](https://github.com/iDoris-ai/iDoris) | ✓ 已克隆 |
| **iDoris-SDK** | 微信桥接 SDK·任意 Agent 接入个人微信号（前 MushroomDAO/Agent-WeChat-SDK） | `../auraai/iDoris-SDK` | [iDoris-ai/iDoris-SDK](https://github.com/iDoris-ai/iDoris-SDK) | ✗ 未克隆 |
| **Agent24** | 自进化 Claude Code Skills 系统（Personal Agent for me and all） | `../auraai/Agent24` | [iDoris-ai/Agent24](https://github.com/iDoris-ai/Agent24) | ✓ 已克隆 |
| **Agent24-Desktop** | 跨平台 Electron 框架·可插拔能力模块·应用方 fork 起点 | `../auraai/Agent24-Desktop` | [iDoris-ai/Agent24-Desktop](https://github.com/iDoris-ai/Agent24-Desktop) | ✓ 已克隆 |
| **agent-speaker** | Nostr-based 跨 agent 通信·NIP-44 加密·MCP 集成 | `../auraai/agent-speaker` | [iDoris-ai/agent-speaker](https://github.com/iDoris-ai/agent-speaker) | ✓ 已克隆 |
| **simple-agent** | 微信场景 Level 1 agent（StorageAgent 等） | `../auraai/simple-agent` | [iDoris-ai/simple-agent](https://github.com/iDoris-ai/simple-agent) | ✗ 未克隆 |
| **OpenCrab** | A Crab work for community（社区信息爬虫/代理） | `../auraai/OpenCrab` | [iDoris-ai/OpenCrab](https://github.com/iDoris-ai/OpenCrab) | ✗ 未克隆 |
| **AuraAI** | AI assistant for community and individuals（知识库+能力基础） | `../auraai/AuraAI` | [iDoris-ai/AuraAI](https://github.com/iDoris-ai/AuraAI) | ✗ 未克隆 |
| **courses** | AI/编程教育课程（面向儿童，5门） | `../auraai/courses` | [iDoris-ai/courses](https://github.com/iDoris-ai/courses) | ✓ 已克隆 |

### 活跃分支

| repo | 最近推送 |
|-----|---------|
| OpenCrab | 2026-03-08 |
| Agent24 | 2026-03-08 |
| courses | 2026-03-08 |
| AuraAI | 2026-03-04 |
| iDoris | 2026-03-13 |

### 克隆命令

```bash
git clone git@github.com:iDoris-ai/iDoris.git           ../auraai/iDoris
git clone git@github.com:iDoris-ai/iDoris-SDK.git       ../auraai/iDoris-SDK
git clone git@github.com:iDoris-ai/Agent24.git          ../auraai/Agent24
git clone git@github.com:iDoris-ai/Agent24-Desktop.git  ../auraai/Agent24-Desktop
git clone git@github.com:iDoris-ai/agent-speaker.git    ../auraai/agent-speaker
git clone git@github.com:iDoris-ai/simple-agent.git     ../auraai/simple-agent
git clone git@github.com:iDoris-ai/OpenCrab.git         ../auraai/OpenCrab
git clone git@github.com:iDoris-ai/AuraAI.git           ../auraai/AuraAI
git clone git@github.com:iDoris-ai/courses.git          ../auraai/courses
```

---

## MushroomDAO — 社区 + 个人 + 城市操作系统

**GitHub Org**: https://github.com/MushroomDAO
**路径约定**: `../mycelium/` (相对 Brood)

### 核心产品

| 产品 | 定位 | 相对路径 | GitHub | 本地状态 |
|-----|------|---------|--------|---------|
| **Sin90** | 个人操作系统（OS for Individual） | `../mycelium/Sin90` | [MushroomDAO/Sin90](https://github.com/MushroomDAO/Sin90) | ✗ 未克隆 |
| **Cos72** | 社区操作系统（MyTask+MyVote+MyShop） | `../Community/Cos72` | [AAStarCommunity/Cos72](https://github.com/AAStarCommunity/Cos72) | ✓ 已克隆 |
| **CityOS** | AI + Blockchain 城市操作系统 | `../mycelium/CityOS` | [MushroomDAO/CityOS](https://github.com/MushroomDAO/CityOS) | ✗ 未克隆 |
| **MyTask** | 社区任务协调模块 | `../mycelium/MyTask` | [MushroomDAO/MyTask](https://github.com/MushroomDAO/MyTask) | ✗ 未克隆 |
| **MyVote** | 社区治理投票模块 | `../mycelium/MyVote` | [MushroomDAO/MyVote](https://github.com/MushroomDAO/MyVote) | ✗ 未克隆 |
| **MyShop** | 社区商店/积分兑换模块 | `../mycelium/MyShop` | [MushroomDAO/MyShop](https://github.com/MushroomDAO/MyShop) | ✗ 未克隆 |
| **Asset3** | （资产协议，设计阶段） | `../mycelium/Asset3` | [MushroomDAO/Asset3](https://github.com/MushroomDAO/Asset3) | ✗ 未克隆 |

### 基础协议 repos

| 协议 | 定位 | GitHub |
|-----|------|--------|
| Park | 数字公共物品 | [MushroomDAO/Park-PublicGoodsGarden](https://github.com/MushroomDAO/Park-PublicGoodsGarden) |
| Spores | 可持续协作 | [MushroomDAO/Spores](https://github.com/MushroomDAO/Spores) |
| OpenPNTs | 积分协议 | [MushroomDAO/OpenPNTs](https://github.com/MushroomDAO/OpenPNTs) |

### 活跃分支

| repo | 最近推送 |
|-----|---------|
| Sin90 | 2026-02-20 |
| CityOS | 2026-03-11 |
| MyTask | 2026-02-26 |
| MyVote | 2026-02-19 |
| MyShop | 2026-02-15 |
| Asset3 | 2026-03-07 |

### 克隆命令

```bash
git clone git@github.com:MushroomDAO/Sin90.git               ../mycelium/Sin90
git clone git@github.com:MushroomDAO/CityOS.git       ../mycelium/CityOS
git clone git@github.com:MushroomDAO/MyTask.git           ../mycelium/MyTask
git clone git@github.com:MushroomDAO/MyVote.git           ../mycelium/MyVote
git clone git@github.com:MushroomDAO/MyShop.git           ../mycelium/MyShop
git clone git@github.com:MushroomDAO/Asset3.git           ../mycelium/Asset3
git clone git@github.com:AAStarCommunity/Cos72.git        ../Community/Cos72
```

---

## 组织间依赖

```
airaccount-contract ←── AirAccount (TEE 调用合约)
SuperRelay ──TEE签名──► AirAccount
SuperPaymaster ──bundler──► SuperRelay
SuperPaymaster ──账户验证──► AirAccount + airaccount-contract
AAStar_SDK ──封装──► SuperPaymaster + AirAccount + CometENS
Cos72 ──使用──► AAStar_SDK (Gasless + 账户 + 积分)
Sin90 ──使用──► AAStar_SDK + Agent24 + iDoris
iDoris ──结算──► SuperPaymaster (AI 服务激励)
iDoris ──身份──► AirAccount (隐私保护)
CityOS ──依赖──► Cos72 + Sin90 + iDoris
```

---

## 本仓库（BroodBrain）

**相对路径**: `.`（即当前仓库）
**GitHub**: https://github.com/AAStarCommunity/Brood
**定位**: 协议神经系统，任务管理 + 上下文发布 + 生态透明化
