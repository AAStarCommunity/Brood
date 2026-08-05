# Cloudflare vs 官方定价 · API vs Coding Plan 选型分析

> 分析日期:2026-08-05 · 前置文档:[`README.md`](README.md)(Cloudflare Workers AI 开源模型可用性调研)
>
> **要回答的问题**:Claude Code 的 $200 订阅已经不够用。如果改用 Cloudflare 上的 GLM-5.2 或
> Kimi K3,相比各家官方定价有没有成本优势?用 API 方式做 PR 评审和日常开发,够不够?
> 还是应该单独订一份 Kimi / GLM 的 coding plan?

---

## 结论先行

**Cloudflare 没有价格优势 —— 它照搬官方牌价,一分没便宜,而且还吃不到官方的缓存和批处理折扣。**

**正确的做法是把两件事拆开办,别用一个方案覆盖:**

| 用途 | 方案 | 月成本 |
|:---|:---|---:|
| **日常开发**(交互式) | **GLM Coding Plan Max** | $160(促销 $112) |
| **PR 评审 / 无人值守**(程序化) | **Moonshot 官方 API `kimi-k2.7-code`** | $30–76 |
| | **合计** | **$190–240** |

同样的钱,配额和能力都比现在这一份 $200 强。

**但在花钱之前,先看第 0 节** —— 你 $200 不够用的原因很可能不是配额不足,而是计费口径变了。

---

## 0. 一个可能比价格更关键的发现

**2026-06-15 起,Claude Code 的非交互用量不再吃订阅配额,改走一笔独立的 $200/月额度。**
适用范围:Agent SDK、`claude -p`、GitHub Actions、以及跑在你订阅上的第三方 app。

本仓库这套东西 —— `/loop 10m pilot run` 通宵推进、后台评审循环 —— **正好全部落在非交互口径里**。

**这意味着:如果你的 $200 是被无人值守跑掉的,再买一份订阅也会撞同一堵墙**,因为这类负载在任何厂商
那里都不属于订阅制的设计目标。正确的动作是**把无人值守那部分挪到 API 计费**,而不是加订阅。

> **行动项**:先确认消耗构成 —— 是你自己敲出来的,还是后台循环跑掉的。这决定了下面走哪条路。

---

## 1. 价格对照

### 1.1 Cloudflare 与官方逐分对齐

单位:美元 / 每百万 tokens(输入 / 输出)

| 模型 | Cloudflare Workers AI | 官方 first-party | 结论 |
|:---|---:|---:|:---|
| **GLM-5.2** | $1.40 / $4.40 | Z.ai **$1.40 / $4.40** | **完全相同** |
| **Kimi K2.7-code** | $0.95 / $4.00 | Moonshot **$0.95 / $4.00** | **完全相同** |
| **Kimi K3** | dashboard 才可见,文档不公布 | Moonshot **$3.00 / $15.00** | **未知,待查** |

Cloudflare 不是转售折扣,是**照搬官方牌价**。

### 1.2 走 Cloudflare 还会丢掉两个大折扣

官方 API 有、而 Cloudflare 没有公开对应价格的:

| 折扣 | 幅度 | 说明 |
|:---|:---|:---|
| **Moonshot 缓存命中** | K2.7-code → **$0.19/M**(-80%)<br>K3 → **$0.30/M**(-90%) | OpenRouter 实测 K3 流量 **92% 命中率**,<br>有效输入价约 **$0.52/M**,是牌价的 1/6 |
| **Moonshot Batch API** | **六折** | 适合离线批量评审 |

Cloudflare 在 2026-03-19 的 changelog 里上线了 prompt caching,但**没有公布对应的折扣价**。
在拿到 dashboard 实测数据之前,只能按无折扣计。

**这一条决定性地反转了对比**:评审是高度重复上下文的负载(同一个仓库、同一份 diff 反复评多轮),
缓存命中率天然很高 —— 而这正是 Cloudflare 拿不出价格承诺的地方。

### 1.3 一条反常数据:OpenRouter 比一方还便宜

**OpenRouter 的 GLM-5.2 报价 $0.406 / $1.276** —— 比智谱自己便宜 3 倍多。

这种价格通常意味着量化档位或路由策略与一方不同。**用于评审前必须先实测质量**,
不能只看价格就切过去。列在这里是为了完整,不作为推荐。

---

## 2. 成本模型

### 假设(明确写出,便于你自己调)

- **一次 PR 评审** = 输入 ~100K tokens(仓库上下文 + diff + 历史评审)、输出 ~8K tokens。
  依据是本仓库的真实评审形态:PR #36 前后评了 6 轮,每轮都带完整上下文重新进入。
- **评审频率** = 20 次/天。按 6 轮/PR 算,约等于每天推进 3 个 PR,不夸张。
- **日常开发** = 30M 输入 / 1M 输出每天。agentic coding 的上下文会随轮次反复重发,
  重度使用一天几十 M 输入是常态。
- 一个月按 30 天计。

### A. PR 评审 / 无人值守

| 模型 | 单次 | 20 次/天 → 月成本 |
|:---|---:|---:|
| **Kimi K2.7-code(缓存命中)** | **$0.051** | **~$31** |
| Kimi K2.7-code(无缓存) | $0.127 | ~$76 |
| GLM-5.2 | $0.175 | ~$105 |
| Kimi K3(缓存命中) | $0.15 | ~$90 |
| Kimi K3(无缓存,1M 上下文) | $0.42 | ~$252 |

**这个量级完全可承受**,而且成本随用量线性、可预测、可观测。

### B. 日常开发

