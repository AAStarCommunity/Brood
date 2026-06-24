# FIREWORKS_CUSTOMER_USECASES.md — Fireworks 帮客户解决什么问题

> **触发**：创始人 2026-06-24 提问 —— Cursor / Notion / Uber 这些硅谷企业采购 Fireworks，是解决内部问题（类 ERP/CRM）还是生产资料（对外产品的算力/模型）？Fireworks 的模型是开源二次开发还是全新模型？
> **状态**：v0.1（2026-06-24）
> **关联**：[FIREWORK_MOAT.md](./FIREWORK_MOAT.md) · [POSITIONING.md](./POSITIONING.md)

---

## 0. 一句话结论

> **Fireworks 的客户买它，几乎全部用于"驱动自己卖给终端用户的产品里的 AI 功能"——是生产资料（means of production），不是内部管理（不是 ERP/CRM）。**
> Fireworks = **"卖铲子的人"**：它不直接面对消费者，而是给一批 AI 产品公司提供推理引擎，嵌进它们的产品里。
> **模型策略你理解对了**：Fireworks 以**托管 + 二次开发开源模型**为主（DeepSeek/Llama/Qwen），**不做全新基座模型**；唯一自有的 FireFunction 也是开源基座上加训练的定制层。
> **对 Hyphae 的意义**：Fireworks 服务"把 AI 嵌进产品的 AI 公司"；Hyphae 服务"用 AI 改善内部运营/决策的非 AI 小组织"。**两者需求完全不同 —— Hyphae 做的恰恰是 Fireworks 不碰的"内部管理/决策"那一类。**

---

## 1. 先纠正/确认你的理解

### 1.1 模型策略 ✅ 你基本全对

| 你的理解 | 事实核对 |
|:---|:---|
| 自建 AI 中心 + GPU | ✅ 自建/租用 GPU 集群跑推理 |
| 部署开源模型为主 | ✅ DeepSeek / Llama / Qwen / Mixtral / DBRX 等开源模型 |
| 在开源基础上"二次开发" | ✅ 优化推理 + 微调；不做全新基座模型 |
| 不是全新开发模型 | ✅ 正确 —— Fireworks **不训练基座大模型** |

**唯一补充**：Fireworks 有一个自有模型族 **FireFunction**（function-calling 专用），但它也是"在开源基座上加训练的定制层"，不是从零的新模型。所以你的"二次开发，不是全新"判断**完全准确**。

### 1.2 收入三段 ✅ 你记对了

| 收入 | 占比 | 内容 |
|:---|:---:|:---|
| Serverless 推理 | ~60-70% | 按 token 卖开源模型（+二次优化）的推理 |
| Fine-tuning | ~10-15% | 训练/微调服务（LoRA 等）|
| On-Demand GPU | ~20-25% | 直接出租 GPU 算力（$7-12/h）|

---

## 2. 核心问题：客户用 Fireworks 解决什么？

### 2.1 答案：驱动"对外产品里的 AI 功能"（生产资料）

**不是内部管理（ERP/CRM），是产品本身的核心引擎。** 逐个看：

| 客户 | 用 Fireworks 干什么 | 是内部还是对外产品？ |
|:---|:---|:---|
| **Cursor** | 托管 Cursor 自己微调的专有模型（`llama-70b-ft-spec`）做**低延迟代码补全**，推测解码达 **>1000 tokens/s** | ⭐ **对外产品核心**（Cursor 卖给开发者的就是这个补全）|
| **Notion** | 微调模型把 **Notion AI 功能**延迟从 2s 降到 350ms | ⭐ **对外产品功能**（Notion AI 卖给用户）|
| **Uber** | 高吞吐、低延迟的生产应用（文本/图像生成）| ⭐ **对外产品/服务**里的 AI 能力 |
| **DoorDash / Quora / Upwork** | 同上，production use case 的推理 | ⭐ **对外产品** |

> **结论**：这些公司买 Fireworks，是因为**它们自己的产品里有 AI 功能要卖给终端用户**，需要一个"比自建便宜、比闭源 API 快"的推理后端。
> **这不是解决"公司内部怎么管理"的问题（那是 ERP/CRM 干的），是解决"我的产品怎么把 AI 功能跑起来"的问题。**

### 2.2 你举的例子核对

- **Cursor 直接用 Fireworks 做算力和模型提供方** → ✅ **完全正确**。Cursor 的代码补全模型就托管在 Fireworks 上，是 Cursor 产品的命脉。
- **Notion 主场景不是推理** → ✅ 对。Notion 是笔记/协作产品，但它的 **Notion AI 功能**用 Fireworks 跑推理。所以 Notion 买的是"给我的 AI 功能提供快推理"，**用在它卖给用户的产品功能上**，不是内部办公。

### 2.3 一个关键的反例澄清

> 没有任何证据显示这些公司用 Fireworks 做"内部 ERP/CRM/办公自动化"。
> Fireworks 是**面向产品工程团队**的基础设施，不是面向 HR/财务/运营的内部工具。

---

## 3. Fireworks 的本质：卖铲子（Picks & Shovels）

