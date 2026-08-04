---
schema_version: "1.0"
org_id: aastar
org_name: AAstar
layer: infrastructure
status: active
protocols:
  - mycelium
provides:
  - capability: daily-crypto-account
    interface: Your daily Web3 account: fingerprint login, no ETH needed
    repo: github.com/AAStarCommunity/AirAccount
    version: v0.27.3-Beta5
  - capability: gas-abstraction
    interface: ERC-4337 Paymaster (validatePaymasterUserOp / postOp)
    repo: github.com/AAStarCommunity/SuperPaymaster
    version: v5.4.1-rc.1
  - capability: bundler-gateway
    interface: ERC-4337 bundler RPC + OpenAPI
    repo: github.com/AAStarCommunity/SuperRelay
    version: v1.0.0
  - capability: developer-sdk
    interface: AirAccount + SuperPaymaster + CometENS + OpenPNTS
    repo: github.com/AAStarCommunity/AAStar_SDK
depends_on:
  - org: auraai
    capability: ai-agent-framework
    optional: true
  - org: mycelium
    capability: protocol-governance
    optional: true
contact:
  builder: jason
  github: github.com/AAStarCommunity
---

# AAstar 组织名片

## 我们是谁

AAstar 是 Mycelium Protocol 生态中的 **Web3 基础设施层**，专注于 ERC-4337 账户抽象技术栈。

我们相信：用户不应该因为 Gas 费用和复杂的密钥管理而被排除在 Web3 之外。

## 我们做什么

三个核心基础设施模块：

| 模块 | 功能 | 状态 |
|-----|------|------|
| **AirAccount** | TEE 私钥管理 + WebAuthn 无密码认证 | 生产中 v0.16.7 |
| **SuperPaymaster** | ERC-4337 Gas 抽象（社区积分付 Gas） | 生产中 v4.4.0 |
| **SuperRelay** | ERC-4337 企业级 bundler 网关 | Phase 1 完成 |
| **AAStar SDK** | 开发者集成包（封装以上三者） | 可用 |

## 我们提供什么

- **对开发者**: 一行代码实现 gasless 交易 + 邮箱账户
- **对社区**: 用自己的代币（xPNTs）替代 ETH 支付 Gas
- **对协议**: Web3 支付 & 身份验证的底层基础设施

## 我们需要什么

- **集成合作**: 愿意把 AirAccount / SuperPaymaster 集成到自己产品的团队
- **测试网络**: 更多真实场景的 UserOperation 测试流量
- **协议反馈**: 如何让 SDK 更易用的开发者反馈

## 当前路线图

见 BroodBrain 任务看板。核心里程碑：
- Phase 1: 基础设施 — AirAccount + SuperPaymaster + SuperRelay 基础集成 ✅
- Phase 2: SDK 完善 — 开发者体验提升，一键集成
- Phase 3: 生态扩展 — 更多链支持，社区 Paymaster 自助部署
