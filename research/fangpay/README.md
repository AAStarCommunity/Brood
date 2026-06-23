# FangPay 研究目录 — Brood/Mycelium 视角

> **来源**：用户问题 — 评估针对中小网站的 gasless 加密支付便利服务的市场和价值
> **本研究目录定位**：以**终端用户支付障碍**为核心，给出**开源工具 + 10% gas fee 协议费 + HyperCapital 辅导式商业服务**三层结构的可行性分析
> **维护者**：Brood orchestrator
> **状态**：v0.2 草稿（2026-06-22，按用户反馈大幅修订）
>
> ## 🎯 当下重心：Lite 版（4 周交付）
> **只做 Path A（USDC EIP-3009）+ Path F（兜底）+ 商业服务包 A（Cloudflare onboarding）**。
> 其他全部推迟到 v1.5/v2。详见 [LITE_SCOPE.md](./LITE_SCOPE.md) — 任何"再加一点点功能"先改那个文档。

---

## 0. 一句话定义

> **FangPay 是一个"加密收款工具"，不是 SaaS、不是支付平台。**
> 开源代码任何人可 fork 自部署；用户的稳定币链上直达商家钱包，平台不过手任何资金。
> 协议层只赚 **gas fee 10% 抽成**（每笔约 0.1 美分），用以维持参考实现的 Relay + 文档。
> 想省心的商家可购买 **HyperCapital 商业辅导服务**：教你开 Cloudflare 账号 + 建 API token，用 token 帮你自动化部署 + 后续运维更新。**账号和 token 始终在你手里**。

---

## 1. 三层结构（必须钉死）

```
┌──────────────────────────────────────────────────────────────────┐
│  L0 协议层 — 开源工具 (MIT/Apache)                                  │
│  ─ Relay Worker 代码 (Cloudflare Worker 模板)                      │
│  ─ 收款页 SPA (React + Vite, 可 fork 部署)                          │
│  ─ slug 链上 registry 合约                                          │
│  ─ EIP-3009 / AirAccount / SuperPaymaster 集成示例                  │
│  ─ 协议费：每笔交易 gas 的 10% 加价 (~0.1 美分/笔, L2)              │
│       └ 流入 MushroomDAO 国库，维持开源持续开发                       │
├──────────────────────────────────────────────────────────────────┤
│  L1 自助层 — 任何技术背景的人都可以照文档自部署                       │
│  ─ 商家 fork repo → 注册 Cloudflare 账号 → 部署 Worker             │
│  ─ 商家自己持有 Cloudflare API token、Relay EOA 私钥                │
│  ─ 商家自己绑定域名（可选）或用 *.pages.dev 子域名                    │
│  ─ 完全免费（除域名 + Cloudflare 免费层即够用）                       │
├──────────────────────────────────────────────────────────────────┤
│  L2 辅导式商业服务层 — 唯一授权: HyperCapital                          │
│  ─ 服务包 A：一对一 Onboarding 辅导                                  │
│     · 教你开 Cloudflare 账号（含免费 SSL/CDN/Worker 200k req/天）   │
│     · 教你建 API token（最小权限：Workers Edit + Pages Edit）        │
│     · 用 token 帮你自动化部署 + 配域名 + 写入 DNS                     │
│     · 一次性收 $99–$299 (按定制化程度)                              │
│  ─ 服务包 B：月度运维代理                                            │
│     · 监控 Relay EOA gas 余额、自动 top-up 提醒                       │
│     · 跟随上游更新自动 PR + 测试 + 部署                                │
│     · 故障 24h 内响应（最低 $29/月，企业定制更高）                     │
│  ─ 服务包 C：企业定制                                                │
│     · 自定义品牌、域名、合规审计、SLA                                 │
│     · 按项目报价                                                     │
│  ─ 关键纪律：HyperCapital **从不接触客户资金、不持有客户私钥**         │
│     只用客户自己的 Cloudflare token 在客户账号里做操作                  │
└──────────────────────────────────────────────────────────────────┘
```

