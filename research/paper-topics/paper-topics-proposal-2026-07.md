# AirAccount 体系论文选题提案（2026-07-21）

> ⚠️ **历史探索稿——命名与分解已被取代。** canonical 命名/编号/章节以 `master-paper-roadmap-2026-07.md` §0 为唯一权威。
> 本文档早期用 P-A/P-B/P-C/P-D 标签，对照如下（且当时"恢复"是独立的 P-D，后来并入 Weighted）：
> **P-A = Onion（Ch3）· P-B = DVT（Ch5）· P-C = AgentPay（Ch8）· P-D = 社交恢复（已并入 Weighted / Ch4）**。
> 下方分析仍有效，仅标签作废。最终 6 篇结构 = Onion / Weighted / DVT / AOA / RepCredit / AgentPay。

> 基于四路仓库考古：airaccount-contract + AirAccount(KMS) / YetAnotherAA + YetAnotherAA-Validator(aNode DVT) / SuperPaymaster + super-relay + aastar-sdk / DSR-Research-Flow（已有论文盘点）
> 视角：博导 + 密码学 + 系统安全 + 期刊审稿人
> 目标：2026 Q3 启动、Q3-Q4 投稿（DSR 方法论，制品已部署测试网）
> 同步存放：Brood `research/paper-topics/` + DSR-Research-Flow `writing/`

---

## 0. 已有论文格局（避免撞车）

| 论文 | 主题 | 状态 |
|---|---|---|
| Paper3 SuperPaymaster (AOA) | 消除中心化 signer 的 gas 代付架构 | **已投 BRA**（2026-05-28） |
| Paper7 CommunityFi | 声誉→gas 信用额度 C(R)，DVT/BLS 验证 | **投 IET Blockchain 收尾** |
| Paper4 AirAccount D2D MultiSig | 多组多权重多签 | overview 0.1-draft（2026-03）← 本提案 P-A 升级填充 |
| Paper5 SocialRecovery | 三层 Guardian 加权恢复 | overview 0.1-draft（2026-03）← 本提案 P-D 升级填充 |
| Paper6 EIP-7702 Gasless EOA | — | 未启动 |
| Paper8 SuperPaymasterV2 | Agentic Economy / EIP-8141 | 仅 idea.md ← 本提案 P-C 填充 |

**切割原则**：Paper3 = "谁出 gas 的授权去中心化"；Paper7 = "声誉换 gas 信用的经济机制"。本提案四篇分别占据：账户安全策略（P-A）、密码学验证模块与 DVT 语义（P-B）、agent 支付与授权链（P-C）、恢复机制（P-D）。RQ 互不重叠，无 salami-slicing 风险。

## 0.5 与 DSR 仓库既有选题材料的衔接（2026-03 构想 → 2026-07 代码现实）

2026-03 的 paper4/paper5 overview 基于当时的设计文档（`research/AirAccount/`、`design/AirAccount/`、OnionModel）。四个月后代码大幅进化（v0.18→v0.27），**多数构想已落地为可测量的链上机制，部分构想被现实取代**——这正是 DSR 叙事最好的素材（design→build→evaluate 迭代证据链）：

| 2026-03 构想（overview） | 2026-07 代码现实 | 论文处理 |
|---|---|---|
| Paper4「洋葱安全模型」（分层随资产递增，定性描述） | 已落地为链上强制 T1/T2/T3 因子升级 + AlgTierLib + 当日累计支出判定 | P-A 的核心制品；洋葱模型作为设计理论前身写进 P3 阶段 |
| Paper4「TEE 双签名 + 意图分离」 | 单手势 KMS TEE 双签（P256+ECDSA）+ "无单因子可解锁"不变量 | 拆给 P-A（合约侧）与 P-C（TEE 授权链） |
| Paper4 评估草案（validateUserOp ≤30k gas、GOMS） | 已有 900 单测 + Pimlico 真实 UserOp + 分档 gas 数据 | P-A evaluation 直接用实测替换草案目标值 |
| Paper5「加权多签模型」 | **已实现**：WeightConfig 六因子可配权重 + algId 0x07 bitmap 累加 + 3/5/6 阈值解析 tier + 弱化防护治理（owner 提案→2 guardian→2 天 timelock）+ SDK 三档默认模板（`AAStarAirAccountBase.sol:1089-1160`、`WeightedSignature.t.sol` 49 用例）。未实现：恢复路径加权（现为固定计数 2-of-3，`AirAccountExtension.sol:744`）、guardian 分组 | 加权多因子+治理闭环可独立成文（见 title/keywords/abstract 文档 Paper 2）；分组与加权恢复列 future work |
| Paper5「Guardian 隐私（TEE 加密/ZK 承诺）」 | 未实现 | 不能作为 DSR 主贡献；仅 discussion |
| Paper8 idea「Agentic Economy / 微支付 / Agent 挣 gas」 | ERC-8004 双通道资格 + TEE-JWT agent key + x402/微支付通道已上 Sepolia | P-C 的主体 |
| Paper8 idea「RIP-7711/7712、EIP-8141 分析」 | 协议未上线，无制品 | P-C 的 future work / discussion 素材 |

