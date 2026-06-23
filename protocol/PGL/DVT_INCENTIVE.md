# PGL aNode - DVT 激励规范（附录）/ DVT Incentive Spec (PGL Appendix)

> 版本：v0.1 草稿（70%，待 SP #283 ROLE_DVT 接口定型后补 §8-§9） · 最后更新：2026-06-14
> 关联：协调 hub [`YetAnotherAA-Validator#42`](https://github.com/AAStarCommunity/YetAnotherAA-Validator/issues/42) · 上游 [`SuperPaymaster#283`](https://github.com/AAStarCommunity/SuperPaymaster/issues/283) · 本 issue [`Brood#3`](https://github.com/AAStarCommunity/Brood/issues/3)
> 定位：**PGL 附录**，不修改 [CHARTER.md](./CHARTER.md) 主体五条；不进入 [MANIFEST_SPEC.md](./MANIFEST_SPEC.md)（DVT 节点不是 AgentStore 商品）

---

## 1. 定位与边界

### 1.1 这份文档是什么

DVT（Distributed Validator Technology）节点是 Mycelium / AAstar 生态的**基础设施公物提供者**：通过运行独立 BLS 共签节点，为大额 / 高风险操作提供「即使单把 owner key 被盗也不会全损」的安全增益。

本文档规范 DVT 节点参与方在 **PGL 体系内**能拿到什么、要遵守什么。它**不是法律契约**，是 PGL（Public Goods Layer）的一部分 —— 自愿签署的社会经济共识。

### 1.2 与现有 PGL 文档的关系

| PGL 文档 | 适用对象 | 与本文档关系 |
|:---|:---|:---|
| [`CHARTER.md`](./CHARTER.md) | 端用户作品（agent / app / model / skill） | **不动主体五条**；DVT 复用 Charter 的法律红线（不可转让 SBT + 不发证券化代币）但不需要签 Charter |
| [`MANIFEST_SPEC.md`](./MANIFEST_SPEC.md) | AgentStore 上架的作品 | DVT 节点**不是 Store 上架商品**，不写 `pgl.yml` |
| [`REVENUE_MODEL.md`](./REVENUE_MODEL.md) | Supplier / Wrapper / Seller 三角色分账 | DVT 节点服务费走**独立通道**（普通商业对价），不进 70/20/10 分账 |
| [`CITY_REP.md`](./CITY_REP.md) | 城市声誉网络 | DVT SBT trait 可作为 CityRep 内引用的「数字基建守护者」信用凭据 |
| **本文档** | DVT 节点（基础设施公物提供者） | PGL 体系内的**第 4 类参与者** |

### 1.3 一句话

> **跟了 PGL 的 DVT 节点拿到的是「链上不可转让的守护者声誉徽章」—— 不发币不分红，但在 Mycelium 生态中能被引用、被信任、解锁 curator 等权限 + 运营服务费（普通商业合同）。**

---

## 2. 角色定义：`ROLE_DVT_NODE`

### 2.1 这个角色做什么

DVT 节点对**特定的高风险操作**（如大额转账、关键参数修改、社交恢复触发等）按各自**独立策略**进行 BLS12-381 门限共签。

**对外承诺**（每个节点上链注册时声明）：
1. 运行**独立 BLS 私钥**（不与 owner key 同环境，不与其他节点共享）
2. 运行**独立策略**（链上注册策略哈希 + 版本号；策略可由 CA 之外的渠道审计）
3. 提供**独立确认通道**（用户可不经 CA 直接连接节点验证操作）

### 2.2 谁可以成为 DVT 节点

**完全开放、无许可**。任何人都可以：

1. 在 SP v5 `Registry` 中 `registerRole(ROLE_DVT)` 并质押 `30 ether` GToken（详见 [Registry.sol:85](https://github.com/AAStarCommunity/SuperPaymaster/blob/main/contracts/src/core/Registry.sol)）
2. 在 `BLSAggregator` 中 `registerBLSPublicKey` 自注册 BLS 公钥（H-02 自服务路径已实装）
3. 上链承诺策略哈希 + 版本号
4. 启动节点软件（参考实现见 [`YetAnotherAA-Validator`](https://github.com/AAStarCommunity/YetAnotherAA-Validator)）

无须人工审核 / KYC / 许可。**反对中心化准入**是 DVT 安全模型的前提。

### 2.3 退出与惩罚

完全复用 SP v5 `ROLE_DVT` 现有机制：

- **退出**：`exitRole(ROLE_DVT)` → 30 天 cooldown → 取回 stake
- **惩罚（slash）**：触发条件见 §6 与 §7（不是「签得少」，而是「签错 / 盲签 / 失联」）

> ⚠️ stake 跌破 `minStake = 1 ether` → BLS 公钥**自动失效**（`BLSAggregator` 已实装），不能继续参与共签。

---

## 3. 核心命门（两条不可妥协）

### 3.1 命门一：独立性

**DVT 的全部安全增益来自独立性**，不来自「再签一次」。

如果节点签名时：
- 私钥与 owner key 同环境（同 TEE / 同进程 / 同 KMS）
- 策略由 CA 制定 / 改写 / 旁路
- 确认通道经过 CA

则 DVT **形同橡皮图章** —— 攻破 CA 就同时攻破 DVT。

**链上可验证的独立性证据**：
- BLS 公钥**唯一**（同一公钥不能被多节点注册）—— `BLSAggregator.registerBLSPublicKey` 已检查
- 策略哈希**注册**（每个节点上链承诺自己跑的策略 + 版本，可被 challenge）
- 运营者命名空间**披露**（运营者地址不能与 owner key 上链关联地址重合）

### 3.2 命门二：激励不绑签名次数

**永远不要把奖励绑在「签了多少次」上**。

- 绑次数 → 节点为攒积分盲签 → 「该拒就拒」失效 → 独立策略名存实亡 → DVT 退化为橡皮图章 → 安全增益归零
- 这是 DVT 设计中**最常见、最致命**的反模式

**正确的激励基准**（详见 §5、§6）：
- 「正确执行策略」（用 Canary 机制做负向验证）
- 「在岗」（stake 在线 + 响应可达 + 无 slash 历史）
- 「多样性」（与生态中其他节点的策略 / 运营者 / 软件栈差异化）

服务费**按「成功共签」计**（这是普通商业对价，不是「次数线性发币」）；SBT trait **按上述非次数指标累积**。

---

## 4. SBT Trait 体系

DVT 节点的「守护者声誉徽章」由**多个不可转让的 SBT trait** 组成，每个 trait 都有**链上自动颁发 / 扣减条件**（零人工裁决）。

### 4.1 五个核心 Trait

| Trait | 颁发条件（链上自动） | 扣减条件 | 价值 |
|:---|:---|:---|:---|
| **NoBlindSign**（无盲签）| 连续 N 次 Canary 全通过（N = 100，可由 DAO 调整） | 任何一次 Canary 失败 → 立即清零 | 直接证明策略被正确执行 |
| **OnDuty**（在岗）| stake 在线连续 ≥ 60 天 + 节点 challenge-response 响应率 ≥ 95% + 无 slash | stake 跌破 minStake / 响应率跌破阈值 / 被 slash → trait 失效 | 证明节点稳定可用 |
| **Diversity**（多样性）| 节点的「策略哈希 + 运营者命名空间 + 软件栈 hash」三元组与生态内**中位数节点**有显著差异 | 任一维度被复制（如另一节点同步上线相同策略哈希）→ 重新评估 | 鼓励生态多样性，反对同质化共谋 |
| **PolicyPublisher**（策略可见）| 上链注册了策略哈希 + 公开承诺哈希内容的可审计参照（git commit / IPFS hash / Arweave）| 策略哈希注册后被第三方证明与实际运行不符 → 扣减 + 触发 slash | 透明 + 可被社区审计 |
| **LongStanding**（长期贡献）| `NoBlindSign + OnDuty` 同时持有 ≥ 6 个月 → 自动颁发 | 任一前置 trait 失效 → 失效 | 复利信用 |

### 4.2 Trait 性质（法律红线）

- **完全不可转让**（Soulbound）—— 永远不能 transfer / sell / inherit
- **完全无金钱面值** —— 不能直接兑换 ETH / USDC / xPNTs
- **不构成证券** —— 没有「持有 SBT 即享受未来收益」的承诺
- **不绑空头** —— 所有 trait 都有真实的链上行为对应（无盲签 = 真有 Canary 通过；在岗 = 真有 stake + 响应；多样性 = 真有差异化注册）

### 4.3 Trait 能换到什么（详见 §5）

- 在 PGL **AgentStore** 体系内解锁 curator 权限 / 高曝光位 / 优先支持
- 在 **Mycelium DAO** 治理中获得引用权重
- 在自身商业活动中作为**可信证明**（运营者可在简历 / 商业洽谈中引用链上 SBT）
- 在 [`CITY_REP.md`](./CITY_REP.md) 体系内被城市层引用为「数字基建守护者」

### 4.4 Diversity trait 的 Sybil 防御

> **clestons review 2026-06-15 提出**：一个 operator 跑 N 个钱包地址不同、policy hash 故意差异化的节点，能伪造 Diversity，让一人吃多份「多样性」激励。

**多层防御组合**（不依赖任何单一机制）：

| 防御层 | 机制 | 攻击成本 |
|:---|:---|:---|
| **经济成本** | 每个节点独立 30 ether GToken stake，N 个假节点 = 30N ether 锁仓 | 线性放大攻击成本 |
| **运营者 namespace 披露**（§3.1 + §8.2）| 节点上链注册时必须披露运营者 namespace（如 ENS / proof-of-control）；同一运营者控制多个节点会被链上发现 | 强制揭示同源关系 |
| **多样性 Canary**（§6.5）| Hub 注入「需要不同策略才能正确处理」的复合 Canary；同一 operator 的多节点策略实际同源 → 检测时全签或全拒一致 → 暴露伪装 | 行为级检测，难规避 |
| **链上声誉外溢**（§5.2）| LongStanding + Diversity 高分需要 6+ 个月稳定运营 + 真实策略差异；攻击者跑 N 节点 6 个月持续维护伪装比真做多样化更贵 | 时间维度成本 |
| **第三方挑战**（§14.3 #7 待 DAO 定）| 任何人可提交「这 N 个节点是同一运营者」的证据（链下识别 + 链上 attest）；hub 验证后触发 trait 扣减 + slash | 社区监督 |

**已知限制**：上述任意单一层都可被绕过。组合使用让攻击成本超过收益。**100% Sybil 不可能**，但 PGL 设计目标是让 Sybil 不经济。

**长期演进**：当 Mycelium 接入更广义的链下身份证明（如 proof-of-humanity / KYC-light），可作为可选「高信任」节点层叠加。但默认层永远保持**无许可加入**（不强制 KYC）。

---

## 5. 激励形态：现金腿 + 声誉腿

### 5.1 现金腿：运营服务费

**性质**：普通商业对价（不是「按签名次数线性发币」，不是分红）

每次**成功完成**门限共签的 DVT 节点，从该笔操作的服务费池中分得固定费率：

```
DVT 节点服务费 = 操作触发的 service fee × DVT 节点分配比例 / 参与共签的节点数
```

- 由 SP v5 `ROLE_DVT` 角色的链上结算合约自动支付（接口待 #283 定型，见 §8）
- 节点收到后是**普通经营所得**，可正常申报 + 开票
- 法律定性：**软件运维服务对价** —— 不是证券、不是分红、不是空投

**关键约束**：服务费**按「成功共签数」计**，不按「签名总数」计；签错 / 被 slash / Canary 失败的次数不入服务费池。

### 5.2 声誉腿：SBT trait 解锁的非货币权益

| Trait 持有 | 解锁的权益 |
|:---|:---|
| 任一核心 trait | 在 AgentStore 个人主页显示「守护者徽章」 |
| `NoBlindSign + OnDuty` | 申请 AgentStore curator 角色的资格 |
| `LongStanding` | Mycelium DAO 治理提案的引用权重 |
| `Diversity` ≥ N | 优先列入 SP v5 BLS 聚合器的「推荐共签集合」 |
| 所有核心 trait 满 | 在 CityRep 体系内被城市层引用为「数字基建守护者」 |

### 5.3 正反馈闭环

```
好好做事
  ↓
SBT trait 累积
  ↓
生态权限 + 商业可信度 + Mycelium 治理影响力
  ↓
更多协作机会 + 更多 DVT 共签需求
  ↓
持续做事的现金回报（服务费）
  ↓
（回到「好好做事」）
```

### 5.4 节点收入反推、敏感性分析、月收入 $100 三情景表

详见独立的 [`DVT_ECONOMICS.md`](./DVT_ECONOMICS.md)：
- 收入相关因素 + 不相关因素清单
- 月收入 $100 反推所需业务量（早期 opt-in / opt-out 默认开 / mandatory 普及 三阶段）
- hub 6-14 「DVT 默认开（opt-out）」决议对经济模型的拐点影响
- 早期参与的隐性时间价值（trait 复利）
- 风险敞口与下行情景

---

## 6. Canary / Honeypot 机制（正确执行的可验证证据）

### 6.1 为什么需要 Canary

「节点是否按独立策略执行」**正向证明很难**（操作真发生了，签了，怎么证明它是按策略该签还是盲签？）

**负向证明可行**：Hub orchestrator 定期注入「按所有合理策略都应拒绝」的诱饵请求；签了诱饵 = 盲签 = 触发 slash + 清零 `NoBlindSign` trait。

### 6.2 Canary 协议（待 hub #42 详细定义）

```
Hub orchestrator 流程：
  1. 生成 Canary 请求（含特征：金额异常 / 接收方黑名单 / 时间窗口异常 / 签名顺序异常）
  2. 注入到 DVT 节点（与正常请求混合，节点不可区分）
  3. 节点应当按其声明的策略**拒绝签名**
  4. 节点签了 → Canary 命中 → Hub 链上提交证据 → slash + trait 清零
  5. 节点拒绝 → 计入 NoBlindSign 累积
```

#### 6.2.1 Canary attestation 的信任根（trust root）

> **clestons review 2026-06-15 提出**：`reportBlindSign` 是 permissionless（任何人可提交 BLS 证据证明节点签了某请求），但**「这是 Canary」本身**还是需要一方 attest。这看起来与 §7.2「中心化裁判」反模式有冲突，需要明确划界。

**信任结构（明文锁死）**：

| 环节 | 信任假设 | 与 §7.2 中心化裁判的区别 |
|:---|:---|:---|
| Canary 的**生成**（"这是一个诱饵"）| 由 hub orchestrator multisig（≥ 2-of-3，与 AirAccount RecoveryService 同源 guardian 模型）attest | hub 多签可被 DAO 罢免；attestation 是**公开可重放的**（任何人能验证 hub 当初注册的诱饵 hash）|
| 节点**签了 Canary** 这个事实 | 任何人提交 BLS 证据 → 链上自动验签 → 无信任 | 同 §3.2 核心，permissionless |
| trait 的**颁发 / slash** 触发 | 自动派生自上两条，零人工 | 真正的「裁判」其实是链上 verifier，hub 只提供 dossier |

**为什么不算 §7.2 反模式**：§7.2 反对的是「中心化主体决定谁拿奖（积极判定）」；Canary attestation 是**对 attack surface 的预先声明**（消极判定）：

- §7.2 中心化裁判：**节点行为发生后**才决定是否给奖（黑箱裁量）
- Canary attestation：**节点行为发生前**已经公开承诺「这条不该签」（白箱可审计）

**减弱 hub 信任的演进路径**：

- v1.0（当前）：hub multisig attest Canary，hub 自身可被 DAO 罢免
- v1.x：引入 Canary attestation **轮值**机制 + 多 hub 联合 attest
- v2.0（长期）：节点策略表达可被 zkVM 编译 → 链上 prove 「按照声明策略，这条请求 100% 应该被拒」 → 完全去 hub 中心化

详细 Canary 协议规范单独拆讨论文档，见 §15 #1 `DVT_CANARY_PROTOCOL.md`（待立项）。

### 6.3 Canary 频率

- **基线频率**：每节点每天 ≥ 5 次（建议）
- **抽样比例**：Canary / 全部请求 ≈ 1 / 200 ～ 1 / 1000（可由 DAO 调整）
- **Canary 模板**：定期由 hub + 社区共建（开放命题，避免节点针对性规避）

### 6.4 防 Canary 被反向识别

- Canary 的**特征签名**必须与真实可疑请求**高度相似**（金额 / 接收方 / 时间窗口都在真实异常分布内）
- 节点针对性识别 Canary = 同等程度识别真实异常 → 拒绝 Canary 与拒绝真实异常**不可区分**
- 这意味着「能识别 Canary」≈「能拒绝真实异常」 ≈ 我们要的安全增益

### 6.5 多样性 Canary

针对 `Diversity` trait，Hub 注入「需要不同策略才能识别」的复合 Canary：
- 节点 A 的策略应拒绝，节点 B 的策略应通过
- 同质化节点全签或全拒 → 没有多样性 → trait 不颁发
- 多样化节点出现策略分歧 → 系统检测到分歧 → 多样性证据成立

---

## 7. 反例库（什么是 PGL-DVT **不允许**做的）

### 7.1 绑签名次数发奖

**为什么不行**：节点为攒积分盲签 → 独立策略失效 → DVT 退化为橡皮图章 → **安全增益归零**。

> ⚠️ 这是历史上 DVT 设计**最致命**的反模式。任何「签 1 次得 X 代币 / X 积分」的设计直接拒绝。

### 7.2 中心化裁判决定谁拿奖

**为什么不行**：裁判者本身成为新的单点（owner key 之外的另一把 master key），攻破裁判 = 攻破 DVT 安全模型。

**正确做法**：trait 全部**链上自动颁发**，触发条件机器可判，零人工决策。

### 7.3 SBT 可转让

**为什么不行**：二级市场 → 投机者持有 → 持有动机偏离守护 → 「我是守护者」的链上声明退化为「我买了一个徽章」 → 信用归零。

**正确做法**：完全 Soulbound（不可 transfer / approve）。

### 7.4 服务费按 stake 大小线性递增

**为什么不行**：DVT 是**工种**（运维 + 策略 + 在岗），不是**收益挖矿**（资本规模）。绑 stake 大小 = 鼓励大户挤压小节点 → 节点集中化 → 独立性退化。

**正确做法**：服务费按「成功共签数」均分；stake 只用于 slash 风险敞口 + 准入门槛，不分多得多。

### 7.5 服务费按「签名成功率」线性递增

**为什么不行**：成功率 = 签名次数 / 总请求次数。「提高成功率」= 「尽量都签」= 「盲签」。绕回 §7.1 同一陷阱。

**正确做法**：服务费**只看「成功共签的绝对次数」**（节点没共签的请求不计），不看比率。

### 7.6 把 Canary 设计公开 / 可预测

**为什么不行**：节点能 100% 识别 Canary → 拒 Canary、签真实异常 → Canary 失去验证价值。

**正确做法**：Canary 生成算法保持**部分混淆**（由 hub + 社区轮换共建），关键特征参数定期改版。

---

## 8. SP v5 `ROLE_DVT` + `IPolicyRegistry` 对接表

> **依据冻结结论**（YetAnotherAA-Validator#42 issuecomment-4702143353 + `docs/design/dvt-node-protocol.md` + `dvt-policy-governance.md`）。
> 由于 SP 侧 `IPolicyRegistry` 具体 Solidity 签名仍在 #283 落地中，本节按**已冻结的概念模型**对接；具体方法名以 SP 最终发布的 interface 为准。

### 8.1 角色注册（复用现状，零变更）

```
DVT 节点上线：
  1. Registry.registerRole(ROLE_DVT) + 质押 30 ether GToken
  2. BLSAggregator.registerBLSPublicKey(...)   // H-02 自服务路径
  3. PolicyRegistry.registerNodePolicy(policyHash, version, sourceUri)  // 上链承诺策略
  4. 启动节点软件
```

### 8.2 策略哈希注册（命门一·独立性）

| 本文档要求 | 冻结结论对应 | 备注 |
|:---|:---|:---|
| 节点上链注册策略哈希 + 版本 | `PolicyRegistry` per-sender / staked / governance-gated | 节点策略源 == slash 引用源（冻结结论 #6）|
| 多样性 trait 颁发依据 | PolicyRegistry 可枚举所有已注册策略 | 链上可对比 hash 分布 |
| 放松类策略变更 2 天时间锁；收紧/冻结即时 | 直接复用冻结结论 #6 | 时间锁内可被社区 review |

### 8.3 Canary slash 触发器（命门二）

| Canary 结果 | 链上动作 | 触发的 trait 变化 |
|:---|:---|:---|
| 节点签了 Canary（盲签） | `executeSlashWithBLS` 调用，按冻结结论的 `signerMask` + `sigG2` 提交证据 | `NoBlindSign` 立即清零；`OnDuty` 失效；如累计 → 节点被 burn SBT + 触发 stake slash |
| 节点拒绝 Canary | `IDVTIncentive.recordCanaryPass(nodeAddr)` 累计 | `NoBlindSign` +1（向 100 累积）|
| 节点 N 次连续失联 Canary | `IDVTIncentive.recordOffline(nodeAddr)` | `OnDuty` 扣减；连续 ≥ 阈值 → trait 失效 |

> Canary 证据格式按冻结结论：`expectedMessageHash = userOpHash`（C1）+ `proof = (signerMask, sigG2)`（无 `pkG1` / `msgG2` / `messagePoint`），verifier 链上重算 `msgG2 = hash_to_curve(userOpHash, DST=BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_)`。

### 8.4 服务费结算（现金腿）

| 流程 | 调用 |
|:---|:---|
| 用户操作触发 DVT 共签 | SP `validatePaymasterUserOp` 检查 `IPolicyRegistry.shouldTriggerDVT(sender, op)` → 是 → 路由到 DVT |
| 节点成功共签 | SP `postOp` 结算服务费 → `IDVTIncentive.distributeServiceFee(workHash, signerMask, amount)` |
| 节点收到 | 普通经营所得，链上记录用于声誉腿统计 |

**关键约束**（命门二）：服务费**按 `signerMask` 中的位数均分**，不按节点的「签了多少次累计」线性加权 → 任何节点单次共签的收益相同 → 没有「攒次数」的激励错配。

### 8.5 状态 sender-keyed（冻结结论 #5）

`todaySpent` 等累计状态必须 sender-keyed，本文档对应：
- `NoBlindSign` 累积按 **(node, sender)** 计 → 防止节点对某 sender 始终签盲、对另一 sender 假装认真
- 多样性 trait 评分按 **跨 sender 行为差异**计算

### 8.6 与 RecoveryService / 时间锁的对齐

- Guardian 复用 AirAccount 2-of-3 RecoveryService（冻结结论 #6）→ DVT 节点可申请 guardian 角色
- 节点策略变更受时间锁约束 → `IDVTIncentive` 的 trait 颁发函数遵守相同时间锁

---

## 9. `IDVTIncentive.sol` Interface 草稿

```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

/// @title IDVTIncentive — PGL 体系内 DVT 节点的激励合约接口
/// @notice 对齐 YetAnotherAA-Validator#42 冻结结论 + SP v5 ROLE_DVT + IPolicyRegistry
/// @dev SBT 完全不可转让；零人工裁决；触发条件全部机器可判
interface IDVTIncentive {

    // ============ Trait 类型 ============
    enum Trait {
        NoBlindSign,        // 连续 100 次 Canary 全通过
        OnDuty,             // stake 在线 ≥ 60d + 响应率 ≥ 95% + 无 slash
        Diversity,          // 策略哈希 / 运营者 / 软件栈 与中位数节点显著差异
        PolicyPublisher,    // 上链注册策略哈希 + 可审计参照
        LongStanding        // NoBlindSign + OnDuty 同持 ≥ 6 个月
    }

    // ============ Trait 状态查询 ============
    /// @notice 查询某节点的 trait 累计计数（NoBlindSign 等线性 trait）
    function traitCount(address node, Trait t) external view returns (uint256);

    /// @notice 查询某节点的 trait 是否当前有效（OnDuty 等门限 trait）
    function traitActive(address node, Trait t) external view returns (bool);

    // ============ Canary 机制（命门二）============
    /// @notice Hub orchestrator 提交：节点正确拒绝了 Canary
    /// @dev 由 hub 多签 / DAO 验证后调用；累加 NoBlindSign
    function recordCanaryPass(address node) external;

    /// @notice 节点签了 Canary（盲签证据）
    /// @dev 提交 BLS 聚合证据，链上 verifier 重算 msgG2 = hash_to_curve(userOpHash, DST)
    ///      验证通过即触发 slash + trait 清零
    function reportBlindSign(
        address node,
        bytes32 userOpHash,         // 冻结结论 #1: preimage = userOpHash
        uint256 signerMask,         // 冻结结论 #3
        bytes calldata sigG2        // 冻结结论 #3: 无 pkG1/msgG2/messagePoint
    ) external;

    /// @notice 节点连续失联（无法响应 Canary）
    function recordOffline(address node, uint256 consecutiveMisses) external;

    // ============ 服务费结算（现金腿）============
    /// @notice SP postOp 调用，按 signerMask 中的位数均分服务费
    /// @dev signerMask 位序 = ROLE_DVT 注册 slot（冻结结论 #3）
    ///      bit i → validatorAtSlot[i+1]
    function distributeServiceFee(
        bytes32 workHash,
        uint256 signerMask,
        uint256 amount
    ) external;

    // ============ 策略哈希注册（命门一·独立性）============
    /// @notice 节点上链注册自己的策略哈希 + 版本 + 可审计参照
    /// @dev 复用 PolicyRegistry（冻结结论 #6: per-sender / staked / governance-gated）
    function registerNodePolicy(
        bytes32 policyHash,
        uint16 version,
        string calldata sourceUri    // IPFS / Arweave / git commit URL
    ) external;

    // ============ Trait 颁发 / 失效 事件 ============
    event TraitIncreased(address indexed node, Trait indexed t, uint256 newCount);
    event TraitInvalidated(address indexed node, Trait indexed t, bytes32 reason);
    event ServiceFeeDistributed(bytes32 indexed workHash, uint256 signerMask, uint256 totalAmount);
    event NodePolicyRegistered(address indexed node, bytes32 policyHash, uint16 version);
    event BlindSignReported(address indexed node, bytes32 userOpHash);
}
```

**实现注意**：
- `recordCanaryPass` 入口必须由 hub orchestrator（多签 / DAO 角色）调用 —— 链上验证调用方权限，**避免任何节点自己 mint trait**
- `reportBlindSign` 是**任何人可调**的 permissionless slash 提交（带 BLS 证据），鼓励第三方监督
- SBT 实现层禁止 `transfer` / `approve`（Soulbound）；trait 失效时只允许合约自身 `burnTrait`

---

## 10. 与其他 PGL 文档的边界澄清

### 10.1 不修改的文档（保持简洁）

- ❌ **不改 CHARTER.md 主体五条**：Charter 针对端用户作品的承诺，DVT 是基建角色，不涵盖
- ❌ **不改 MANIFEST_SPEC.md**：DVT 节点不是 Store 商品，不写 `pgl.yml`
- ❌ **不改 REVENUE_MODEL.md 主体**：DVT 服务费走独立通道，不进 70/20/10 分账

### 10.2 需要的最小变更

- ✏️ **REVENUE_MODEL.md** 末尾加 1 段指针：「DVT 节点的服务费 + SBT trait 激励见 `DVT_INCENTIVE.md`，不进本文档的 70/20/10 分账」
- ✏️ **CITY_REP.md** 可选加 1 段：「持有 PGL-DVT 完整 SBT trait 集合的节点运营者，可被城市层引用为『数字基建守护者』」
- ✏️ **README.md** 在 PGL 文件列表中加 1 行：「`DVT_INCENTIVE.md` — DVT 节点激励规范（PGL 附录）」

---

## 11. 版本历史

| 版本 | 日期 | 状态 |
|:---|:---|:---|
| v0.1 草稿（70%） | 2026-06-14 | §1-§7 + §10 完成；§8-§9 占位 |
| v0.2 草稿（95%） | 2026-06-15 | §8 + §9 基于 hub #42 冻结结论填充 |
| v1.0 草稿（100%） | 2026-06-15 | hub owner 拍板 (A) PGL 附录 + aNode 总称 + §13 + §14 + §15 |
| **v1.1**（PR #4 follow-up） | **2026-06-15** | **响应 clestons review 2 个 design-open 项**：§6.2.1 Canary attestation 信任根 / §7.2 划界 / 演进路径；§4.4 Diversity Sybil 多层防御 |

---

## 12. Charter 范围决策 — ✅ (A) 锁定

hub #42 issuecomment-4702143353 第 6 项冻结结论原文：

> 「激励落 PGL Charter，与 SuperPaymaster ROLE_DVT 的 slash 路径对齐。」

**hub owner 2026-06-15 拍板 = (A) PGL 附录**。

| 决策 | 含义 |
|:---|:---|
| **(A) PGL 框架内附录** ✅ 锁定 | 本文档作为 `protocol/PGL/DVT_INCENTIVE.md` 独立存在；CHARTER.md 主体五条**不动**；REVENUE/CITY_REP/README 加指针 |

→ 本文档 §1.2 + §10 的「不动 Charter 主体」实现保持有效，无额外修改。

「激励落 PGL Charter」的准确含义 = 「激励**落在 PGL 体系（Charter 法律红线 + 复用 SBT 不可转让 + 不发币）之内**」，而非「写进 Charter 五条主体」。

---

## 13. 基础设施总称 — aNode（forward compatibility）

### 13.1 hub owner 2026-06-15 决策

DVT 与 x402 facilitator 等**所有基础设施角色**统称为 **aNode**。当前为避免改动过大，本文档继续用「DVT」命名；**未来基础设施角色统一在 aNode 命名空间下**。

### 13.2 影响本文档的命名映射

| 当前命名（v1.0）| 未来 aNode 命名（向前兼容）|
|:---|:---|
| `ROLE_DVT` / `ROLE_DVT_NODE` | `ROLE_ANODE_DVT` 或 `ROLE_ANODE.DVT` |
| `IDVTIncentive` | `IANodeIncentive` 或 `aNode.DVTIncentive` 模块 |
| `DVT_INCENTIVE.md` | 未来可能成为 `ANODE_DVT_INCENTIVE.md` 或纳入 `protocol/aNode/` 子目录 |
| `DVT_ECONOMICS.md` | 同上 |

### 13.3 设计含义

aNode 总称意味着：
- DVT、x402 facilitator、**未来其他基础设施**（如 reputation oracle、data availability node、indexer 等）**共享同一套 PGL 激励范式**：trait + 服务费 + 命门约束
- 本文档 §3 两条命门（独立性 + 不绑次数）**自然延展到所有 aNode 角色**
- 节点运营者可同时持有多个 aNode 角色（如同一运营者同时跑 DVT + facilitator），trait 跨角色独立累积

### 13.4 关联仓库

- 线上：[`AAStarCommunity/aNode`](https://github.com/AAStarCommunity/aNode)（permissionless paymaster + gas token，当前活跃）
- 本文档**不直接修改**该仓库，只声明「未来基础设施 PGL 激励规范集中到 aNode 命名空间下」

---

## 14. 技术依赖核对清单（Tech Dependencies Check）

本节列出**实施 v1.0 设计**所依赖的所有外部技术，区分**已核对** vs **待核对** vs **外部决策**。

### 14.1 已核对（基于 SP v5 source 直接确认）

| # | 依赖项 | 实装位置 | 核对结论 |
|:---:|:---|:---|:---:|
| 1 | `ROLE_DVT` 初始化（stake / ticket / cooldown）| `SuperPaymaster/contracts/src/core/Registry.sol:85` | ✅ 30 ether stake, 3 ether ticket, 10 max keys, 30 days exit |
| 2 | `BLSAggregator.registerBLSPublicKey` 自服务路径（H-02）| `SuperPaymaster/contracts/src/modules/monitoring/BLSAggregator.sol:232` | ✅ stake 跌破 minStake 自动失效逻辑已写 |
| 3 | hub 冻结的签名格式 DST=POP | hub #42 [comment-4702127834](https://github.com/AAStarCommunity/YetAnotherAA-Validator/issues/42#issuecomment-4702127834) | ✅ `BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_` |
| 4 | proof tuple `(signerMask, sigG2)` 位序 = ROLE_DVT 注册 slot | hub #42 [comment-4702127834](https://github.com/AAStarCommunity/YetAnotherAA-Validator/issues/42#issuecomment-4702127834) | ✅ |

### 14.2 待核对（v1.0 → v1.1 实施前必须确认）

| # | 依赖项 | 为什么需要 | 核对方法 |
|:---:|:---|:---|:---|
| 1 | `@noble/curves` v2.0.1 DST=POP 支持 | §8.3 Canary 证据 BLS verifier 链下生成 | 在 SDK #63 范围内验证；查 SDK lock 文件 |
| 2 | EIP-2537 BLS precompile 在 Sepolia / OP mainnet 的支持状态 | §8.3 链上重算 msgG2 + pkAgg 重建依赖 G1ADD precompile | 查 OP-stack 升级日志 + 测试 fork 实际 gas 成本 |
| 3 | `IPolicyRegistry` 具体 Solidity 签名 | §8.2 + §9 所有「per-sender / staked / governance-gated」调用都依赖此 interface | 等 SP #283 发布；目前用占位假设 |
| 4 | `AAStarGlobalGuard.TokenConfig`（v0.18 已实装）实际字段形状 | §8.5 sender-keyed 状态机依赖每账户每资产 tier 阈值 | 读 airaccount-contract v0.18 源码 + hub #110 确认 |
| 5 | `AirAccount RecoveryService` 2-of-3 接口 | §8.6 guardian 复用依赖 | 读 AirAccount KMS proto 源 + hub #70 确认 |
| 6 | `PaymasterV4 oracle`（USD aggregator）| 全局 USD 兜底阈值需要喂价 | 读 PaymasterV4 源；确认 oracle 健康度 + heartbeat |
| 7 | Mycelium SBT 系统现状 | 5 个 trait 实际颁发依赖 SBT 合约 | 找 mycelium 生态的 SBT 实装；如无，本文档要明文「待 SBT 合约 v1 落地」|
| 8 | AgentStore curator 角色实装 | §5.2 trait 解锁 curator 权益需要 AgentStore 端有对应入口 | AgentStore 还未上线 → 标「v1.1 待 AgentStore MVP 后兑现」|
| 9 | CityRep 实装状态 | §5.2 「数字基建守护者」引用依赖 CityRep 落地 | CityRep 现在是 RFC，标「v1.1 待 CityRep 上线后兑现」|

### 14.3 外部决策（DAO / hub owner 拍板，非技术核对）

| # | 决策项 | 当前默认 / 占位 | 谁决定 |
|:---:|:---|:---|:---|
| 1 | DVT 服务费率 F（单 op 费用）| 占位 $0.50-$2 区间 | Mycelium DAO |
| 2 | Canary 抽样比例 | 占位 1/200 ～ 1/1000 | hub owner + DAO |
| 3 | NoBlindSign 累积阈值（默认 100）| 100 次 Canary 通过 | hub owner + DAO |
| 4 | OnDuty 阈值（响应率 ≥ 95%, stake ≥ 60d）| 默认 95% / 60d | hub owner + DAO |
| 5 | LongStanding 阈值（≥ 6 个月）| 默认 6 个月 | hub owner + DAO |
| 6 | opt-out 默认开 flip 时点 | 「DVT 网络成熟后」（定性，待量化）| hub owner |
| 7 | slash 绝对金额（盲签 / 失联 / 策略不符 各档）| 占位 | DAO（实施前必须定）|

---

## 15. 待拆分讨论的子主题（hub line-comment 时 pin 这里）

以下子主题**可能需要拆出独立讨论 / 独立子文档**。hub owner 可在 line-comment 时标记哪些要拆：

| # | 子主题 | 现在位置 | 是否拆 |
|:---:|:---|:---|:---|
| 1 | Canary 协议细化（hub orchestrator 接口 + 反 Canary 识别 + 多样性 Canary）| §6 | 建议拆 `DVT_CANARY_PROTOCOL.md` |
| 2 | `IPolicyRegistry` 接口最终定型 | §8.2 + §9 占位 | 不拆（等 SP #283）|
| 3 | Slash 绝对金额 + cooldown 表 | §14.3 #7 占位 | 建议拆 `DVT_SLASH_TABLE.md`（DAO 提案模板）|
| 4 | Mycelium SBT 合约选型 | §14.2 #7 待核对 | 建议拆 `MYCELIUM_SBT_CHOICE.md`（生态选型决策）|
| 5 | DVT 服务费率 F 定价模型 | §14.3 #1 | 留在 `DVT_ECONOMICS.md` |
| 6 | opt-out 默认开 flip 触发条件量化 | §14.3 #6 | 留在 `DVT_ECONOMICS.md` |
| 7 | DVT 与 x402 facilitator 共享 aNode 体系的具体方式 | §13 概念 | **新增**：v1.1 时考虑 `ANODE_ARCHITECTURE.md` |
| 8 | 服务费上下游资金流细节（用户 → SP → 节点 钱包）| §8.4 + §4.1 | 留在本文档（不必拆）|
| 9 | Canary slash 与 Mycelium DAO 治理流程的衔接 | §3.2 + §6 | 留在本文档 |
| 10 | trait 持有者商业可信度的对外证明方式（API / 签名）| §5.2 | 建议拆 `DVT_REPUTATION_API.md`|
