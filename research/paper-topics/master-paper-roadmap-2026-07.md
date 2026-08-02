# Mycelium/AAStar 论文总作战图 + 博士论文框架（2026-07-21）

> 覆盖 6 篇核心论文（thesis 承载簇）：已投 1 篇（AOA）+ 收尾重投 1 篇（RepCredit）+ 新启动 4 篇（Onion / Weighted / DVT / AgentPay）。CometENS 等另计，不进本 thesis 主线。
> 作者：Huifeng Jiao（清迈大学 ICDI 博士生）· 导师：Dr. Nathapon Udomlertsakul · 方法论：DSR 贯穿
> 视角：博导 + 密码学 + 系统安全 + 期刊审稿人 · 目标窗口 2026 Q3–2027 Q1
> 配套：`paper-topics-proposal-2026-07.md`、`paper-title-keywords-abstract-2026-07.md`、各 paper 目录 `*_chapter_plan.md`、`dvt-paper-vs-paper7-merge-analysis-2026-07.md`
> 同步存放：Brood `research/paper-topics/` + DSR-Research-Flow `writing/`

---

## 0. 命名与编号（唯一权威，先钉死）★

**决定一：共 6 篇**（不是 7）。连贯的博士论文簇就这 6 篇；CometENS/EIP-7702/ChiangMai 等不进 thesis 主线（可 future work 或独立发表）。

**决定二：弃用数字 "P" 标签，唯一锚 = 短名 + thesis 章号。** 之前 "paper3=SuperPaymaster"（DSR 目录号）与 "P3=DVT"（我的旧提案号）撞车，现全部作废，一律以下表短名/章号引用，不再出现裸 "Paper 3"。

| 短名（引用用这个） | thesis 章 | 一句话 | 制品 | DSR 目录 | 旧提案号(废) | 状态 |
|---|---|---|---|---|---|---|
| **Onion** | Ch3 | 值→密码学因子升级 + 新攻击类 | airaccount-contract | paper4-AirAccount-D2D-MultiSig | (旧 P1) | 就绪 |
| **Weighted** | Ch4 | 加权多因子 + 防弱化治理 + 抗盗钥恢复 | airaccount-contract | paper5-SocialRecovery | (旧 P2) | 就绪 |
| **DVT** | Ch5 | DVT 语义迁移为账户层第二因子 + 全链上 BLS 验证 | YetAnotherAA + aNode | （待建目录） | (旧 P3) | 待写 |
| **AOA** | Ch6 | 资产导向抽象，消除中心化赞助 signer | SuperPaymaster | paper3-SuperPaymaster-DSR-Rewrite | (即"你的 paper3") | **已投 BRA** |
| **RepCredit** | Ch7 | 贡献→有界 gas 信用，抗合谋上限 + DVT 验证 | SuperPaymaster + aNode | paper7-CommunityFi | (旧 P7) | v16 重投 |
| **AgentPay** | Ch8 | 声誉赞助 + TEE 委托链 + 统一结算 | SuperPaymaster + KMS | paper8-SuperPaymasterV2 | (旧 P4) | 就绪 |

**决定三：章号按层自底向上单调**——安全栈（Ch3-5）在下、支付栈（Ch6-8）在上，章号随依赖递增，读者从"账户怎么安全"走到"账户怎么付钱"。

---

## 1. Portfolio at a glance（按 thesis 章号排序）

| 章 | 短名 | 一句话贡献 | 状态 | 目标期刊 | 投稿窗口 | 承重? |
|---|---|---|---|---|---|---|
| Ch3 | Onion | 金额分级密码学因子升级 + 新攻击类 | 就绪 | ACM DLT | Q3 | ★核心 |
| Ch4 | Weighted | 加权多因子 + 防弱化治理 + 抗盗钥恢复 | 就绪 | IET / JBBA | Q4 | 支撑 |
| Ch5 | DVT | DVT 语义迁移为账户层第二因子 + 全链上 BLS 验证 | 待写 | FC'27 / ACM DLT | Q4 | ★核心 |
| Ch6 | AOA | Gas Card SBT + 确定性链上资格，消除中心化赞助 signer | **已投 BRA** | BRA | 在审 | ★核心 |
| Ch7 | RepCredit | 贡献→有界 gas 信用，抗合谋上限 + DVT 验证 | **v16 重投** | IET Blockchain | Q3 | ★核心 |
| Ch8 | AgentPay | 声誉赞助 + TEE 委托链 + 统一结算 | 就绪 | Financial Innovation | Q4–Q1 | 支撑 |

---

## 2. 博士论文框架（PhD Thesis Framework）★本轮重点