---

## P-A（旗舰）：金额分级的密码学因子升级账户体系

**暂定题**: *Value-Tiered Factor Escalation: An On-Chain Enforced Multi-Factor Security Policy for Smart Contract Accounts*

- **核心命题**：现有智能账户（Safe/Argent/Clave）的金额限制只做"限流/延时"，不改变密码学强度。本制品把交易金额映射为**链上强制的签名因子等级**：T1 单因子（passkey/ECDSA）→ T2 双因子（+DVT BLS 门限共签）→ T3 三因子（+guardian），并可形式化为安全策略状态机。
- **三个防绕过设计（审稿人最看重的硬核点）**：
  1. tier 判定用**当日累计支出** `requiredTier(alreadySpent+value)`，防拆单绕过（AlgTierLib.sol）
  2. 阈值烙入 CREATE2 salt 配置哈希，改配置需 2-of-3 guardian
  3. 验证/执行阶段 algId 经 transient storage 强制一致 —— v0.25/v0.26 修复的**"验证/执行 tier 脱钩"提权漏洞本身可作为对 ERC-4337 模块化账户的新攻击面分类**，是 Related Work 之外的独立贡献点
- **证据基座**：Sepolia v0.18→v0.27 全版本部署记录、Forge 900 单测、链上 E2E 31/31、真实 UserOp via Pimlico、多轮对抗审计报告（docs/）、tier-setup 用户画像初始化（YetAnotherAA 前端）
- **DSR 适配**：制品完整、已部署、有攻击-修复迭代史（正好对应 DSR 的 build-evaluate 循环）；evaluation = 安全性论证（状态机+攻击面分析）+ gas 开销分档实测 + E2E
- **须处理的局限**：参考账户存在 owner-ECDSA 回退路径，分层结论仅对强制 BLS 路径的账户变体成立（DVT_VALUE.md 自曝）——论文中要么修掉、要么明确 scope
- **venue**：BRA / ACM DLT / IET Blockchain；会议选项 AFT、IEEE ICBC。**建议 Q3 首发**

## P-B：DVT 语义迁移 + 全链上 BLS 验证模块

**暂定题**: *From Consensus Duties to Account Policies: Distributed Validator Technology as a Transaction-Semantic Second Factor for ERC-4337 Accounts*

- **核心命题**：Obol/SSV 的 DVT 分发的是共识层 validator duty（盲执行）；本制品把 DVT 重新定位为**账户层策略执行者**——"链上验签答『签名对不对』，DVT 答『这笔该不该签』"，明确"盲签=橡皮图章"命题，owner 私钥被盗也跨不过的独立失效域。
- **两大技术贡献**：
  1. **RFC 9380 hash_to_curve 完整搬上链** + EIP-2537 pairing 验证（Solidity modexp + map_fp2_to_g2），messagePoint 链上重算防重放；动态 gas 模型 + 实测（3 签名者验签 ~450k gas，UserOp 全程 1 节点 ~520k / 3 节点 ~653k）—— 与 BLS Wallet（BLS 用于 calldata 压缩省 gas）目标截然不同：这里 BLS 是安全因子
  2. **节点侧三道门**：owner-auth fail-closed → 双层策略 AND（节点本地底线 + 链上 PolicyRegistry）→ 大额带外确认（TTL 10min）
- **可选扩展章节**（也可拆成第五篇）：live gossip quorum 审计-罚没——客观证据（liveness/超发）→ gossip BLS 法定数共签 → 两步链上 slash，罚没对象是账户层服务节点而非质押验证者
- **证据基座**：aNode v1.12、Sepolia 3 节点真机共签、跨语言 conformance 金向量、Raspberry Pi / STM32MP157F 边缘硬件部署、Docker+CF tunnel 一键 3 节点 wizard
- **与 Paper7 的切割**：Paper7 用 DVT/BLS 做 gas 信用验证（经济机制）；P-B 是密码学/系统贡献（验证模块 + 策略执行语义），RQ 不同
- **venue**：ACM DLT / IET Blockchain / P2P Netw. Appl.；密码学工程角度可试 FC（Financial Cryptography）。**建议 Q3-Q4**

## P-C：Agent 支付与受限自治密钥（承接 Paper8 slot）

**暂定题**: *Accountable Autonomy: Reputation-Gated Sponsorship and TEE-Bound Delegated Keys for AI-Agent Payments on Account Abstraction Rails*

