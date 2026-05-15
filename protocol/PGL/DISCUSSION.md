# PGL — Public Goods License 讨论文档

> 创建：2026-05-15 · 状态：构想阶段
> 这是一份**讨论稿**，不是定稿。结论尚未形成。

---

## 1. 问题陈述（用户原话提炼）

开源社区有两个长期失衡：

| 失衡 | 表现 |
|:---|:---|
| **A. 用户信息差/能力差** | GitHub 上有免费的 PDF 扫描模型、电子宠物、PPT 工具，但普通人不会 clone/build/安装，享受不到 |
| **B. 套利者抢夺归属与收益** | 一些人把开源项目稍加包装就在淘宝/小红书卖钱，部分还**抹掉原作者署名声称自创**（违反 Apache 2.0 NOTICE 条款，但无人追究） |

**目标**：
1. 弥补「信息差」→ 让普通人能像用 App Store 一样获取开源数字公物
2. 弥补「归属/收益差」→ 套利者无法独占信息差的红利，原作者得到 reputation + 收入回流

---

## 2. 我的初步判断（要跟你对线）

**核心观点：你想解决的不是「license 问题」，而是「分发渠道 + 归属链 + 收益路由」三件套问题。**

理由：

1. **法律层面**：Apache 2.0 已经强制 NOTICE 保留 + 不允许抹掉署名。淘宝卖家抹署名其实已经违法，问题是**没人起诉**（个人开发者没精力没钱）。
2. **MIT 的署名条款**：MIT 也要求保留 copyright notice。所以"抢署名"在两个许可证下都不合法。
3. **限制商业转售的尝试都翻车了**：Commons Clause（Redis）、SSPL（MongoDB）、BUSL（MariaDB）、Anti-Capitalist License、Hippocratic License —— 全部被 OSI 判定为「非开源」，导致主流生态边缘化。
4. **历史经验**：试图发明一个"既开源又限制商业"的 license 几乎没有成功案例。最接近成功的是 **PolyForm** 和 **Fair Source**，但它们也只在小范围使用。

**所以我建议：**

> **PGL 不应该是一个新的法律 license，应该是一个「兼容性规范 + 分发渠道 + 链上归属/收益层」**。

法律层继续用 Apache 2.0（已经够强）。PGL 是叠加的**社会经济层**，靠以下三件套生效：

```
┌─────────────────────────────────────────────────┐
│ 法律层：Apache 2.0（不动，OSI 兼容，无法律风险）     │
├─────────────────────────────────────────────────┤
│ 社会契约层：PGL Charter（自愿签署的"公物精神宣言"）   │
├─────────────────────────────────────────────────┤
│ 技术层 1：PGL Manifest（pgl.yml 元数据规范）        │
│   定义如何被 App Store 打包、运行、攻击署名链        │
├─────────────────────────────────────────────────┤
│ 技术层 2：链上归属与收益路由（SuperPaymaster + SBT）│
│   每次安装/使用 → 链上记录 → 收入按 Manifest 分账   │
├─────────────────────────────────────────────────┤
│ 分发层：PGL Store（一键安装 App Store）             │
│   只收录签署 Charter 的项目；劣币（淘宝套利）拿不到流量│
└─────────────────────────────────────────────────┘
```

「治套利者」的真正杠杆**不是法律**，而是**分发渠道的稀缺性**。淘宝卖家可以继续卖，但 PGL Store 不收他 → 用户主流量都被 PGL Store 截走 → 套利者只能去触达低信任的渠道。

---

## 3. 前置参考（避免重复造轮子）

| 类别 | 项目 | 启示 |
|:---|:---|:---|
| **失败的限制式 license** | Commons Clause / SSPL / BUSL | 被 OSI 判 non-open，社区抵制。**避免重蹈覆辙。** |
| **道德条款 license** | Hippocratic License | 法律可执行性弱，但社区认同有一定作用。 |
| **OSS 公共品融资** | Gitcoin Grants（二次方融资）、Optimism RetroPGF | 证明「事后基于 reputation 分配资金」是可行路径 |
| **OSS 收益路由** | drips.network（Streaming OSS funding） | 已经做了链上自动按依赖关系分账，技术参考价值极高 |
| **OSS App Store** | F-Droid、Snap Store、Homebrew Cask | 分发渠道为开源项目带来用户的成功先例 |
| **属性链** | OpenChain（Linux Foundation 供应链合规标准） | 企业级 OSS 供应链溯源参考 |
| **可借鉴 license** | PolyForm Project 套件 | 模块化条款（非商业、限制竞争、Shield 等），比从零写 license 风险低 |

