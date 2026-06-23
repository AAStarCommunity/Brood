# USER_PAYMENT_BARRIERS.md — 终端用户支付障碍全梳理

> **本文档是整个 FangPay 研究目录的核心**。
> 中小网站收加密支付能否成功，**核心约束不在商家侧，而在终端用户侧** —— 用户能不能在 30 秒-15 分钟内顺利完成支付，决定了商家会不会用这个工具。
>
> 本文用以下结构展开：
> 1. 用户起点矩阵（持币位置 × 代币种类 × 链）
> 2. 12 类支付障碍清单
> 3. 8 条解决路径（每条给出适用场景、操作步骤、失败模式、技术依赖）
> 4. 路径决策树（用户来到收款页 → 自动推荐路径的逻辑）
> 5. 边界情况和我们暂不支持的场景

---

## 1. 用户起点矩阵（30 种组合，逐个看）

### 1.1 持币位置（5 类）

| 编号 | 持币位置 | 全球估计用户数 | 加密原生程度 | 主要痛点 |
|:---:|:---|:---:|:---:|:---|
| **L1** | **CEX**（Binance, OKX, Coinbase, Kraken, Bybit, Gate） | ~3 亿 | 低 | 提币摩擦、KYC、网络选错 |
| **L2** | **EOA 钱包**（MetaMask, OKX Wallet, Rainbow, Trust） | ~1.2 亿 | 中 | 没 ETH 付 gas、地址混乱 |
| **L3** | **智能账户**（Safe, AirAccount, Argent, Ambire, Coinbase Smart Wallet） | ~500 万 | 高 | 钱包不普及、跨 dApp 支持差 |
| **L4** | **硬件钱包**（Ledger, Trezor） | ~600 万 | 高 | 签名繁琐、需连电脑 |
| **L5** | **App 钱包 / mWeb3**（Trust, OKX Wallet App, Coinbase Wallet App, Phantom） | ~1.5 亿 | 中 | 移动端签名 UX、链切换 |

> 总活跃加密持币用户全球估 **5-6 亿**，但**真正高频使用稳定币付款**的活跃用户估 **5000 万**。

### 1.2 代币种类（6 类）

| 编号 | 代币 | 协议特性 | 在 FangPay 中的可用性 |
|:---:|:---|:---|:---|
| **T1** | **USDC** (Circle) | EIP-3009 ✓, Permit ✓, ERC-20 ✓ | ⭐ 最佳 |
| **T2** | **USDT** (Tether) | 仅 ERC-20，无 3009/Permit | ⚠️ 需间接路径 |
| **T3** | **DAI** (MakerDAO) | Permit ✓ (DAI-style permit) | ✓ 可用 |
| **T4** | **ETH / WETH** | 原生币，需自付 gas（或包装） | ✓ 可用，但用户体验差 |
| **T5** | **BTC** | 非 EVM，需跨链桥 | ✗ v1 不支持 |
| **T6** | **其他链稳定币**（TRC-USDT, SOL-USDC, Aptos-USDC） | 非 EVM | ✗ v1 不支持 |

### 1.3 链选择

| 链 | gas 中位价 | EVM | Circle Native USDC | Tether USDT | FangPay v1 支持 |
|:---|:---:|:---:|:---:|:---:|:---:|
| **Ethereum Mainnet** | ~$2/tx | ✓ | ✓ (EIP-3009) | ✓ | ✓ 但不推荐 |
| **Base** | ~$0.005/tx | ✓ | ✓ (EIP-3009) | ✗ | ⭐ 推荐 |
| **Arbitrum One** | ~$0.005/tx | ✓ | ✓ (EIP-3009) | ✓ | ⭐ 推荐 |
| **OP Mainnet** | ~$0.005/tx | ✓ | ✓ (EIP-3009) | ✓ | ✓ |
| **Polygon PoS** | ~$0.001/tx | ✓ | ✓ (EIP-3009) | ✓ | ✓ |
| **Polygon zkEVM** | ~$0.01/tx | ✓ | ✓ | ✗ | ✓ |
| **BSC** | ~$0.05/tx | ✓ | ✗（非原生 USDC） | ✓ | ⚠️ 可选 |
| **TRON** | ~$0.1/tx (能量) | ✗ | ✗ | ✓ TRC-USDT 主流 | ✗ v2+ |
| **Solana** | ~$0.001/tx | ✗ | ✓ Native USDC | ✗ | ✗ v2+ |

