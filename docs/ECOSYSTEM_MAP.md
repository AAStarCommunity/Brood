# Mycelium Protocol — 生态地图 / Ecosystem Map

> 最后更新: 2026-07-07
> 路径约定：相对于 `~/Dev/Brood/`（本仓库）
> 数据来源：与 GitHub 三个 org（AAStarCommunity / iDoris-ai / MushroomDAO）的线上 repo 完成同步
> **不追踪**：jhfnetboy 个人仓库（个人 fork/草稿不进生态地图）

---

## 生态全景

```
                    🍄 Mycelium Protocol
                  Park · Spores · OpenPNTs
                      MushroomDAO 治理
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
    🌐 AAstar         🤖 iDoris.ai       🏙️ MushroomDAO
  区块链基础设施      AI 基础设施     社区/个人/城市OS
```

---

## 本地仓库目录约定

固定映射（**必须遵守**，sync-progress 等 skill 依赖）：

| 本地目录 | GitHub 组织 | 仓库数 |
|:---|:---|:---:|
| `~/Dev/aastar/` | `AAStarCommunity` | 26 |
| `~/Dev/auraai/` | `iDoris-ai`（显示名 iDoris.ai）| 12 |
| `~/Dev/mycelium/` | `MushroomDAO` | 26 |
| `~/Dev/backup/` | 已删除/转移/重复的归档 | — |

**特殊路径**：
- `~/Dev/Brood/` —— 本仓库（协议神经系统，launchd 依赖此路径，不放在 aastar/）

---

## 核心产品速览 / Product Overview

| 产品 | 组织 | 十词定位 |
|-----|------|---------|
| **SuperPaymaster** | AAstar | Gasless transactions and micropayments for Web3 agents |
| **AirAccount** | AAstar | Your daily Web3 account: fingerprint login, no ETH needed |
| **SuperRelay** | AAstar | ERC-4337 企业级 bundler 网关·双签名 TEE 零入侵架构 |
| **UltraRelay-AAStar** | AAstar | Alto fork · aastar-dev 自主分支 · 长期跟踪上游 |
| **Cos72** | MushroomDAO | 社区操作系统：Onboarding + 正反馈激励 + 治理 |
| **Sin90** | MushroomDAO | 个人操作系统：表达者·创作者·建设者的数字自我 |
| **iDoris** | iDoris.ai | 隐私优先·Token Free·边缘计算·多端自进化开源 AI 模型 |
| **Agent24** | iDoris.ai | 个人 AI Agent 框架 · **AgentStore 承载平台**（PGL）|
| **CityOS** | MushroomDAO | AI + Blockchain 城市操作系统 |
| **Listener** | MushroomDAO | AI Native Entrance·组织/个人的 AI 原生入口工具 |

---

## AAStarCommunity — 区块链基础设施

**GitHub Org**: https://github.com/AAStarCommunity
**本地路径**: `~/Dev/aastar/`

### 全部仓库（26 个）

| 仓库 | 本地路径 | 最近提交 | 性质 |
|-----|---------|---------|------|
| AirAccount | aastar/AirAccount | 2026-07-07 | 核心产品（账户基础设施）v0.27.3-Beta5 |
| airaccount-contract | aastar/airaccount-contract | 2026-07-07 | AirAccount 合约 v0.27.0 DVT BLS |
| AirAccountEmailAdapter | aastar/AirAccountEmailAdapter | 2026-04-15 | 邮箱登录适配 |
| AirAccountGateway | aastar/AirAccountGateway | 2026-04-15 | 入口网关 |
| AirAccountSmsAdapter | aastar/AirAccountSmsAdapter | 2026-04-15 | 短信登录适配 |
| SuperPaymaster | aastar/SuperPaymaster | 2026-07-07 | 核心产品（Gas 抽象）v5.4.1-rc.1 |
| SuperRelay | aastar/super-relay | 2026-04-29 | 核心产品（Bundler 网关）|
| UltraRelay-AAStar | aastar/UltraRelay-AAStar | 2026-05-06 | Bundler（Alto fork, aastar-dev）|
| YetAnotherAA | aastar/YetAnotherAA | 2026-07-06 | AL Account（DVT wizard + tier-setup）|
| YetAnotherAA-Validator | aastar/YetAnotherAA-Validator | 2026-07-07 | BLS 验证合约 v1.3.0 live gossip quorum |
| Cos72 | aastar/Cos72 | 2026-04-29 | 社区 OS（关联 MushroomDAO）|
| aastar-sdk | aastar/aastar-sdk | 2026-07-07 | 开发者 SDK v0.39.0 |
| aastar.io | aastar/aastar.io | 2026-04-15 | 主站 |
| cos72-tour | aastar/cos72-tour | 2026-07-03 | 🆕 Cos72 引导式 tour |
| .github | aastar/.github | 2026-04-15 | Org profile |
| SDSS | aastar/SDSS | 2025-05-27 | （静默）|
| WhiteList | aastar/WhiteList | 2026-04-15 | 白名单 |
| XSchedule | aastar/XSchedule | 2026-04-15 | 调度服务 |
| captcha-bot | aastar/captcha-bot | 2024-09-09 | Captcha |
| coinJar | aastar/coinJar | 2026-04-15 | （早期试验）|
| create-cos72-dapp | aastar/create-cos72-dapp | 2026-04-15 | Cos72 脚手架 |
| demo | aastar/demo | 2026-04-15 | 演示项目 |
| dvt | aastar/dvt | 2026-04-15 | DVT 节点 |
| me | aastar/me | 2026-05-08 | Personal page |
| registry | aastar/registry | 2026-06-13 | 注册表 |
| research | aastar/research | 2026-04-15 | 研究记录 |
| zu.coffee | aastar/zu.coffee | 2026-04-15 | （社区站点）|
| aastar-docs | aastar/aastar-docs | 2026-06-20 | 🆕 SDK 文档站（v0.16.23）|
| aastar-examples | aastar/aastar-examples | 2026-06-20 | 🆕 SDK 示例集合 |
| abi-docs-kit | aastar/abi-docs-kit | 2026-06-13 | 🆕 ABI 文档生成工具 |