---

## 4. 三层结构具体设计（粗稿，等你回应再细化）

### 4.1 PGL Charter（社会契约层）

不是法律文本，是一份 ~500 字的「精神宣言」，作者签名（GitHub commit）即视为加入。

**核心 5 条原则**：

1. **可访问性承诺（Accessibility）**：作者保证自己的工作有合理途径让非技术用户使用（不一定亲自做，但允许社区做封装并保留署名）
2. **归属链不可断（Attribution Chain）**：任何下游再分发、再包装必须保留 NOTICE + 在 PGL Manifest 中声明 upstream
3. **公允收益分配（Fair Value Routing）**：通过封装、转售获利的下游应通过 PGL Manifest 申报，按预设比例（建议 30-50%）回流上游
4. **拒绝信息差套利（No Information Asymmetry Rent）**：禁止以「自己原创」名义售卖明显是封装他人工作的产品
5. **反 Charter 行为的社会惩罚（Reputation Slash）**：违反者在 PGL Store 中被标记，丧失推荐位

### 4.2 PGL Manifest（技术规范层）

一个 `pgl.yml` 文件，放在 repo 根目录：

```yaml
pgl_version: "0.1"
work:
  name: "Awesome PDF Scanner"
  type: ["app", "model", "skill"]   # app/model/library/skill/dataset
  base_license: "Apache-2.0"
  charter_signed: true
  charter_signed_at: "2026-05-15"
  signed_by: "0xAuthor_AirAccount_Address"

attribution:
  authors:
    - name: "Alice"
      sbt: "0x..."          # 链上声誉 SBT
      revenue_share: 70     # 70% to original author
  upstreams:                 # 我借鉴/依赖的上游 PGL 作品
    - work: "github.com/foo/pdf-core"
      share: 20             # 20% 上游分账
    - work: "github.com/bar/ocr-model"
      share: 10

distribution:
  app_store_compatible: true
  installer_type: "one-click"   # one-click | cli | docker
  end_user_friendly: true

monetization:
  tier_free: true               # 必须有免费层
  tier_paid:
    price_pnts: 100             # 用 OpenPNTs 计价
    price_usd_equivalent: 1.0
  revenue_routing:
    contract: "0xPGL_Router_Sepolia"
    splits_locked: true         # 一旦发布，分配比例不可改

verification:
  signature: "0x..."             # 作者用 AirAccount 签名
  proof_of_open_source: "github.com/alice/pdf-scanner"
```

### 4.3 PGL Store + 链上层（分发与执行）

**架构（融合 Mycelium 生态现有基础设施）**：

```
PGL Store (Web/Mobile App)
   │ 1. 用户浏览/搜索/一键安装
   ▼
PGL Registry (链上索引合约)
   │ 2. 验证 Manifest 签名 + Charter 状态
   ▼
作者 SBT（链上声誉，复用 SuperPaymaster v5 SBT 系统）
   │ 3. 安装/使用记录 → 累积 reputation score
   ▼
PGL Revenue Router (智能合约)
   │ 4. 用户付费/打赏 → 按 Manifest 中 splits 自动分账
   ▼
作者 AirAccount + Upstream AirAccounts
   │ 5. xPNTs / 稳定币到账
   ▼
Gas 抽象（SuperPaymaster 赞助小额用户支付）
```

**生态现有积木复用**：
- **AirAccount**：作者+用户账户（passkey 登录，无门槛）
- **SuperPaymaster v5**：Gas 赞助 + xPNTs 积分 + SBT 声誉 + Agent 注册（PGL Store 注册为 Agent）
- **CometENS**：作者命名 `alice.pgl.eth`
- **OpenPNTs**：通用积分协议作为定价基础

**完全不需要发新链，复用 Mycelium Protocol 现有合约即可。**

---

## 5. 与 Agent24 的关系

你提到 Agent24 会引入符合 PGL 的开源公物作为 Skill。这就是 **PGL Store + Agent24 = 双向赋能**：

- Agent24 = **PGL Store 的官方客户端**（其中一个）
- PGL Store 收录的 skills → 自动可装入 Agent24
- 用户在 Agent24 中调用某 skill → 链上记录 → 收益分给原作者

这让 PGL Store 有了**杀手级 distribution**（嵌在 AI agent 流量中），而 Agent24 有了**杀手级内容供应**（持续吸纳 GitHub 优质开源工具）。

---

## 6. 弹性 vs 约束（你提到的关键张力）