| 方式 | 日成本 | 月成本 |
|:---|---:|---:|
| K2.7-code API(90% 缓存命中) | ~$12 | **~$360** |
| K2.7-code API(无缓存) | ~$32.5 | ~$975 |
| GLM-5.2 API(无缓存) | ~$46 | ~$1,392 |
| **GLM Coding Plan Max(订阅)** | — | **$160**(促销 $112) |
| Kimi Code Vivace(订阅) | — | $199 |
| Claude Max 20x(订阅) | — | $200 |

**订阅制是补贴价,单位成本比 API 低一个数量级。日常开发走 API 是纯烧钱** ——
最乐观的缓存假设下也要 $360/月,是 GLM Max 订阅的 2 倍多。

### C. 配额对照

| 计划 | 价格/月 | ~prompts / 5h | ~prompts / 周 |
|:---|---:|---:|---:|
| Claude Pro | $20 | ~45 | — |
| **Claude Max 20x** | **$200** | **~200–900**(社区实测) | 两条周上限(全模型 + Sonnet 专项) |
| GLM Coding Lite | $18($12.6) | ~80 | ~400 |
| GLM Coding Pro | $72($50.4) | ~400 | ~2,000 |
| **GLM Coding Max** | **$160($112)** | **~1,600** | **~8,000** |
| Kimi Code Moderato / Allegretto / Allegro / Vivace | $19 / $39 / $99 / $199 | 未公开细分 | — |

> **注意口径**:各家「prompt」定义不同。一次用户提问在编码工具里通常触发 **5–30 次模型调用**,
> 有的厂商按用户消息计,有的按底层请求计。表里的数字用于量级对比,不宜逐一对齐。

**GLM Max 相对 Claude Max 20x:配额约 2–8 倍,价格低 20%。**

---

## 3. 为什么这两件事必须分开办

| | 日常开发 | PR 评审 / 无人值守 |
|:---|:---|:---|
| 交互形态 | 人在键盘前,一轮一轮来 | 程序触发,无人值守 |
| 计费最优 | **订阅**(补贴价) | **API**(可脚本化、吃缓存/批处理折扣) |
| 配额匹配 | coding plan 的 prompt 配额就是为它设计的 | coding plan 多数绑定特定交互式客户端,套不上 |
| 成本特性 | 固定,封顶 | 线性,可预测,可按 PR 归因 |

用一个方案覆盖两件事,必然在其中一边付出数倍代价:用 API 做日常开发是烧钱,
用订阅跑无人值守是撞配额墙(而且现在还撞在那笔独立的非交互额度上)。

---

## 4. 建议

1. **日常开发 → 买 GLM Coding Plan Max($160,促销 $112)。**
   能直接在 Claude Code 客户端里用,配额是 Claude Max 20x 的 2–8 倍,价格更低。
   想先试水就 **Pro $72**(~400 prompts/5h)。

2. **评审 / 无人值守 → 走 Moonshot 官方 API 的 `kimi-k2.7-code`。**
   理由:coding 专用模型、262K 上下文(够一个 PR 的 diff + 仓库上下文)、
   **缓存命中 $0.19/M**、批处理六折。月成本 $31–76,可预测。

3. **Cloudflare 只在你的应用本身跑在 Workers 上时才用。**
   把 AI 嵌进请求路径、要零网络跳数和统一计费 —— 那时它很值(见前置调研)。
   **作为「便宜的 API 供应商」它不成立。**

4. **先做第 0 节那件事**:确认 $200 是被交互式还是非交互式用量烧掉的。
   如果是后者,正确动作是把无人值守挪到 API,而不是再买一份订阅。

---

## 5. 待确认项

| 项 | 为什么重要 | 怎么确认 |
|:---|:---|:---|
| **CF 上 Kimi K3 的价格** | 这张表唯一的空格;K3 是 1M 上下文,整仓评审场景会用到 | 登 Cloudflare dashboard 查 |
| **CF prompt caching 的折扣价** | 决定 CF 在评审场景是否还有翻盘余地 | dashboard / 联系 CF |
| **$200 的消耗构成** | 决定该加订阅还是转 API | Claude 用量面板,分交互/非交互看 |
| **OpenRouter GLM-5.2 的实际质量** | 价格便宜 3 倍,但可能是量化档 | 拿本仓库真实 PR 做对照评审 |
| **各家 prompt 口径** | 配额表的可比性 | 实际跑一周记录 |

---

## 数据来源

- [Z.ai GLM-5.2 API Pricing](https://www.aipricing.guru/z-ai-pricing/)
- [GLM 5.2 — OpenRouter](https://openrouter.ai/z-ai/glm-5.2)
- [GLM Coding Plan Pricing: Lite $18, Pro $72, Max $160](https://www.aipricing.guru/z-ai-subscription-pricing/)
- [GLM 5.2 Coding Plan: Limits, Pricing & 3-Week Test](https://techsy.io/en/blog/glm-5-2-coding-plan)
- [Kimi API Pricing (August 2026): Kimi K3 at $3/$15](https://benchlm.ai/moonshot/api-pricing)
- [Kimi K2.7 Code Pricing: $0.95/$4 per Million Tokens](https://tokencost.app/blog/kimi-k2-7-code-pricing)
- [Kimi Code Pricing July 2026: K2.7 Code, API Costs](https://www.nxcode.io/resources/news/kimi-code-2026-plans-pricing-developer-guide)
- [Claude Code Usage Limits (2026)](https://www.morphllm.com/claude-code-usage-limits)
- [Claude Code Rate Limits & Usage Quotas Explained (2026)](https://www.truefoundry.com/blog/claude-code-limits-explained)
- [AI Coding Plan Comparison 2026 — Claude vs GLM vs Kimi](https://codingplan.org/en/)
- Cloudflare 侧价格见前置调研 [`README.md`](README.md) 的数据来源一节