### 2.1 论文题目（推荐 + 备选）

**★ 推荐：**
> **Accountable Account Abstraction: A Design-Science Architecture for Value-Proportional Security and Sponsor-Backed Payments on ERC-4337**

**备选（更突出"普通人自托管"的人本线）：**
> Making Self-Custody Safe and Payable: A Design-Science Account of Secure, Sponsor-Backed, and Agent-Ready Account Abstraction

### 2.2 中心论点（Thesis Statement）

普通人用 Web3 撞上两堵墙：**(a) 自托管安全是"值不变"且脆弱的**（一把钥匙管全部身家、被盗即清零）；**(b) 没有 ETH 就无法交易，而 AI agent 更无法"可问责"地交易**。本论文主张：把 ERC-4337 账户抽象当作 DSR 制品重新架构，可以造出一个**值成比例安全、无需自备 gas、且 agent-ready 的账户栈**——每篇已发表论文是其中一层。

### 2.3 两层栈 ⇄ 六个实证章（章号自底向上单调）

```
┌──────────────────────────────────────────────────────────────┐
│ 支付栈 Payment Stack (make transacting possible & accountable)│
│   Ch6 AOA       ──地基：赞助授权去中心化 (谁有权出 gas)        │
│   Ch7 RepCredit ──扩展：声誉→有界信用 (凭什么给、给多少、抗合谋)│
│   Ch8 AgentPay  ──扩展：agent 委托链 + 统一结算 (机器可问责付费)│
├──────────────────────────────────────────────────────────────┤
│ 安全栈 Security Stack (make self-custody safe)                │
│   Ch3 Onion    ──策略：值→密码学因子升级 + 抗绕过 + 新攻击类   │
│   Ch4 Weighted ──治理：加权多因子 + 防弱化 + 抗盗钥恢复        │
│   Ch5 DVT      ──密码学底座：账户层第二因子 + 全链上 BLS 验证   │
└──────────────────────────────────────────────────────────────┘
        ↑ 章号从下往上递增：先讲账户怎么安全(3-5)，再讲怎么付钱(6-8)
```

安全栈内部叙事：Onion 定义"值→tier 策略"(Ch3) → Weighted 让它可配置且配置本身可治理(Ch4) → DVT 给出实现 T2/T3 强因子的分布式验证密码学(Ch5，安全栈的收口)。支付栈内部：AOA 是地基(Ch6)，RepCredit 与 AgentPay 在其上分别加"凭声誉发信用"和"human→agent 委托"——三者共享同一 SuperPaymaster 合约家族，贡献不相交（见 §4）。

### 2.4 完整章节骨架

**Part I — 问题与方法**
- **Ch1 Introduction**：两堵墙（值不变安全 / 无 ETH 不可交易 + agent 不可问责）→ 论点 → 两层栈预览 → 各章贡献地图（Ch1 用"用户故事"开场，先抓痛点再展开）。
- **Ch2 Background & DSR Methodology**：ERC-4337/7702、Peffers 六阶段 + Hevner 三循环 + FEDS；制品家族总览；测试网部署纪律与复现锚点（commit pinning）。

**Part II — 安全栈（Ch3–5）**
- **Ch3 Onion**：值→tier 密码学因子升级；三条抗绕过（拆单/配置篡改/相位脱钩）；validation-execution 脱钩新攻击类。
- **Ch4 Weighted**：加权多因子代数 + 防弱化配置治理（强化即时、弱化需 guardian+timelock）+ 抗盗钥恢复（cancel 亦需 quorum）。
- **Ch5 DVT**：把共识层盲执行的 DVT 迁移为账户层"该不该签"的第二因子；全链上 RFC 9380 hash-to-curve + EIP-2537 验证模块 + 动态 gas 模型。安全栈收口章——它让 Ch3/Ch4 里的 T2/T3 强因子"真实存在"。

**Part III — 支付栈（Ch6–8）**
- **Ch6 AOA**（已投 BRA）：Gas Card SBT + 确定性链上资格取代链下 signer；OP 主网实测（L2 执行 gas ↓~18.5%、总计费 gas ↓>25%）+ 抗审查 failover。**支付栈地基章**。
- **Ch7 RepCredit**（v16）：贡献→有界 gas 信用；抗合谋信用上限 C_max < ⌈2N/3⌉ρS_op；DVT 验证声誉更新。
- **Ch8 AgentPay**：声誉门控赞助 + TEE 委托链（human→agent，无单因子不变量）+ gasless/x402/微支付统一结算。