> v1 主推 **Base + Arbitrum + Polygon**（EVM + EIP-3009 + 低 gas）；Ethereum mainnet 仅作高净值用户兜底。

### 1.4 30 种组合的可行性表

|  | USDC | USDT | DAI | ETH | BTC | 其他链 |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| **CEX** | ⭐ Path E→A | ✓ Path E→B | ✓ Path E→A | ⭕ Path E→D | ✗ | ✗ |
| **EOA** | ⭐ Path A | ✓ Path C | ✓ Path A (DAI permit) | ⭕ Path D | ✗ | ✗ |
| **Smart AA** | ✓ Path B | ✓ Path B | ✓ Path B | ✓ Path B | ✗ | ✗ |
| **硬件钱包** | ✓ Path A (签名慢) | ✓ Path C | ✓ Path A | ⭕ Path D | ✗ | ✗ |
| **App 钱包** | ⭐ Path A | ✓ Path C | ✓ Path A | ⭕ Path D | ✗ | ✗ |

图例：⭐ 最佳路径 / ✓ 可用 / ⭕ 可用但体验差 / ✗ v1 不支持

---

## 2. 12 类支付障碍清单（按"被卡住的概率"排序）

> 这里列出**用户实际抱怨过**的所有问题（来源：Reddit r/CoinBase、Twitter 加密圈、X.com 跨境支付社区、Mirror.xyz 创作者反馈）。

### 障碍 1：没有 ETH 怎么付 gas（**最高频，~40% 流失**）
- **典型场景**：用户钱包里有 100 USDC，想付 10 USDC，但没有 0.001 ETH 付 gas
- **传统解法**：先去 CEX 买 ETH → 提币 → 付 gas（3 步、半小时、还要交易所充值）
- **FangPay 解法**：Path A（EIP-3009 用户不付 gas）/ Path B（Paymaster aPNTs 代付）

### 障碍 2：提币摩擦（**第二高频，影响 CEX 用户 100%**）
- **2a. KYC 未完成**：新用户没法提币
- **2b. 提币网络选错**：USDT TRC-20 提到 ERC-20 地址 = 资金消失
- **2c. 提币 fee 高**：CEX 收 5-15 USDT 提币费（OKX/Binance 主网 USDT）
- **2d. 提币冷却**：CEX 风控 24-72h 冻结新地址
- **2e. 小额不划算**：提 5 USDT 收 1 USDT fee = 20% 成本
- **FangPay 解法**：商家页内置提币教学卡片 + 推荐 L2 网络 + 一键复制地址 + 检测网络匹配

### 障碍 3：地址复制错误 / 钓鱼（**影响金额大**）
- **3a. 复制粘贴时被剪贴板劫持替换**（恶意浏览器扩展）
- **3b. 收款地址显示截断**，用户没法验证全长
- **3c. 没有 ENS / 不知道用 ENS**
- **FangPay 解法**：slug 链上 registry（地址写链上）+ ENS 自动解析显示 + 弹窗显示完整地址 + ENS 名

### 障碍 4：链选择困惑（**直接导致 5-10% 失败**）
- **4a. 商家收哪条链**？多数商家不写清楚
- **4b. 用户在哪条链**？大多数用户不会查
- **4c. 跨链桥**：贵、慢、有黑客风险（Wormhole、Multichain 都被黑过）
- **FangPay 解法**：收款页自动检测用户钱包当前链 → 自动切换 → 显示"商家在 Base 收 USDC，你在 Ethereum 持 USDC，预计 1 分钟桥到 Base"