- **核心命题**：AI agent 经济需要"人类授权、机器执行、链上问责"的支付基础设施。本制品给出完整机制栈：
  1. **ERC-8004 声誉驱动 agent gas 赞助**：双通道资格（SBT ∨ 注册 agent）+ per-operator 分层费率/日限额 + 链上声誉反馈闭环 + ERC-7562 associated-storage 合规论证（少见的"验证期外部调用合规性"工程贡献）
  2. **Human→Agent 授权链**：人类 WebAuthn 仪式派生 agent key，TEE 签发 JWT 凭证，agent 凭 TEE-JWT 签 UserOp；**单手势 TEE 双签**（P256 passkey + TEE 持有 owner ECDSA，合约强制"无单因子可解锁"不变量）
  3. **多支付通道统一结算**：gasless / x402(EIP-3009) / 微支付通道(EIP-712 voucher+争议窗口) / agent 策略共用同一 credit-debt 结算层
- **明确未被已投 SuperPaymaster 论文（arXiv:2605.05774, AOA 主线）覆盖**
- **证据基座**：SuperPaymaster v5.4.x Sepolia、400+ Foundry 测试 + Echidna 模糊 + 两轮对抗审计、SDK v0.29 npm 发布、x402 client
- **时效性**：2026 agentic economy 正热（对标 Alchemy AgentPay），窗口价值高；paper8 idea.md 中 RIP-7711/7712、EIP-8141 分析作 future work
- **venue**：Financial Innovation（免费、跨学科快审）/ BRA / IET Blockchain；会议 WWW/AAMAS 的 agent-economy track 亦可探。**建议 Q4（或与 P-A 并行）**

## P-D：分层社交恢复（承接 Paper5 slot，体量较小）

**暂定题**: *Passkey Guardians and Quorum-Cancellation: Practical Social Recovery for Tiered Smart Accounts*

- **核心亮点**：
  1. **P-256/WebAuthn passkey 可当 guardian**（EIP-7212 链上验证，Touch ID 即 guardian）——降低 guardian 门槛的实际创新
  2. **cancel 也是 2-of-N 法定数投票且 owner 无权 cancel**：防"盗 owner key 者阻断恢复"，与 Argent 的 owner-cancel 模型相反，值得安全性对比论证
  3. 签名域折入版本+chainId+地址+nonce 防跨账户/跨版本重放；guardian 门控 ForceExit（L2→L1 强制提款）
- **诚实提醒**：当前代码中 **DVT/BLS 不在恢复路径里**（是 T2/T3 第二因子）。若想写"BLS 聚合 DVT 社交恢复"，需先补制品（guardian 侧用 DVT 节点做门限恢复共签）——约 2-4 周合约工作量，否则 DSR 评审过不了"制品真实存在"这关
- **与 paper5 overview（2026-03）的关系**：三层 1-2-3 加权 Guardian 与隐私保护存储（TEE 加密/ZK）均未实现，只能作 future work；主制品按现状代码写
- **两个走法**：(a) 按现状写 passkey-guardian 恢复，投中小型 venue（PeerJ CS / JBBA）；(b) 补 DVT-recovery 制品后与 P-B 呼应，升级为强论文。**建议先走 (a) 或并入 P-A 一章，Q4 再定**

## 候补（不建议本轮启动）

- **P-E 可验证消费级 TEE KMS**：TA 内验 WebAuthn + 可复现构建 + Sigsum 透明日志 + "抗提取 vs 抗滥用"分析框架（vs Turnkey/Web3Auth 闭源云 TEE）。系统安全 venue（ACSAC/Computers & Security）路线，与现有期刊管线风格差异大，放 2027
- **P-F super-relay 零入侵双签网关**：工程扎实但学术新颖性中等，建议作为 P-C 的系统实现章节

---

## 执行建议（Q3-Q4 时间线）

| 时间 | 动作 |
|---|---|
| 2026-07 下旬 | P-A 进 DSR P1-P2（问题识别+制品映射）；修/圈定 owner-ECDSA 回退局限 |
| 2026-08 | P-A 实验补齐（分档 gas 基准、攻击面复现脚本、commit pinning）；P-B P1 启动 |
| 2026-09 | P-A 成稿 → Sub-Before-Submission Scale 预审 → 投稿（Q3 内）；P-B 实验 |
| 2026-10~11 | P-B 成稿投稿；P-C 启动（等 OP 主网 Alpha 部署数据更佳） |
| 2026-12 | P-C 投稿；P-D 决策（并入 vs 独立 vs 补制品） |

**期刊分配建议**（同一期刊避免同时两篇在审）：P-A → BRA 或 ACM DLT；P-B → ACM DLT 或 FC'27；P-C → Financial Innovation；P-D → PeerJ CS / JBBA。不投 MDPI/IEEE Access（导师政策）。
