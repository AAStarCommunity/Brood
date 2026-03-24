# Mycelium Protocol — 生态地图 / Ecosystem Map

> 最后更新: 2026-03-24
> 原则：区块链产品→AAstar，AI产品→AuraAI，社区/用户/城市OS→MushroomDAO

---

## 生态全景 / Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    🍄 Mycelium Protocol                              │
│         协议层：Park · Spores · OpenNest                             │
│         治理层：MushroomDAO                                          │
└───────────────┬─────────────────────┬───────────────────────────────┘
                │                     │
    ┌───────────▼──────────┐ ┌────────▼──────────────┐
    │  🌐 AAstar           │ │  🤖 AuraAI             │
    │  Blockchain Infra    │ │  AI Infra              │
    │                      │ │                        │
    │  SuperPaymaster      │ │  iDoris                │
    │  AirAccount (KMS)    │ │  (Multi-layer model,   │
    │  SuperRelay          │ │   Edge Computing,      │
    │  AAStar SDK          │ │   Privacy, Token Free) │
    └───────────┬──────────┘ └────────┬───────────────┘
                │                     │
    ┌───────────▼─────────────────────▼───────────────┐
    │  🏙️ MushroomDAO / Mycelium                       │
    │  Community OS + Individual OS + Future City OS   │
    │                                                  │
    │  Cos72 (社区操作系统)    Sin90 (个人操作系统)      │
    │  Park Protocol           Spores Protocol         │
    │  OpenNest Protocol                               │
    └──────────────────────────────────────────────────┘
```

---

## 组织一：AAstar — 区块链基础设施

**GitHub**: https://github.com/AAStarCommunity
**本地路径约定**: `~/Dev/aastar/`
**定位**: ERC-4337 Web3 基础设施，为所有组织提供支付和身份底层

### 核心产品

| 产品 | 描述（10词） | 本地路径 | GitHub |
|-----|------------|---------|--------|
| **SuperPaymaster** | Gasless transactions and micropayments for Web3 agents | `aastar/SuperPaymaster` | [AAStarCommunity/SuperPaymaster](https://github.com/AAStarCommunity/SuperPaymaster) |
| **AirAccount** | TEE私钥+WebAuthn无密码认证+AWS KMS兼容API | `aastar/AirAccount` | [AAStarCommunity/AirAccount](https://github.com/AAStarCommunity/AirAccount) |
| **SuperRelay** | ERC-4337 enterprise bundler gateway with dual-signature TEE | `aastar/super-relay` | [AAStarCommunity/SuperRelay](https://github.com/AAStarCommunity/SuperRelay) |
| **AAStar SDK** | Developer SDK wrapping SuperPaymaster+AirAccount+CometENS | `aastar-sdk/AAStar_SDK` | [AAStarCommunity/AAStar_SDK](https://github.com/AAStarCommunity/AAStar_SDK) |
| **CometENS** | ENS resolution demos on unruggable gateways | `aastar/CometENS` | [AAStarCommunity/unruggable-gateways-ens-resolution-demos](https://github.com/AAStarCommunity/unruggable-gateways-ens-resolution-demos) |

### 活跃 Repos（近一年有提交）

| 本地目录 | GitHub | 近一年提交 | 最近活跃 |
|---------|--------|-----------|---------|
| `aastar/AirAccount` | [AAStarCommunity/AirAccount](https://github.com/AAStarCommunity/AirAccount) | 161 | 11天前 |
| `aastar/SuperPaymaster` | [AAStarCommunity/SuperPaymaster](https://github.com/AAStarCommunity/SuperPaymaster) | 603 | 3周前 |
| `aastar/super-relay` | [AAStarCommunity/SuperRelay](https://github.com/AAStarCommunity/SuperRelay) | 144 | 7个月前 |
| `aastar/InnovateCrab` | [jhfnetboy/InnovateCrab](https://github.com/jhfnetboy/InnovateCrab) | 156 | 5天前 |
| `aastar/SP-v2` | [AAStarCommunity/SuperPaymaster](https://github.com/AAStarCommunity/SuperPaymaster) | 244 | 4个月前 |
| `aastar/AAStar-design-all` | [AAStarCommunity/AirAccount-v0.2-design](https://github.com/AAStarCommunity/AirAccount-v0.2-design) | 155 | 9个月前 |
| `aastar/Research` | [AAStarCommunity/Research](https://github.com/AAStarCommunity/Research) | 61 | 9个月前 |
| `aastar/YetAnotherAA` | [jhfnetboy/YetAnotherAA](https://github.com/jhfnetboy/YetAnotherAA) | 88 | 7个月前 |
| `aastar/EvaluationAllPaymaster` | [AAStarCommunity/EvaluationAllPaymaster](https://github.com/AAStarCommunity/EvaluationAllPaymaster) | 30 | 10个月前 |
| `aastar-sdk/AAStar_SDK` | [AAStarCommunity/AAStar_SDK](https://github.com/AAStarCommunity/AAStar_SDK) | 9 | 10个月前 |

---

## 组织二：AuraAI — AI 基础设施

**GitHub**: https://github.com/AuraAIHQ
**本地路径约定**: `~/Dev/AuraAI/`
**定位**: AI 能力层，多端自进化模型 + 边缘计算 + 数据隐私 + Token Free 开源模型

### 核心产品

| 产品 | 描述 | 本地路径 | GitHub |
|-----|------|---------|--------|
| **iDoris** | 多端自进化模型，边缘计算架构，数据隐私，Token Free 开源模型 | `AuraAI/iDoris`（待创建） | 待建 |
| **courses** | AI/编程教育课程（面向儿童，5门） | `AuraAI/courses` | [AuraAIHQ/courses](https://github.com/AuraAIHQ/courses) |

### 活跃 Repos

| 本地目录 | GitHub | 近一年提交 | 最近活跃 |
|---------|--------|-----------|---------|
| `AuraAI/courses` | [AuraAIHQ/courses](https://github.com/AuraAIHQ/courses) | 2 | 2周前 |

> AuraAI 核心 repo（iDoris 等）待建或私有，需补充。

---

## 组织三：MushroomDAO / Mycelium — 社区+个人+城市操作系统

**GitHub**: https://github.com/MushroomDAO
**本地路径约定**: `~/Dev/mycelium/`
**定位**: 社区操作系统（Cos72）+ 个人操作系统（Sin90）+ 未来城市操作系统

### 核心产品

| 产品 | 描述 | 本地路径 | GitHub |
|-----|------|---------|--------|
| **Cos72** | 社区操作系统：Onboarding + 正反馈 + Check | `Community/Cos72` | [AAStarCommunity/Cos72](https://github.com/AAStarCommunity/Cos72) |
| **Sin90** | 个人操作系统：BBSwarm/KnowKnow/CrabZZ | 待建 | 待建 |
| **Park Protocol** | 数字公共物品协议 | — | — |
| **Spores Protocol** | 可持续协作协议 | `mycelium/mushroom-docs` | [MushroomDAO/docs](https://github.com/MushroomDAO/docs) |
| **OpenNest Protocol** | 预测市场孵化协议 | — | — |

### 活跃 Repos

| 本地目录 | GitHub | 近一年提交 | 最近活跃 |
|---------|--------|-----------|---------|
| `mycelium/mushroom-docs` | [MushroomDAO/docs](https://github.com/MushroomDAO/docs) | 37 | 8个月前 |
| `mycelium/mushroom.github.io` | [MushroomDAO/mushroom.github.io](https://github.com/MushroomDAO/mushroom.github.io) | 31 | 8个月前 |
| `mycelium/my-exploration` | [AAStarCommunity/my-exploration](https://github.com/AAStarCommunity/my-exploration) | 324 | 5个月前 |
| `mycelium/mycelium-protocol-reserach` | [HyperCapitalHQ/mycelium-protocol](https://github.com/HyperCapitalHQ/mycelium-protocol) | 34 | 8个月前 |

---

## 本地 Clone 约定 / Local Clone Convention

其他参与者按以下约定 clone，可与本文件中的相对路径完全对应：

```bash
mkdir -p ~/Dev/aastar ~/Dev/AuraAI ~/Dev/mycelium ~/Dev/aastar-sdk

