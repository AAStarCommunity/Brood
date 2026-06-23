# DESIGN_OPTIONS.md — 4 个方案设计 + 推荐

> **基于** [CASE_STUDIES](./CASE_STUDIES.md) 第 7 节的 7 大合规共性 + [LEGAL_COMPLIANCE](./LEGAL_COMPLIANCE.md) 第 10 节的 10 条硬约束
> **结构**：每个方案给定义 + 架构图 + 合规分析 + 优缺点 + 适用场景

---

## 1. 方案 A — 单商家积分（最保守，最合规）

### 1.1 定义

每个商家发自己的积分，**完全不互通**。

### 1.2 架构

```
商家 X 的 OpenPNTs 合约
   ├─ 用户 U1 余额: 100 PNTs-X
   ├─ 用户 U2 余额: 50 PNTs-X
   └─ ...

商家 Y 的 OpenPNTs 合约（独立）
   ├─ 用户 U1 余额: 200 PNTs-Y
   └─ ...

无跨家关联。
```

### 1.3 合规

- ✅ 全球几乎所有司法辖区**绿色通道**
- ✅ 中国大陆也可做（单一商家积分 = 折扣返还）

### 1.4 优缺点

| 优 | 缺 |
|:---|:---|
| 100% 合规无门槛 | 无网络效应 |
| 与 Brood 现有 OpenPNTs 完全兼容 | "联盟"价值不存在 |
| 商家立刻可用 | 用户只能用积分回本店 |
| 不需要联盟运营方 | 用户对积分价值感知低 |

### 1.5 适用场景

- task-2 Cos72 Lite 版（**当前最该做的**）
- 不希望承担合规风险的商家
- 中国大陆唯一可走路径

---

## 2. 方案 B — 双边联盟（航空联盟模式） ⭐ 推荐核心

### 2.1 定义

每家发自己积分，联盟内任意两家签**双边汇率协议**，用户可"用 A 家积分换 B 家商品"，背后是 A 家与 B 家**法币 B2B 结算**。

### 2.2 架构

```
┌─────────────────────────────────────────────────────────────┐
│  联盟治理（多边协议）                                          │
│  ─ 加入条件、退出机制、争议解决                                │
│  ─ MushroomDAO 治理 / 联盟章程                                │
├─────────────────────────────────────────────────────────────┤
│  双边协议层（N×(N-1)/2 对）                                   │
│  ─ A↔B: 1 PNTs-A = 0.7 PNTs-B；月度上限 100k                │
│  ─ A↔C: 1 PNTs-A = 1.2 PNTs-C；月度上限 50k                 │
│  ─ B↔C: ...                                                  │
├─────────────────────────────────────────────────────────────┤
│  链上积分合约（每家独立 ERC-1155 Soulbound）                  │
│  ─ PNTs-A: 商家 A 余额管理 + 时效 + 兑换权                    │
│  ─ PNTs-B: 商家 B 余额管理 + 时效 + 兑换权                    │
│  ─ ...                                                       │
├─────────────────────────────────────────────────────────────┤
│  跨家兑换合约（核心创新）                                      │
│  ─ exchangeForRedemption(from_pnts, to_merchant, to_product)│
│  ─ 1. 销毁用户 from_pnts                                     │
│  ─ 2. 给用户发 to_merchant 的兑换券（NFT）                   │
│  ─ 3. emit Event: 联盟账本读取                               │
├─────────────────────────────────────────────────────────────┤
│  联盟账本（开源 SDK + Cloudflare Worker）                     │
│  ─ 订阅链上事件                                              │
│  ─ 双边轧差（每月底）                                         │
│  ─ 推送结算建议（B2B USDC 转账或法币）                        │
│  ─ 报表导出（CSV / PDF）                                     │
├─────────────────────────────────────────────────────────────┤
│  商家 B2B 结算（链下）                                        │
│  ─ A 家欠 B 家 $5000 → A → B 转 USDC（或法币）               │
│  ─ HyperCapital 提供托管服务（可选）                          │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 用户视角

```
用户 U1 钱包：
  ├─ PNTs-A: 1000 (来自商家 A 消费返还)
  ├─ PNTs-B: 500  (来自商家 B 消费返还)
  └─ PNTs-C: 200  (来自商家 C 消费返还)

