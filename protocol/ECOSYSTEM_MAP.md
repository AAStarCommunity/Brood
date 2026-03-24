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
    🌐 AAstar         🤖 AuraAI       🏙️ MushroomDAO
  区块链基础设施      AI 基础设施     社区/个人/城市OS
```

---

## AAstar — 区块链基础设施

**GitHub Org**: https://github.com/AAStarCommunity
**路径约定**: `../aastar/` (相对 Brood)

### 核心产品

| 产品 | 十词定位 | 相对路径 | GitHub | 本地状态 |
|-----|---------|---------|--------|---------|
| **SuperPaymaster** | Gasless transactions and micropayments for Web3 agents | `../aastar/SuperPaymaster` | [AAStarCommunity/SuperPaymaster](https://github.com/AAStarCommunity/SuperPaymaster) | ✓ 已克隆 |
| **AirAccount** | TEE私钥管理·WebAuthn无密码认证·AWS KMS兼容API | `../aastar/AirAccount` | [AAStarCommunity/AirAccount](https://github.com/AAStarCommunity/AirAccount) | ✓ 已克隆 |
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

## AuraAI — AI 基础设施

**GitHub Org**: https://github.com/AuraAIHQ
**路径约定**: `../AuraAI/` (相对 Brood)

### 核心产品

| 产品 | 定位 | 相对路径 | GitHub | 本地状态 |
|-----|------|---------|--------|---------|
| **Sin90** | 个人操作系统（OS for Individual） | `../AuraAI/Sin90` | [AuraAIHQ/Sin90](https://github.com/AuraAIHQ/Sin90) | ✗ 未克隆 |
| **OpenCrab** | A Crab work for community（社区信息爬虫/代理） | `../AuraAI/OpenCrab` | [AuraAIHQ/OpenCrab](https://github.com/AuraAIHQ/OpenCrab) | ✗ 未克隆 |
| **Agent24** | Personal Agent for me and all（个人 AI 代理） | `../AuraAI/Agent24` | [AuraAIHQ/Agent24](https://github.com/AuraAIHQ/Agent24) | ✗ 未克隆 |
| **AuraAI** | AI assistant for community and individuals（知识库+能力基础） | `../AuraAI/AuraAI` | [AuraAIHQ/AuraAI](https://github.com/AuraAIHQ/AuraAI) | ✗ 未克隆 |
| **courses** | AI/编程教育课程（面向儿童，5门） | `../AuraAI/courses` | [AuraAIHQ/courses](https://github.com/AuraAIHQ/courses) | ✓ 已克隆 |

### 活跃分支

| repo | 最近推送 |
|-----|---------|
| OpenCrab | 2026-03-08 |
| Agent24 | 2026-03-08 |
| courses | 2026-03-08 |
| AuraAI | 2026-03-04 |
| Sin90 | 2026-02-20 |

### 克隆命令

```bash
git clone git@github.com:AuraAIHQ/Sin90.git       ../AuraAI/Sin90
git clone git@github.com:AuraAIHQ/OpenCrab.git    ../AuraAI/OpenCrab
git clone git@github.com:AuraAIHQ/Agent24.git     ../AuraAI/Agent24
git clone git@github.com:AuraAIHQ/AuraAI.git      ../AuraAI/AuraAI
git clone git@github.com:AuraAIHQ/courses.git     ../AuraAI/courses
```

---

## MushroomDAO — 社区 + 个人 + 城市操作系统

**GitHub Org**: https://github.com/MushroomDAO
**路径约定**: `../mycelium/` (相对 Brood)

### 核心产品

| 产品 | 定位 | 相对路径 | GitHub | 本地状态 |
|-----|------|---------|--------|---------|
| **iDoris** | Community Brain·多端自进化模型·边缘计算·隐私·Token Free | `../mycelium/iDoris` | [MushroomDAO/iDoris](https://github.com/MushroomDAO/iDoris) | ✗ 未克隆 |
| **Cos72** | 社区操作系统（MyTask+MyVote+MyShop） | `../Community/Cos72` | [AAStarCommunity/Cos72](https://github.com/AAStarCommunity/Cos72) | ✓ 已克隆 |
| **SmartCity2** | AI + Blockchain 城市操作系统 | `../mycelium/SmartCity2` | [MushroomDAO/SmartCity2](https://github.com/MushroomDAO/SmartCity2) | ✗ 未克隆 |
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
| iDoris | 2026-03-13 |
| SmartCity2 | 2026-03-11 |
| MyTask | 2026-02-26 |
| MyVote | 2026-02-19 |
| MyShop | 2026-02-15 |
| Asset3 | 2026-03-07 |

### 克隆命令

```bash
git clone git@github.com:MushroomDAO/iDoris.git           ../mycelium/iDoris
git clone git@github.com:MushroomDAO/SmartCity2.git       ../mycelium/SmartCity2
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
SmartCity2 ──依赖──► Cos72 + Sin90 + iDoris
```

---

## 本仓库（BroodBrain）

**相对路径**: `.`（即当前仓库）
**GitHub**: https://github.com/jhfnetboy/Brood
**定位**: 协议神经系统，任务管理 + 上下文发布 + 生态透明化
