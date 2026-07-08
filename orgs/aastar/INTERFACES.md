# AAstar — 对外接口规范

> 文档类型：接口契约（Interface Contracts）
> 维护者：jason | 最后更新：2026-07-08
> 关联：`orgs/aastar/PROFILE.md`

---

## 我们提供 / What We Provide

### 1. AirAccount — 账户基础设施

**仓库**: `github.com/AAStarCommunity/AirAccount`
**版本**: v0.27.3-Beta5（KMS+WebAuthn，Sepolia 生产中）

| 接口 | 类型 | 说明 |
|-----|------|------|
| `/health` | HTTP GET | 服务健康检查 |
| `/kms/create-key` | HTTP POST | 在 TEE 中创建密钥对（p256/secp256k1） |
| `/kms/sign` | HTTP POST | TEE 内签名（私钥不离开安全环境） |
| `/webauthn/register` | HTTP POST | WebAuthn 注册（指纹/面部/PIN） |
| `/webauthn/authenticate` | HTTP POST | WebAuthn 认证 → 获取签名能力 |
| `/stats` | HTTP GET | 交易历史统计（TX count, wallet stats） |

**集成方式**：
- 直接 HTTP API（适合后端集成）
- 通过 AAStar SDK（适合前端/应用集成）

**关键特性**：
- TEE（Trusted Execution Environment）：私钥永不暴露
- 支持 WebAuthn（指纹/面部识别）取代密码/助记词
- 多链支持（Optimism, Sepolia, 其他 EVM 链）

---

### 2. SuperPaymaster — Gas 抽象支付

**仓库**: `github.com/AAStarCommunity/SuperPaymaster`
**版本**: v5.4.1-rc.1（slash-threshold-evidence-unify，BLS 模块 Sepolia 已部署）

**核心接口（ERC-4337 标准层）**

| 接口 | 类型 | 说明 |
|-----|------|------|
| `validatePaymasterUserOp` | Solidity | ERC-4337 Paymaster 验证 UserOperation |
| `postOp` | Solidity | 操作后结算（扣积分/代币） |
| `deposit` / `depositFor` | Solidity | 运营商 ETH 存款 |
| `addStake` / `withdrawStake` | Solidity | 运营商质押/取回 |
| `withdraw` / `withdrawTo` | Solidity | 余额提取 |

**v5.x 新增接口分组（v4→v5 主要扩展）**

| 分组 | 核心函数 | 说明 |
|-----|---------|------|
| 角色体系 | `registerRole`, `configureRole`, `exitRole`, `hasRole`, `ROLE_*` | 多角色（ANODE/DVT/KMS/Community/EndUser）权限管理 |
| 社区管理 | `leaveCommunity`, `deactivateMembership`, `transferCommunityOwnership` | 社区生命周期 |
| 信用/债务 | `recordDebt`, `repayDebt`, `clearPendingDebt`, `getCreditLimit`, `getDebt` | 链上信用额度系统 |
| Agent 注册 | `registerAgent`, `revokeAgent`, `isRegisteredAgent`, `setAgentPolicies` | Agent 白名单与策略 |
| BLS 聚合签名 | `registerBLSPublicKey`, `executeSlashWithBLS`, `setBLSAggregator` | BLS 签名聚合 + 惩罚机制 |
| SBT 声誉 | `safeMint`, `burnSBT`, `getUserSBT`, `setReputation` | 链上声誉 SBT（不可转让） |
| 代币操作 | `mint`, `burn`, `burnFromWithOpHash`, `faucet`, `transferAndCall` | xPNTs 代币扩展 |
| 价格预言机 | `updatePrice`, `getRealtimeTokenCost`, `calculateCost` | 实时 Gas 成本计算 |

**集成方式**：
- 作为 ERC-4337 Paymaster 合约部署
- 通过 AAStar SDK 调用（无需了解合约细节）
- 支持社区积分（xPNTs）替代 ETH 付 Gas

**关键特性**：
- 多角色体系（v5 新增）：ANODE / DVT / KMS / Community / EndUser
- 链上信用系统（v5 新增）：无需预付 Gas 的 Agent 赞助
- BLS 聚合签名 + 惩罚机制（v5 新增）
- 社区代币付 Gas（任意 ERC-20 稳定币 + 社区积分）
- UUPS 可升级合约 | 支持 7 条链稳定币

---

### 3. SuperRelay — Bundler 网关

**仓库**: `github.com/AAStarCommunity/SuperRelay`（私有，联系 jason）
**版本**: v1.0.0

| 接口 | 类型 | 说明 |
|-----|------|------|
| `eth_sendUserOperation` | JSON-RPC | 提交 UserOperation |
| `eth_estimateUserOperationGas` | JSON-RPC | Gas 估算 |
| `eth_getUserOperationByHash` | JSON-RPC | 查询 UO 状态 |
| `eth_supportedEntryPoints` | JSON-RPC | 支持的 EntryPoint 列表 |

