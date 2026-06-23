# BROOD_PRIOR_ART.md — Brood/Mycelium 过往积分相关讨论汇总

> **目的**：在做新设计前，先**穷尽 Brood 现有上下文**，避免重复造轮子。
> **结论**：Brood 已有相当深入的"单一类型积分"基础设施和经济模型设计，但**没有专门研究"跨商家积分流通 + 联盟清算"**。

---

## 1. 总览（4 处分布）

| 来源 | 类型 | 状态 | 与跨商家积分流通的关系 |
|:---|:---|:---:|:---|
| **AAStar OpenPNTs / xPNTs / aPNTs** | 协议层 + 已部署合约 | ✅ 生产 v4.4.0 | 单一代币替代 ETH 付 gas，**非跨商家** |
| **task-2 Cos72 Cards-Points-Perks** | 产品规划 | 🚧 In Progress 20% | 社区/商家发卡 + 积分 + 权益框架；**未启动具体实现** |
| **task-29 Asset3 Protocol** | 协议设计 | 🚧 In Progress 10% | "价值定义自治"，仍在概念阶段 |
| **protocol/PGL v0.1** | 协议规范草稿 | 📝 Phase 1 草稿 | ⭐ 三角色弹性收益分配模型 + **明确不发收益权代币避免证券化** |

> **没有**任何文档专门讨论：A 家积分 ↔ B 家积分如何兑换、联盟清算、跨商家账目。这是本研究目录的核心 gap。

---

## 2. AAStar OpenPNTs / xPNTs — 单一代币付 gas 模型

### 2.1 定位

- AAStar SuperPaymaster v4.4.0+ 支持"社区积分（xPNTs）替代 ETH 付 gas"
- xPNTs / aPNTs / OpenPNTs 在 Brood 文档中混用，本质是**同一套架构**：
  - **OpenPNTs** = 协议层标准（接口规范）
  - **aPNTs** = AAStar 官方发行的 PNTs（默认）
  - **xPNTs** = 社区自定义 PNTs（任意 ERC-20 + Paymaster 注册）

### 2.2 技术接口（已实现）

来自 `orgs/aastar/INTERFACES.md`：

```
SuperPaymaster (v4-v5)
├─ validatePaymasterUserOp   ─ 验签 + 检查用户 xPNTs 余额
├─ postOp                    ─ tx 后从用户账户扣 xPNTs 抵 gas
├─ deposit / withdraw        ─ 运营商管理 ETH 储备金
└─ registerToken             ─ 注册新 xPNTs（社区自定义代币）
```

### 2.3 当前能力 / 不能力

✅ 单一商家/社区发自己的代币（任意 ERC-20）  
✅ 用该代币付 gas（背后用 ETH 实际付）  
✅ 多种代币并存（不同社区互不干扰）  

❌ **不支持** 跨代币兑换（A 家 PNTs ↔ B 家 PNTs）  
❌ **不支持** 联盟清算账本  
❌ **不支持** "时效"（PNTs 永不过期）

### 2.4 对本研究的启示

- OpenPNTs 已经解决了"单家发币 + 付 gas 抵扣"的协议层
- 但"跨家流通"是**协议层的全新维度**，需要新合约 / 新清算逻辑
- 可以复用 OpenPNTs 作为**底层"商家自家积分"**，再在上面加一层"联盟兑换"

---

## 3. task-2 Cos72 Cards-Points-Perks — 最接近的产品讨论

来自 `backlog/tasks/task-2 - Product-Cos72-Cards-Points-Perks.md`：

### 3.1 当前状态（2026-06-21 扫描）

- 进度 **20%**
- 关联仓库 `AAStarCommunity/demo` 连续静默 ≥ 60 天
- Cos72 主仓库本期仅 3 次治理提交，无 feature 代码
- AC：定义 Card 结构 + 实现 Points 系统 + 开发 Perks 分发（全 ⬜ 未开始）

### 3.2 概念定位

- "A framework for user engagement and community incentives, featuring Cards, Points, and Perks"
- 社区/商家发**会员卡**（Cards）
- 用户做事**赚积分**（Points）
- 积分**兑换权益**（Perks）

### 3.3 与本研究的关系

- task-2 的**单家版本**几乎已经在 OpenPNTs 协议下可以实现
- task-2 没有讨论**跨家流通**
- 本研究 = task-2 的"协议层向上拓展"

### 3.4 建议

把本研究结论**反馈到 task-2**：
- 单家版本（Lite）先做
- 跨家版本（v2）按本研究的 [DESIGN_OPTIONS.md](./DESIGN_OPTIONS.md) 推荐方案

---

## 4. task-29 Asset3 Protocol — 价值定义自治

来自 `backlog/tasks/task-29 - Asset3-Protocol.md`：

### 4.1 当前状态

- 进度 **10%**
- 仓库 `MushroomDAO/Asset3` 静默约 14 天
- 仅有 license 文件，缺乏协议规范文档

### 4.2 概念

- "A Protocol for Value Definition Autonomy"
- 让任何人/组织能**自主定义"什么是有价值的"**
- 通常涉及：积分、徽章、声誉、贡献度