U1 看到商家 D 的某商品 ($10)：
  └─ 检测器: 1000 PNTs-A 可换 D 家 $7 抵扣券
            500 PNTs-B 可换 D 家 $3 抵扣券
            (汇率由 A↔D 和 B↔D 双边协议决定)

U1 点击兑换：
  ├─ 销毁 1000 PNTs-A
  ├─ 销毁 500 PNTs-B
  ├─ Mint D 家 "$10 抵扣券" NFT
  └─ 商家 A/B 看到自己 "欠" 商家 D
                       (清算账本累加)
```

### 2.4 合规分析

| 硬约束 [#] | 满足 |
|:---|:---:|
| 1. 不发可 DEX 交易代币（Soulbound） | ✅ |
| 2. 不允许兑现金 | ✅（仅换商品/抵扣券） |
| 3. 联盟不持积分 | ✅（每家合约独立持） |
| 4. 兑换结果限定（商家商品） | ✅ |
| 5. 有时效 | ✅（合约层强制） |
| 6. 不在中国大陆 | ✅（IP 屏蔽） |
| 7. 联盟收技术服务费 | ✅（订阅 + 按笔固定费） |
| 8. B2B 用 USDC / 法币结算 | ✅ |
| 9. ToS 明确积分性质 | ✅ |
| 10. 律师函 ≥ 3 份 | 必做 |

**结论**：方案 B 满足所有硬约束，**最贴近航空联盟成熟模式**。

### 2.5 优缺点

| 优 | 缺 |
|:---|:---|
| 网络效应（A 家客户因为 B 家积分而来） | 复杂度高（N×(N-1)/2 双边协议） |
| 合规路径清晰（有航空联盟先例） | 需要法币 B2B 结算（链下） |
| 不发统一币，避免证券化 | 用户需要理解"双边汇率" |
| 每家商家保留主权 | 联盟运营方需要工程能力 |

### 2.6 适用场景

- **本研究的核心推荐**
- 5-50 家中小商家先试点
- 全球范围（除中国大陆）
- 与 FangPay 商家网络协同

---

## 3. 方案 C — 通用兑换币（最危险，不推荐）

### 3.1 定义

联盟发一个**统一代币**（如 ALLIANCE-PNTs），每家积分按比率自动换成统一币，再用统一币兑换任何商家商品。

### 3.2 架构

```
商家积分 → 兑换层 → ALLIANCE-PNTs（联盟统一币）
                       │
                       └─ 兑换任意商家商品（按比率扣除）
