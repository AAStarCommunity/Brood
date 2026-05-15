# PGL 收益模型 / Revenue Model

> 版本：v0.1（草稿） · 最后更新：2026-05-15

---

## 1. 设计原则

PGL 的收益模型必须同时满足三个原则：

1. **作者拿大头** —— 创作者的回报必须显著高于分发渠道，避免重蹈"中间商赚差价"的覆辙
2. **上游不被遗忘** —— 凡是借鉴/依赖的上游公约作品，自动获得回流，建立可持续的开源生态
3. **法律安全** —— 任何收益分配机制都必须避开证券化（避免 share / 股份 / 收益权代币等敏感设计）

---

## 2. 默认 70 / 20 / 10 分配

| 接收方 | 比例 | 性质 | 法律定性 |
|:---|:---:|:---|:---|
| **作者**（manifest 中 `royalty.authors`） | **70%** | 软件销售分成 | 普通商品销售收入 |
| **上游依赖**（manifest 中 `royalty.upstreams`） | **20%** | 知识产权使用费（类似版税） | 类似图书/音乐版税 |
| **分发渠道**（AgentStore） | **10%** | 平台运营佣金 | 类似 App Store 30% 中的运营服务费 |

**法律定性的重要性**：这三笔款项都对应**成熟的商业合同类型**（销售分成 / 版税 / 平台佣金），既无证券属性，也有清晰的税务处理路径。我们刻意**不发行任何代表收益权的代币**，避免触碰证券监管红线。

---

## 3. 可调整空间

`pgl.yml` 允许作者在以下边界内调整默认比例：

| 场景 | 允许的调整 |
|:---|:---|
| **无上游依赖** | 作者可拿 90%，渠道 10%（上游 20% 转给作者） |
| **多个共同作者** | 作者总额 70% 内部分配，比例自定 |
| **多个上游依赖** | 上游总额 20% 按 manifest 中各 upstream 的相对比例分配 |
| **作者主动让利** | 可降低自己比例，将差额转给指定地址（如公益基金、上游） |
| **渠道比例** | 固定 10%，不可降低（这是 AgentStore 的运营成本底线） |
| **完全免费作品** | 无销售时分账机制不激活，仅累积声誉 |

**作者不能做的事**：
- 不能把作者比例设为 0%（这意味着滥用渠道做免费推广，被禁止）
- 不能让上游比例为 0%（如果声明了 `upstreams`）
- 不能改变三方分账模型本身（如想要四方分账，需向 PGL DAO 提案）

---

## 4. 收益的形态

收益结算单位是**双轨制**：

### 4.1 法币锚定通道（OpenPNTs）

- 用户在 AgentStore 用 `xPNTs`（OpenPNTs 协议下的稳定积分）支付
- `xPNTs` 1:1 锚定 USD，可在合作交易所或 Mycelium 内部市场兑换为人民币 / USDC / ETH
- 适合普通用户场景：定价直观（"¥1 一次"）

### 4.2 原生加密通道

- 高级用户可直接用 USDC / ETH 支付，跳过 xPNTs
- 链上路由合约自动按比例分配
- Gas 费由 SuperPaymaster 赞助（降低用户摩擦）

无论哪种通道，**作者最终都可以一键提现到法币账户**（通过合作出金通道），或自行保留链上资产。

---

## 5. 链上路由合约接口（草案）

```solidity
// PGLRoyaltyRouter.sol（简化版伪代码）

interface IPGLRoyaltyRouter {
    /**
     * @notice 用户购买作品时调用，将支付按 manifest 中的比例自动分发
     * @param workSlug 作品 slug
     * @param payToken 支付代币地址（xPNTs / USDC / 0x0 表示 ETH）
     * @param amount 支付金额
     */
    function settle(
        string calldata workSlug,
        address payToken,
        uint256 amount
    ) external payable;

    /**
     * @notice 作品注册：根据 pgl.yml 内容创建分账规则
     * @param manifestHash manifest 的 SHA-256
     * @param authorSplits 作者分账列表
     * @param upstreamSplits 上游分账列表
     * @param channelAddress 渠道地址
     */
    function registerWork(
        bytes32 manifestHash,
        Split[] calldata authorSplits,
        Split[] calldata upstreamSplits,
        address channelAddress
    ) external;

    struct Split {
        address recipient;
        uint16 basisPoints;  // 1/10000；如 7000 = 70%
    }
}
```

**关键设计**：
- 合约本身不持有资金（pass-through），降低被攻击的资产敞口
- 分账规则不可变（`splits_locked: true` in manifest）—— 一旦发布，作者无法事后改分配比例
- 作者升级版本 = 新 manifest = 新 workSlug 版本号 = 新合约记录

---

## 6. 声誉（非货币）回馈

对**免费层**作品，没有现金分账，但仍累积**链上声誉**：

| 用户行为 | 作者获得 |
|:---|:---|
| 安装作品 | +1 install count（写入作者 SBT） |
| 7 天后仍在用 | +1 active retention（SBT 加权） |
| 点赞 / 推荐 | +1 endorsement |
| 把作品推荐给好友（带链上 referrer 标记） | +1 viral score |
| 在 AgentStore 撰写测评 | +1 review，附评分（1-5） |

**声誉的用途**：
- AgentStore 推荐排序的核心信号
- 解锁 PGL DAO 治理投票权（声誉门槛）
- Mycelium Protocol 生态内的"信任凭证"（如申请 OpenPNTs 信用额度）

---

## 7. 反套利与边界

| 套利场景 | 防御机制 |
|:---|:---|
| 套利者复制公约作品，自己重新签 manifest 卖钱 | manifest 校验时强制声明 upstream；不声明被发现 → 标记 + 下架 |
| 套利者把作品搬到 AgentStore 之外卖（如淘宝）| 不可技术阻止；但因失去 AgentStore 流量与一键支付便利，竞争劣势明显 |
| 自买自卖刷量获取声誉 | 声誉算法只认有真实安装+留存的用户；可疑模式触发 DAO 审查 |
| 滥用免费层"绑架"用户（强制看广告等）| Charter 第一条不允许；用户可举报 → DAO 审查 → 降权或下架 |

---

## 8. 税务建议

**作者侧**：作者收到的款项性质是 **软件销售分成**，按个人/企业经营所得申报。中国境内作者建议设立工作室或个体户简化申报。

**渠道侧**：AgentStore 由 Mycelium Protocol DAO 运营，10% 渠道佣金作为运营收入，由 DAO 合规主体接收并申报。

**上游侧**：上游收到的是 **知识产权使用费 / 类版税收入**，与图书出版业的版税申报路径一致。

具体合规操作以 PGL DAO 后续发布的《税务与合规手册》为准。

---

## 9. 历史决议

| 决议 | 日期 | 来源 |
|:---|:---|:---|
| 默认 70/20/10 比例 | 2026-05-15 | 与项目发起人讨论确定 |
| 避免使用 "share" / 收益权代币 | 2026-05-15 | 法律安全考虑 |
| 渠道比例下限 10% 不可降 | 2026-05-15 | 保障运营可持续 |
