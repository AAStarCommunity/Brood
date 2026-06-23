# TWO_PATHS.md — 双路径技术原理

> 用户提出的核心技术框架：
> **Path A** = USDC + EIP-3009 + EIP-712 + Relay（外部钱包直签直付）
> **Path B** = USDT 从 CEX → AirAccount → 买 aPNTs → ERC-4337 gasless 支付
>
> 本文证明这两条路径是当下**唯一可行的"零额外操作 + 真 gasless"组合**，并给出每条路径的协议级细节、合约引用和质疑应对。

---

## 1. EIP-3009 vs Permit / Permit2 vs EIP-7702 — 为什么是 EIP-3009

| 方案 | 用户操作 | 钱包支持 | USDC 支持 | USDT 支持 | 适合做 gasless | 适合 FangPay |
|:---|:---|:---:|:---:|:---:|:---:|:---:|
| **EIP-3009** `transferWithAuthorization` | 1 签 | 所有 EVM 钱包（链下 EIP-712） | ✅ Circle 官方 USDC v2+ | ❌ Tether 主网未实现 | ⭐ 最佳 | ⭐ Path A 必选 |
| **EIP-2612 Permit** | 1 签 + 1 链上 tx | 所有 | ✅ USDC 也支持，但需 approve+transferFrom 两步 | ❌ Tether USDT 未实现 | ✅ 但需要 relay 调 2 个合约 | 次选 |
| **Permit2 (Uniswap)** | 1 签（首次需 approve Permit2 合约） | 所有 | ✅ | ✅（绕过 USDT permit 缺失） | ✅ | Path A 备选，但首次 approve 需 ETH（不 gasless） |
| **EIP-7702** EOA 临时变智能账户 | 1 签 | ❌ MetaMask 2026-06 仍未生产支持 | ✅ | ✅ | ⭐ 理论最佳 | **暂时不可用** |
| **ERC-4337 智能账户** | 多签或一签 | ✅（仅智能钱包，非 MetaMask） | ✅ | ✅ | ⭐ | Path B 必选 |

> **结论**：
> - USDC 走 **EIP-3009**：唯一同时满足"全钱包兼容 + 真 gasless + 1 步用户操作"的方案 → **Path A**
> - USDT 用户绝大多数在 CEX，提到 MetaMask 后无法 gasless（Permit2 首次 approve 也要 ETH），因此走 **CEX → AirAccount (4337) → aPNTs 付 gas** → **Path B**
> - EIP-7702 是未来正确答案，但 2026 年内 MetaMask 等主流 EOA 钱包未支持，**不进 v1**

---

## 2. Path A — USDC + EIP-3009 + Relay 详细流程

### 2.1 时序图

```
Buyer Wallet              FangPay Frontend         FangPay Relay         USDC Contract        Merchant Wallet
   (MetaMask)               (pay.fangpay.io)         (Node.js)        (0xA0b8...eB48)
       │                          │                       │                  │                       │
       │   ① 浏览商家收款页         │                       │                  │                       │
       │ ◀───────────────────────│                       │                  │                       │
       │                          │                       │                  │                       │
       │   ② 点击 [Pay 10 USDC]   │                       │                  │                       │
       │ ─────────────────────▶ │                       │                  │                       │
       │                          │                       │                  │                       │
       │                          │  ③ Build EIP-712     │                  │                       │
       │                          │  TypedData (auth)    │                  │                       │
       │ ◀ eth_signTypedData_v4 │                       │                  │                       │
       │                          │                       │                  │                       │
       │   ④ Sign in MetaMask    │                       │                  │                       │
       │   (no ETH needed)        │                       │                  │                       │
       │ ──── signature ──────▶ │                       │                  │                       │
       │                          │  ⑤ POST /relay       │                  │                       │
       │                          │  {sig, auth, merchant│                  │                       │
       │                          │ ────────────────────▶│                  │                       │
       │                          │                       │  ⑥ 验签 + 验配额  │                       │
       │                          │                       │  (前 10 笔免费 / │                       │
       │                          │                       │   aPNTs 余额够)  │                       │
       │                          │                       │                  │                       │
       │                          │                       │  ⑦ transferWith- │                       │
       │                          │                       │  Authorization() │                       │
       │                          │                       │ ────────────────▶│                       │
       │                          │                       │                  │  USDC 10 → merchant   │
       │                          │                       │                  │ ────────────────────▶ │
       │                          │                       │  ⑧ tx receipt   │                       │
       │                          │                       │ ◀────────────────│                       │
       │                          │  ⑨ {txHash}          │                  │                       │
       │                          │ ◀────────────────────│                  │                       │
       │   ⑩ ✅ 支付成功页          │                       │                  │                       │
       │ ◀───────────────────────│                       │                  │                       │
```