```

### 3.3 合规分析

| 硬约束 | 满足 |
|:---|:---:|
| 1. 不上 DEX | ⚠️ 难（统一币易被人挂上） |
| 2. 不可兑现金 | ⚠️ 难（统一币近似货币） |
| 3. 联盟不持余额 | ⚠️ 联盟需要管理 ALLIANCE 池 |
| 4. 限定用途 | ⚠️ 因为通用，难限定 |

**结论**：方案 C **几乎必触红线**：
- US: Money Transmitter License
- EU: EMI License
- SG: Major Payment Institution License
- CN: 多用途预付卡牌照

### 3.4 历史教训

参考 [CASE_STUDIES §4.2](./CASE_STUDIES.md#42-不合规--被叫停的案例)：
- 中国"积分宝" → 叫停
- 几个加密积分项目 → SEC 调查

### 3.5 何时考虑

❌ **本研究不推荐**。如果一定要做，需 EMI / MPI 牌照，门槛极高。

---

## 4. 方案 D — PGL 三角色变体（Brood 协议层升级）

### 4.1 定义

把跨商家积分流通**嵌入** [PGL 三角色模型](../../protocol/PGL/REVENUE_MODEL.md)，作为 AgentStore 之外的另一个 PGL 应用。

### 4.2 角色映射

| PGL 角色 | 积分联盟对应 | 收益 |
|:---|:---|:---|
| **Supplier** | 发行商家（A/B/C） | 50-90% 兑换商品收入 |
| **Wrapper** | 联盟运营方 / 集成 SDK 提供者 | 0-40% |
| **Seller** | 联盟前端门户（用户兑换入口） | 10% |

### 4.3 架构

复用 PGL：
- `pgl.yml` Manifest 中加 `loyalty:` 字段，声明积分类型、兑换比率、时效
- 商家通过 PGL CHARTER 加入联盟
- 复用 PGL 现有合约 + 治理

### 4.4 合规分析

继承 PGL 的"不发收益权代币"原则 → 完全符合硬约束 #1

### 4.5 优缺点

| 优 | 缺 |
|:---|:---|
| 复用 PGL 现有协议设计 | PGL 自己还在 v0.1 草稿，本身未实施 |
| 与 Mycelium 哲学完全对齐 | 增加 PGL 复杂度 |
| 不需要新治理结构 | 等 PGL Phase 1 实施后才能用 |

### 4.6 适用场景

- 中长期（PGL Phase 1 实施后）
- 与 AgentStore 共享商家入网流程

---

## 5. 推荐方案：**B + 渐进 D**

### 5.1 短期（6-12 月）：方案 A + Lite 版方案 B

**第一阶段（Lite）**：
- 单商家方案 A 优先实施（task-2 Cos72 Lite）
- 验证商家发积分 + 用户消费返积分 + 用户兑换商品的核心循环
- 暂不做联盟

**第二阶段（联盟试点）**：
- 招募 3-5 家关系密切的商家做方案 B 试点
- 仅双边汇率（A↔B），不构造多边
- 测试链上账本 + 链下 USDC 结算
- 6 个月后评估扩展

### 5.2 中期（12-24 月）：方案 B 扩展

- 联盟扩展到 20-50 家商家
- 完整双边协议矩阵
- HyperCapital 提供联盟运营服务包
- 律师函覆盖 US/EU/SG/HK 4 个市场

### 5.3 长期（24 月+）：方案 D 协议升级

- 等 PGL Phase 1 落地
- 把联盟模型升级为 PGL 标准（pgl.yml + Charter）
- 与 AgentStore 共享治理

### 5.4 永不做

- ❌ 方案 C（统一币）
- ❌ 中国大陆运营
- ❌ 可兑现金的积分
- ❌ 可在 DEX 交易的代币

---

## 6. 方案 B 的商业模型（重点展开）

### 6.1 联盟运营方收入

| 收入项 | 模式 | 金额（估算） |
|:---|:---|:---:|
| 商家入网年费 | 订阅 | $99-999/商家/年 |
| 每笔兑换技术服务费 | 固定 | $0.05-0.20/笔 |
| 链上 gas 抽成 10% | 与 FangPay 一致 | ~$0.01/笔 |
| HyperCapital 联盟咨询服务包 | 一次性/月度 | $299/商家 onboarding + $99/月运维 |

### 6.2 收入预估（中期 20 家商家联盟）

- 20 商家 × $499 入网费/年 = $10k/年
- 1 万笔兑换/月 × $0.10 = $1k/月 = $12k/年
- HyperCapital onboarding 20 × $299 = $6k 一次性
- HyperCapital 运维 10 商家 × $99/月 = $12k/年
- **合计 ~$40k/年**

> 与 FangPay 类似，小但稳，对齐 Mycelium 双生模型。

### 6.3 商家分账（参考 PGL）

每笔兑换收入：
- 兑换商品价值 $10
- 商家自己承担 $10 商品成本（这是 loyalty discount）
- 联盟分账：
  - 商家自己 = 90%（商品定价权）
  - 联盟方 = 10%（技术服务）
  - HyperCapital = 0%（除非用商业服务包）

### 6.4 资金路径

```
用户兑换商家 D 的 $10 商品
   │
   ├─ 销毁用户 PNTs-A（链上）
   ├─ D 出 $10 商品给用户
   └─ 链上账本：A 欠 D $10 等值

