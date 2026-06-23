# LITE_SCOPE.md — Lite 版边界（当下重心，4 周交付）

> **本文档锁死 Lite 版边界**。任何"再加一点点功能"的诱惑都必须先 PR 修改本文档，否则一律推迟到 v1.5。
>
> 用户明确指示：**"Lite 版是当下重心"**。

---

## 1. Lite 版一句话

> **让中小商家在 30 分钟内拥有一个"收 USDC + 客户不付 gas"的收款页。**
>
> 仅此而已。其他全部推迟。

---

## 2. Lite 版功能矩阵（必须 / 推迟）

### 2.1 必做 ✅

| 功能 | 边界 | 责任方 |
|:---|:---|:---|
| 收款页 SPA | 单一 `pay.fangpay.io/<slug>`，单商品，无购物车 | 协议层开源 |
| Path A 支付 | EOA + USDC + EIP-3009 + Relay | 协议层开源 |
| Path F 兜底 | Relay 故障时用户自付 gas，仍能收钱 | 协议层开源 |
| Slug registry 合约 | 商家地址写链上，前端从链上读 | 协议层开源 |
| Relay Worker | Cloudflare Worker，验签 + 提交 tx + 收 10% gas fee | 协议层开源 |
| 商家配置表单 | 邮箱（哈希）+ 收款地址 + 商品名 + 价格 + 链 | 协议层开源 |
| 链上 hash 凭证 | tx hash 作为订单号；商家后台一表展示 | 协议层开源 |
| aPNTs 抵扣 | 抽成的 10% gas fee 用 aPNTs 计价扣除 | 协议层开源 |
| 中英双语 | 收款页 + 文档 + 服务包 A 流程 | 协议层开源 |
| 商业服务包 A | $99/$199/$299 一次性 Cloudflare onboarding | HyperCapital |

### 2.2 推迟 ❌（Lite 不做，v1.5/v2 做）

| 功能 | 推迟到 | 原因 |
|:---|:---|:---|
| USDT 支持（Path C） | v1.5 | Permit2 体验差，先验证 USDC 路径 |
| CEX 提币引导（Path E） | v1.5 | 复杂度高，先验证主流路径 |
| AirAccount + aPNTs 用户侧体验（Path B） | v1.5 | 等 AirAccount Beta5 用户普及 |
| 原生币 ETH 支付（Path D） | v2 | 用户少，价值低 |
| 跨链桥（Path G） | v2 | 复杂度极高 |
| 多商品 / 购物车 | v2 | 不是中小商家的核心需求 |
| NFT 凭证 | v2 | 链上 hash 已足够，NFT 增加 gas |
| 订阅 / 周期扣款 | v2 | 需要 Permit2 长期授权 + 风控 |
| 退款 | v2 | Kleros 集成需法务前置 |
| 积分 / 忠诚度 | v2 或不做 | 偏离工具定位 |
| 商家 Dashboard 多页面 | v1.5 | Lite 用 adminKey URL + 单页就够 |
| AI Skill 配置 | v2 | 表单更简单更可靠 |
| 多链聚合（同一 slug 收多链）| v2 | 链上数据复杂 |
| 商业服务包 B（月度运维）| v1.5 | Lite 验证商业模型后再上 |
| 商业服务包 C（企业定制）| v1.5+ | 等 Lite 有 50+ 商家再说 |

---

## 3. Lite 版交付清单（4 周拆解）

### Week 1 — 协议层基础

- [ ] `contracts/SlugRegistry.sol` — 写商家收款地址到链上
- [ ] `worker/relay.ts` — Cloudflare Worker，验 EIP-3009 签名 + 估 gas + 收 10% fee + 提交 tx
- [ ] 在 Base Sepolia 部署 + 跑通 1 笔测试支付（端到端：签名 → Relay → 链上转账）
- [ ] 文档：`docs/CONTRACT.md` + `docs/RELAY.md`

### Week 2 — 收款页 SPA

- [ ] `page/Pay.tsx` — 商品页 + 钱包连接 + Path A 签名 + 状态轮询
- [ ] `page/Admin.tsx` — adminKey URL 进入，订单列表 + 配置编辑
- [ ] `page/Create.tsx` — 商家注册表单 → 生成 slug
- [ ] Path F 兜底逻辑：检测 Relay 健康，故障切自付模式
- [ ] 中英双语 i18n
- [ ] 部署到 `pay.fangpay.test`（测试域名）

