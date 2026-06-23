# Hyphae Training — 中小组织专属模型训练 + 隐私保护

> **触发**：用户 2026-06-23 要求 — 调研预训练 / LoRA / Fine-tuning 业界成熟方案，GitHub Top 框架，硬件配置，隐私保护（联邦 / 差分 / TEE），形成完整商业服务流程（既保隐私又能赚钱）
> **状态**：v0.1 完整调研（2026-06-23）
> **位置**：`~/Dev/Brood/research/hyphae-training/`
> **关联**：`research/hyphae/`（Hyphae 主项目）

---

## 0. 一句话

> **Hyphae Training 是"中小组织专属模型微调 + 隐私保护"的完整解决方案 —— 用 LoRA/QLoRA + 联邦学习 + TEE 三层隐私防护，在客户硬件或我们的机密计算 GPU 上跑训练，数据永不离开授信边界，HyperCapital 把这变成 \$499-5k 一次性辅导服务赚钱。**

---

## 1. 文档索引

| # | 文档 | 内容 | 阅读对象 |
|:---:|:---|:---|:---|
| 1 | [README.md](./README.md) | 本文件 | 所有人 |
| 2 | **[TRAINING_PHILOSOPHY_AND_RULES.md](./TRAINING_PHILOSOPHY_AND_RULES.md)** ⭐ | **(2026-06-23) 训练哲学与指导规则 — 训练什么 / 三层结构 / 10 个挑战 / 10 条规则 / 蛋糕店示例** | **决策者 + 工程师必读（最重要）** |
| 3 | [LANDSCAPE_AND_STACKS.md](./LANDSCAPE_AND_STACKS.md) | 业界全景 + 4 大技术栈 + RAG vs Fine-tune 决策 | 决策者 / PM |
| 4 | [GITHUB_TOP_FRAMEWORKS.md](./GITHUB_TOP_FRAMEWORKS.md) | GitHub Top 10 微调框架详评（LLaMA-Factory / Unsloth / Axolotl / TRL / PEFT 等）+ 硬件配置 | 工程师 |
| 5 | [PRIVACY_PRESERVING_TRAINING.md](./PRIVACY_PRESERVING_TRAINING.md) ⭐ | 三大隐私路径：联邦学习（Flower/FLARE）+ 差分隐私（DP-SGD/Opacus）+ TEE（H100 CC + Intel TDX） | 隐私 / 合规 / 商业模式 |
| 6 | [PAPERS_AND_RESEARCH.md](./PAPERS_AND_RESEARCH.md) | 关键论文：LoRA / QLoRA / DoRA / FedAvg / DP-SGD / GPU Travelling | 工程师 / 研究 |
| 7 | [OUR_PIPELINE_AND_BUSINESS.md](./OUR_PIPELINE_AND_BUSINESS.md) ⭐ | **Hyphae Training 完整流程 + HyperCapital 商业服务设计** | **决策者必读** |

## 2. 核心结论速览

### 2.1 业界四大技术栈

```
┌──────────────────────────────────────────────────────────────┐
│  Stack A: 全参微调 (Full Fine-tuning)                          │
│  ─ 改所有权重，效果最好，成本最高                                 │
│  ─ 70B 模型需 ≥ 8×A100 80GB（~$2-5万/天）                       │
│  ─ 工具：DeepSpeed + Megatron-LM + Torchtune                  │
├──────────────────────────────────────────────────────────────┤
│  Stack B: PEFT/LoRA/QLoRA 参数高效微调（⭐ 主流）                 │
│  ─ 只改 0.5-3% 参数，效果接近全参，成本降 90%+                    │
│  ─ 7B QLoRA 单 RTX 3060 12GB；13B 单 4090 24GB；70B 单 A100 80GB │
│  ─ 工具：LLaMA-Factory / Unsloth / Axolotl / Hugging Face PEFT │
├──────────────────────────────────────────────────────────────┤
│  Stack C: RAG（检索增强）                                       │
│  ─ 不改模型，外挂知识库，运行时检索                                │
│  ─ 2025 Gartner: 70% 企业用 RAG 作为主要方案                    │
│  ─ 工具：LlamaIndex / LangChain / Haystack / Verba              │
├──────────────────────────────────────────────────────────────┤
│  Stack D: 持续预训练 (Continued Pre-training)                  │
│  ─ 在领域数据上继续 base model 预训练                            │
│  ─ 仅大型组织需要（医疗 / 法律 / 金融头部）                       │
│  ─ 成本：8×H100 ~$50-200K / 项目                                │
└──────────────────────────────────────────────────────────────┘
```