> 这个三层结构 = Mycelium 协议层"开源 + 商业双生模型"（Linux + Red Hat 升级版）的具体落地。

---

## 2. 终端用户支付障碍 + 路径分支（核心）

> **本研究目录最核心的工作**：把"中小网站收加密"分解成**终端用户的实际支付路径**，逐条找障碍，逐条给路径分支。
> 完整分析见 [USER_PAYMENT_BARRIERS.md](./USER_PAYMENT_BARRIERS.md)，这里只列摘要。

### 2.1 终端用户起点矩阵（5 × 6 = 30 种组合）

|  | USDC | USDT | DAI | ETH | BTC | 其他链稳定币 |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| **CEX**（Binance/OKX/CB） | ① | ② | ③ | ④ | ⑤ | ⑥ |
| **EOA**（MetaMask） | ⑦⭐ | ⑧ | ⑨ | ⑩ | — | — |
| **智能账户**（Safe/AirAccount） | ⑪ | ⑫ | ⑬ | ⑭ | — | — |
| **硬件钱包**（Ledger） | ⑮ | ⑯ | ⑰ | ⑱ | ⑲ | — |
| **App 钱包**（Trust/OKX） | ⑳ | ㉑ | ㉒ | ㉓ | — | ㉔ |

⭐ 推荐主流路径 = 用户最多 + 障碍最少：**EOA + USDC + L2** → EIP-3009 直签直付。

### 2.2 八条解决路径（分支决策树）

```
                  用户在哪里 + 持什么币？
                          │
   ┌──────────────────────┼──────────────────────┐
   │                      │                       │
   持稳定币                持 ETH/原生币           持其他链 / BTC
   │                      │                       │
   ┌──┴──┐                ▼                       ▼
   │     │            Path D                  Path G
   USDC  USDT      "原生币直转"              "跨链桥引导"
   │     │       (用户付 gas)              (v2,非 v1)
   │     │
   ┌─┴─┐ ┌─┴───┐
   │   │ │     │
  EOA Smart EOA  CEX
   │   │  │     │
   ▼   ▼  ▼     ▼
 Path A Path B Path C Path E
"3009 "Paymaster "需 ETH " 提币到
 直签" 直接付"   引导转 AA + buy
                USDC"  aPNTs"
                       │
                       └─→ 也通向 Path B

                  ▼
              Path F (备份)
          "用户自付 gas, 显示原生 metamask 提示"
                          (任何情况下兜底)

                  ▼
              Path H (信任最低)
          "导出签名 JSON, 用户自己链上提交"
                          (隐私党/极端场景)
```

| 路径 | 用户操作步骤 | 用户额外成本 | 适用场景 | 完成时间 |
|:---:|:---:|:---:|:---|:---:|
| **A** | 2 | 0 | EOA + USDC ⭐主流 | 30s |
| **B** | 3 | 少量 aPNTs | 智能账户 + 任意稳定币 | 60s |
| **C** | 3 | 一点 ETH | EOA + USDT，不愿换 USDC | 90s |
| **D** | 1 | 自付 gas | 持 ETH 且数额小 | 30s |
| **E** | 5 | CEX 提币费 + aPNTs | CEX 持币，无钱包 | 15min |
| **F** | 2 | 自付 gas | 平台 Relay 故障兜底 | 30s |
| **G** | 6+ | 跨链桥费 | 非 EVM 链持币 | 30min |
| **H** | 4 | 自付 gas | 极端隐私需求 | 5min |