### 障碍 5：金额精度错误
- **5a. USDC 6 decimals vs ETH 18 decimals 易混淆**
- **5b. Gas 估算不透明，怕扣多**
- **5c. 不知道实际到账多少（链上 fee 是否扣自转账金额）**
- **FangPay 解法**：弹窗严格显示"你支付：10 USDC，商家收到：10 USDC，gas 由平台代付"

### 障碍 6：失败回滚 + 体验差
- **6a. tx revert 但 gas 不退** → 用户白扣 ETH
- **6b. Mempool 堵塞，签名 5 分钟未上链**
- **6c. Nonce 冲突，钱包多个 dApp 同时签**
- **FangPay 解法**：Relay 失败时**不上链不扣 aPNTs**（仅本地 stub tx）+ 自动重试 3 次 + 失败明确提示

### 障碍 7：心理门槛 + 加密黑话
- **7a. 看不懂 hash / typedData / EIP-712 字段**
- **7b. 怕签了恶意合约被掏空**
- **7c. 不信任"陌生网站"调起的钱包弹窗**
- **FangPay 解法**：签名前弹自家 UI 解释"你要签的是 USDC 协议官方方法 transferWithAuthorization，金额 10，对方 0xMERCHANT，1 小时后过期，无法被改"

### 障碍 8：退款 + 纠纷
- **8a. 链上不可逆**
- **8b. 商家失联怎么办**（这是真问题）
- **8c. 商品不符合预期**
- **FangPay 解法**：明确告知"链上不可退，请商家自行处理"；商业服务包 C 可接 Kleros / Aragon Court 仲裁路径（v2+）

### 障碍 9：发票 / 对账
- **9a. 个人需要购买证明**（报销）
- **9b. 商家需要月度结算明细**
- **9c. 税务申报需要法币换算**
- **FangPay 解法**：每笔自动生成 PDF 收据（含 tx hash + 时间 + 法币换算） + 商家后台可导出 CSV

### 障碍 10：隐私
- **10a. 钱包地址公开关联购物记录**
- **10b. 商家能看到用户钱包余额**
- **10c. 链上分析（Chainalysis 等）可反推身份**
- **FangPay 解法**：v1 不解决；v2 接 stealth address（EIP-5564）+ Privacy Pool

### 障碍 11：手机端体验
- **11a. 移动端浏览器 dApp 调起钱包不丝滑**
- **11b. WalletConnect 二维码扫描麻烦**
- **11c. 移动端签名 UI 字小看不清**
- **FangPay 解法**：收款页全 mobile-first + 优先检测 in-app 钱包 + WalletConnect v2 兼容 + 大字号签名预览

### 障碍 12：监管恐慌（特定国家）
- **12a. 中国大陆用户**：上链交易可能违法
- **12b. 印度用户**：1% TDS 扣税
- **12c. 美国用户**：报税复杂
- **FangPay 解法**：v1 通过 IP 地理围栏屏蔽中国大陆；其余在 ToS 明示用户自行合规

---

## 3. 八条解决路径详解

### Path A — EIP-3009 直签直付（USDC + EOA） ⭐ 主推

**适用**：EOA 钱包持 USDC，任何链上（推荐 Base/Arb/Polygon）

**用户旅程**：
```
1. 打开 pay.fangpay.io/xxx
2. 点 [Pay 10 USDC with MetaMask]
3. 钱包弹签名（无 gas 提示，因为是链下签名）
4. 等 5-15 秒
5. ✅ 完成
```

**用户成本**：0 ETH，0 额外步骤
**完成时间**：30 秒
**失败模式**：
- 钱包当前链 ≠ 商家收款链 → 自动提示切换
- USDC 余额不足 → 显示余额 + 提示充值
- 签名 typedData 被钱包警告 → 我方网站显示"为什么这个签名是安全的"教学