**Part IV — 综合**
- **Ch9 Discussion**：全栈作为一个连贯架构；六条可迁移设计原则（值成比例、配置单调、相位绑定、授权去中心化、发行有界、委托硬件可证）；跨制品威胁模型与共同局限。
- **Ch10 Conclusion & Future Work**：主网、EIP-8141 原生 AA、PQC 签名、加权恢复、EIP-7702 迁移；thesis 级贡献陈述。

### 2.5 一个博导视角的诚实提醒：6 篇偏多，分清承重与支撑

典型 thesis-by-publication 的**承重章是 3–4 篇**。本框架 6 篇偏多，答辩时会被问"哪些是你的核心贡献"。故明确分层（见 §1 表"承重?"列）：
- **承重章（core，4 篇）**：Ch3 Onion（安全策略）、Ch5 DVT（密码学）、Ch6 AOA（支付地基）、Ch7 RepCredit（信用）。这四篇撑起"安全 + 支付"完整论点，各有独立实测，覆盖两层栈的两端。
- **支撑章（supporting，2 篇）**：Ch4 Weighted（可视作 Ch3 的深化）、Ch8 AgentPay（可视作 Ch7 的 agent 延伸）。若答辩体量需收缩，这两章可降为综述性小节或 future work——**即使它们投稿延迟，thesis 承重结构不塌**。

---

## 3. 贯穿主线（一句话对外）

> 从密钥到支付，我们把 ERC-4337 账户抽象重构成一个**可问责的安全与结算栈**——每篇论文是其中一层。

这条主线是每篇论文 Introduction 的"制品背景"段，也是 thesis Ch1 的骨架。

---

## 4. 反"切香肠"差异矩阵（每两篇如何不重叠）

| 论文对 | 表面重叠 | 切割断言 |
|---|---|---|
| AOA ↔ RepCredit | 都是 SuperPaymaster/gas 赞助 | AOA=赞助**授权**去中心化（谁有权签）；RepCredit=赞助**资格与定价**（凭贡献给谁、发多少、如何有界） |
| AOA ↔ AgentPay | 都是 SuperPaymaster | AOA=消除中心化 signer；AgentPay=**agent** 委托链 + 多模式结算，资格随行为定价 |
| RepCredit ↔ AgentPay | 都涉及声誉驱动赞助 | RepCredit=**社区贡献→信用额度**的信用原语与抗合谋界；AgentPay=**human→agent 委托**与 TEE 密钥链 |
| RepCredit ↔ DVT | 都用 DVT/BLS | RepCredit=DVT 验证**声誉→信用更新**（计分预言机）+ 信用上限经济界；DVT=DVT 作**交易授权第二因子**（该不该签）+ 链上 hash-to-curve 验证模块。不同流程节点、不同学科抽屉 |
| Onion ↔ Weighted | 都是 AirAccount 分层安全 | Onion=**值→tier 策略**与强制/抗绕过；Weighted=**权重代数 + 配置治理 + 恢复** |
| Onion ↔ DVT | tier 里都提 BLS | Onion 把 DVT-BLS 当 T2 因子（黑盒引用 DVT 章）；DVT 是该因子的密码学实现与语义论证 |

**关键纪律**：DVT 章的 BLS 贡献必须是"全链上 RFC 9380 hash-to-curve 验证模块 + 动态 gas 模型"，绝不 claim "EIP-2537 聚合省 gas"——那个 ~112k gas 数据 RepCredit 已发表，DVT 只能引用为基线（详见 merge 分析 §4）。

---

## 5. 期刊分布与错峰

| 期刊 | 承接 | 理由 | 错峰 |
|---|---|---|---|
| **BRA** | AOA（在审） | 已投，模板熟 | AOA 有结果前不再投 BRA |
| **IET Blockchain** | RepCredit（Q3）→ Weighted（Q4） | 免 APC、~74 天首审、接受 systems+simulation | RepCredit 先投；Weighted 到 Q4 时 RepCredit 已有决定 |
| **ACM DLT** | Onion（Q3） | 接受硬技术系统论文，与攻击类+策略契合 | 与 IET/BRA 解耦 |
| **FC'27 / AFT** | DVT（Q4） | 密码学工程 + 会议赛道，与期刊池零冲突 | 独立周期 |
| **Financial Innovation** | AgentPay（Q4–Q1） | agent 经济跨学科、免费快审 | 独占 |

> Onion 首选 ACM DLT 是为不和已在审的 AOA 挤 BRA；若 ACM DLT 拒，Onion 回落 BRA（届时 AOA 应已有结果）。

---

## 6. Paper 7 重定位与重投简报（v16）

### 6.1 病因（为什么标题被拒 / 读起来像社会实验）

