---
schema_version: "1.0"
org_id: mycelium
org_name: Mycelium Protocol / MushroomDAO
layer: protocol
status: active
protocols:
  - mycelium
provides:
  - capability: protocol-governance
    interface: 协议规格 + 治理框架 + GToken 治理
    repo: github.com/HyperCapitalHQ/mycelium-protocol
  - capability: community-os
    interface: 社区操作系统（Cos72: MyTask + MyShop + MyVote）
    repo: github.com/AAStarCommunity/Cos72
  - capability: personal-os
    interface: 个人操作系统（Sin90: AI代理 + 知识管理 + 数字主权）
    repo: github.com/MushroomDAO/Sin90
  - capability: community-ai
    interface: 社区 AI 决策与自动化（iDoris）
    repo: github.com/MushroomDAO/Doris
  - capability: broodbrain
    interface: 协议神经系统（任务看板 + 上下文发布）
    repo: github.com/AAStarCommunity/Brood
  - capability: nostr-relay
    interface: Nostr 中继节点（agent 通信基础设施，NIP-86）
    repo: github.com/MushroomDAO/agent-speaker-relay
depends_on: []
contact:
  builder: jason
  github: github.com/MushroomDAO
---

# Mycelium Protocol / MushroomDAO 组织名片

## 我们是谁

Mycelium Protocol 是本生态的**协议层**，也是 BroodBrain 所服务的核心协议。

MushroomDAO 是协议的治理组织，致力于"构建数字公共物品——开源、免费、无许可，让普通人掌握数字主权"。

## 核心理念

**菌丝网络**：不是层级制，而是去中心化协作网络。

> "我们拒绝数字劳工生态。普通人的数据、注意力、创造力应该归属于他们自己，而非成为平台的免费资产。"

我们服务于**意义经济**下的三类角色：表达者（Expressors）、创造者（Creators）、建设者（Builders）。

## 产品体系

| 产品 | 定位 | 状态 |
|-----|------|------|
| **Cos72** | 社区 OS（MyTask + MyShop + MyVote） | In Progress |
| **Sin90** | 个人 OS（AI 代理 + 数字主权） | 设计阶段 |
| **iDoris** | 社区 AI 决策与自动化 | 低活跃 |
| **BroodBrain** | 协议神经系统（本仓库） | 活跃 |
| **CometENS** | 免费子域名服务（.comet.eth） | In Progress 65% |
| **launch.mushroom.cv** | 冷启动众筹页面 | 活跃 |

## 服务三层对象

```
个人 → 数字主权（数据、身份、资产自主）
  ↓
社区 → 非营利协作基础设施
  ↓
城市 → 连接社区与居民的操作系统
```

## 融资模型（Cold Launch）

来源：https://launch.mushroom.cv

| 阶段 | 目标 | 金额 | 期限 |
|-----|------|------|------|
| A1 | Claude Max 共享席位 | $1,200 | 1年 |
| A2 | 双席位 + 服务器 | $3,600 | 1年 |
| A3 | 研究 + 设备 | $8,000 | 1年 |
| 3 | 社区启动团队 | $36,600 | 1年 |
| 4 | 核心开发（兼职） | $86,400 | 1.5年 |

总目标：$135,800（早期冷启动，非 VC 融资）

## GToken 经济模型

- **价格**：$0.15/token（USDC）
- **总量**：2,100 万枚（固定，不增发）
- **用途**：治理投票 + 社区参与权（非投机工具）
- **明确拒绝**：无 IDO、无白名单、无投机友好机制
- **商业实体持有**：20%（对齐激励，非控制）
- **国库管理**：Gnosis Safe 多签，全链上透明

## 可持续收入模型

1. 协议层 Gas 代付最小费用
2. 企业服务（托管、定制）
3. iDoris 社区 AI 订阅

所有核心产品永久免费（个人/≤50人小社区）。

## 当前路线图

- 2026-04-15: Testnet Beta（Cos72 + Sin90）启动
- 2026-05~07: Optimism 主网 Beta（延迟中）
- AirAccount v0.16.8 在 Sepolia testnet 可用
- 所有代码 Apache 2.0 开源，GitHub 公开

## 与其他组织的关系

- AAstar: 提供 Web3 基础设施（支付 + 身份）→ 是协议的技术底层
- AuraAI: 提供 AI 能力层 → 为 Sin90/iDoris 提供智能
- BroodBrain: 协议神经系统（上下文 + 任务管理）→ 本仓库

## 透明与信任机制

- 链上全透明：Gnosis Safe 多签，所有资金流向可查
- ENS 实名：所有钱包地址关联真实身份
- 委员会决策：国库支出需社区委员会商议
- 代码开源：所有协议代码 Apache 2.0
- 三年后：社区可投票引入商业竞争，独家授权有条件有期限