### 2.2 EIP-712 TypedData 结构（USDC mainnet 实际格式）

```typescript
const typedData = {
  domain: {
    name: 'USD Coin',
    version: '2',
    chainId: 1, // 主网；Base = 8453；Arbitrum = 42161
    verifyingContract: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
  },
  types: {
    EIP712Domain: [
      { name: 'name',    type: 'string' },
      { name: 'version', type: 'string' },
      { name: 'chainId', type: 'uint256' },
      { name: 'verifyingContract', type: 'address' },
    ],
    TransferWithAuthorization: [
      { name: 'from',        type: 'address' },  // buyer
      { name: 'to',          type: 'address' },  // merchant
      { name: 'value',       type: 'uint256' },  // USDC amount (6 decimals)
      { name: 'validAfter',  type: 'uint256' },  // unix ts
      { name: 'validBefore', type: 'uint256' },  // unix ts (典型 +1h)
      { name: 'nonce',       type: 'bytes32' },  // random 32 bytes (防重放)
    ],
  },
  primaryType: 'TransferWithAuthorization',
  message: {
    from: buyerAddress,
    to:   merchantAddress,
    value: 10_000_000n, // 10 USDC = 10 * 1e6
    validAfter:  0,
    validBefore: Math.floor(Date.now()/1000) + 3600,
    nonce: '0x' + crypto.randomBytes(32).toString('hex'),
  },
}
```

### 2.3 Relay 提交的交易（合约调用）

```solidity
// USDC 合约（FiatTokenV2_1）原生方法
function transferWithAuthorization(
    address from,
    address to,
    uint256 value,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    uint8 v, bytes32 r, bytes32 s   // 用户的 EIP-712 签名
) external;
```

Relay 用**自己的 EOA**（持有 ETH）发起 tx：
```typescript
await usdcContract.transferWithAuthorization(
  from, to, value, validAfter, validBefore, nonce, v, r, s,
  { gasLimit: 100_000 } // 实际 ~60-70k
);
```

### 2.4 关键属性

✅ **真 gasless**：用户只签名，不发交易，**不需要持有任何 ETH**
✅ **原子性**：1 笔链上交易完成转账
✅ **资金路径直达**：USDC 从 `from` → `to`，Relay **从不持有**这笔 USDC
✅ **防重放**：每个 `nonce` 在 USDC 合约里只能用一次（`authorizationState[from][nonce]`）
✅ **可取消**：用户可链上调 `cancelAuthorization` 主动作废未提交的签名
✅ **gas 成本**：~65k gas，主网 ~$2、L2 ~$0.005

### 2.5 已知合约地址（确认）

| 链 | USDC 合约 | 支持 EIP-3009 |
|:---|:---|:---:|
| Ethereum Mainnet | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` | ✅ v2.1 |
| Base | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | ✅ |
| Arbitrum | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` | ✅ |
| Optimism | `0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85` | ✅ |
| Polygon PoS | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` | ✅ |

> ⚠️ **不要用 USDC.e（桥接版）**，那个版本经常不支持 EIP-3009。只用 Circle Native USDC。

---

## 3. 为什么 USDT 不能像 USDC 那样简单

### 3.1 协议层缺失

```
Tether USDT 主网合约 (0xdAC17F958D2ee523a2206206994597C13D831ec7) 不实现:
  ❌ EIP-3009 (transferWithAuthorization)
  ❌ EIP-2612 (permit)