> 已归档的旧仓库（在 GitHub 标记 archived）：Adapters, Gateway, AnotherAirAccountCommunityNode —— 不本地化。

---

## iDoris.ai — AI 基础设施

> **命名说明**：2026-07 组织完成改名——显示名 **iDoris.ai**，GitHub org slug 由 `AuraAIHQ` 改为 **`iDoris-ai`**（github.com/iDoris-ai），15 个子仓库 git remote 已全部更新。**本地目录仍为 `~/Dev/auraai/`**（物理目录名未改，约定映射到 iDoris-ai org）。仓库 `iDoris-ai/AuraAI` 保留原仓库名。

**GitHub Org**: https://github.com/iDoris-ai
**本地路径**: `~/Dev/auraai/`（映射 org iDoris-ai）

### 全部仓库（12 个）

| 仓库 | 本地路径 | 最近提交 | 性质 |
|-----|---------|---------|------|
| Agent24 | auraai/Agent24 | 2026-05-15 | **AgentStore 承载平台**（PGL）|
| iDoris | auraai/iDoris | 2026-04-29 | 隐私优先 AI 模型 |
| iDoris-SDK | auraai/iDoris-SDK | 2026-05-21 | 微信 Agent SDK（含 wechat-agent-bridge submodule）|
| AuraAI | auraai/AuraAI | 2026-04-29 | AI 知识库 |
| OpenCrab | auraai/OpenCrab | 2026-04-29 | 个人 Agent 框架（设计阶段）|
| simple-agent | auraai/simple-agent | 2026-04-29 | Level 1 agent（StorageAgent）|
| agent-speaker | auraai/agent-speaker | 2026-06-20 | Nostr 通信层 v0.25.0 |
| agent-speaker-relay | auraai/agent-speaker-relay | 2026-04-12 | Nostr relay |
| auraai-packages | auraai/auraai-packages | 2026-05-29 | 共享包 |
| courses | auraai/courses | 2026-04-29 | AI/编程教育课程 |
| AI_Beginner_Courses | auraai/AI_Beginner_Courses | 2026-07-05 | 入门课程（Agent Loop 讲义新增）|
| infoCrab | auraai/infoCrab | 2026-04-15 | 信息爬虫 |
| AgentSocial | auraai/AgentSocial | 2026-05-29 | 🆕 Paper3 设计决策 + milestone（Codex 协作） |

---

## MushroomDAO — 社区 + 个人 + 城市操作系统

**GitHub Org**: https://github.com/MushroomDAO
**本地路径**: `~/Dev/mycelium/`

### 全部仓库（26 个）

