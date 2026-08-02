# Mycelium Protocol / MushroomDAO — 对外接口规范

> 文档类型：接口契约（Interface Contracts）
> 维护者：jason | 最后更新：2026-04-27
> 关联：`orgs/mycelium/PROFILE.md`

---

## 我们提供 / What We Provide

### 1. 协议规范 / Protocol Specification

**仓库**: `github.com/HyperCapitalHQ/mycelium-protocol`
**性质**: 文档型，开放规范

| 规范文档 | 说明 |
|--------|------|
| dKMS 规范 | 分布式密钥管理协议规范 |
| 协作经济模型 | Spores 可持续协作协议设计 |
| OpenPNTs 积分协议 | 社区积分标准（ERC-20 兼容扩展） |

**集成方式**：遵循规范文档，无代码 API

---

### 2. OpenPNTs — 积分协议

**仓库**: `github.com/MushroomDAO/OpenPNTs`
**状态**: 低活跃（设计阶段）

| 接口 | 类型 | 说明 |
|-----|------|------|
| `mint` | Solidity | 社区铸造积分 |
| `burn` | Solidity | 消耗积分（用于 SuperPaymaster Gas） |
| `transfer` | ERC-20 | 标准转账 |

**定位**：xPNTs = 社区积分，可用于 SuperPaymaster 替代 ETH 付 Gas

---

### 3. Cos72 — 社区操作系统

**仓库**: `github.com/AAStarCommunity/Cos72`
**状态**: 低活跃（框架已有，部分模块待开发）

| 模块 | 说明 |
|-----|------|
| MyTask | 社区任务协调（MushroomDAO/MyTask 独立仓库） |
| MyShop | 社区积分兑换（完整 + Slither 审计通过） |
| MyVote | 社区治理投票（框架存在） |

**MyShop 集成方式**（最成熟模块）：
```solidity
// MyShop ERC-1155 积分商店合约
// x402 API + Jury 合约（TASK-13）
import { MyShop } from '@mushroom/cos72-shop';
```

---

### 4. CometENS — 免费子域名服务

**仓库**: `github.com/MushroomDAO/CometENS`
**状态**: 活跃（v0.5.0，65% 完成）

| 接口 | 类型 | 说明 |
|-----|------|------|
| `registerSubdomain` | Solidity/API | 免费注册 .comet.eth 子域名 |
| `resolveL2` | Solidity | L2 记录 OPResolver（Bedrock 状态证明） |
| `FreePlugin` | Plugin API | 免费子域名分配插件 |
| `WhitelistPlugin` | Plugin API | 白名单子域名插件 |
| `FlatFeePlugin` | Plugin API | 固定费用子域名插件 |
| ERC-721 | 标准接口 | 子域名所有权 NFT（L2RecordsV3） |

**关键特性**：
- L2RecordsV3：ERC-721 子域所有权 + IRegistrarPlugin 插件架构
- OPResolver：Optimism Bedrock 状态证明 + 签名/证明双模式
- 多根域名支持：.box, .cv, .zparty.eth

---

### 5. Nostr Relay — Agent 通信基础设施

**仓库**: `github.com/MushroomDAO/agent-speaker-relay`
**状态**: 活跃（strfry Docker）

| 接口 | 说明 |
|-----|------|
| Nostr WebSocket | NIP-01 标准 relay 端点 |
| NIP-44 加密 | 端对端加密消息 |

**定位**：iDoris.ai agent 通信、WeChat-Nostr 桥接的基础设施

---

### 6. BroodBrain — 组织神经系统（本仓库）

**仓库**: `github.com/AAStarCommunity/Brood`

| 提供 | 说明 |
|-----|------|
| 协议上下文 | `protocol/` 目录 — L0 层上下文文档 |
| 组织名片 | `orgs/*/PROFILE.md` — 各组织公开名片 |
| 任务看板 | `backlog/` — 任务进度透明化 |
| 静态站点 | `dist/` → Cloudflare Pages 部署 |
| `/sync-progress` | Claude Code skill — 扫描 GitHub 进度更新任务 |

**集成方式**：任何 repo 的 `CLAUDE.md` 可引用本仓库文件获取生态上下文，见 `CONTEXT-INHERIT.md`

---

## 我们消费 / What We Consume

| 来源组织 | 能力 | 用途 | 可选性 |
|--------|------|------|------|
| AAstar / AirAccount | 账户身份 | Cos72 用户账户（邮箱即账户） | 核心 |
| AAstar / SuperPaymaster | Gas 抽象 | Cos72 用户免 Gas 参与治理/任务 | 核心 |
| AAstar / CometENS | ENS 子域名 | mushroom.cv、forest.mushroom.cv | 核心 |
| iDoris.ai / Agent24 | AI 代理 | Sin90 个人 OS 的 AI 能力 | 可选 |
| iDoris.ai / iDoris | AI 模型 | 社区 AI 服务（规划中） | 可选 |

---

## 联系 / Contact

- GitHub Org: https://github.com/MushroomDAO
- 主要维护者: @jhfnetboy (jason)
- 协议研究: https://github.com/HyperCapitalHQ/mycelium-protocol