**集成方式**：
- 标准 ERC-4337 bundler RPC 端点
- 支持双签名（TEE + operator）
- 提供 OpenAPI 文档（32 schema）

---

### 4. AAStar SDK — 开发者集成包

**仓库**: `github.com/AAStarCommunity/aastar-sdk`（monorepo，pnpm workspace）
**版本**: v0.39.0（DVT operator registration API + BLSAggregator ABI sync）
**Sub-packages**: `core` / `sdk` / `dapp` / `enduser` / `operator` / `paymaster` / `identity` / `data` / `tokens` / `x402`

```typescript
import { AirAccount, SuperPaymaster, CometENS } from '@aastar/sdk';

// 创建账户
const account = await AirAccount.create({ provider: 'webauthn' });

// 发起 gasless 交易
const tx = await SuperPaymaster.sendGasless({
  account,
  to: '0x...',
  data: '0x...'
});
```

**封装能力**：AirAccount + SuperPaymaster + CometENS + OpenPNTs

> ⚠️ 旧仓库 `jhfnetboy/AAStar_SDK`（注意:owner 是个人账号，不是 AAStarCommunity）已 **archived**，仅作历史 backup 保留。所有新集成请用上方 `AAStarCommunity/aastar-sdk` monorepo。

---

### 5. 合约接口契约 / Cross-repo Versioned Contracts

> 本节收录跨仓库调用的稳定接口 selector，作为版本管理权威来源。
> owner 仓库变更接口时须通过 CC 任务通知 brood 更新版本行。

#### `isValidOwnerAuth` — AirAccount owner-gate

| 字段 | 值 |
|------|-----|
| **接口** | `function isValidOwnerAuth(bytes32 userOpHash, bytes calldata ownerAuth) external view returns (bytes4)` |
| **Selector / 成功 magic** | `0xa0cf00cf`（= `isValidOwnerAuth.selector`，刻意不用 ERC-1271 `0x1626ba7e`，避免混淆） |
| **失败返回** | `0xffffffff`（fail-closed，永不 revert） |
| **宿主合约** | `AirAccountExtension`，经 `AAStarAirAccountV7` fallback 路由 |
| **owner** | `airaccount-contract` |
| **consumers** | DVT `YetAnotherAA-Validator` v1.9.0（`blockchain.service.ts` owner-gate）；AirAccount KMS |
| **稳定自** | v0.23.0（issue #159）；经 v0.24/25/26/27.0 未变 |
| **当前实现（Sepolia v0.27.0）** | impl `0x4a76dEf9eE4EE44eF6D0B2a327a068B5B7931E1C`；Extension `0xEcE87546989Da7df573b107D54a0ead0aCB49923` |
| **参考账户** | e2e_account `0x92EA8b02D34A4D5d10f0Db9Ea894e8bC72e292e8`（owner `0xb5600060…`） |
| **源码位置** | `src/core/AirAccountExtension.sol:1016` |

**`ownerAuth` 编码规则（consumers 必读）**：

| tag | 含义 | payload 构造 | 长度 |
|-----|------|-------------|------|
| `0x01` | owner ECDSA (secp256k1) | `personal_sign(userOpHash)`（EIP-191）；v=0/1 归一到 27/28；low-S 强制；ownerAuth = `0x01 ‖ sig` | 严格 66 字节，非 66 直接返回 `0xffffffff` |
| `0x02` | owner WebAuthn passkey | `authenticatorData ‖ clientDataJSON ‖ …` | 可变 |

> **版本管理约定**：`airaccount-contract` 升级该接口（改 selector/magic/tag 语义/宿主）时通过 CC 任务通知 brood，brood 更新本表版本行并同步 consumers。

---

## 我们消费 / What We Consume

| 来源组织 | 能力 | 用途 | 可选性 |
|--------|------|------|------|
| AuraAI | AI 推理 | AirAccount 用户行为分析 / 风险检测（规划中） | 可选 |
| MushroomDAO | 协议治理 | 协议规范遵守 + 生态参与规则 | 可选 |
| OpenPNTs | 积分协议 | SuperPaymaster 积分支付基础 | 核心 |

---

## 跨组织集成指南

### AuraAI 集成 AAstar

```
场景：AI 代理通过 AirAccount 身份管理 + SuperPaymaster 付费
步骤：
1. 为 AI 代理创建 AirAccount（TEE 保护的代理密钥）
2. 代理执行操作时，通过 SuperPaymaster gasless 提交 tx
3. 结算时通过积分/稳定币支付，而非 ETH
```

### MushroomDAO / Cos72 集成 AAstar

```
场景：社区用户使用 Cos72 免 Gas 参与治理/任务
步骤：
1. 用户通过 AirAccount 注册（邮箱即账户）
2. 社区为用户发放积分（OpenPNTs）
3. 积分可用于 SuperPaymaster 替代 Gas 费
```

---

## 联系 / Contact

- GitHub Org: https://github.com/AAStarCommunity
- 主要维护者: @jhfnetboy (jason)
- 集成问题: 提 issue 到对应 repo 或联系 jason
