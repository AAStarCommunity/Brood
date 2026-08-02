---
title: "Hyphae"
author: "Mycelium Protocol / iDoris.ai"
date: "2026 年 6 月"
documentclass: article
classoption:
  - 10pt
geometry:
  - margin=2cm
  - top=1.8cm
  - bottom=1.8cm
  - includefoot
mainfont: "PingFang SC"
colorlinks: true
linkcolor: "MidnightBlue"
urlcolor: "MidnightBlue"
header-includes:
  - \usepackage{setspace}
  - \setstretch{1.0}
  - \setlength{\parskip}{3pt}
  - \setlength{\parindent}{0pt}
  - \usepackage{enumitem}
  - \setlist{nosep,leftmargin=1.2em}
  - \usepackage{array}
  - \renewcommand{\arraystretch}{1.08}
---

\thispagestyle{empty}

\begin{center}
{\Huge\bfseries Hyphae}\\[4pt]
{\Large 中小组织的专属智能菌丝}\\[6pt]
{\itshape Bring AI to every small organization, not just AI-native companies.}\\[4pt]
{\small\itshape 由 Mycelium Protocol —— 数字公共物品共建生态 —— 孵化}
\end{center}

\vspace{4pt}

\noindent\rule{\linewidth}{0.4pt}

\vspace{4pt}

\noindent\textbf{一句话定位}：
Hyphae 是中小组织的"专属智能菌丝" —— 开源全栈（模型 + 微调 + 推理 + Agent）本地部署，token 永久免费；溢出能力按需调用，比 Firework 便宜。**当下卖训练 + 部署服务；远期建立中小组织协作网络。**

\vspace{2pt}

| | |
|:---|:---|
| **产品** | Hyphae —— 开源全栈 AI 基础设施 |
| **所属** | iDoris.ai / Mycelium Protocol（数字公共物品共建生态） |
| **阶段** | Seed（v0.1 草稿，2026 年 6 月）|
| **联系** | jhfnetboy@gmail.com |

# 1. 问题：5000 万中小组织被 AI 浪潮抛弃

全球 AI 推理基础设施被 **Firework AI / Together / Modal / Replicate** 主导，他们的客户都是 Cursor / Notion / Uber 这种 **AI 原生 mid-market+ 公司**。但全球还有 **~5000 万家中小组织**（10-200 人的公司、社区、协会、学校、医院、律所、本地服务），被现有 AI 工具完全忽略：

| 痛点 | 描述 | 现有方案为什么不行 |
|:---|:---|:---|
| **没人会用** | 老板想用 AI 但团队不会 fine-tune / RAG / prompt 工程 | Firework 假设客户有 AI 团队 |
| **数据不能上云** | 律所卷宗、医院病历、贸易公司报关单 —— 监管禁止 | Firework 必须把数据传美国云端 |
| **业务太特殊** | 每家公司流程独一无二，标准 AI 工具不解决 | OpenAI / Anthropic API 是通用工具 |

**市场容量**：5000 万中小组织 × 0.1\% 渗透率 = 5 万付费客户 × LTV \$5k-50k = **\$2.5-25 亿 ARR 潜在市场**。这是 Firework **主动放弃**的市场，也是 Hyphae 的独占战场。

\pagebreak

# 2. 方案：开源全栈 + 本地部署 + 运营合伙人落地

**一句话**：Hyphae 把"硬件 + OS + 开源模型 + 场景微调 + 推理引擎 + 业务 Agent"打包成一套**中小组织自己能装上跑起来**的开源系统。

\begin{center}
\footnotesize
\begin{tabular}{|l|}
\hline
\textbf{业务 Agent 层}：客服 / 邮件 / 报销 / 知识库 / 报表 / 行业定制 \\
\hline
\textbf{Agent 编排}（复用 iDoris.ai Agent24）：工具调用 / 工作流 / 多 Agent 协作 \\
\hline
\textbf{推理引擎}（开源）：vLLM / Ollama / llama.cpp \\
\hline
\textbf{模型 + 微调}：Llama / Qwen / DeepSeek / GLM + 组织专属 LoRA \\
\hline
\textbf{OS / 容器}：Linux + Docker / Tauri 跨平台 \\
\hline
\textbf{硬件}：4080 / 5090 / Mac Studio / H100 单卡 \\
\hline
\multicolumn{1}{c}{$\downarrow$ 偶尔需要重活（做图 / 视频 / embed）$\downarrow$} \\
\multicolumn{1}{c}{\textbf{[Hyphae 云端 API]} —— 比 Firework 便宜 30-50\%} \\
\end{tabular}
\end{center}

**用户体验** —— 5 步上线：

1. **买硬件**：带 GPU 的小服务器（4080 ≈ ¥10k / Mac Studio ¥30k / H100 单卡 ¥200k）
2. **装 Hyphae**：区域/行业运营合伙人落地（分润），30-60 分钟
3. **上传数据**：组织自家合同 / 病历 / 报关单 / 课件 → 自动 LoRA 微调
4. **团队使用**：浏览器 / IDE / 钉钉 / 飞书直接用，数据 100\% 不出门，token 永久免费
5. **溢出调云**：做图 / 视频走 Hyphae 云端 API，脱敏后传

