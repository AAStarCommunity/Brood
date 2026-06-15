# PGL DVT 经济模型 / DVT Economics

> 版本：v0.1 · 最后更新：2026-06-15
> 关联：[`DVT_INCENTIVE.md`](./DVT_INCENTIVE.md)（规范）· 协调 hub [YetAnotherAA-Validator#42](https://github.com/AAStarCommunity/YetAnotherAA-Validator/issues/42)
> 定位：DVT 节点收入的**反推、敏感性分析、运营者决策参考**。
> **不替代**规范文档，只做经济直觉建模。

---

## 1. 为什么需要这份文档

`DVT_INCENTIVE.md` 定义了 **trait 颁发规则** + **服务费分账机制**（规范层）。

但 DVT 节点运营者（潜在新加入者 / 现有节点 / 投资人）真正想知道的是：

- 我要不要做 DVT 节点？
- 月收入大概多少？
- 收入和什么相关？我能控制什么、不能控制什么？
- 早期参与有什么倾斜？
- 网络规模变了我的收入怎么变？

本文档用**反推 + 敏感性分析**回答这些问题。所有数字是**估算**，最终以实际链上数据为准。

---

## 2. Charter 范围决策的位置

DVT 激励是「**Charter 第六条**」还是「**PGL 附录**」的范围问题：

| 位置 | 看什么 |
|:---|:---|
| `protocol/PGL/DVT_INCENTIVE.md` §12 | 完整 (A)/(B) 对比 + Brood 端倾向 (A) 的理由 |
| hub #42 [comment-4703606187](https://github.com/AAStarCommunity/YetAnotherAA-Validator/issues/42#issuecomment-4703606187) | Brood 端正式提请 hub owner 拍板 |

决策**尚未做出**。**(A) PGL 附录** vs **(B) Charter 第六条**：
- (A)：CHARTER.md 五条不动，本文档 + DVT_INCENTIVE.md 独立存在
- (B)：CHARTER.md 五条 → 六条，DVT_INCENTIVE.md 成为「第六条·基础设施公物提供者」的实施细则

**经济模型不受 (A)/(B) 影响** —— 资金流、分账规则、trait 颁发完全相同。

---

## 3. 声誉激励：谁决定，如何发放

### 3.1 谁决定？没人决定。**全部链上合约自动判**

5 个 trait 各有机器可判的颁发条件，零人工裁决：

| Trait | 颁发条件 | 触发上链的角色 |
|:---|:---|:---|
| **NoBlindSign**（无盲签） | 连续 100 次 Canary 通过 | Hub orchestrator 提交 Canary 结果 |
| **OnDuty**（在岗） | stake ≥ 60d + 响应率 ≥ 95% + 无 slash | 合约读 SP v5 Registry |
| **Diversity**（多样性） | 策略哈希 + 运营者 + 软件栈与中位数节点显著差异 | 合约扫 PolicyRegistry 自动比对 |
| **PolicyPublisher** | 节点上链注册策略哈希 + 可审计 URI | 节点自己 `registerNodePolicy` |
| **LongStanding** | NoBlindSign + OnDuty 同时 ≥ 6 个月 | 合约从前两个 trait 自动派生 |

SBT 是 **Soulbound NFT**，颁发即铸到节点地址，**永远不可转让**。

### 3.2 trait 解锁什么权益

不直接换钱，但解锁**非货币权益**：

- AgentStore 个人主页显示「守护者徽章」
- `NoBlindSign + OnDuty` → 申请 AgentStore curator 资格
- `LongStanding` → Mycelium DAO 治理引用权重
- `Diversity ≥ N` → 优先列入 SP v5 BLS 聚合器推荐集合
- 全 trait 满 → CityRep 体系内被城市层引用为「数字基建守护者」

### 3.3 声誉腿的「现金折现」

声誉本身不发钱，但有可量化的二阶现金效应：
- AgentStore curator → 中介费 / 推荐分成
- DAO 治理权重 → 影响 PaymasterV4 oracle 配置、DVT 服务费率等参数（间接影响自己的现金腿）
- 商业合同引用 → 申请商业 DVT 合作（如企业级 AirAccount 用户）时的可信背书

---

## 4. 商业激励：谁出钱，如何分，收入相关因素

### 4.1 资金从哪来：**用户付费 = 真实业务量**

```
用户发起高额/高风险操作（账户自定义策略触发 DVT）
  ↓
SP v5 validatePaymasterUserOp 检查 IPolicyRegistry → 触发 DVT
  ↓
SP 在 user op 的服务费中**抽出一部分**作为 DVT 服务费池
  ↓
N 个节点 BLS 共签成功
  ↓
SP postOp 调 IDVTIncentive.distributeServiceFee(workHash, signerMask, amount)
  ↓
amount 按 signerMask 的 bit 数均分到节点钱包
```

**资金来源 = 真实业务**。不是国库补贴、不是凭空发币、不是 staking yield。

### 4.2 触发阈值是**账户自定义**（hub 6-14 owner 输入）

DVT 触发**不是全局 USD 门槛**，而是每个账户对**指定合约 + 指定资产 + 数额**自定义：

```
账户 A 的策略（PolicyRegistry per-sender）:
  - USDC > $100 转账 → 触发 DVT
  - 任意金额转账到 0xUnknown → 触发 DVT
  - 任何合约调 setApprovalForAll → 触发 DVT
  - 社交恢复触发 → 触发 DVT

账户 B 的策略可以完全不同（更激进/更保守）
全局 USD-oracle 阈值只作默认/兜底。
```

→ **业务量 M 是所有账户策略触发数的总和**，不是简单的「网络大额 ops / 全局阈值」。

### 4.3 如何分：**按 signerMask 中的 bit 数均分**

```
节点单次收入 = 服务费池 / 参与共签的节点数
```

举例：服务费池 $0.70，5 个节点共签 → 每个节点 **$0.14**。

**绝对不**：
- ❌ 按节点 stake 大小加权
- ❌ 按累计签名次数加权
- ❌ 按成功率（signed/total）加权

### 4.4 收入相关因素

| 因素 | 影响 | 节点能控制吗 |
|:---|:---|:---|
| **网络月 DVT-trigger ops 总数 M** | 业务量越大，节点收入越多 | 间接（推广 Mycelium 生态用户）|
| **单 op 服务费率 F** | DAO 决定（建议初期 $0.50-$2 区间）| 间接（DAO 投票）|
| **网络总节点数 N** | 节点越多每个分越少 | 间接（推广 / Diversity trait 站位） |
| **节点参与共签的频率 P** | 在场 + 响应快 + 通过 trait 验证 | **可控**（运维质量）|
| **trait 状态** | Slashed / blacklisted 节点失去分账资格 | **可控**（不盲签、不失联、保持策略独立）|

**不相关**（命门二硬约束）：
- 节点累计签名次数
- 节点 stake 大小
- 节点签名成功率（rate）

---

## 5. 月收入 100 USD 反推：所需业务量与节点规模

### 5.1 基础公式

```
节点月收入 ≈ M × F × P / N
```

- M = 月 DVT-trigger ops 总数
- F = 单 op 服务费率（DAO 设定）
- N = 网络参与共签的总节点数
- P = 节点参与率（trait 满 + 在线 → 接近 1）

设 **P = 1**（理想情况），公式化简为 `M × F / N`。

### 5.2 三种生态规模情景表

要求节点月入 = **$100 USDC**，反推所需 M（月 ops 总数）：

| 阶段 | DVT 启用模式 | N（节点数） | F（单 op 费）| 节点月入 $100 所需 M | 折每天 ops |
|:---:|:---|:---:|:---:|:---:|:---:|
| **网络启动** | opt-in（rolled out 前夕） | 5 | $0.50 | **1,000 ops/mo** | ~33/day |
| **网络启动** | opt-in | 5 | $2.00 | **250 ops/mo** | ~8/day |
| **opt-out 切换** | DVT 默认开（hub 6-14 决议）| 20 | $1.00 | **2,000 ops/mo** | ~67/day |
| **opt-out 切换** | DVT 默认开 | 20 | $2.00 | **1,000 ops/mo** | ~33/day |
| **普及期** | DVT mandatory | 100 | $0.50 | **20,000 ops/mo** | ~667/day |
| **普及期** | DVT mandatory | 100 | $2.00 | **5,000 ops/mo** | ~167/day |

### 5.3 hub 6-14 决议对经济模型的影响

hub owner 决议「**DVT 默认开（opt-out）**」（[comment-4702126341](https://github.com/AAStarCommunity/YetAnotherAA-Validator/issues/42#issuecomment-4702126341)）是经济模型的**关键拐点**：

| 阶段 | opt-in 期 | opt-out 默认开后 |
|:---|:---|:---|
| 业务量 M | 主动开 DVT 的少数用户 | 绝大多数大额/高风险 ops |
| 估算 M 量级 | 几十～几百 ops/天 | 几百～几千 ops/天（增长 10x+）|
| 节点收入对网络节点数 N 的敏感度 | 高（节点少时收入波动大）| 低（高基数下均衡） |
| 早期参与者优势 | 中等 | **高** —— flip 时已经有 LongStanding trait + Diversity 站位 |

**重要前提**（hub owner 已明确）：opt-out 默认开 **只能在 DVT 网络成熟后 flip**，否则大额 ops 会因「凑不齐门限」直接失败。

→ **节点早入的真实价值**：在 flip 那天前积累 trait + 运维信任，flip 后吃业务量爆发的第一波红利。

### 5.4 直觉判断

- **早期 opt-in**（DVT 还是可选）：业务量天然偏低，单节点月入 $100 需要**几十到几百 ops/天**。对一个真正生产环境的 Web3 协议（AirAccount 用户群体），这是**可达的中等规模目标**
- **opt-out flip 后**：业务量爆发，节点数也会增加，但**比例 M/N 决定一切**。如果 ops 增长比节点增长快 → 节点收入上升；反之下降
- **经济均衡内生于业务量增长**：节点收入低 → 没人来 → 业务量增长但节点数不变 → 收入上升 → 吸引新节点。**不靠通胀发币**

### 5.5 一句话给 DVT 节点运营者

> **月入 $100 现金腿 = 「每天 30-100 次 DVT-protected ops 流过的网络」+「合理的节点规模」。**
>
> 生态做大，节点同步赚得多；做大不靠你多签，靠你跟其他节点一起把网络做可信。

---

## 6. 早期参与的「隐性时间价值」

声誉腿是慢函数，但**复利可观**：

| 时点 | 节点状态 | 现金腿（月）| 声誉腿（trait） |
|:---|:---|:---:|:---|
| T0 加入 | 注册 + 质押 | $0 | 无 |
| T0+60d | OnDuty 起效 | $5-$50 | OnDuty |
| T0+90d | NoBlindSign 累积 | $10-$80 | OnDuty + 部分 NoBlindSign |
| T0+180d | LongStanding 起效 | $30-$150 | OnDuty + NoBlindSign + LongStanding |
| opt-out flip 时 | 全 trait | $50-$500+ | 全套 trait + 站位 Diversity |

**早期 vs 后期参与的本质区别**：
- 早期：业务量低、收入波动大，但 trait 积累从 0 起步，6 个月后享受 LongStanding
- 后期：业务量稳定、收入可预期，但要从头积累 6 个月才能拿 LongStanding

→ **对长期运营者**，早期参与的 NPV（净现值）显著高于后期等到稳定再进。

---

## 7. 风险敞口与下行情景

### 7.1 节点会损失什么

| 风险 | 触发 | 损失 |
|:---|:---|:---|
| **盲签 slash** | Canary 命中 | NoBlindSign 清零 + stake 部分 slash + 上链不光彩记录 |
| **失联 slash** | 连续失联 > 阈值 | OnDuty 失效 + 暂时无收入 |
| **策略哈希不符 slash** | 第三方提交证据「你声称跑 X 策略实际跑 Y」 | trait 全部 burn + 巨额 stake slash |
| **stake 跌破 minStake** | GToken 价格下跌或被 slash | BLS 公钥**自动失效**，不再分账 |

### 7.2 下行场景：业务量低于预期

如果 opt-out flip 推迟、生态拓展慢：
- 月收入可能长期 < $50/节点
- 但 **stake 不亏**（30 ether GToken 可正常 exit + 30 天 cooldown 取回）
- trait 不会贬值（继续累积 LongStanding）
- 等业务量起来时，「老兵」的复利价值兑现

**这是一个长期主义节点的游戏**，不适合追短期高收益的运营者。

---

## 8. References

- `DVT_INCENTIVE.md` — 规范文档（trait 定义 + 接口）
- hub `YetAnotherAA-Validator#42` 冻结决议 [comment-4702143353](https://github.com/AAStarCommunity/YetAnotherAA-Validator/issues/42#issuecomment-4702143353)
- hub 触发阈值账户自定义 [comment-4702135103](https://github.com/AAStarCommunity/YetAnotherAA-Validator/issues/42#issuecomment-4702135103)
- hub DVT 默认开（opt-out） [comment-4702126341](https://github.com/AAStarCommunity/YetAnotherAA-Validator/issues/42#issuecomment-4702126341)
- SuperPaymaster v5 `Registry.sol:85` `_initRole(ROLE_DVT)`
- SuperPaymaster v5 `BLSAggregator.registerBLSPublicKey` H-02 自服务路径

---

## 9. 版本历史

| 版本 | 日期 | 变更 |
|:---|:---|:---|
| v0.1 | 2026-06-15 | 初稿：从 DVT_INCENTIVE.md 拆出经济模型 / 收入反推 / 风险敞口；纳入 hub 6-14 owner opt-out 决议 |