v15 已改硬 scope/claim/contribution，但三处"社科皮"未除：
1. **标题** CommunityFi 打头像产品名/社区愿景。
2. **§1.1 标题** "The Friction of Decentralized Collaboration" + 开篇 "Social Network Assets / mission-driven communities"。
3. **核心原语** "Social Capital (R)" / "Individual Value (V)" 本身是社科术语。
4. **ABM** 虽降级但仍被 abstract 提及，易被当主证据。

真正的技术王冠——**抗合谋信用上限 C_max < ⌈2N/3⌉ρS_op**——被埋在 §5.2.7，没进标题、没进 abstract 头部。

### 6.2 新标题（推荐 + 备选）

**★ 推荐（A）：**
> **Bounded Reputation Credit for ERC-4337 Gas Sponsorship: A Collusion-Resistant, DVT-Verified Paymaster**

**备选 B：** Gas Without Collateral: A Bounded, Collusion-Resistant Reputation-Credit Paymaster for ERC-4337
**备选 C：** Contribution-Backed Gas Credit: Bounding Sponsorship Risk in ERC-4337 Paymasters via Decentralized Reputation Verification

### 6.3 v16 必改项

| # | 位置 | 改法 |
|---|---|---|
| 1 | 标题 | 换 6.2-A（或 B/C） |
| 2 | Abstract 首句 | 改系统问题开场：谁为 ERC-4337 上反复的低值执行付费、且不要求用户持 ETH/抵押品 |
| 3 | Abstract 中段 | C_max 抗合谋界提到与 DVT 验证并列的主结果位；ABM 一句话降级为 design-level evidence |
| 4 | §1.1 标题 | → **"Who Funds Recurring On-Chain Execution?"** |
| 5 | 原语命名 | "Social Capital (R)" → **reputation score R**；"Individual Value (V)" → **utility-point balance V** |
| 6 | 新增子节 | C_max 界提成 §5 独立子节，theorem 式陈述 + 推导 + 参数敏感性图（抗社科攻击锚点） |
| 7 | ABM | 收进单一子节，标题明确 "Mechanism-Level Simulation (design evidence, not field outcome)" |
| 8 | Related Work | 主线改为 paymaster 模型 → DVT/BLS 验证 → 欠额抵押信用原语（Aave/信用委托类比）；Web2 社会学降一段 |
| 9 | Discussion | inclusive finance/beyond-gas 保持 future work |

### 6.4 期刊：仍首选 IET Blockchain

病根从不是选错期刊，而是呈现太社科；v16 去社科化恰使它更贴 IET 工程系统口径。进阶备选 ACM DLT（周期长、和 Onion 挤）。不建议 Ledger（bar 更高需 crypto-econ rewrite）/ Financial Innovation（拉回金融叙事）。artifact 名 CommunityFi 可保留（仅正文一处），只要不进标题、不做全文框架。

### 6.5 v16 执行顺序（约 1 周，纯重构不加内容）

定标题 → 改 abstract 四句 → §1.1 改名 + 原语全局替换 → C_max theorem 化 → Related Work 换主线 → cover letter 同步（去 "zombie balances/sustainability paradox"）→ 按 pinned commit 重采 gas 表 → 重建 PDF。

---

## 7. 总时间线（Q3'26 → Q1'27）

| 月 | AOA(Ch6) | RepCredit(Ch7) | Onion(Ch3) | Weighted(Ch4) | DVT(Ch5) | AgentPay(Ch8) |
|---|---|---|---|---|---|---|
| 2026-07 | 在审 | v16 重投 IET | 文献+gas 重采 | — | — | — |
| 2026-08 | 在审 | （在审） | 成稿→预审→投 ACM DLT | 文献 | 启动 | — |
| 2026-09 | 返修? | （在审/返修） | （在审） | 实验 | 实验+FC'27 对齐 | — |
| 2026-10 | — | — | — | 成稿投 IET | 成稿投 FC'27 | 启动（等 OP 主网数据） |
| 2026-11 | — | — | — | （在审） | （在审） | 实验 |
| 2026-12 | — | — | — | — | — | 成稿投 Financial Innovation |
| 2027-Q1 | thesis 综合章（Ch1/Ch2/Ch9/Ch10）+ 装订 | | | | | |

> 里程碑约束：RepCredit 唯一"改一版就能投"，优先级最高；AOA 是支付栈地基（Ch6），其 BRA 结果直接影响 thesis Part III 的成熟度；DVT 卡 FC'27 deadline（需查具体日期）；承重四章（Onion/DVT/AOA/RepCredit）全部投出后即可动笔 thesis 综合章。
