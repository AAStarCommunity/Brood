# LANDSCAPE_AND_STACKS.md — 业界全景与四大技术栈

> 目的：搞清楚"给一个组织训练专属智能"这件事有几种做法、各自适用场景、为什么 Hyphae 选 Stack B + C 而非 A 或 D。

---

## 1. 业界全景图（2026-06）

```
                      "给组织建立专属智能"
                              │
        ┌─────────────────────┴─────────────────────┐
        │                                           │
   改模型本身                                  不改模型
        │                                           │
   ┌────┴────┬─────────────┐                    Stack C
   │         │             │                       │
Stack A   Stack B       Stack D                   RAG
全参微调   PEFT/LoRA   持续预训练              检索增强
   │         │             │                       │
"重炮"   "主流"           "顶配"                "外挂"
   │         │             │                       │
学院/巨头  ⭐ 中小组织      大型企业              ⭐ 中小组织
   │      Hyphae 主推       │                  Hyphae 标配
   │         │             │                       │
   └─────────┴─────────────┘                       │
             │                                     │
             └──────── 混合最优 ───────────────────┘
                      （fine-tune 改行为 + RAG 加知识）
```

---

## 2. 四大技术栈详细对比

### Stack A — 全参微调（Full Fine-tuning）

**做法**：把 base model 全部参数都改一遍。

| 维度 | 数据 |
|:---|:---|
| 训练参数比例 | **100%** |
| 效果 | 最好（理论上限）|
| 硬件需求（70B 模型） | ≥ **8×A100 80GB**（≈ ¥250 万/套）|
| 训练时间 | 7B：1-3 天；70B：1-2 周 |
| 单次训练成本 | 7B：\$500-2k；70B：\$20-50k |
| 工具 | DeepSpeed / Megatron-LM / Torchtune |
| 适用 | 大型企业 / 学院派研究 / 头部 AI lab |

**为什么 Hyphae 不推**：成本太高，中小组织绝对负担不起；效果相对 LoRA 提升有限（不到 5%）。

### Stack B — PEFT / LoRA / QLoRA / DoRA ⭐ Hyphae 主推

**做法**：插入小型可训练矩阵，冻结 base model 大部分参数。

| 维度 | LoRA | QLoRA | DoRA |
|:---|:---:|:---:|:---:|
| 训练参数比例 | 0.5-3% | 0.5-3% | 0.5% |
| 效果（vs 全参） | 95-98% | 92-97% | 96-99% |
| 内存节省 | 70-80% | **80-95%** | 与 LoRA 类似 |
| 7B 模型 VRAM | 12-16 GB | **6-10 GB** | 12-16 GB |
| 13B 模型 VRAM | 24 GB | **12-16 GB** | 24 GB |
| 70B 模型 VRAM | 88 GB | **46 GB** | 88 GB |
| 推荐场景 | 中型组织 | 中小组织默认 | 追求质量 |

> ⭐ **Hyphae 默认 = QLoRA（节省 VRAM）+ DoRA（追求质量）**

**为什么 Hyphae 推**：
- 成本低（一台 RTX 4090 ¥15k 即可微调 13B）
- 效果接近全参微调
- 训练快（小时级，非天级）
- 工具成熟（LLaMA-Factory / Unsloth / Axolotl）

### Stack C — RAG（检索增强）⭐ Hyphae 标配

**做法**：不改模型，把组织文档存向量库，运行时检索拼接到 prompt。

| 维度 | 数据 |
|:---|:---|
| 改模型权重 | ❌ |
| 知识更新成本 | 极低（新文档秒级入库）|
| 适合数据类型 | 文档 / 知识库 / 法律条款 / 病历 / 报告 |
| 不适合 | 改变模型说话风格、改变推理模式 |
| 工具 | LlamaIndex / LangChain / Haystack / Verba / DSPy |
| 关键组件 | 向量数据库（Chroma / Weaviate / Qdrant / Milvus / pgvector）+ Embedding 模型（bge-m3 / multilingual-e5）+ Reranker |

**2025 Gartner 数据**：**70%+ 企业用 RAG 作为主要知识接入方案**，<25% 用 fine-tuning 作为独立方案。

**为什么 Hyphae 标配**：
- 中小组织最常见诉求：让 AI "知道"我们公司的东西
- RAG 比 fine-tuning 更便宜 + 更及时 + 更易调试

### Stack D — 持续预训练（Continued Pre-training）

**做法**：在领域数据上继续 base model 的预训练（不是微调，是继续训）。