详见 [USER_PAYMENT_BARRIERS.md §3](./USER_PAYMENT_BARRIERS.md#3-八条解决路径详解)。

---

## 3. 商业模型（修订后）

### 3.1 协议层收入：每笔 10% gas fee 抽成

```
单笔 gas 成本（L2 Base/Arbitrum）≈ $0.005 - $0.01
平台加价 10% = $0.0005 - $0.001 /笔
= 0.05 - 0.1 美分 /笔
```

**怎么收**：
- Relay 在发送 tx 时，把"商家应付 gas"按市价 × 1.10 计算
- 用 aPNTs 抵扣（默认）或 商家钱包直扣 USDC（高级用户）
- 抽成流入 MushroomDAO 国库 multisig，链上透明

**为什么不抽交易金额 %**：
- 抽 % = 走入 Stripe / 支付机构的定性
- 抽 gas = "我们卖的是 gas 代付服务"，合规清晰
- 抽 gas 还有自然激励：商家会主动选 L2、批量打包，对生态友好

### 3.2 商业服务层收入：HyperCapital 三档服务包

| 包 | 内容 | 价格 | 目标客户 |
|:---:|:---|:---:|:---|
| **A** | 一对一 onboarding：开 CF 账号 + 建 token + 部署 + DNS | $99–$299 一次 | 不懂技术的独立创作者 |
| **B** | 月度运维代理：监控 + 自动更新 + 故障响应 | $29/月起 | 月流水 $1k–$10k 的独立站 |
| **C** | 企业定制：品牌 + 域名 + SLA + 合规审计 | 按项目 $5k+ | 月流水 $10k+ 的中小品牌 |

**关键纪律**：
1. HyperCapital 始终用客户自己的 CF token 在客户账号里操作（账号主权 100% 在客户手里）
2. HyperCapital **从不接触客户私钥、客户资金、客户客户的资金**
3. 服务包 B 自动更新需客户授权（默认 ask-before-apply）
4. 客户可随时停服 + 撤销 token + 自己接手运维

### 3.3 收入预估（粗略）

| 阶段 | 自助商家数 | 商业服务客户数 | 月流水/商家 | 协议层收入 | 商业服务收入 | 合计 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Y1 | 500 | 50 | $1k | $300/月 | $1.5k/月 | **$1.8k/月** |
| Y2 | 5000 | 500 | $2k | $6k/月 | $15k/月 | **$21k/月** |
| Y3 | 50000 | 5000 | $3k | $90k/月 | $150k/月 | **$240k/月** |

> 协议层收入"小但稳"（用以维持开源），HyperCapital 商业服务收入是放大杠杆（用以做商业实体）。这正是 Linux + Red Hat 模型的本质。

详见 [MARKET_VALUE.md](./MARKET_VALUE.md)。

---

## 4. 商家 / 用户疑虑 + 我们的支持

| 角色 | 主要疑虑 | 我们的支持 |
|:---|:---|:---|
| **商家** | "我不会 Cloudflare" | 商业服务包 A 一对一辅导 30 分钟开通 |
| **商家** | "工具会跑路吗" | 开源 + 客户自部署 + 私钥在自己手里 |
| **商家** | "合法吗" | Apache 2.0 + MushroomDAO 治理 + 律师函公开 |
| **商家** | "客户不懂签名怎么办" | 收款页内置中文/英文/日文教学弹窗 + 8 条路径自动引导 |
| **商家** | "万一收不到钱" | 链上 hash 可查 + 商家后台自动对账 + 失败自动重试 |
| **用户** | "签名会不会被掏空" | EIP-3009 强制单笔金额 + 1h 失效 + 钱包原生 UI 显示完整字段 |
| **用户** | "钱真的到商家了吗" | 弹窗显示商家 ENS + 完整地址 + 链上链接 |
| **用户** | "没有 ETH 怎么办" | 自动检测 + 8 条路径自动推荐 + 一键引导 |
| **用户** | "我在 CEX 怎么办" | Path E 引导 + 视频教学 + AirAccount 一键创建 |
| **用户** | "退款怎么办" | 商家页明示"链上不可逆"+ 商家自行退款流程指引 |

完整 20 项疑虑 + 应对：[OBJECTIONS_AND_SUPPORT.md](./OBJECTIONS_AND_SUPPORT.md)。

---

## 5. 目录索引

| 文档 | 内容 | 阅读对象 |
|:---|:---|:---|
| [README.md](./README.md) | 本文件 — 一页式总览（v0.2 已修订） | 所有人 |
| **[LITE_SCOPE.md](./LITE_SCOPE.md)** ⭐ | **Lite 版边界 + 4 周交付清单 + 成功定义**（当下重心） | **全员（最重要）** |
| [USER_PAYMENT_BARRIERS.md](./USER_PAYMENT_BARRIERS.md) | 终端用户支付障碍 5×6 矩阵 + 8 条解决路径 + 路径决策树 | 全员 |
| [OBJECTIONS_AND_SUPPORT.md](./OBJECTIONS_AND_SUPPORT.md) | 商家/用户 20 项疑虑 + HyperCapital 商业服务包 A 流程 | 商家、运营、HyperCapital |
| [MARKET_VALUE.md](./MARKET_VALUE.md) | 商家市场 + 终端用户市场 + 双层收入推算（v0.2 待修订） | 决策者、HyperCapital |
| [TWO_PATHS.md](./TWO_PATHS.md) | 双路径技术原理（USDC EIP-3009 / USDT AirAccount）协议层细节 | 工程师 |
| [INTEGRATION_FLOW.md](./INTEGRATION_FLOW.md) | 自助部署 vs 商业辅导两种集成路径（v0.2 待修订） | 商家、PM |
| [FEASIBILITY_ANALYSIS.md](./FEASIBILITY_ANALYSIS.md) | 风险矩阵 + 监管定性 + 上线决策清单（v0.2 待修订） | 全员 |

---

## 6. 与 Mycelium / Brood 生态的对齐

| Mycelium 原则 | FangPay 体现 |
|:---|:---|
| **数字公共物品** | L0 协议层 Apache 2.0 全开源，任何人可 fork 自部署 |
| **零数据剥削** | Relay 只见 hash 和 gas，看不到商品/客户/邮件内容 |
| **资金主权** | 商家自持私钥；HyperCapital 用客户自己的 CF token，账号在客户手里 |
| **意义经济** | 帮独立创作者跨境收款，不依赖 Stripe/PayPal |
| **两层成本** | 运营 = gas fee 10%；商业规模 = HyperCapital 服务包 |
| **协议层不抽租** | 只抽 gas，不抽交易金额 % |
| **开源 + 商业双生** | L0 协议 vs L2 HyperCapital，权责清晰 |
| **独家授权有期限** | HyperCapital 是唯一授权商业实体，三年后社区可投票引入竞争 |

---

## 7. 下一步（推进路径）

| 优先级 | 动作 | 产出 | 周期 |
|:---:|:---|:---|:---:|
| P0 | 法务确认"非支付机构 + 协议层 gas 服务费"定性 | 律师函（US/EU/SG 各 1 份） | 4 周 |
| P0 | aPNTs 定性 + 公开储备金证明 | MushroomDAO 公告 | 2 周 |
| P0 | Sepolia 跑通 Path A 端到端 | demo.fangpay.test | 2 周 |
| P1 | Path E (CEX → AirAccount + aPNTs) demo | 完整 5 步流程 | 3 周 |
| P1 | HyperCapital 服务包 A 流程文档 | onboarding 脚本 + CF 教学视频 | 2 周 |
| P1 | 5-10 个种子商家试点（自助 + 商业各半） | 真实用户反馈 | 6 周 |
| P2 | slug 链上 registry 合约审计 | 合约 + 审计报告 | 4 周 |
| P2 | 8 条路径全部落地 + 多语言文档 | 完整文档站 | 8 周 |

---

## 8. License

研究文档：MIT。
参考实现（待开发）：Apache 2.0。