# AAstar 核心
git clone git@github.com:AAStarCommunity/AirAccount.git         ~/Dev/aastar/AirAccount
git clone git@github.com:AAStarCommunity/SuperPaymaster.git      ~/Dev/aastar/SuperPaymaster
git clone git@github.com:AAStarCommunity/SuperRelay.git          ~/Dev/aastar/super-relay
git clone git@github.com:AAStarCommunity/AAStar_SDK.git          ~/Dev/aastar-sdk/AAStar_SDK
git clone git@github.com:AAStarCommunity/Cos72.git               ~/Dev/Community/Cos72

# AuraAI
git clone git@github.com:AuraAIHQ/courses.git                   ~/Dev/AuraAI/courses

# MushroomDAO / Mycelium
git clone git@github.com:MushroomDAO/docs.git                    ~/Dev/mycelium/mushroom-docs
git clone git@github.com:MushroomDAO/mushroom.github.io.git      ~/Dev/mycelium/mushroom.github.io
git clone git@github.com:HyperCapitalHQ/mycelium-protocol.git   ~/Dev/mycelium/mycelium-protocol-reserach

# BroodBrain（本仓库）
git clone git@github.com:jhfnetboy/Brood.git                    ~/Dev/Brood
```

---

## 组织间依赖关系

```
SuperRelay ──TEE签名──► AirAccount
SuperPaymaster ──bundler──► SuperRelay
SuperPaymaster ──账户验证──► AirAccount
AAStar_SDK ──封装──► SuperPaymaster + AirAccount + CometENS
Cos72 ──使用──► AAStar_SDK（Gasless + 账户）
Sin90 ──使用──► AAStar_SDK + iDoris（AI能力）
iDoris ──结算──► SuperPaymaster（激励机制）
iDoris ──身份──► AirAccount（隐私保护）
```
