# Mycelium Protocol — 仓库能力注册表

> 协议层全局视图。扫描来源: `/Users/jason/Dev/`
> 最后同步: 2026-03-24
> 格式: [org] repo — 用途 — 当前状态

---

## 组织索引

| 组织 | 目录 | 定位 |
|-----|------|------|
| [AAstar](#aastar) | `orgs/aastar/` | Web3 基础设施（ERC-4337） |
| [Mycelium Protocol](#mycelium-protocol) | `orgs/mycelium/` | 协议层 & MushroomDAO |
| [AuraAI](#auraai) | `orgs/auraai/` | AI 能力与教育 |
| [Community](#community) | — | 社区工具与生态应用 |

---

## AAstar

> GitHub: github.com/AAStarCommunity | 定位: ERC-4337 Web3 基础设施层

### AirAccount
- **本地路径**: `/Users/jason/Dev/aastar/AirAccount`
- **GitHub**: git@github.com:AAStarCommunity/AirAccount.git
- **用途**: TEE（Trusted Execution Environment）上的私钥管理系统（KMS）+ WebAuthn 无密码账户认证
- **当前版本**: v0.16.7（根据 commit 消息）
- **活跃度**: 高（近 30 天 15+ commits）
- **对外接口**:
  - AWS KMS 兼容 API（`/health`, `/kms/*`）
  - WebAuthn 注册/认证端点
  - TX 历史统计 API（`/stats`）
- **最近变更**: TX history stats dashboard, WebAuthn multi-origin support, graceful deploy
- **依赖**: TEE (Teaclave TrustZone SDK), WebAuthn, p256

### SuperPaymaster
- **本地路径**: `/Users/jason/Dev/aastar/SuperPaymaster`（同 SP-v2）
- **GitHub**: git@github.com:AAStarCommunity/SuperPaymaster.git
- **用途**: ERC-4337 去中心化 Gas 支付基础设施；社区用自己的积分代币（xPNTs）替代 ETH 支付 Gas
- **当前版本**: v4.4.0-optimism-mainnet
- **活跃度**: 中（近 30 天 5 commits）
- **对外接口**:
  - `validatePaymasterUserOp` — 验证 UserOperation
  - `postOp` — 操作后结算
  - `deposit` / `addStake` — 资金管理
  - 多链配置（Sepolia, Optimism mainnet）
- **最近变更**: stablecoin support, Sepolia standalone deploy+test (13 tests), security review v4.3
- **依赖**: ERC-4337, AirAccount (账户验证), SuperRelay (bundler)

### SuperRelay
- **本地路径**: `/Users/jason/Dev/aastar/super-relay`
- **GitHub**: git@github.com:AAStarCommunity/SuperRelay.git
- **用途**: 基于 Rundler（Alchemy ERC-4337 bundler）的企业级 API 网关；提供 Gas 赞助 + 认证授权 + 企业策略
- **当前版本**: v1.0.0（package.json）
- **活跃度**: 高（Phase 1 完成：双签名架构 + TEE 集成）
- **对外接口**:
  - ERC-4337 bundler RPC（`eth_sendUserOperation` 等标准接口）
  - OpenAPI 生成文档（utoipa，32 个 schema）
  - Node.js SDK 集成指南
- **最近变更**: Phase 1 完成：dual-signature architecture，AirAccount-SuperRelay TEE 集成
- **依赖**: Rundler (Alchemy), AirAccount (TEE签名), Rust

### AAStar SDK
- **本地路径**: `/Users/jason/Dev/aastar-sdk/AAStar_SDK`
- **GitHub**: git@github.com:AAStarCommunity/AAStar_SDK.git
- **用途**: 开发者集成 SDK，封装 AirAccount + SuperPaymaster + CometENS + OpenPNTS
- **活跃度**: 低（无近期 commits）
- **对外接口**:
  - AirAccount 账户创建/管理
  - SuperPaymaster gasless 交易
  - CometENS 域名注册
  - OpenPNTS 积分管理
- **依赖**: AirAccount, SuperPaymaster, CometENS

### aastar-start（产品 Demo）
- **本地路径**: `/Users/jason/Dev/aastar/aastar-start`
- **GitHub**: git@github.com:AAStarCommunity/start.git
- **用途**: 基于 SDK 的产品 mock 集合：CoinJar（小额收款）/ Spores（KOL 效果付费）/ CryptoNewbieShuttle（新手引导）/ CommunityTapWater（社区运营）
- **活跃度**: 低
- **依赖**: AirAccount, SuperPaymaster, COS72

### Cos72
- **本地路径**: `/Users/jason/Dev/Community/Cos72`
- **GitHub**: git@github.com:AAStarCommunity/Cos72.git
- **用途**: DAO/社区工具；在 SuperChain 上提供 Gasless + NFT + Smart Account + ENS（邮箱即账户）
- **活跃度**: 低
- **依赖**: AirAccount, SuperPaymaster, CometENS, Push Protocol

### EvaluationAllPaymaster（研究）
- **本地路径**: `/Users/jason/Dev/aastar/EvaluationAllPaymaster`
- **GitHub**: git@github.com:AAStarCommunity/EvaluationAllPaymaster.git
- **用途**: AA 生态评估研究（Pimlico/Alchemy/ZeroDev/Coinbase/Biconomy/Particle Network 对比）
- **活跃度**: 存档级
- **性质**: 竞品分析 & 技术研究，不对外提供接口

---

## Mycelium Protocol

> GitHub: github.com/MushroomDAO, github.com/HyperCapitalHQ | 定位: 协议层 & 去中心化协作网络

### mycelium-protocol-research
- **本地路径**: `/Users/jason/Dev/mycelium/mycelium-protocol-reserach`
- **GitHub**: git@github.com:HyperCapitalHQ/mycelium-protocol.git
- **用途**: 协议规格研究与定义；"构建让合作更快更多样的协议"
- **活跃度**: 低（文档型，无近期 commits）
- **内容**: 协议规格、dKMS 设计、v3 规范
- **性质**: 研究型，不对外提供代码接口

### mushroom-docs
- **本地路径**: `/Users/jason/Dev/mycelium/mushroom-docs`
- **GitHub**: git@github.com:MushroomDAO/docs.git
- **用途**: MushroomDAO 官方文档；定义"超越 DeFi 的新经济范式"
- **活跃度**: 低
- **性质**: 文档型

### mushroom.github.io
- **本地路径**: `/Users/jason/Dev/mycelium/mushroom.github.io`
- **GitHub**: git@github.com:MushroomDAO/mushroom.github.io.git
- **用途**: MushroomDAO 官网
- **活跃度**: 低

---

## AuraAI

> GitHub: github.com/AuraAIHQ | 定位: AI 能力与教育

### courses
- **本地路径**: `/Users/jason/Dev/AuraAI/courses`
- **GitHub**: git@github.com:AuraAIHQ/courses.git
- **用途**: 面向儿童的编程/AI 教育课程（5个课程，含 Workshop）
- **活跃度**: 低（2 commits）
- **最近变更**: Document key figures in computer science and AI
- **性质**: 教育内容，不对外提供代码接口

---

## 待分类 / 暂存

> 以下仓库存在于本地但组织归属待确认，或属于三方依赖/fork

| 仓库 | 路径 | 备注 |
|-----|------|------|
| BroodBrain | `/Users/jason/Dev/Brood` | 本仓库，协议神经系统 |
| my-exploration | `/Users/jason/Dev/mycelium/my-exploration` | AAStarCommunity 下，探索性实验 |
| AI/* | `/Users/jason/Dev/AI/` | 14个AI工具 fork（dify/ragflow/langmanus等），学习/工具类，非生态产品 |
| Demos/* | `/Users/jason/Dev/Demos/` | 演示项目，学习用 |
| Community/* | `/Users/jason/Dev/Community/` | 多方贡献，含三方依赖 fork |

---

## 组织间依赖关系

```
SuperRelay ──依赖──> AirAccount (TEE 签名)
SuperPaymaster ──依赖──> SuperRelay (bundler)
SuperPaymaster ──依赖──> AirAccount (账户验证)
AAStar_SDK ──封装──> SuperPaymaster + AirAccount + CometENS
Cos72 ──使用──> AirAccount + SuperPaymaster + CometENS
aastar-start ──使用──> AAStar_SDK

（待明确）AuraAI AI能力 ──接入──> AAstar SuperPaymaster (支付结算)
（待明确）Mycelium Protocol ──治理──> AAstar + AuraAI
```

---

_此文件由 `scripts/sync-all-repos.js` 维护，手动校对后生效_