月底清算（D 计算账上）：
   ├─ A 欠 D 累计：$5,000
   ├─ B 欠 D 累计：$3,000
   ├─ C 欠 D 累计：$2,000
   └─ 等等

D 收钱：
   ├─ A 通过 USDC 转 $5,000 到 D 的钱包
   ├─ B 同上
   ├─ C 同上
   └─ 联盟方收 10% 服务费（链上自动扣 0.05 ETH 等值）
```

**关键**：钱**从未经过联盟方账户**（与 FangPay "不过手"哲学一致）。

---

## 7. 方案 B 的技术架构

### 7.1 合约层

```solidity
// 1. 每家商家的积分合约（Soulbound, 不可转账）
contract MerchantPoints is ERC1155Soulbound {
    address public merchant;
    uint256 public maxValidDays;     // 时效
    mapping(uint256 => uint256) public mintedAt;
    
    function mint(address user, uint256 amount) external onlyMerchant;
    function burn(address user, uint256 amount) external;  // 用户主动 burn
    function isExpired(address user) view returns (bool);
}

// 2. 双边兑换合约
contract BilateralExchange {
    struct BilateralRule {
        address fromPnts;          // PNTs-A 合约地址
        address toMerchant;        // 接收商家
        uint256 fromAmount;        // 1000 PNTs-A
        uint256 toRedemptionValue; // 兑换券价值 ($7 等值)
        uint256 monthlyLimit;
        uint256 monthlySpent;
    }
    
    mapping(bytes32 => BilateralRule) public rules;
    
    function exchange(
        address fromPntsContract,
        uint256 fromAmount,
        address toMerchant,
        bytes32 productId
    ) external {
        // 1. 检查双边规则
        BilateralRule memory rule = rules[keccak256(fromPntsContract, toMerchant)];
        require(fromAmount == rule.fromAmount, "amount mismatch");
        require(rule.monthlySpent + 1 <= rule.monthlyLimit, "monthly limit");
        
        // 2. 销毁用户 PNTs-A
        MerchantPoints(fromPntsContract).burn(msg.sender, fromAmount);
        
        // 3. Mint 用户 toMerchant 的兑换券 NFT
        RedemptionNFT(toMerchant).mint(msg.sender, productId, rule.toRedemptionValue);
        
        // 4. emit Event for 联盟账本订阅
        emit Exchange(msg.sender, fromPntsContract, toMerchant, fromAmount, rule.toRedemptionValue);
        
        rules[keccak256(fromPntsContract, toMerchant)].monthlySpent += 1;
    }
}

// 3. 兑换券（在商家 D 处兑换商品）
contract RedemptionNFT is ERC721 {
    mapping(uint256 => uint256) public value;
    mapping(uint256 => bytes32) public productId;
    mapping(uint256 => bool) public redeemed;
    mapping(uint256 => uint256) public expiresAt;
    
    function mint(address to, bytes32 productId, uint256 value) external onlyExchange;
    function redeem(uint256 tokenId) external onlyMerchant;  // 商家核销
}
```

### 7.2 联盟账本（Cloudflare Worker）

```typescript
// alliance-ledger.ts
// 订阅链上 Exchange 事件 + 维护双边账本

interface BilateralLedger {
  from: string;       // 商家 A
  to: string;         // 商家 D
  totalOwed: bigint;  // 累计 A 欠 D
  lastSettled: number;
}

// 每月底触发：
async function monthlySettle() {
  const ledgers = await readAllBilateralLedgers();
  
  for (const ledger of ledgers) {
    if (ledger.totalOwed > 0) {
      // 通知 A 商家："你欠 D 商家 $X"
      await sendSettlementRequest(ledger.from, ledger.to, ledger.totalOwed);
    }
  }
}

