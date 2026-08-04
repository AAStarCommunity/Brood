# 四篇论文：Title / Keywords / Abstract（2026-07-21）

> 依据：airaccount-contract v0.27 / YetAnotherAA + aNode DVT v1.12 / SuperPaymaster v5.4 / AirAccount KMS 代码考古 + file:line 级核实（加权多签实现已逐行验证）
> 配套选题分析见 `paper-topics-proposal-2026-07.md`
> 摘要中的数字均来自仓库实测记录（成稿前需按论文 commit pin 重新采集）
> 覆盖 6 篇 thesis 中的 4 篇（Ch3/Ch4/Ch5/Ch8）；Ch6 AOA 已投 BRA、Ch7 RepCredit 见 paper7-CommunityFi 目录，各有独立底稿。canonical 命名见 `master-paper-roadmap-2026-07.md` §0。

---

## Onion (Thesis Ch3) — 洋葱安全模型

**Title**
*The Onion Security Model: On-Chain Enforcement of Asset-Proportional Multi-Factor Authorization for Smart Contract Accounts*

**Alternative title**
*Peeling by Value: Tiered Cryptographic Factor Escalation for ERC-4337 Smart Accounts*

**Keywords**
account abstraction; ERC-4337; smart contract wallet; tiered security; multi-factor authorization; WebAuthn passkey; threshold BLS signatures; security policy enforcement

**Abstract**

Self-custodial blockchain accounts enforce a single authorization policy regardless of transaction value: the same signature that spends one dollar can drain a user's entire savings. Existing smart-contract wallets bound spending through rate limits or time delays, but never escalate the *cryptographic strength* required as value at risk grows. We present the Onion Security Model, a design theory holding that account security should be layered in proportion to asset exposure, and its on-chain instantiation in AirAccount, an ERC-4337 smart account deployed on Ethereum testnets. The artifact maps transaction value to three enforced authorization tiers — single-factor (passkey or ECDSA), dual-factor (adding a distributed BLS threshold co-signature), and triple-factor (adding guardian approval) — with three anti-bypass mechanisms: tier resolution over cumulative daily spending to defeat transaction splitting; security thresholds sealed into the account's CREATE2 deployment salt so that weakening requires a guardian quorum with a time lock; and transient-storage binding of the validation and execution phases. Iterative evaluation surfaced a previously undocumented attack class for modular ERC-4337 accounts — validation–execution tier decoupling, where a UserOperation validates at a low tier but executes a high-tier action — which we characterize and mitigate. Following Design Science Research methodology, we evaluate the artifact through nine deployment iterations on Ethereum Sepolia, a 900-case unit test suite, 31 on-chain end-to-end scenarios, live UserOperations via commercial bundler infrastructure, and per-tier gas measurements, showing that asset-proportional factor escalation is practical within mainstream account-abstraction infrastructure.

---

## Weighted (Thesis Ch4) — 加权多因子账户与防弱化治理

**Title**
*Flexible but Never Weaker: A Weighted Multi-Factor Smart Account with Anti-Weakening Governance and Quorum-Controlled Recovery*

**Alternative title**
*Weighted Multi-Factor Authorization for Smart Accounts: Configurable Security Templates, Anti-Weakening Governance, and Passkey-Guardian Recovery*

**Keywords**
weighted multi-signature; multi-factor authentication; smart contract account; security configuration governance; social recovery; WebAuthn guardian; EIP-7212; account abstraction

**Abstract**

User-configurable account security faces a dilemma: rigid factor policies cannot fit both novices and traders, while free configurability lets an attacker — or a careless owner — weaken the account from inside. We present a weighted multi-factor smart account architecture that resolves this tension with three mechanisms, all implemented and tested on-chain. First, a *weighted authorization scheme*: six independent factors (P-256 passkey, owner ECDSA, distributed BLS threshold co-signature, and up to three guardians) carry individually configurable weights; a bitmap-encoded signature bundle accumulates weights on-chain and resolves to one of three authorization tiers, letting arbitrary factor combinations substitute for one another under explicit thresholds. Reference templates (beginner, trader, conservative) give mainstream users safe defaults without forfeiting configurability. Second, *anti-weakening governance*: a configuration validator enforces structural invariants — no single factor may reach the first threshold, and the owner-exclusive factor subset can never reach the highest tier — while any weakening change (raising a weight or lowering a threshold) is rejected unless it passes an owner proposal, approval by two guardians, a two-day time lock, and a thirty-day expiry; strengthening changes apply immediately. Third, *quorum-controlled recovery*: passkey-capable guardians recover the account through a 2-of-3 vote with a 48-hour time lock, where cancellation itself requires a quorum and the owner alone cannot veto — neutralizing an adversary who has stolen the owner key. We evaluate the artifact on Ethereum Sepolia through Design Science Research iterations, including a dedicated 49-case weighted-signature test suite, full recovery-path testing, and gas measurements, and derive design principles for accounts that are flexible for users yet monotonically non-weakening against attackers.

