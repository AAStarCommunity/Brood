# AAstar — 对外接口规范

> 文档类型：接口契约（Interface Contracts）
> 维护者：jason | 最后更新：2026-04-27
> 关联：`orgs/aastar/PROFILE.md`

---

## 我们提供 / What We Provide

### 1. AirAccount — 账户基础设施

**仓库**: `github.com/AAStarCommunity/AirAccount`
**版本**: v2025.09.29-kms-web-ui（git tag，KMS 分支生产中）

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
**版本**: v5.3.0-dev（git tag，含 UUPS 升级，Sepolia 已部署）

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

**仓库**: `github.com/AAStarCommunity/AAStar_SDK`
**包名**: `@aastar/sdk`（npm）

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