```

历史原因：Tether 合约 2017 年部署，至今未升级。USDT 是 EVM 上**最古老**的稳定币之一，合约接口极简，只有 ERC-20 标准方法 + 黑名单管理。

### 3.2 那 Permit2 不是绕过了么？

是，但有一个**致命首步**：
```
First-time use Flow:
  User → approve(Permit2, max)  ← 需要 ETH 付 gas！⛔
  User → sign Permit2 message    ← 后续都免 gas，但首次没救
```
Permit2 是一个**单独的合约**（`0x000000000022D473030F116dDEE9F6B43aC78BA3`），用户首次必须 `approve` 它，否则 Permit2 无权操作 USDT。这一步必须用户付 ETH，破坏了 gasless 体验。

对于"从 MetaMask 直接付"的 USDT 用户，没有 EIP-3009 等价物。

### 3.3 那 EIP-7702 不是把 EOA 变智能账户么？

是，理论最优。但现实是：
- EIP-7702 在 Pectra 升级后已激活（2025-05 Ethereum mainnet）
- **MetaMask** 截至 2026-06 仍未在生产版本提供原生 7702 用户流（需要复杂的 batchUserOp 包装）
- **OKX Wallet / Rainbow / Coinbase Wallet** 同上
- 即使支持，UI/UX 培育期还要 6-12 个月

所以 v1 **不依赖 EIP-7702**，等 2027 年再说。

---

## 4. Path B — USDT via CEX → AirAccount → aPNTs Gasless

### 4.1 用户旅程

```
[Step 1: User in CEX]
   - Binance / OKX / Coinbase 持有 USDT
   - 在 FangPay 商家页点击"我有 USDT 在 CEX"
   - 页面引导生成 AirAccount 地址 (一次性 setup)

[Step 2: CEX 提币到 AirAccount]
   - 用户在 CEX 提币 USDT 到 AirAccount 地址
   - 选 Arbitrum / Base / Polygon (Ethereum mainnet 提币费太高)
   - 等 5-15 min (CEX 风控冷却 + 出块)

[Step 3: 在 FangPay 商家页继续]
   - 检测到 AirAccount 余额到账
   - 如果 aPNTs 余额 < 单笔 gas 估值 → 弹窗 "购买 aPNTs"
     → 跳合规 aPNTs 购买页 (单独 page, 仅卖 utility token)
     → 用 USDT/USDC swap 到 aPNTs (Uniswap 或自有 AMM 池)
   - aPNTs 到位后 → 点击 [Pay]

[Step 4: AirAccount + SuperPaymaster + Bundler]
   - AirAccount 构造 UserOperation:
       callData: USDT.transfer(merchant, amount)
       paymasterAndData: SuperPaymaster 签名 + aPNTs 抵扣指令
   - SuperPaymaster.validatePaymasterUserOp() 验证 aPNTs 余额够
   - SuperRelay (bundler) 把 UserOp 打包成 handleOps()
   - SuperPaymaster 代付 ETH gas
   - EntryPoint 执行 → USDT transfer → 商家钱包到账
   - postOp: 从 AirAccount 扣 aPNTs 抵扣

[Step 5: Done]
   - 商家收到 USDT
   - AirAccount aPNTs 余额扣减
   - 用户下次直接走 Step 4 (AirAccount 已有 USDT 余额)