> ⭐ **Hyphae 主推 Stack B（PEFT/LoRA）+ Stack C（RAG）混合**。Stack A/D 需要时通过商业服务包 C 提供。

### 2.2 GitHub Top 10 微调框架（按 star 排序，2026-06）

| 排名 | 框架 | Stars | 定位 | 适合 |
|:---:|:---|:---:|:---|:---|
| 1 | **LLaMA-Factory** | 68.4K | 全能 WebUI，100+ LLM/VLM | 中小组织主推 |
| 2 | **Unsloth** | 53.9K | 2-5x 速度，80% 少 VRAM，单 GPU | 中小组织 + 单卡场景 |
| 3 | **TRL** (HF) | 17.6K | RLHF / 对齐 | 高级用例 |
| 4 | **Axolotl** | 11.4K | 多 GPU + 可复现配置 | 工程化部署 |
| 5 | **Hugging Face PEFT** | ~17K | PEFT 库（被 1 - 4 复用） | 底层组件 |
| 6 | **DeepSpeed** | 35K+ | 微软，超大模型分布式 | 大型场景 |
| 7 | **Torchtune** | 5K+ | PyTorch 官方 | 学院派 |
| 8 | **Megatron-LM** | 11K+ | NVIDIA，万亿参数 | 巨型 |
| 9 | **OpenRLHF** | 5K+ | 开源 RLHF | 对齐 |
| 10 | **microsoft/LoRA** | 12K+ | 原始 LoRA | 教学 |

> ⭐ **Hyphae 默认栈**：LLaMA-Factory（中小组织友好）+ Unsloth（单卡加速）+ HF PEFT（底层）

### 2.3 硬件配置速查

| 模型规模 | QLoRA 最低 VRAM | 推荐 GPU | 客户预算 |
|:---:|:---:|:---|:---:|
| **7B** | 6-10 GB | RTX 3060 12GB | ¥3-8k |
| **13B** | 12-16 GB | RTX 4090 24GB | ¥15-30k |
| **70B** | 46 GB | A100 80GB 或 Mac M4 Max 128GB | ¥120-300k |
| **400B+** | 240 GB+ | 8×H100 80GB | ¥500万+ |

> ⭐ **Hyphae 主战场是 7B / 13B**，对应中小组织能买得起的硬件。70B+ 通过商业服务包 + 溢出 API 提供。

### 2.4 隐私保护三大路径

| 路径 | 原理 | 隐私强度 | 性能损失 | Hyphae 用法 |
|:---|:---|:---:|:---:|:---|
| **A. 本地训练** | 数据 + 模型都在客户硬件 | ⭐⭐⭐⭐⭐ | 0 | **默认模式**（开源工具自部署） |
| **B. 联邦学习** | 多组织合作训练，数据不出门 | ⭐⭐⭐⭐ | 中（通信开销） | 多组织协作场景（v2）|
| **C. TEE 机密计算** | 在加密 GPU 内训练，我们也看不到 | ⭐⭐⭐⭐⭐ | 2-5% (H100 CC) | **HyperCapital 训练服务核心** |
| D. 差分隐私 (DP-SGD) | 训练时加噪声防止逆向 | ⭐⭐⭐ | 15-30% | 可选叠加 |