### Week 3 — 商业服务包 A

- [ ] 自动化部署脚本 `scripts/deploy-fangpay.sh`（用 wrangler）
- [ ] Cloudflare onboarding 60 分钟标准流程文档
- [ ] 中英双语 onboarding 视频（YouTube + Bilibili）
- [ ] HyperCapital 工程师 SOP（安全纪律 + 价格 + 流程）
- [ ] 法务备忘：服务条款 + 数据处理协议（DPA）

### Week 4 — 5 个种子商家试点

- [ ] 招募：从 AAStar / Mycelium 社区找 5 个真实独立创作者
- [ ] 2 个自助（用 L1 文档 + L2 社区）
- [ ] 3 个用商业服务包 A
- [ ] 跑 1 周真实交易
- [ ] 收反馈 → 决定是否扩展（10 → 50 商家）

---

## 4. Lite 版**不需要**的事情清单

> 任何超出此清单的工作都**不要做**。看到诱惑就贴这张表。

- ❌ 不需要 NFT 工厂合约
- ❌ 不需要 Paymaster 自部署（Lite 暂不要 Path B，直接用 EIP-3009）
- ❌ 不需要 Bundler 自部署（同上）
- ❌ 不需要 SDK npm 包（一行 `<script>` 嵌入足够）
- ❌ 不需要 React 组件库
- ❌ 不需要 Webhook 系统
- ❌ 不需要积分代币合约
- ❌ 不需要订阅合约
- ❌ 不需要管理面板的图表 / 分析
- ❌ 不需要邮件通知系统（用户/商家通过链上 event 监听）
- ❌ 不需要多商品 catalog
- ❌ 不需要 AI Skill / MCP server
- ❌ 不需要硬件钱包专门适配（标准 EIP-712 签名足够）
- ❌ 不需要 BTC / 非 EVM 链
- ❌ 不需要法币 onramp / offramp 集成
- ❌ 不需要 KYC 系统
- ❌ 不需要 Telegram / Discord 机器人
- ❌ 不需要"商家社交关系"
- ❌ 不需要"用户社交关系"
- ❌ 不需要"商家间互相推荐返佣"

---

## 5. Lite 版风险（必须先解决）

> 上线前**必须**关闭这 3 项，否则 Lite 版不能发布。

| 风险 | 必做动作 | 责任 | 截止 |
|:---|:---|:---|:---|
| **监管定性** | 至少 1 份律师函覆盖 US 或 EU 或 SG，确认"非支付机构 + 协议费定性" | MushroomDAO 法务 | W2 |
| **aPNTs 定性** | MushroomDAO 公告 aPNTs 是"prepaid service credit"，储备金链上可查 | MushroomDAO 财库 | W2 |
| **slug 链上 registry** | 商家地址写链上，前端从链上读，防止平台数据库被改 | 协议层 | W1 |

---

## 6. Lite 版**成功**的定义

4 周后跑 1 周真实交易，**任意 4 项达标**即认为 Lite 版成功，可进入 v1.5：

- [ ] 5 个种子商家中至少 4 个完成集成（自助或商业服务包 A）
- [ ] 1 周内至少 50 笔真实支付成功
- [ ] Path A 成功率 > 95%
- [ ] 商家平均上线时间 < 60 分钟（含商业服务包 A 流程）
- [ ] 用户从打开收款页到支付成功 < 60 秒（P95）
- [ ] HyperCapital 服务包 A 至少卖出 3 单
- [ ] 律师函至少 1 份送达
- [ ] 0 起资金损失事故（包括钓鱼 / 重放 / Relay 故障导致丢单）

---

## 7. Lite 版失败的处置

如果 4 周后未达上述 4 项标准：

- 不要"再加功能"试图救活 — 加功能只会让坑更深
- 召集核心团队 1 周 retro，重新审视 ICP / 价格 / 路径
- 必要时关闭 Lite 版，沉淀代码作为 AAStar SuperPaymaster 的 reference integration
- 把经验整理成 post-mortem 文档放进 backlog

---

## 8. 一句话

> **Lite 版 = Path A + Path F + 商业服务包 A + 4 周交付**。
> **其他全部推迟。任何"再加一点点"都先改本文档**。