### 4.3 与本研究的关系

- Asset3 是更**底层**的协议（价值定义层），积分只是其一种实例
- 如果 Asset3 成熟，本研究的"跨商家积分"可作为 Asset3 的一个 reference application
- 当前 Asset3 太早期，**不应依赖**

---

## 5. protocol/PGL v0.1 — 三角色弹性收益模型 ⭐核心可复用

来自 `protocol/PGL/REVENUE_MODEL.md`（v0.2）。这是 Brood 关于"经济模型 + 合规设计"**最成熟的思考**。

### 5.1 PGL 解决的问题

- 数字 Agent 商店（AgentStore）的**收入分配**
- 原作者（Supplier）+ UX 适配者（Wrapper）+ 平台（Seller）三方分账

### 5.2 关键设计原则（与积分流通**强相关**）

1. **作者拿大头** —— Supplier 永远 ≥ 50%
2. **承认 UX 劳动** —— Wrapper 0-40%
3. **法律安全** —— 避开证券化（避免 share / 股份 / 收益权代币）⭐
4. **市场弹性** —— 区间式分配

### 5.3 三角色法律定性（可直接借鉴）

| 角色 | 收入性质 | 法律定性 |
|:---|:---|:---|
| **Supplier** | 软件销售分成 | 普通商品销售收入 |
| **Wrapper** | 适配/集成服务报酬 | 类似图书设计费、影视改编费、技术服务费 |
| **Seller** | 平台运营佣金 | 类似 App Store 30% 中的运营服务费 |

> "**三笔款项都对应成熟的商业合同类型**，无证券属性，税务处理路径清晰。我们**不发行任何代表收益权的代币**，避免触碰证券监管红线。"

### 5.4 对本研究的启示

⭐ PGL 的"**不发可交易代币**"原则**应当直接套用**到积分联盟设计：
- 商家积分应是"服务凭证"，对应商家提供的具体商品/服务
- **不发代表流动性/收益权的可交易代币**
- 清算应是"账本"而非"托管"
- 角色映射：发行商家 ≈ Supplier / 联盟运营 ≈ Wrapper / 清算服务 ≈ Seller

### 5.5 PGL 其他可借鉴部分

- `protocol/PGL/CITY_REP.md` — 城市声誉网络（"虚拟股东"机制，**值得展开看**是否能套用到联盟治理）
- `protocol/PGL/CHARTER.md` — 五条精神承诺（社会层约定）
- `protocol/PGL/MANIFEST_SPEC.md` — 机器可读接入声明（`pgl.yml` schema）

---

## 6. 其他相关 backlog 任务（次要）

| Task | 标题 | 关联性 |
|:---|:---|:---|
| task-13 | Cos72 Core Modules (MyTask/MyShop/MyVote) | MyShop 涉及积分交易 |
| task-17 | Asset3 Personal Asset Management | 个人持有的"资产"含积分 |
| task-21 | TradeStar Real Trading Training | 不强相关，但有"积分激励"元素 |
| task-25 | Phase 3 Ecosystem Maturity | 长期愿景含积分网络 |

> 这些任务**都还在 In Progress 或 To Do**，本研究**不应阻塞**它们，但可以为它们提供"跨商家积分"的设计参考。

---

## 7. Brood 现有积分相关基础设施汇总

✅ **已有 / 可直接用**：
- AAStar OpenPNTs / SuperPaymaster — 单家代币 + 付 gas
- AirAccount — 用户智能账户（持积分载体）
- PGL 三角色弹性收益模型 — 经济 + 法律框架
- MushroomDAO Treasury — 国库（积分背书 / 清算资金池）

🚧 **设计中 / 需推进**：
- task-2 Cos72 Cards-Points-Perks — 单家产品形态
- task-29 Asset3 — 价值定义协议（早期）

❌ **空白 / 本研究填补**：
- 跨商家积分流通模型
- 联盟清算账本（链上 + 链下双轨）
- 多商家时效协调机制
- 兑换比率治理
- 跨司法辖区合规策略

---

## 8. 关键决策建议

> 在写 [DESIGN_OPTIONS.md](./DESIGN_OPTIONS.md) 之前，下列原则**强烈建议**直接继承自 PGL：

1. ⭐ **不发可交易代币**（不能在 DEX 上炒卖）
2. ⭐ **链上记录 + 链下清算**（透明度 + 法律灵活性）
3. ⭐ **平台不持有用户积分余额**（与 FangPay "不过手"哲学一致）
4. ⭐ **每家积分是"服务凭证"**（绑定具体商品/服务，避免价值储存定性）
5. ⭐ **明确不可兑换法币**（避免触发支付牌照）
6. ⭐ **时效短期**（90 天-2 年），避免长期价值储存定性
7. ⭐ **联盟运营方 = HyperCapital 角色**（参考 Mycelium 双生模型）

详见 [DESIGN_OPTIONS.md](./DESIGN_OPTIONS.md) 和 [SYNTHESIS.md](./SYNTHESIS.md)。