| 仓库 | 本地路径 | 最近提交 | 性质 |
|-----|---------|---------|------|
| launch | mycelium/launch | 2026-06-24 | **Phase 1 Genesis Launch**（sale 审计修复 + ops 脚本）|
| blog | mycelium/blog | 2026-07-03 | 研究博客 |
| Sin90 | mycelium/Sin90 | 2026-04-29 | 核心产品（个人 OS）|
| Cos72 | mycelium/Cos72 | 2026-04-15 | 核心产品（社区 OS）|
| CityOS | mycelium/CityOS | 2026-04-29 | 核心产品（城市 OS）|
| CometENS | mycelium/CometENS | 2026-06-18 | 免费子域名服务 v0.7.0 |
| Listener | mycelium/Listener | 2026-05-07 | AI Native Entrance |
| Expresser | mycelium/Expresser | 2026-05-05 | 个人表达工具 |
| Xiaoheishu | mycelium/Xiaoheishu | 2026-04-29 | （内容工具）|
| MyShop | mycelium/MyShop | 2026-06-20 | 社区商店 |
| MyTask | mycelium/MyTask | 2026-04-29 | 社区任务 |
| MyVote | mycelium/MyVote | 2026-05-02 | 社区治理投票 |
| MyNFT | mycelium/MyNFT | 2026-06-20 | NFT 模块 |
| Asset3 | mycelium/Asset3 | 2026-04-29 | 资产协议（设计阶段）|
| Park | mycelium/Park | 2026-04-29 | 数字公物协议（Public Goods Garden）|
| Spores | mycelium/Spores | 2026-04-29 | 可持续协作协议 |
| OpenPNTs | mycelium/OpenPNTs | 2026-06-20 | 积分协议 |
| YetAnotherAA | mycelium/YetAnotherAA | 2026-03-02 | （MushroomDAO 镜像）|
| All-You-Should-Know-Today | mycelium/All-You-Should-Know-Today | 2026-05-03 | 资讯 |
| Doris | mycelium/Doris | 2026-04-15 | （早期 iDoris）|
| docs | mycelium/docs | 2025-07-15 | 文档 |
| mycelium-protocol | mycelium/mycelium-protocol | 2026-04-29 | 协议研究 |
| mushroomdao.github.io | mycelium/mushroomdao.github.io | 2026-04-15 | 主站 |
| whitelist | mycelium/whitelist | 2026-04-15 | 白名单 |
| .github | mycelium/.github | 2026-04-15 | Org profile |
| demo-repository | mycelium/demo-repository | 2026-04-15 | 模板 |

### 基础协议 repos

| 协议 | 定位 | GitHub |
|-----|------|--------|
| Park | 数字公共物品 | [MushroomDAO/Park-PublicGoodsGarden](https://github.com/MushroomDAO/Park-PublicGoodsGarden) |
| Spores | 可持续协作 | [MushroomDAO/Spores](https://github.com/MushroomDAO/Spores) |
| OpenPNTs | 积分协议 | [MushroomDAO/OpenPNTs](https://github.com/MushroomDAO/OpenPNTs) |
| **PGL** | 数字公共物品公约 | [本仓库 protocol/PGL/](../protocol/PGL/) |

---

## 组织间依赖

```
airaccount-contract ←── AirAccount (TEE 调用合约)
SuperRelay ──TEE签名──► AirAccount
SuperPaymaster ──bundler──► SuperRelay / UltraRelay
SuperPaymaster ──账户验证──► AirAccount + airaccount-contract
aastar-sdk ──封装──► SuperPaymaster + AirAccount + CometENS
Cos72 ──使用──► aastar-sdk (Gasless + 账户 + 积分)
Sin90 ──使用──► aastar-sdk + Agent24 + iDoris
iDoris ──结算──► SuperPaymaster (AI 服务激励)
iDoris ──身份──► AirAccount (隐私保护)
iDoris-SDK ──桥接──► WeChat (iLink 协议，mason0510/wechat-agent-bridge submodule)
CityOS ──依赖──► Cos72 + Sin90 + iDoris
Agent24 ──承载──► PGL AgentStore (数字 Agent 商店)
PGL ──复用──► SuperPaymaster v5 角色 + AirAccount + OpenPNTs + CometENS
```

---

## 本仓库（Brood）

**相对路径**: `.`（即当前仓库）
**GitHub**: https://github.com/AAStarCommunity/Brood
**定位**: 协议神经系统 —— 任务管理 + L0/L1/L2 上下文发布 + 生态透明化 + **PGL 公约 L0**

不放在 `~/Dev/aastar/Brood`（launchd plist 依赖固定路径 `~/Dev/Brood`）。

---

## 同步历史

| 日期 | 事件 |
|:---|:---|
| 2026-07-07 | sync-context-reverse 状态刷新：更新 65 个 repo 最新提交日期；新增 cos72-tour；修复依赖能力名称；INTERFACES.md 版本同步 |
| 2026-05-15 | 全量同步三个 org 与本地：移走 12 个已删除/转移/重复仓库到 backup；新增 clone 28 个；停止追踪 jhfnetboy 个人仓库 |
| 2026-05-07 | 加入 Listener |
| 2026-05-02 | 加入 UltraRelay-AAStar aastar-dev 分支说明 |
| 2026-04-30 | 三大目录约定建立 |
