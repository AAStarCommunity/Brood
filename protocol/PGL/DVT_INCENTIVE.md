# PGL DVT 激励规范（附录）/ DVT Incentive Spec (PGL Appendix)

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

## 8. SP v5 `ROLE_DVT` 对接表

> ⏸️ **待 SP #283 ROLE_DVT slash 触发器接口定型后补充。**
>
> 预期内容：
> - `registerRole(ROLE_DVT)` 调用规范
> - `BLSAggregator.registerBLSPublicKey` 与本文档 §3 策略哈希注册的接口对齐
> - slash 触发条件链上映射：Canary 失败 / 策略哈希不符 / 长期失联
> - 服务费结算合约调用接口
> - trait 颁发合约与 SP v5 SBT 系统的对接

---

## 9. `IDVTIncentive.sol` Interface 草稿

> ⏸️ **待 §8 完成后基于实际对接表生成。**
>
> 预期内容：
> - `interface IDVTIncentive` 完整方法签名
> - trait 颁发 / 扣减 / 查询接口
> - Canary 提交 / 验证 / slash 触发接口
> - 服务费结算接口

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
| v0.1 草稿（70%） | 2026-06-14 | §1-§7 + §10 完成；§8-§9 待 SP #283 接口定型后补 |
| v0.2（目标） | TBD | §8 + §9 补全 → 进入 hub #42 命门复核 |
| v1.0（目标） | TBD | 经 hub #42 + SP #283 双向 review 通过 → 合入 main 分支 |