**与 iDoris.ai 姊妹品的关系**：iDoris = 个人 AI（个体细胞）/ Agent24 = Agent 框架 / **Hyphae = 组织 AI 全栈**（一根菌丝里跑多个 iDoris 服务组织成员）。

\pagebreak

# 3. 竞争与护城河

Firework AI 是行业标杆：2026-05 估值 **\$150 亿在谈**，ARR **\$800M**，处理 10+ trillion tokens/天。**他们的三大收入** = (1) 卖 token / GPU 时长（\$7-12/h H100/B200）+ (2) 预训练 / 微调（\$0.5-40/M token）+ (3) 部署服务（enterprise）。**他们的三大护城河** = (1) PyTorch 团队全建制空降（CEO Lin Qiao 前 Meta PyTorch 负责人）+ (2) FireAttention 自研内核（vLLM 的 5.6x-12.2x 快）+ (3) FireOptimizer 自适应优化栈（100k+ 配置自动选）。

但他们**刻意不服务中小组织** —— 这给了我们独占战场。

| 维度 | Firework AI | Hyphae |
|:---|:---|:---|
| 客户 | mid-market 到 enterprise | **中小组织**（Firework 放弃）|
| 部署 | 100\% 云端（Firework GPU） | **本地优先 + 按需上云** |
| Token 计费 | 按 token，\$0.5-40/M | **本地 token 永久免费** |
| 客户能力假设 | 有 fine-tune / RL 团队 | **完全不懂** AI |
| 平台代码 | 闭源 | **全开源（Apache 2.0）** |
| 数据主权 | 数据传 Firework | **数据 100\% 不出门** |
| 业务 know-how | 通用工具 | **行业 playbook + 运营合伙人落地** |
| 背后实体 | 普通公司 | **数字公共物品共建生态** |

**Hyphae 六大护城河**（按 sustainability 排序）：

| # | 护城河 | 难复制度 | 来源 |
|:---:|:---|:---:|:---|
| 1 | **业务流程 know-how** | 极强 | 创始人 **10 年 ERP + 20 年软件工程**经验 |
| 2 | **中小组织聚焦 + Firework 拒绝市场** | 极强 | 战略选择 + 早期占位（5000 万 TAM）|
| 3 | **Mycelium 数字公共物品共建生态** | 极强 | 不是普通公司，是**协议层共建网络**（详见 §5）|
| 4 | **Mycelium 兄弟产品协同** | 强 | AirAccount / SuperPaymaster / iDoris / Agent24 / FangPay / Cos72 / HyperCapital |
| 5 | **开源 + 数据主权品牌** | 强 | Apache 2.0 + 本地部署 + 客户审计 |
| 6 | **运营合伙人分润网络 + 联邦行业数据** | 强 | 轻平台+合伙人重落地；同行联邦持续加深 |

**核心论点**：Firework 团队是世界顶级 PyTorch 工程师，但他们**完全不懂**一个 30 人贸易公司的报关流程、50 人律所的卷宗管理、100 人制造业的 BOM 工单。模型部署只占 AI 落地 20\% 工作，**80\% 是把业务流程拆解为 AI 可执行的步骤**。这需要领域经验 —— 创始人 30 年软件 + ERP 经验是 Firework 团队 **5-10 年也补不上**的护城河。

**不正面打 Firework 的事**：不自研推理引擎、不挖 PyTorch 大佬、不做 Notion / Cursor 这种大客户、不做模型本身。

\pagebreak

# 4. 商业模式：收入对比 + 远期协作网络愿景

## 4.1 收入渠道对比（vs Firework 三大收入）

| # | 收入渠道 | Firework AI | Hyphae | 阶段 |
|:---:|:---|:---|:---|:---:|
| 1 | **Token (serverless)** | ⭐ 主力 (per token) | ❌ 本地永久免费（用户用自己硬件）| —— |
| 2 | **GPU 时长 (on-demand)** | ⭐ 主力 (\$7-12/h) | ❌ 客户自购硬件 | —— |
| 3 | **订阅式产品价值** | n/a | ✅ 碎片流程AI化+数据同步+持续进化+判断推送（月/年费）| **当下主力** |
| 4 | **行业模型训练** | \$0.5-40/M token | ✅ 帮某行业训出可用 AI（一次性+持续迭代）| **当下主力** |
| 5 | **溢出 API** | n/a | ✅ 比 Firework 便宜 30-50\% | 当下补充 |
| 6 | **协作网络服务费**（远期）| n/a | ⭐⭐ **中小组织 Hyphae 间互联** | **远期愿景** |

**当下定位**：本地 token 免费，靠**产品化持续价值**（不是人力贴身服务）赚钱；落地由**区域/行业运营合伙人分润**完成，Hyphae 总部保持轻平台。详见 [POSITIONING.md](./POSITIONING.md)。

## 4.2 远期愿景：中小组织协作网络（"分布式 Firework"）

