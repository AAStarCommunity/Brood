# 数字公共物品公约 / Digital Public Goods Charter

> 版本：v0.1（草稿）
> 起草：Mycelium Protocol 社区
> 最后更新：2026-05-15

---

## 中文版本

### 前言

我们相信，软件、模型、数据、知识等数字成果，可以像清洁的空气、公共的道路、社区的花园一样，成为人人可享的**数字公共物品**。

许多开源贡献者已经为世界做了大量工作，但他们的成果常常因为安装复杂、缺少封装而无法被普通人使用；同时，少数人利用信息差和能力差，抹去原作者的署名、稍加包装就拿去赚钱，对原贡献者既不公平，也辜负了开源的初衷。

本公约的目的，是为愿意把自己的工作视为**数字公共物品**的贡献者，建立一个**自愿签署的共同承诺**：

我们的工作面向所有人，原作者的署名和贡献必须被记录，下游的商业收益要按公平比例回流上游。

签署本公约**不会改变你原有的开源协议**（Apache 2.0 / MIT / GPL 等），它是叠加在原协议之上的**社会经济层共识**，让所有签署者共同进入「数字 Agent 商店」分发渠道并享受链上分账。

### 五条共同承诺

签署本公约的贡献者承诺：

**第一条 · 可访问性承诺**
我承诺为我的工作提供合理的使用途径，让非技术用户也能受益。如果我本人没有时间完成最终封装，我允许社区按本公约的规范代为封装，前提是保留我的署名。

**第二条 · 署名不可抹除**
任何对我工作的再分发、再封装、再销售，必须在显著位置保留我的署名和原始仓库链接。这也是 Apache 2.0、MIT 等开源协议的既有要求，本公约重申并通过分发渠道予以强化。

**第三条 · 公允版税回流**
对我工作的商业化销售，应通过本公约的 `pgl.yml` 文件声明分配比例，并通过链上路由合约自动结算。默认建议：**作者 70% / 上游依赖 20% / 分发渠道 10%**，可在 `pgl.yml` 中调整。

**第四条 · 拒绝信息差套利**
我不会以「自己原创」的名义出售明显基于他人公约作品的封装产品；我也理解，如果我违反此条，将失去「数字 Agent 商店」的推荐位与分账资格。

**第五条 · 透明记录与社会问责**
所有依据本公约产生的下载、使用、销售记录都将上链可查。违反公约的行为不依赖法律追究，而通过社区可见的声誉记录与分发渠道的访问控制来约束。

### 签署方式

签署本公约的方式很简单：在你的项目根目录添加一个 `pgl.yml` 文件，将其 `charter_signed` 字段标记为 `true`，并用你的 AirAccount 地址签名。

详见 [`MANIFEST_SPEC.md`](./MANIFEST_SPEC.md) 与 [`ONBOARDING.md`](./ONBOARDING.md)。

### 关于本公约的弹性

本公约**完全自愿**。你可以：
- 不签署，继续按原 Apache 2.0 / MIT / GPL 协议自由分发
- 签署，但拒绝商业分发模式（设置 `tier_paid: null`）
- 签署，使用默认 70/20/10 比例
- 签署，自定义你的分账比例（例如全部 100% 给到某公益基金）

公约的执行**不依赖法律强制**，而是依赖签署者共同认可的**分发渠道激励 + 链上记录可见性 + 社区声誉约束**。

---

## English Version

### Preamble

We believe that software, models, datasets and knowledge — like clean air, public roads and community gardens — can become **digital public goods** that anyone may freely benefit from.

Many open-source contributors have already done remarkable work for the world, yet their results often fail to reach ordinary users due to installation complexity or missing packaging. At the same time, a small number of people exploit this information gap, strip away the original author's attribution, repackage the work with minor changes, and sell it — unfair to the original contributors and contrary to the spirit of open source.

This Charter establishes a **voluntary, shared commitment** for contributors who wish to treat their work as **digital public goods**:

Our work is for everyone, the attribution of original authors must be preserved, and downstream commercial revenue must be routed back upstream in fair proportions.

Signing this Charter **does not replace your existing open-source license** (Apache 2.0 / MIT / GPL etc.). It is a **socio-economic consensus layer** layered on top, giving all signers access to the "AgentStore for Public Goods" distribution channel and on-chain royalty routing.

### Five Commitments

By signing, contributors commit:

**Article 1 · Accessibility Commitment**
I commit to providing a reasonable path for non-technical users to benefit from my work. If I do not have time to produce the final packaging myself, I permit the community to do so under this Charter, provided my attribution is preserved.

**Article 2 · Attribution is Inviolable**
Any redistribution, repackaging or resale of my work must prominently preserve my attribution and a link back to the original repository. This is already required by Apache 2.0, MIT and similar licenses; this Charter restates the requirement and enforces it through the distribution channel.

**Article 3 · Fair Royalty Routing**
Commercial sales of my work must declare a split through the `pgl.yml` file and settle automatically through the on-chain royalty router. Default suggestion: **Author 70% / Upstream Dependencies 20% / Distribution Channel 10%**, adjustable via `pgl.yml`.

**Article 4 · No Information-Asymmetry Arbitrage**
I will not sell repackaged products that are obviously derived from others' Charter-signed work under the claim of "original authorship". I understand that violating this clause will cost me my placement and royalty rights in the AgentStore.

**Article 5 · Transparent Records and Social Accountability**
All downloads, usage and sales records under this Charter will be recorded on-chain and publicly queryable. Violations are not enforced through legal means but through community-visible reputation records and distribution-channel access control.

### How to Sign

Add a `pgl.yml` file to the root of your project, set the `charter_signed` field to `true`, and sign it with your AirAccount address.

See [`MANIFEST_SPEC.md`](./MANIFEST_SPEC.md) and [`ONBOARDING.md`](./ONBOARDING.md) for details.

### On Flexibility

This Charter is **entirely voluntary**. You may:
- Not sign, and continue under your original Apache 2.0 / MIT / GPL license
- Sign but disable commercial distribution (set `tier_paid: null`)
- Sign and use the default 70/20/10 split
- Sign and customize your split (e.g., route 100% to a charity fund)

The Charter is **not enforced by law**, but through **distribution-channel incentives + on-chain visibility + community reputation accountability**, all of which the signers mutually agree to honor.

---

## 公约变更 / Charter Versioning

本公约通过 Mycelium Protocol DAO 治理流程修订。重大变更需 30 天公开评议期 + 多签批准。

This Charter is amended through Mycelium Protocol DAO governance. Major changes require a 30-day public review and multi-sig approval.

| 版本 | 日期 | 变更 |
|:---|:---|:---|
| v0.1 | 2026-05-15 | 初稿 |