// 商家手动触发结算（USDC 转账）
async function executeSettlement(from: string, to: string, amount: bigint) {
  // 1. from 商家钱包发起 USDC.transfer(to, amount) 链上
  // 2. emit Settlement event
  // 3. 联盟账本归零
  // 4. 收 10% 服务费（HyperCapital aPNTs 抽成）
}
```

### 7.3 前端

**用户视角**（钱包页面）：
```
┌────────────────────────────────────────┐
│ 我的积分 (3 家)                          │
│                                        │
│ 🍔 麦当劳 PNTs-A:  1000 (到期 90 天)   │
│ ☕ 星巴克 PNTs-B:   500 (到期 60 天)   │
│ 🥡 必胜客 PNTs-C:   200 (到期 30 天)   │
│                                        │
│ 商家页面: 你可以用以上积分兑换 D 商品    │
└────────────────────────────────────────┘

商家 D 的商品页：
┌────────────────────────────────────────┐
│ D 家 - 1 杯咖啡 $10                     │
│                                        │
│ 💰 直接付 $10                           │
│ 🎁 用积分兑换:                          │
│    ├─ 1000 PNTs-A → 抵 $7              │
│    ├─ 500 PNTs-B → 抵 $3               │
│    └─ 总计: $10 (免费!)                │
│                                        │
│ [一键兑换 + 销毁积分]                    │
└────────────────────────────────────────┘
```

**商家视角**（后台）：
```
┌────────────────────────────────────────┐
│ 商家 A 后台                              │
│                                        │
│ 本月发出积分: 50,000 PNTs-A             │
│ 本月被外家兑换: 12,000 PNTs-A           │
│ 本月外家兑换我家商品: 80 单 = $800       │
│                                        │
│ 我欠其他商家（需结算）:                  │
│   ├─ B 家: $200                         │
│   ├─ C 家: $50                          │
│   └─ D 家: $100                         │
│                                        │
│ 其他商家欠我:                            │
│   ├─ B 家: $50                          │
│   └─ E 家: $300                         │
│                                        │
│ [一键结算（USDC）]                       │
└────────────────────────────────────────┘
```

---

## 8. 方案 B 的部署模型（接 FangPay 经验）

完全复用 FangPay 三层架构：

| 层 | 内容 |
|:---|:---|
| **L0 协议层** | 开源合约（每家发 PNTs + Exchange + Redemption + Ledger） |
| **L1 自助层** | 商家 fork repo + Cloudflare Pages 部署 |
| **L2 商业服务层** | HyperCapital 提供联盟 onboarding（与 FangPay 包 A 类似） |

### 8.1 联盟运营成本

- 同 FangPay：每月 $5k-50k Cloudflare + gas + 律师
- 律师函预算：$30k-100k/年（覆盖 3-4 个 jurisdictions）
- HyperCapital 联盟运营人力：1-2 FTE

### 8.2 商家加入成本

- 入网费 $99-999/年
- 商业服务包 A: $299 一次（HyperCapital 辅导 Cloudflare 部署 + 合约部署 + 双边协议签署）
- 月运维 $29-199（可选）

---

## 9. 方案对比总表

| 维度 | 方案 A | 方案 B ⭐ | 方案 C | 方案 D |
|:---|:---:|:---:|:---:|:---:|
| 跨商家流通 | ❌ | ✅ | ✅ | ✅ |
| 合规难度 | 极低 | 中 | 极高 | 低（继承 PGL） |
| 实施复杂度 | 低 | 中 | 高 | 高（依赖 PGL） |
| 网络效应 | 无 | 强 | 强 | 强 |
| 中国大陆可行 | ✅ | ❌ | ❌ | ❌ |
| 与 Brood 现有兼容 | ✅ | ✅ | ❌ | 部分（PGL v0.1） |
| 商业收入潜力 | 低 | 中 | 高（但门槛极高） | 中 |
| 推荐 | Lite 必做 | **核心方案** | 永不 | 长期方向 |

---

## 10. 一句话

> **方案 B（航空联盟模式 + 链上账本）是当前唯一既能形成网络效应又能合规的设计**。
> **方案 A 是 Lite 版必经之路 / 中国大陆 fallback**。
> **方案 C 不要碰，方案 D 等 PGL 成熟再升级**。
> 详细执行节奏见 [SYNTHESIS.md](./SYNTHESIS.md)。