Firework = **AWS 模型**（中心化大算力）；Hyphae = **比特币网络模型**（每个节点独立 + 节点间协作）。当 5000 个 Hyphae 节点上线后会发生什么：

- 节点 A 想跑某个特殊任务但本地算力不够 → **通过 Mycelium 网络借用 B/C/D 闲置算力**
- 节点 A 沉淀了医疗行业 fine-tuned 模型 → **其他医疗组织可订阅使用**（aPNTs 计费）
- 节点之间形成**算力 + 模型 + 知识的三层市场**
- 协议层抽取小额服务费（参考 FangPay 10\% gas 模式）

**未来收入** = 网络规模 × 节点交互频次 × 服务费率。**这是 Firework cloud 中心化架构永远做不到的**。

## 4.3 三年收入预估

| 阶段 | 自助客户 | 商业服务客户 | 平均年付费 | 年 ARR | 协作网络贡献 |
|:---:|:---:|:---:|:---:|:---:|:---:|
| **Y1** | 50 | 20 | \$3k | **\$210k** | — |
| **Y2** | 1,000 | 200 | \$5k | **\$6M** | 试点 |
| **Y3** | 5,000 | 1,000 | \$8k | **\$48M** | 占比 ~10\% |

## 4.4 GTM 三阶段

- **Y1 行业 playbook 奠基**：创始人亲自带 20 种子客户，沉淀小服装厂/民宿/诊所/培训等行业 playbook；以成交闭环 + 口碑传播
- **Y2 运营合伙人分润网络复制**：招募区域/行业运营合伙人（分润、非雇佣）做落地 + 反哺行业经验；同行联邦学习试点；进入数据主权强需求市场
- **Y3 开源社区 + 协作网络**：开源贡献者 100+；合伙人网络规模化；与 ERP / CRM / OA 服务商合作；协作网络 + 行业联邦试运行

\pagebreak

# 5. 团队 · Mycelium 共建生态 · 里程碑 · Ask

## 5.1 团队

| 角色 | 背景 |
|:---|:---|
| **创始人 / CEO** | jhfnetboy —— **10 年 ERP 经验 + 20 年软件工程实践** + Mycelium Protocol 创始人 + AAStar / iDoris.ai 体系搭建者 |
| **CTO** | **David** —— AI 基础设施 + 系统编排 |
| **行业顾问** | 医疗 / 律所 / 制造 / 教育各 1-2 位（创始人 ERP 网络）|
| **区域/行业运营合伙人** | 分润制（非雇佣）—— 带本地资源 + 行业经验做落地，破解人力成本陷阱 |

## 5.2 Mycelium 共建生态 —— 我们不是普通软件公司

**Hyphae 背后不是一家公司，而是 Mycelium Protocol 数字公共物品共建生态**：协议层共建（MushroomDAO 治理 + 全球开源贡献者 + Apache 2.0）+ 兄弟产品复用（AirAccount / SuperPaymaster / aPNTs / iDoris / Agent24 / FangPay / Cos72 / HyperCapital，节省 60-80\% 工程投入）+ MushroomDAO Treasury 链上财务支持 + AAStar + iDoris.ai + MushroomDAO 三组织联合研发 + 协议层共享法务。**普通 Series A 创业公司从零搭这些需 \$10-30M + 12-18 个月；Hyphae 直接接入，节省 \$8-25M**。

## 5.3 12 个月里程碑

| 季度 | 目标 |
|:---:|:---|
| **Q3 2026** | v0.1 Lite 完成：Llama + vLLM + Agent 部署脚本；2-3 种子客户跑通 |
| **Q4 2026** | 5 个行业模板；10 客户；ARR \$30k |
| **Q1 2027** | 行业 playbook + 运营合伙人 playbook 标准化；20 客户；ARR \$90k |
| **Q2 2027** | 同行联邦学习试点 + 数据主权强需求市场首批客户；50 客户；ARR \$250k |

## 5.4 风险 · Ask

**风险与应对**：Firework 下沉 → 业务 know-how + 本地化筑墙 ／ "找路径"沦为成本黑洞 → 产品化为行业 playbook + 联邦聚合，每行业做一次 ／ 中小组织付费意愿低 → 本地免费降门槛 + 成交闭环口碑传播 ／ 数据 / 监管 → 完全本地 + 联邦 + 开源可审计。

**Ask**：资金 \$\_\_\_（Pre-seed，金额待填）·  用途 50\% 工程（平台+训练+联邦+隐私）/ 25\% 行业 playbook 与种子客户 / 15\% 运营合伙人网络启动 / 10\% 法务  ·  期限 18 个月跑到 50 客户 + ARR \$250k 支撑 Series A  ·  联系 **jhfnetboy@gmail.com**

\begin{center}
\noindent\rule{0.4\linewidth}{0.4pt}\\[2pt]
\textit{"Firework 的护城河深到不可正面挑战。但他们刻意不服务中小组织，这才是 Hyphae 的金矿。"}\\[2pt]
—— Hyphae, 2026 年 6 月于昆明
\end{center}