| 维度 | 弹性方案（推荐） | 约束方案 |
|:---|:---|:---|
| **签 Charter** | 完全自愿，签了拿 PGL Store 推荐位 | 强制（OSI 不答应） |
| **分账比例** | 作者自己设定 splits，不强制 | 强制 30% 回流上游 |
| **基础 license** | 兼容任何 OSI license | 必须 Apache-2.0 |
| **商业转售** | 允许（但要 Manifest 申报 + 分账） | 禁止商业 |
| **违规处罚** | 失去 PGL Store 推荐位 + 声誉标记 | 法律追究（不现实） |

**我倾向全弹性方案**：约束做在「分发渠道」一层（不进 PGL Store 等于隐形惩罚），而非进入 license 法律条文。这样既不引战，又有实际杠杆。

---

## 7. 落地路径（粗稿）

**Phase 1（2-4 周）**：写规范 + Charter 0.1
- `pgl.yml` schema
- Charter 文本（中英双语）
- 注册第一批种子项目（从 Mycelium 生态自己的 repo 开始：Brood / AirAccount / CometENS）

**Phase 2（1-2 月）**：链上合约 + Registry
- 部署 PGL Registry / Revenue Router（Sepolia 先行）
- 复用 SuperPaymaster v5 角色体系（注册 PGL Author 角色）
- 用 SBT 跟踪 reputation

**Phase 3（2-3 月）**：PGL Store MVP
- Web 端（搜索 + 一键安装 + 打赏）
- 移动端可选（PWA 即可）
- Agent24 集成（PGL skills 直接可装）

**Phase 4（持续）**：生态扩展
- 邀请外部 GitHub 项目签 Charter
- 建立 Curator 角色（社区策展人，挑选优质工具）
- Quadratic funding 引入（学 Gitcoin）

---

## 8. 风险与挑战

| 风险 | 等级 | 缓解 |
|:---|:---:|:---|
| 没人签 Charter（启动困难） | 高 | 自家生态先全签，做出榜样；提供切实分发流量奖励 |
| 被 OSI 社区抵制为「假开源」 | 中 | 不动 base license，PGL 明确定位为"补充层而非替换层" |
| 链上分账被规避（链下交易） | 中 | 接受灰色地带；只保证「主流量主收益」走 PGL，不追求闭环 |
| 中心化风险（PGL Store 成为新巨头） | 中 | DAO 治理 + Open Manifest，允许第三方建客户端 |
| 跨境法律差异 | 低 | Charter 不是法律文件，规避大部分管辖问题 |

---

## 9. 待你回应的 5 个关键分叉点

我把判断的责任留给你，**请逐项回应**：

### Q1. PGL 是「叠加层」还是「替换层」？
- **A. 叠加层**（我推荐）：法律层保持 Apache 2.0，PGL 是社会经济层。OSI 兼容，启动友好。
- **B. 替换层**：发明完整新 license。OSI 不会认证，但表达更纯粹。

### Q2. 强制 vs 完全自愿？
- **A. 完全自愿 + 渠道奖励**（我推荐）：签 Charter 即获 PGL Store 推荐位/收益路由，不签可继续 Apache 2.0 单独运作。
- **B. 强制 NOTICE + 强制分账**：写入合约，未签不能上 Store。

### Q3. 分发渠道是 webapp 还是嵌入 Agent24？
- **A. 双轨**：独立 PGL Store（web）+ Agent24 内嵌（推荐）
- **B. 只在 Agent24 内**：起步快，但天花板低
- **C. 只独立 Store**：触达广但缺杀手级场景

### Q4. 收益路由要不要强制上链？
- **A. 强制链上**（chain-native，透明）：用 SuperPaymaster + AirAccount 走完整链上结算。Gas 由 Paymaster 赞助。
- **B. 链下也行**：Manifest 声明分账比例，链下转账也算「履约」。技术门槛低，但难审计。

### Q5. 第一阶段「最重要的一件事」？
- **A. 写规范 + 自家生态先签**（基础建设优先）
- **B. 先做 Agent24 内的 PGL skill 装载体验**（用户场景优先）
- **C. 先做链上 Registry + Revenue Router**（资金路由优先）

---

## 10. 我的整体倾向（一句话）

**「不发明新 license，发明一套 "Charter + Manifest + Store + 链上路由" 的叠加层」**，把 Mycelium 生态现有的 AirAccount / SuperPaymaster / OpenPNTs / CometENS 直接复用为基础设施 —— 这是 Mycelium Protocol 的天然延伸，而不是另起炉灶。