```

### 4.2 关键合约（AAStar 已有）

| 组件 | 合约 / 版本 | 状态 |
|:---|:---|:---:|
| AirAccount factory | `aastar-contracts/AirAccountFactory.sol` (v0.23.2 Beta5) | ✅ |
| AirAccount logic | `aastar-contracts/AirAccount.sol` | ✅ |
| EntryPoint | `0x0000000071727De22E5E9d8BAf0edAc6f37da032` (4337 v0.7 canonical) | ✅ 全链通用 |
| SuperPaymaster | AAStar/SuperPaymaster v4.4.0 | ✅ Sepolia, GA prep |
| Bundler (SuperRelay) | AAStar/SuperRelay | ✅ Phase 1 |
| aPNTs (OpenPNTs) | AAStar/OpenPNTS | ✅ |
| AAStar SDK | `@aastar/sdk` v0.24.1 | ✅ DVT 5 连发 |

### 4.3 关键属性

✅ 用户**不需要 ETH**（aPNTs 抵扣 gas）
✅ USDT 仍直接到商家钱包（链上一笔）
⚠️ 用户操作步骤多（5 步 vs Path A 的 2 步）
⚠️ 首次需要 CEX 提币（5-15 min 等待 + CEX 提币费）
⚠️ 需购买 aPNTs（合规 page 必备）

### 4.4 优化方向（v2+）

- **预充值 USDT 包**：商家可垫付小额 aPNTs 让买家"白嫖"首次 gas，类似 Path A 的"10 笔免费"模型
- **AirAccount 一键创建**：买家用 passkey/Google 登录 → 自动创建 AirAccount → 跳过 onboarding 摩擦
- **CEX 自动提币**：通过 CEX OAuth + API 自动触发提币（需用户授权，类似 Wyre 接 Coinbase）

---

## 5. 两条路径对比

| 维度 | Path A (USDC EIP-3009) | Path B (USDT via AirAccount) |
|:---|:---:|:---:|
| 用户操作步骤 | 2（连接 + 签名） | 5（生成 AA 地址 + 提币 + 买 aPNTs + 签名 + 等确认） |
| 用户需要 ETH | ❌ 不需要 | ❌ 不需要 |
| 用户需要 aPNTs | ❌ 不需要 | ✅ 需要（首次购买） |
| 链上原子性 | ✅ 1 tx | ✅ 1 UserOp |
| 资金不过手 | ✅ | ✅ |
| 首次使用门槛 | 极低 | 中等（CEX 提币 + AA 注册） |
| 重复使用门槛 | 极低 | 极低 (AA 已存余额 + aPNTs) |
| 适合场景 | 已有钱包的加密用户 | CEX 持币的"准加密用户" |
| 商家集成复杂度 | 极低（一行 script） | 同 Path A（同一个 Relay 调度） |
| 推出顺序 | **MVP** | **v1.5** |

---

## 6. 一行 SDK 自动选路（关键！）

```typescript
// pay.fangpay.io 的前端核心逻辑（极简版）
async function pay(merchantSlug, amount, currency) {
  if (currency === 'USDC') {
    // Path A: 检测当前连接的 EOA 钱包
    const wallet = await detectWallet(); // MetaMask / OKX / Rainbow
    const sig = await wallet.signTypedData(buildEIP3009TypedData({
      to: getMerchantAddress(merchantSlug),
      value: amount,
    }));
    return relay.submit({ path: 'A', sig, ... });
  }

  if (currency === 'USDT') {
    // Path B: 引导到 AirAccount 流程
    const airAccount = await ensureAirAccount(userEmail);
    if (!await airAccount.hasUSDT(amount)) {
      return showCEXWithdrawGuide(airAccount.address, amount);
    }
    if (!await airAccount.hasAPNTs(estimateGasInAPNTs())) {
      return showAPNTsPurchasePage();
    }
    const userOp = await airAccount.buildUserOp({
      call: encodeUSDTTransfer(merchant, amount),
      paymaster: SUPER_PAYMASTER_ADDR,
    });
    return relay.submit({ path: 'B', userOp });
  }
}
```

商家**完全不感知**用户走哪条路径，集成代码只有一行：

```html
<fang-pay product="abc123"></fang-pay>
```

详见 [INTEGRATION_FLOW.md](./INTEGRATION_FLOW.md).