```
        终端用户（开发者 / 消费者）
              ↑ 使用产品
   ┌──────────┴──────────────────────┐
   │  AI 产品公司（Cursor/Notion/Uber）│  ← 它们卖产品给终端用户
   │  产品里有 AI 功能                  │
   └──────────┬──────────────────────┘
              ↑ 采购推理/算力（生产资料）
        ┌─────┴─────┐
        │ Fireworks │  ← 卖铲子的人，不直接面对消费者
        │ 推理+微调+GPU│
        └─────┬─────┘
              ↑ 跑在
        开源模型（DeepSeek/Llama/Qwen）+ 自研推理优化
```

- Fireworks 是 **B2B2C 链条里的"B2"**：它的客户(B)再把含 AI 的产品卖给终端(C)
- 它赚的是"淘金热里卖铲子"的钱 —— 不赌哪个 AI 产品赢，只要 AI 产品都需要推理，它就赚
- 这也解释了它的客户假设（见 FIREWORK_MOAT §3）：客户必须**有自己的产品 + 有 AI 团队 + 有量**

---

## 4. 对 Hyphae 的关键意义（最重要）

### 4.1 Fireworks 和 Hyphae 服务的是两类完全不同的需求

| 维度 | Fireworks 的客户 | Hyphae 的客户 |
|:---|:---|:---|
| 客户是谁 | AI 产品公司（Cursor/Notion）| 非 AI 的小组织（服装厂/民宿/诊所/培训）|
| 用 AI 干什么 | **嵌进对外产品**（生产资料）| **改善内部运营/决策**（类 ERP/CRM 的内部用）|
| 客户有没有 AI 团队 | 有 | 没有 |
| 数据上不上云 | 上（信任 Fireworks 云）| 不能上（敏感 + 合规）|
| 买的是什么 | 快 + 便宜的推理后端 | 懂业务的"数字合伙人" |
| 类比 | 卖铲子给淘金者 | 教不会淘金的人怎么淘金 + 给工具 |

### 4.2 这个区分为什么是 Hyphae 的护城河确认

> **Fireworks 帮"已经会用 AI 的公司"把 AI 跑得更快更便宜。**
> **Hyphae 帮"根本不会用 AI 的小组织"第一次把 AI 用起来，且用在内部运营/决策上。**

这两件事的**客户、场景、交付、价值主张全都不同**：
- Fireworks 是**生产资料供应商**（卖算力/推理给产品）
- Hyphae 是**业务智能赋能者**（帮小组织把内部业务 AI 化）

→ 这正是 [FIREWORK_MOAT §3](./FIREWORK_MOAT.md) 说的"Fireworks 刻意不服务的边界"。**Hyphae 不是和 Fireworks 抢客户，是去做 Fireworks 的客户假设挡在门外的那群人。**

### 4.3 一个值得警惕的误区

> ⚠️ 不要因为"Fireworks 估值高"就想做"中国版 Fireworks"（卖推理给 AI 产品公司）。
> 那个市场在中国已经挤满了（硅基流动、阿里云百炼、火山引擎、各家 MaaS）。
> **Hyphae 的差异化恰恰是不卖铲子给淘金者，而是服务那些"不淘金、只想用 AI 把自己小生意做好"的人。** 这是一片空地。

### 4.4 Hyphae 可以借鉴 Fireworks 的部分

| Fireworks 做法 | Hyphae 借鉴 |
|:---|:---|
| 托管 + 二次开发开源模型（不做基座）| ✅ Hyphae 也用开源 Qwen + 行业 LoRA，不做基座 |
| 推理优化是工程护城河 | ⚠️ Hyphae 不拼推理优化，拼"找路径 + 行业 know-how" |
| 三段收入（推理/微调/GPU）| ⚠️ Hyphae 本地免费，靠产品化价值 + 行业训练（见 POSITIONING）|
| 按 token 计费 | ❌ Hyphae 本地 token 免费（核心差异化）|

---

## 5. 一句话

> **Fireworks 帮硅谷 AI 公司把"产品里的 AI 功能"跑得更快更便宜——是生产资料，不是内部管理；是卖铲子，不是淘金。模型是开源二次开发，不是全新基座（你判断对了）。**
> **Hyphae 做的恰恰相反：帮不会用 AI 的小组织，第一次把 AI 用在内部运营和决策上。客户、场景、价值全不同 —— 这不是竞争，是 Fireworks 主动放弃的另一片大陆。**

---

## 参考来源

- [How Cursor built Fast Apply using the Speculative Decoding API — Fireworks](https://fireworks.ai/blog/cursor)
- [How Cursor Serves Billions of AI Code Completions Every Day — ByteByteGo](https://blog.bytebytego.com/p/how-cursor-serves-billions-of-ai)
- [Inference is the New Runtime — Index Ventures](https://www.indexventures.com/perspectives/inference-is-the-new-runtime-our-investment-in-fireworks/)
- [How Cursor Trained Composer on Fireworks — Sequoia](https://sequoiacap.com/podcast/how-cursor-trained-composer-on-fireworks-distributed-infrastructure-for-high-performance-rl/)
- [Fireworks Customers](https://fireworks.ai/customers)
- [Fireworks Models (open source)](https://fireworks.ai/models)
- [Introducing Supervised Fine-tuning V2 — Fireworks](https://fireworks.ai/blog/supervised-finetuning-v2)
- [What is Fireworks AI? Features, Pricing, Use Cases — Walturn](https://www.walturn.com/insights/what-is-fireworks-ai-features-pricing-and-use-cases)