---

## DVT (Thesis Ch5) — DVT 语义迁移 + 全链上 BLS 验证

**Title**
*From Consensus Duties to Account Policies: Repurposing Distributed Validator Technology as a Transaction-Semantic Second Factor for ERC-4337 Accounts*

**Alternative title**
*Should This Be Signed? Policy-Aware Distributed Co-Signing with Fully On-Chain BLS Verification for Smart Accounts*

**Keywords**
distributed validator technology; BLS12-381; threshold signatures; hash-to-curve; EIP-2537; account abstraction; transaction policy enforcement; key compromise resilience

**Abstract**

Distributed Validator Technology (DVT) as deployed by consensus-layer protocols distributes *blind* signing duties: nodes attest to whatever the protocol schedules, never judging content. We argue this blindness squanders DVT's potential at the account layer, where the decisive question is not "is this signature valid?" but "should this transaction be signed at all?" We present aNode, a DVT network repurposed as a transaction-semantic second factor for ERC-4337 smart accounts: even an adversary holding the owner's private key cannot move funds without convincing a threshold of independent policy-enforcing nodes. Each node passes a candidate UserOperation through three gates — fail-closed owner authentication against the on-chain account, a two-layer policy conjunction combining node-local floors (per-transaction caps, whitelists, immutable to the account owner) with an on-chain per-account policy registry whose relaxations are time-locked, and out-of-band confirmation for large transfers. Approving nodes produce BLS12-381 partial signatures that aggregate off-chain and verify *fully on-chain*: we port RFC 9380 hash-to-curve to the EVM over the EIP-2537 precompiles, recomputing the message point on-chain to bind signatures to the UserOperation hash, and derive a dynamic gas model validated by measurement (~450k gas for three-signer verification; ~653k for a complete three-node UserOperation). A gossip-based quorum protocol lets nodes audit peers for liveness and over-issuance, escalating objective evidence into threshold-signed, two-step on-chain slashing. Evaluated on Ethereum Sepolia with a three-node reference deployment, cross-language conformance vectors, and commodity edge hardware (Raspberry Pi, STM32MP157F), aNode demonstrates that consensus-layer fault-tolerance machinery can be re-grounded as programmable, owner-independent transaction policy for everyday accounts.

---

## AgentPay (Thesis Ch8) — Agent 支付与受限自治密钥

**Title**
*Accountable Autonomy: Reputation-Gated Gas Sponsorship and TEE-Bound Delegated Keys for AI-Agent Payments on Account Abstraction Rails*

**Alternative title**
*Paying Like a Person, Audited Like a Machine: An On-Chain Payment Stack for Autonomous AI Agents*

**Keywords**
AI agents; machine-to-machine payments; account abstraction; ERC-8004; paymaster; trusted execution environment; delegated authorization; micropayment channels; x402

**Abstract**

Autonomous AI agents increasingly need to transact — paying for gas, APIs, and services — yet today they either borrow a human's unrestricted keys or depend on centralized billing intermediaries, making autonomy unaccountable and delegation unsafe. We present an integrated on-chain payment stack for AI agents built on Ethereum account abstraction, deployed on testnet. The artifact contributes three mechanisms. First, *reputation-gated sponsorship*: a paymaster grants gas sponsorship through dual eligibility — soulbound community membership or registration in an ERC-8004 agent identity registry — with per-operator tiered fee rates, daily USD caps, and an on-chain feedback loop that reprices an agent's sponsorship as its behavioral reputation evolves; the validation path is engineered to satisfy ERC-7562 associated-storage rules, preserving compatibility with permissionless bundlers. Second, a *human-to-agent delegation chain*: a human authorizes agent keys through a WebAuthn ceremony inside a trusted execution environment, which issues verifiable credentials binding the agent key to its principal; a single user gesture yields a TEE dual signature (P-256 passkey plus TEE-held ECDSA) under a contract-enforced invariant that no single factor can authorize spending alone — so agents act autonomously within cryptographically delegated, revocable bounds. Third, *unified settlement*: gas sponsorship, HTTP-402 (x402/EIP-3009) pay-per-call, and EIP-712 micropayment channels with dispute windows share one credit–debt settlement layer with balance-aware credit ceilings. Following Design Science Research methodology, we evaluate the stack on Ethereum Sepolia with a 400-case test suite, property-based fuzzing, adversarial audit rounds, and a published SDK, and distill design principles for payment infrastructure where machine autonomy remains human-accountable.