**技术依赖**：[TWO_PATHS.md §2](./TWO_PATHS.md#2-path-a--usdc--eip-3009--relay-详细流程)

---

### Path B — Smart Account + Paymaster（任意稳定币）

**适用**：用户已经有智能账户（AirAccount、Safe、Argent、Coinbase Smart Wallet）

**用户旅程**：
```
1. 打开 pay.fangpay.io/xxx
2. 点 [Pay with Smart Wallet]
3. 检测到 AirAccount（或其他 ERC-4337 钱包）
4. Passkey / Face ID / 指纹签名
5. ✅ 完成
```

**用户成本**：少量 aPNTs（首次需买 ~$0.01 aPNTs）
**完成时间**：60 秒（首次）/ 20 秒（后续）
**失败模式**：
- 智能账户余额不足
- 智能账户未充值 aPNTs → 引导购买
- Paymaster 余额耗尽（极少）

**技术依赖**：[TWO_PATHS.md §4](./TWO_PATHS.md#4-path-b--usdt-via-cex--airaccount--apnts-gasless)

---

### Path C — EOA + USDT + Permit2 / 引导买 ETH

**适用**：EOA 钱包持 USDT（不愿换 USDC）

**子路径 C1：Permit2 路径（首次需付一点 ETH approve）**
```
1. 检测 Permit2 是否已 approve
2. 若否 → 提示"你需要首次授权 Permit2，预计 gas $0.5"
3. 用户付 gas approve
4. 后续每次签名免 gas
```

**子路径 C2：引导买 ETH（最直白）**
```
1. 显示"你的 USDT 需要少量 ETH 付 gas"
2. 一键跳 onramper.com 买 $5 ETH
3. 返回支付页
```

**子路径 C3：建议换成 USDC**
```
1. 弹窗"换 1:1 USDT → USDC 更省"，跳 Uniswap one-click
2. 完成后走 Path A
```

**用户成本**：~$0.5 ETH（C1 首次）/ $5 ETH（C2）/ swap 滑点（C3）
**完成时间**：5 分钟（C1）/ 15 分钟（C2）/ 5 分钟（C3）

**推荐**：C3 > C1 > C2（让用户尽量换到 USDC 享 Path A 体验）

---

### Path D — 原生币直转（ETH/MATIC）

**适用**：用户只持 ETH/MATIC 等原生币，且数额小

**用户旅程**：
```
1. 检测用户钱包 ETH 余额
2. 提示"用 ETH 付 (按当前汇率 0.003 ETH)，gas 你自付 ~$0.005"
3. 钱包弹送币 UI
4. ✅ 完成
```

**用户成本**：自付 gas（~$0.005 on L2）
**完成时间**：30 秒
**失败模式**：
- ETH 汇率波动 → 多扣/少扣
- 原生币精度问题 → 显示到 6 位小数

**收款合约**：需部署一个 `Receiver.receive() payable` 合约，避免重入 + 自动 emit Event

---

### Path E — CEX → AirAccount + aPNTs Gasless

**适用**：用户 CEX 持稳定币，无钱包

**用户旅程**：
```
1. 打开 pay.fangpay.io/xxx
2. 点 [I have USDT in Binance/OKX]
3. 创建 AirAccount（邮箱 + Passkey 30 秒）
4. 显示提币教学：选 Arbitrum 网络 + 复制 AA 地址 + 等 10 min
5. 检测到入账 → 弹窗"购买 $0.01 aPNTs 抵 gas"
6. Passkey 确认支付
7. ✅ 完成
```

**用户成本**：CEX 提币费（$0.5-$2，看 CEX）+ ~$0.01 aPNTs
**完成时间**：10-15 分钟（首次）/ 60 秒（后续，AA + aPNTs 已有）

**关键 UX**：
- 提币教学卡片：每个主流 CEX（Binance/OKX/Coinbase/Bybit）一张图文 + 视频
- 一键复制 AA 地址 + 二维码（防输错）
- 实时监听 AA 入账 → 自动进入下一步

---

### Path F — Relay 故障兜底（用户自付 gas）

**适用**：Relay Worker 故障 / aPNTs 不够 / 平台维护中

**用户旅程**：
```
1. Relay 不可达
2. 收款页降级模式："我们的 gas 代付暂时不可用，你可以直接付（需 ETH gas）"
3. 钱包弹"用 X ETH 直接付 USDC.transfer(merchant, amount)"
4. ✅ 完成
```

**用户成本**：自付 gas
**完成时间**：30 秒
**重要**：FangPay **永远不允许商家因 Relay 故障收不到钱**，这是产品红线。

---

### Path G — 跨链桥（v2，不在 v1 范围）

**适用**：用户持币在非商家收款链上（如商家在 Base，用户在 Polygon）

**v2 设计思路**：
- 自动桥（Across / Stargate / Hop） + Path A 二段执行
- 用户签 2 个签名：一个授权桥转出，一个 Path A 签转账

**v1 处理**：明确告诉用户"商家只收 Base 链 USDC，请用桥工具自行处理"+ 推荐 superbridge.app

---

### Path H — 导出签名 + 自己提交（极端隐私）

**适用**：用户不信任 Relay，要求"完全自己控制"

**用户旅程**：
```
1. 点击高级选项 → [Export signature JSON]
2. 我方生成签名后弹 JSON 下载
3. 用户拿 JSON 去 etherscan WriteContract / 自己脚本提交
4. （平台不收 fee，因为没经过我们 Relay）
```

**用户成本**：自付 gas + 自己懂技术
**完成时间**：5 分钟
**适用人群**：极少（< 1%），但**必须有**，否则"中心化"指控成立

---

## 4. 路径决策树（前端自动推荐）

```javascript
// 收款页打开时立即执行
async function recommendPath(merchantConfig) {
  // 1. 检测用户当前状态
  const wallet = await detectConnectedWallet();
  const isCEX = !wallet && askUserHasOnlyCEX();
  const isSmartAccount = wallet && (await isSmartAccount(wallet.address));
  const tokenBalances = await fetchBalances(wallet?.address);
  const chain = wallet?.chainId;

  // 2. 决策树
  // (a) 智能账户 → Path B (最佳体验)
  if (isSmartAccount && hasAPNTsOrFundable(wallet)) {
    return { path: 'B', reason: '你已有智能账户，Passkey 一签即可' };
  }

  // (b) EOA + USDC + 商家收 USDC + 同链 → Path A ⭐主路径
  if (wallet && tokenBalances.USDC > merchantConfig.amount
      && merchantConfig.tokens.includes('USDC')
      && chain === merchantConfig.chain) {
    return { path: 'A', reason: '一签即付，平台代付 gas' };
  }

  // (c) EOA + USDC + 跨链 → 提示切链
  if (wallet && tokenBalances.USDC > merchantConfig.amount
      && merchantConfig.tokens.includes('USDC')
      && chain !== merchantConfig.chain) {
    return { path: 'A', action: 'switchChain', targetChain: merchantConfig.chain };
  }

  // (d) EOA + DAI → Path A (with DAI permit)
  if (wallet && tokenBalances.DAI > merchantConfig.amount
      && merchantConfig.tokens.includes('DAI')) {
    return { path: 'A_DAI', reason: '一签即付（DAI permit）' };
  }

  // (e) EOA + USDT only → Path C (try C3 first)
  if (wallet && tokenBalances.USDT > merchantConfig.amount && !tokenBalances.USDC) {
    return { path: 'C', subPath: 'C3',
             reason: '推荐你 1:1 换成 USDC，体验最好',
             fallback: ['C1', 'C2'] };
  }

  // (f) EOA + ETH only → Path D
  if (wallet && tokenBalances.ETH > merchantConfig.amountInETH * 1.05
      && merchantConfig.tokens.includes('ETH')) {
    return { path: 'D', reason: '直接用 ETH 付，gas 自付（~$0.005）' };
  }

  // (g) 无钱包但 CEX 有币 → Path E
  if (isCEX) {
    return { path: 'E', reason: '从 CEX 提币到 AirAccount（10 分钟）' };
  }

  // (h) Relay 故障 → Path F
  if (!isRelayHealthy()) {
    return { path: 'F', reason: 'Relay 维护中，你需要自付 gas' };
  }

  // (i) 完全无加密 → 推荐 onramper 买 USDC
  return { path: 'onramp', action: 'goToOnramper',
           reason: '你需要先买点 USDC（信用卡可购）' };
}
```

---

## 5. 边界情况（v1 明确不支持）

| 场景 | 为什么不支持 | 用户怎么办 |
|:---|:---|:---|
| BTC 持有者 | 跨链 + 桥不成熟 | 推荐 Strike / Bitrefill |
| Solana 持有者 | 非 EVM，UX 完全不同 | 推荐 Solana Pay |
| TRON USDT 持有者 | 占 USDT 流量 ~50%，但不在 EVM | v1 引导用户先桥到 Arb；v2 接 TRC-20 |
| 国家受 OFAC 制裁 | 法律风险 | IP 屏蔽 + ToS 拒绝 |
| 单笔 > $10k | 风控复杂、法务风险 | 引导联系商家走 OTC |
| 单笔 < $0.50 | gas 占比过高 | 不引导，建议商家提高最低门槛 |
| 退款 | 链上不可逆 | 商家与买家自行处理（v2 接 Kleros） |
| 自动订阅 | 需 Permit2 长期授权 + 风控 | v2 接入 |
| 多商品购物车 | UX 复杂 | v2，v1 仅单商品 |

---

## 6. 总结：v1 必须解决的"4 条主路径"

> 8 条路径中，v1 必做 **4 条**，v1.5/v2 做剩下 4 条。

| 优先级 | 路径 | 覆盖人群 | 启动复杂度 |
|:---:|:---:|:---:|:---:|
| **P0 v1** | A (EOA + USDC) | ~60% | 低（EIP-3009 现成） |
| **P0 v1** | F (兜底自付) | 100% 兜底 | 极低 |
| **P1 v1** | E (CEX → AA + aPNTs) | ~25% | 中（AAStar 现成） |
| **P1 v1** | C (USDT 引导) | ~10% | 中（Permit2 或 swap 引导） |
| P2 v1.5 | B (Smart Account 直签) | ~5% | 中 |
| P2 v1.5 | D (原生币) | ~5% | 低 |
| P3 v2 | G (跨链桥) | ~5% | 高 |
| P3 v2 | H (导出签名) | <1% | 低 |

**v1 上线 = Path A + F 跑通 = 解决 60% 用户 + 100% 兜底。**
**v1 完整 = + Path E + C = 解决 95% 主流场景。**

剩下 5% 通过 v2 解决 + 明示"v1 不支持，请这样处理"。

---

## 7. 推论：商家需要做什么

> 倒推：用户路径越多 → 商家越省心。

商家在 FangPay 工具里**只需要配置**：
1. 收款钱包地址（一个 EVM 地址）
2. 商品名 + 价格（必填 USD，FangPay 自动换算所有支持代币）
3. 接受哪条链（默认勾选 Base + Arbitrum）
4. 是否允许 Path F 兜底（默认开）
5. 是否允许 Path E（CEX 用户，默认开）

剩下的**用户路径分支、代币兼容性、链切换、签名教学、失败重试、提币教学、aPNTs 充值引导** —— **全部由 FangPay 收款页自动处理**。

商家**不需要懂**：
- ❌ EIP-3009 / Permit2 / EIP-4337 / Paymaster
- ❌ USDC vs USDT 协议差异
- ❌ 各链 gas 价格
- ❌ aPNTs 是什么

这才是"中小商家 10 分钟集成"的真正含义 —— **复杂度被吃掉，而非转嫁给商家**。

---

## 8. 一句话

> **不是问"商家怎么收"，而是问"用户怎么付才不被卡住"。**
> **8 条路径覆盖 95% 的真实用户场景，v1 必做 4 条，剩下兜底+v2 渐进**。
> 把"复杂度"沉淀在工具里（开源 + 协议费 + 商业服务三层），商家和用户都不用承担。