| 维度 | 数据 |
|:---|:---|
| 数据量需求 | **10-100 GB 高质量领域 token** |
| 硬件 | 8×H100 80GB（≈ ¥500 万）|
| 单次成本 | \$50k-\$500k |
| 适用 | 头部医疗 / 头部金融 / 头部法律 |
| 典型案例 | BloombergGPT / Med-PaLM / FinLLaMA / ChatLaw |

**为什么 Hyphae 一般不做**：
- 中小组织没有足够数据（10 GB 领域 token 极难凑齐）
- 成本超出 Hyphae 客户能负担
- v3 才考虑通过 HyperCapital 包 C 提供（需要客户有 ≥ \$50k 预算）

---

## 3. RAG vs Fine-tune 决策树

```
              客户问："我们要做 AI"
                     │
                     ▼
            ┌──────────────────┐
            │  目标是什么？      │
            └────┬─────────┬───┘
                 │         │
        让 AI 知道我们   让 AI 像我们一样说话
        的知识            / 处理特定任务
            │                  │
            ▼                  ▼
        ⭐ RAG (Stack C)    ⭐ Fine-tune (Stack B)
            │                  │
            │           ┌──────┴──────┐
            │           │             │
            │       7B-13B 模型    70B+ 模型
            │           │             │
            │       QLoRA on        QLoRA on
            │       RTX 4090         A100 80GB
            │       (¥15k)         (HyperCapital 训练服务)
            │
            ▼
        知识更新频繁？
            ├─ 是 → 仅 RAG
            └─ 否 → 考虑 fine-tune + RAG 混合
```

### 决策矩阵

| 客户场景 | 推荐方案 | 理由 |
|:---|:---|:---|
| 律所卷宗问答 | **RAG**（合同库每天更新）| 知识动态，RAG 完胜 |
| 医院病历助手 | **RAG + LoRA**（专业术语 + 病历库） | 风格固定 + 知识动态 |
| 制造业工艺手册 | **RAG**（手册更新慢但要精确引用） | 准确引用 > 风格 |
| 客服话术统一 | **LoRA**（学公司话术） | 行为定型 |
| 报关单结构化提取 | **LoRA**（学组织内特殊格式） | 固定任务 |
| 跨城市分店运营经验 | **RAG + LoRA 混合** | 知识动态 + 行为统一 |

---

## 4. 中小组织的现实选择（90% 场景）

| 阶段 | 默认方案 | 工具 | 硬件 | 成本 |
|:---:|:---|:---|:---|:---:|
| **v0** | 纯 RAG | LlamaIndex + Qwen 2.5 7B + Chroma | Mac Studio M4 Pro | ¥30k 一次性 |
| **v1** | RAG + QLoRA | LLaMA-Factory + 上述 | + RTX 4090 24GB | + ¥15k |
| **v2** | RAG + QLoRA + 多模态 | + DocVQA / OCR / 视觉模型 | + 第二张 4090 | + ¥15k |
| **v3** | + 持续预训练 | Stack D（HyperCapital 项目）| 借用 H100 集群 | ¥50k+ 单次 |

> 90% 客户停留在 v0-v2，5-10% 进入 v3。

---

## 5. 不在本研究范围

- **从零预训练 base model**（中小组织永远不会做）
- **超大规模分布式训练**（不在我们能力范围）
- **AI 安全 / 对齐**（学术研究方向，非 Hyphae 重点）
- **多模态训练**（v2/v3 才考虑）

---

## 6. 一句话

> **Hyphae 主推 Stack B（QLoRA/DoRA）+ Stack C（RAG）混合 — 这覆盖 90% 中小组织实际需求**。
> Stack A/D 通过 HyperCapital 商业服务包 C 按项目提供，不是默认产品形态。

---

## 参考来源

- [RAG vs Fine-Tuning Enterprise Decisions, Databricks](https://www.databricks.com/blog/rag-vs-fine-tuning)
- [Fine-tuning in 2026 Comparison, dev.to](https://dev.to/ultraduneai/eval-003-fine-tuning-in-2026-axolotl-vs-unsloth-vs-trl-vs-llama-factory-2ohg)
- [Top 10 Open-Source Libraries to Fine-Tune LLMs Locally](https://www.analyticsvidhya.com/blog/2026/05/open-source-libraries-to-fine-tune-llm-locally/)
- [LoRA vs QLoRA: Best AI Model Fine-Tuning Tools 2026](https://www.index.dev/blog/top-ai-fine-tuning-tools-lora-vs-qlora-vs-full)
