# PGL 收益模型 / Revenue Model

> 版本：v0.2（弹性区间模型） · 最后更新：2026-05-15

---

## 1. 设计原则

PGL 收益模型必须同时满足四个原则：

1. **作者拿大头** —— Supplier 永远不低于 50%，避免重蹈"中间商赚差价"
2. **承认 UX 劳动** —— Wrapper（让作品能被普通人用的人）拿到合理回报
3. **法律安全** —— 避开证券化（避免 share / 股份 / 收益权代币）
4. **市场弹性** —— 区间式分配反映 AI 时代劳动结构的真实变化

---

## 2. 三角色弹性区间

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  Supplier (原作者)         Wrapper (UX 适配)        │
│  ┌───────────────────┐    ┌─────────────────┐      │
│  │ 区间: 50% ─ 90%   │    │ 区间: 0% ─ 40%  │      │
│  │ 默认: 70%         │    │ 默认: 20%       │      │
│  │ 下限硬约束: 50%    │    │ 上限硬约束: 40% │      │
│  └───────────────────┘    └─────────────────┘      │
│                                                     │
│         Seller (AgentStore)                         │
│         ┌──────────────────┐                        │
│         │ 固定: 10%（不可降）│                        │
│         └──────────────────┘                        │
│                                                     │
│  约束：Supplier + Wrapper + Seller = 100%           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 2.1 三角色的法律定性

| 角色 | 收入性质 | 法律定性 |
|:---|:---|:---|
| **Supplier** | 软件销售分成 | 普通商品销售收入（如商业软件销售） |
| **Wrapper** | 适配/集成服务报酬 | 类似图书设计费、影视改编费、技术服务费 |
| **Seller** | 平台运营佣金 | 类似 App Store 30% 中的运营服务费 |

**三笔款项都对应成熟的商业合同类型**，无证券属性，税务处理路径清晰。

我们**不发行任何代表收益权的代币**，避免触碰证券监管红线。

---

## 3. 弹性区间调整规则

### 3.1 谁能调整

**"主动发起方在区间内提议，所有签字方接受才生效"**

| 场景 | 发起方 | 流程 |
|:---|:---|:---|
| Supplier 主动签 PGL | Supplier | 写 pgl.yml → 自签 → 公示 → Wrapper 加入时谈判 |
| Wrapper 主动包装 dormant 项目 | Wrapper | 写 pgl.yml（默认 50/40/10 — Wrapper 最有利方案）→ Supplier 可选认领或不认领 |
| Supplier+Wrapper 联合发起 | 双方 | 区间内协商出值 → 双签 pgl.yml |
| 多 Wrapper 竞争同一 Supplier | 各 Wrapper | **每个 Wrapper 独立写 manifest**，独立上架，市场竞争 |

### 3.2 典型场景与对应分配

| 场景 | Supplier | Wrapper | Seller |
|:---|:---:|:---:|:---:|
| 作品已用户友好（如 Marker PDF）—— 无 Wrapper | **90%** | 0% | 10% |
| 标准 UX 包装（Docker + GUI 包装）—— 默认 | **70%** | 20% | 10% |
| Wrapper 工作较轻（只加了点 Docker 化）| **80%** | 10% | 10% |
| Wrapper 工作中等（完整 UX + 文档 + 部署）| **65%** | 25% | 10% |
| Wrapper 重度参与（重写 30% bug + 加新功能）| **50%** | 40% | 10% |
| 商店兼任 Wrapper 角色（无独立 Wrapper） | **70%** | 0%（合并到 Seller） | **30%** |

### 3.3 多 Wrapper = 多产品（重要原则）

**同一 Supplier 作品可被不同 Wrapper 独立包装成不同产品上架**。

