# PGL · 数字公共物品公约 / Digital Public Goods Charter

> **本文档是全局上下文 @-include 载荷。**
> 所有 Mycelium 生态 repo 的 CLAUDE.md 通过此文件了解 PGL 体系。
> 完整文档：[`protocol/PGL/`](https://github.com/AAStarCommunity/Brood/tree/main/protocol/PGL)
> 最后更新：2026-05-15

---

## 是什么 / What is PGL

**PGL = Public Goods Layer**。叠加在 Apache 2.0 / MIT / GPL 等原 license 之上的**自愿社会经济层**。

签署 PGL 公约的开源贡献者可以：
- 上架「**数字 Agent 商店 / AgentStore for Public Goods**」分发渠道
- 通过 Mycelium 生态获得链上自动分账（销售分成 + 上游回流）
- 累积链上声誉 SBT（**不可转让**）

PGL **不替代**原 license，**不强制**任何人签署。不签 = 继续按原协议运作；签 = 获得 Store 推荐位与链上分账。

---

## 一句话定位

> **数字 Agent 商店是普通人能用、本地优先、原作者拿大头的 AI 应用商店。**

---

## 核心命名

| 概念 | 中文 | 英文 |
|:---|:---|:---|
| 商店品牌 | 数字 Agent 商店 | AgentStore for Public Goods |
| 签约文件 | 数字公共物品公约 | Digital Public Goods Charter |
| 接入清单 | `pgl.yml` | PGL Manifest |
| 收益单位 | 销售分成 / 版税 / 贡献记录 | Royalty / Contribution Record |

---

## 三大用户价值支柱（"为什么用 AgentStore"）

1. **消除信息差** —— 把 GitHub 上的好工具策展给普通人
2. **抹平 UX gap** —— **「妈妈测试」硬门槛** + 强制 UI 规范
3. **Local-first** —— 敏感数据不出本地，公开数据可走远程（用户/作者声明）

附加价值：**公允回流** —— 链上自动分账，原作者拿大头，反信息差套利。

---

## 三大用户层级

1. **个体** —— 时间紧、预算少、隐私敏感的普通用户
2. **中小组织** —— 雇不起开发团队的律所/诊所/设计室
3. **城市 / CityOS** —— 用真实声誉网络替代官方宣传（[`CITY_REP.md`](./CITY_REP.md)）

---

## 收益分配模型（生产链三角色 · 弹性区间）

**三角色顶层切分**：

| 角色 | 区间 | 默认 | 说明 |
|:---|:---:|:---:|:---|
| **Supplier** 原作者 | 50-90% | 70% | 写核心代码的人 |
| **Wrapper** UX 适配者 | 0-40% | 20% | 把作品包装成普通人能用的（每个 pgl.yml 最多一个 Wrapper）|
| **Seller** AgentStore 渠道 | 10% 固定 | 10% | 分发 + 结算运营，**不可降** |

**硬约束**：
- Supplier ≥ 50%（不可妥协的道德底线）
- Seller = 10%（不可调）
- 三者加总 = 100%

**调节权**：
- 区间内由**主动发起方提议**，**所有签字方接受**才生效
- 默认场景：70/20/10（标准 UX 包装工作量）
- Wrapper 做了大量额外工作（新 feature + 修 bug + 重构）：可调到 50/40/10
- 无 Wrapper 环节（作品已经用户友好或 Supplier 自己包装）：90/0/10

**多 Wrapper = 多产品（不是内部分账）**：
- 同一个 Supplier 的作品，可被不同 Wrapper 独立包装成不同产品上架
- 每个 Wrapper-产品有**独立的 pgl.yml + 独立的产品名 + 独立的分账**
- 用户在 AgentStore 选哪个，就走哪个 manifest 的分账协议
- Wrapper 之间是**市场竞争**，不是平分蛋糕

**内部分配（自愿，非顶层）**：
- Supplier 的 50-90% 内部可自愿分给共同作者 / 上游 OSS 依赖 / 公益基金
- Wrapper 的 0-40% 内部可自愿分给团队成员（设计师 + UX + 集成工程师等）
- Seller 的 10% 不强制再分（如未来引入 curator 角色，可由 DAO 决定）

---

## 法律安全红线（不可妥协）

- **不发任何可交易的代币**
- **贡献度 SBT 永远不可转让**
- 所有收益对应**真实商业行为**（不是分红 / 不是股份 / 不是空气）
- 法律定性始终是「营销活动 / 推荐佣金 / 商品折扣」
- 平台不充当资金池（直接结算）

---

## 加入 PGL 的三个动作

```
动作 1 · 仓库声明
  添加 PGL_CHARTER.md + pgl.yml

动作 2 · 链上注册（复用 SuperPaymaster v5，零新合约）
  用 AirAccount 调用 registerRole()
  注册角色之一：
    ROLE_AGENTSTORE_SUPPLIER
    ROLE_AGENTSTORE_WRAPPER（可选）
  签 Charter hash 写入 metadata

动作 3 · 设置分账
  默认区间内或自定义；详见签名协议四场景
```

### 签名协议要点

**永远存在三方签名**（Supplier + Wrapper + Seller），路径因发起方而异：

| 场景 | 发起方 | Supplier 响应 | 结果 |
|:---|:---|:---|:---|
| A | Supplier | — | 三方直接签字 |
| B | Wrapper | 在线响应（30 天内）| 协商后双签 |
| C | Wrapper | 不响应（30 天后）| **GitHub PR 作客观证据** → Wrapper 提议生效，Supplier 份额进 escrow |
| D | Wrapper（C 之后 Supplier 迟到） | 想调整 | 双方协商，新版本 manifest 上链；历史销售不追溯 |

**关键**：Wrapper 主导时必须向 Supplier 原仓库提 PR（含 PGL_CHARTER.md + pgl.yml + 说明），30 天客观公示，无 DAO 主观仲裁。

详见 [`ONBOARDING.md`](./ONBOARDING.md) 与 [`MANIFEST_SPEC.md §4`](./MANIFEST_SPEC.md#4-签名协议四场景)。

---

## 与 Mycelium 生态的关系（零新合约）

| 能力 | 复用 |
|:---|:---|
| 身份 | AirAccount + CometENS |
| 角色 / 质押 / 退出 / 惩罚 | **SuperPaymaster v5 角色体系** |
| 计价 / 支付 | OpenPNTs (xPNTs) |
| Gas 赞助 | SuperPaymaster Paymaster |
| 公物治理 | Park 协议 |
| 商店运行时 | **Agent24** |

**Agent24 是 AgentStore 的主要承载平台** —— 复用其 skill 加载、eval 系统、memory、多平台 gateway。

---

## 「妈妈测试」AgentStore 上架硬门槛

任何作品上架前必须通过：

1. 首次启动 ≤ 60 秒
2. 无需改配置文件
3. 错误信息说人话（不能露 stacktrace）
4. 核心功能 3 步内可达
5. 不假设用户懂 CLI / Git / 网络

审核员在 Linux + macOS + Windows 三平台跑测试。通过的拿 **「妈妈认证 / Mother-Approved」** 徽章。

---

## 完整文档索引

| 文件 | 内容 |
|:---|:---|
| [`README.md`](./README.md) | 索引 + 锁定决议 |
| [`VALUE.md`](./VALUE.md) | 价值定位 + 竞品对比 + 三大支柱 |
| [`CHARTER.md`](./CHARTER.md) | 公约正文（中英双语，五条承诺）|
| [`MANIFEST_SPEC.md`](./MANIFEST_SPEC.md) | `pgl.yml` 完整 schema |
| [`REVENUE_MODEL.md`](./REVENUE_MODEL.md) | 分账模型 + 链上合约接口 |
| [`ONBOARDING.md`](./ONBOARDING.md) | 接入指南 + 妈妈测试 + FAQ |
| [`UI_MODULE_SPEC_v0.1.md`](./UI_MODULE_SPEC_v0.1.md) | UI 模块规范 |
| [`CITY_REP.md`](./CITY_REP.md) | 城市声誉网络 RFC（下游网络层） |
| [`DISCUSSION.md`](./DISCUSSION.md) | 决策过程 + 备选方案 |

---

## 给 AI 助手的提示 / Hints for AI Assistants

当用户在本 repo 工作时遇到以下话题，请直接引用本文档要点：

| 用户提到 | AI 行为 |
|:---|:---|
| PGL / 公约 / 数字 Agent 商店 | 引用本文档核心要点，必要时引导到完整文档 |
| 想给 repo 加 PGL | 走"加入 PGL 的三个动作"流程 |
| 收益分成 / 版税 / royalty | 强调三角色弹性区间模型（Supplier 50-90% / Wrapper 0-40% / Seller 固定 10%）|
| 上架 AgentStore | 提醒「妈妈测试」5 项验收 |
| 虚拟股东 / 城市声誉 / CityRep | 引到 CITY_REP.md 但强调**不是证券** |
| Agent24 | 它是 AgentStore 的主要承载平台 |
| 上游分账 | Supplier 70% 内部自愿分给上游，非顶层强制 |
| 本地推理 / token-free | Local-first ≠ Local-only，按数据敏感度分路由 |