**核心创新**：A + C 组合 = "你的数据先在你机房脱敏 / 摘要 → 加密上传我们的 H100 CC GPU 训练 → 训练好的 LoRA 权重下载回你机房 → 我们全程看不到你的数据"。

### 2.5 商业服务流程（HyperCapital 训练服务包）

```
客户场景：30 人律所，要给员工做个"律所内部 AI 助手"
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 1: 需求咨询（HyperCapital 包 A）                          │
│  ─ 业务流程梳理：合同审查 / 卷宗检索 / 条款问答                    │
│  ─ 数据资产盘点：5 年合同 PDF + 内部知识库 + 邮件                  │
│  ─ 推荐：Qwen 2.5 14B + RAG + LoRA fine-tune                  │
│  ─ 输出：技术方案 + 报价（一次性 ¥4988）                          │
├─────────────────────────────────────────────────────────────┤
│  Step 2: 数据准备（客户机房，HyperCapital 远程辅导）              │
│  ─ 客户在自己服务器跑数据清洗脚本（开源）                          │
│  ─ 生成训练样本 JSONL（脱敏处理）                                │
│  ─ 客户审核：决定哪些数据出门、哪些不出门                          │
├─────────────────────────────────────────────────────────────┤
│  Step 3: 训练（关键，3 种模式客户选）                            │
│  ─ 模式 A: 客户本地训练（自家 4090）— 慢但 0 风险               │
│  ─ 模式 B: HyperCapital H100 CC 训练 — 快 + TEE 隐私保护       │
│  ─ 模式 C: 联邦学习 — 与其他律所协作训练（v2）                    │
├─────────────────────────────────────────────────────────────┤
│  Step 4: 部署（客户机房）                                       │
│  ─ 训练好的 LoRA 权重打包 + 加密签名                              │
│  ─ 装到客户的 Hyphae 节点                                       │
│  ─ 集成 RAG（动态合同库）+ 业务 Agent                           │
├─────────────────────────────────────────────────────────────┤
│  Step 5: 后续运维（HyperCapital 包 B，订阅）                    │
│  ─ 模型迭代（每月新增数据 → 增量 LoRA）                          │
│  ─ 性能监控 + 用户反馈分析                                       │
│  ─ ¥299-2999 / 月                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 关键论文速览（详见 PAPERS_AND_RESEARCH.md）

| 论文 | 年 | 重要性 | 一句话 |
|:---|:---:|:---|:---|
| **LoRA** | 2021 | ⭐⭐⭐⭐⭐ | 低秩矩阵分解，只训练 0.5% 参数 |
| **QLoRA** | 2023 | ⭐⭐⭐⭐⭐ | 4-bit 量化 + LoRA，单 GPU 70B |
| **DoRA** | 2024 | ⭐⭐⭐⭐ | Weight-Decomposed LoRA，效果优于 LoRA |
| **DP-SGD** | 2016 | ⭐⭐⭐⭐ | 差分隐私训练奠基 |
| **FedAvg** | 2017 | ⭐⭐⭐⭐⭐ | 联邦学习开山 |
| **GPU Travelling** | 2025 | ⭐⭐⭐ | TEE GPU 协作训练新方案 |

---

## 4. 下一步动作

| 优先级 | 动作 | 责任 |
|:---:|:---|:---|
| P0 | 与用户对齐"商业服务流程"是否符合预期 | jhfnetboy |
| P1 | 在 Hyphae 主项目 BP 中加入"训练服务包 A/B/C"细化 | Brood |
| P1 | 申购 1-2 张 H100 CC 测试机（验证 TEE 训练）| 工程 |
| P2 | 实现 Hyphae v0.1 训练流程参考代码（LLaMA-Factory + Unsloth）| 工程 |
| P2 | 联系 Phala / OpenRouter 谈 TEE GPU 算力合作 | BD |
| P3 | 法务审查："我们看不到客户数据"的合规话术 | 法务 |