```
Supplier: OCR 模型作者 Alice（已签 PGL）
   │
   ├── Wrapper A: 团队 X 包装成 "Awesome PDF Scanner"  
   │       └── 自己的 pgl.yml，分配 70/20/10，主打个人用户
   │
   ├── Wrapper B: 团队 Y 包装成 "DocConverter Pro"
   │       └── 自己的 pgl.yml，分配 60/30/10，主打律所，加了批量处理
   │
   └── Wrapper C: 团队 Z 包装成 "OCR Cloud Service"
           └── 自己的 pgl.yml，分配 50/40/10，主打 SaaS API，加了云端推理

用户在 AgentStore 选哪个 → 走哪个 pgl.yml → 钱按那个 manifest 分账
```

**关键设计**：
- 不存在"多个 Wrapper 之间分蛋糕"的情况
- 用户买的是**一个具体 Wrapper-产品**，不是"原始 OCR 模型 + 任选包装"
- Wrapper 之间是**市场竞争关系**（谁的 UX 好、定价合理、Mother Test 分高，谁胜出）

### 3.4 防止"Wrapper 压榨 Supplier"的机制

由于 Wrapper 主导发起场景下可能压低 Supplier 比例，加入以下保护：

1. **硬下限 50%** —— pgl.yml 中 Supplier < 50% 直接被 Registry 拒绝
2. **三方签名永远成立** —— Supplier + Wrapper + Seller，签名路径见 [`MANIFEST_SPEC.md §4`](./MANIFEST_SPEC.md#4-签名协议四场景)
3. **30 天 GitHub PR 公示期** —— Wrapper 主导发起时必须向 Supplier 原仓库提 PR：
   - PR 内容：PGL_CHARTER.md + pgl.yml + 公开说明
   - 公示期间：Supplier 可在 GitHub 上响应（merge / comment / 拒绝）
   - 公示期满 + Supplier 无响应 = 视为客观默认接受
   - 全程 GitHub 公开记录可审计，**不依赖任何主观仲裁**
4. **链上托管** —— Supplier 应得份额（≥ 50%）存入 escrow，Supplier 未来用 AirAccount 认领
5. **可追溯协商** —— Supplier 迟到响应后想调整比例，必须与 Wrapper 重新协商 + 双签新版本 manifest（历史销售不追溯）

详细签名协议四场景见 [`MANIFEST_SPEC.md §4`](./MANIFEST_SPEC.md#4-签名协议四场景)。

---

## 4. 内部分配（角色内部，自愿）

三角色顶层切分之外，每个角色拿到的钱**内部可自愿再分配**：

### 4.1 Supplier 内部分配

`pgl.yml` 中 `roles.supplier.internal_split` 字段：

```yaml
roles:
  supplier:
    percent: 70           # 顶层 70%
    internal_split:
      - address: "0xAlice"
        share: 60          # 70% 中的 60% = 总收入 42%
        role: "core author"
      - address: "0xBob"
        share: 25          # 总收入 17.5%
        role: "co-author, OCR contributor"
      - address: "0xUpstreamMarker"
        share: 10          # 总收入 7%
        role: "upstream OSS (Marker library)"
      - address: "0xCharityFund"
        share: 5           # 总收入 3.5%
        role: "voluntary donation"
```

**特点**：
- 完全自愿（不强制）
- 上游 OSS 依赖只有签了 PGL 的才能收到链上分账
- 慈善捐赠是 Supplier 自选

### 4.2 Wrapper 内部分配

同理，Wrapper 团队内部可分给设计师、UX 写作、集成工程师、测试者等：

```yaml
roles:
  wrapper:
    percent: 25
    internal_split:
      - address: "0xDesigner"
        share: 30
        role: "UI designer"
      - address: "0xEngineer"
        share: 50
        role: "integration engineer"
      - address: "0xTester"
        share: 20
        role: "tester + documentation"
```

### 4.3 Seller 内部分配

当前阶段：Seller = AgentStore DAO 单一接收。

未来可能引入 curator（社区策展人）、reviewer（妈妈测试审核员）等子角色，由 DAO 决定 Seller 10% 的内部分配。

---

## 5. 收益的形态

### 5.1 法币锚定通道（OpenPNTs）

- 用户用 `xPNTs`（OpenPNTs 协议下的稳定积分）支付
- `xPNTs` 1:1 锚定 USD
- 适合普通用户：定价直观（"¥1 一次"）

### 5.2 原生加密通道

- 高级用户用 USDC / ETH 支付
- 链上路由合约自动按 pgl.yml 比例分配
- Gas 由 SuperPaymaster 赞助

无论哪种通道，作者最终都可一键提现到法币账户。

---

## 6. 链上路由合约接口（草案）

```solidity
interface IPGLRoyaltyRouter {
    struct RoleSplit {
        address recipient;
        uint16 basisPoints;        // 1/10000；7000 = 70%
    }
    
    struct InternalSplit {
        address recipient;
        uint16 shareOfRole;        // 1/10000，相对于该角色的子份额
    }

    /**
     * @notice 注册作品分账规则
     * @dev manifestHash 已包含弹性区间内的具体值；合约校验 supplier ≥ 5000 且 seller = 1000
     */
    function registerWork(
        bytes32 manifestHash,
        RoleSplit calldata supplier,
        RoleSplit calldata wrapper,    // wrapper.basisPoints 可为 0（无 Wrapper 场景）
        RoleSplit calldata seller,
        InternalSplit[] calldata supplierInternal,  // 可空
        InternalSplit[] calldata wrapperInternal    // 可空
    ) external;

    /**
     * @notice 用户支付时调用，自动分账到所有 recipient
     */
    function settle(
        bytes32 workHash,
        address payToken,
        uint256 amount
    ) external payable;
}
```

**关键设计**：
- 合约不持有资金（pass-through），降低被攻击的资产敞口
- 顶层分账规则**不可改**（splits_locked = true）；要改 = 新 manifest = 新 workHash = 新版本
- 内部分配可改（角色内部纠纷由角色 leader 调整）

---

## 7. 声誉（非货币）回馈

对**免费层**作品，没有现金分账，但累积**链上声誉**：

| 用户行为 | Supplier 获得 | Wrapper 获得 |
|:---|:---|:---|
| 安装作品 | +1 install count | +1 install count |
| 7 天后仍在用 | +1 retention SBT | +1 retention SBT |
| 点赞 / 推荐 | +1 endorsement | +1 endorsement |
| 通过妈妈测试 | +1 mother-approved badge | +1 mother-approved badge |
| 写测评 | +1 review，附评分 | +1 review |

**贡献度 SBT 永远不可转让**（Soulbound）。

---

## 8. 反套利与边界

| 套利场景 | 防御机制 |
|:---|:---|
| Wrapper 试图把 Supplier 压到 < 50% | 链上合约拒绝注册（硬约束） |
| Wrapper 抹掉 Supplier 名字自己上架 | manifest 强制包含 Supplier 签名 / 代理签名流程 |
| 套利者把作品搬到 AgentStore 之外卖 | 不可技术阻止；但失去 Store 流量是隐形惩罚 |
| 自买自卖刷量获取声誉 | AI 异常检测 + DAO 审查 |
| 滥用免费层（强制广告等） | Charter 第一条不允许；可举报降权 |

---

## 9. 税务建议

| 角色 | 收入性质 | 申报路径 |
|:---|:---|:---|
| Supplier | 软件销售分成 | 个人/企业经营所得，建议设工作室或个体户 |
| Wrapper | 技术服务费 / 适配服务费 | 经营所得，可按月开发票 |
| Seller | 平台运营佣金 | DAO 合规主体收取，按运营收入申报 |
| Supplier 内部 → 上游 | 知识产权使用费 | 类版税收入 |
| 慈善捐赠 | 公益捐赠 | 可申请税前扣除（具体看地区） |

PGL DAO 后续会发布《税务与合规手册》。

---

## 10. 版本历史

| 版本 | 日期 | 变更 |
|:---|:---|:---|
| **v0.2** | 2026-05-15 | 改为三角色弹性区间模型；Upstream 降级为 Supplier 内部分配；多 Wrapper 改为多产品 |
| v0.1 | 2026-05-15 | 初稿（固定 70/20/10 author/upstream/channel）|
