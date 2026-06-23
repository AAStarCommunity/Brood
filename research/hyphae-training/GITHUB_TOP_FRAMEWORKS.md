# GITHUB_TOP_FRAMEWORKS.md — GitHub Top 10 微调框架详评 + 硬件配置

> 数据时间：2026-06；按 GitHub Stars 排序

---

## 1. 框架总表（10 个）

| # | 框架 | Stars | 公司/作者 | 一句话定位 | Hyphae 用 |
|:---:|:---|:---:|:---|:---|:---:|
| 1 | **LLaMA-Factory** | 68.4K | hiyouga (北航) | WebUI + 100+ LLM/VLM 一站式 | ⭐⭐⭐⭐⭐ |
| 2 | **Unsloth** | 53.9K | Daniel/Michael Han | 2-5x 训练加速 + 80% 少 VRAM (单 GPU) | ⭐⭐⭐⭐⭐ |
| 3 | **DeepSpeed** | 35K+ | Microsoft | 超大规模分布式训练 | ⭐⭐⭐ |
| 4 | **Hugging Face PEFT** | 17K+ | Hugging Face | PEFT 标准库（LoRA/IA3/Prefix）| ⭐⭐⭐⭐ |
| 5 | **TRL** | 17.6K | Hugging Face | RLHF / 对齐官方库 | ⭐⭐⭐ |
| 6 | **microsoft/LoRA** | 12K+ | Microsoft | 原始 LoRA 实现 | 教学 |
| 7 | **Megatron-LM** | 11K+ | NVIDIA | 万亿参数训练 | ⭐⭐（高端）|
| 8 | **Axolotl** | 11.4K | OpenAccessAI | 多 GPU + 可复现配置 | ⭐⭐⭐⭐ |
| 9 | **OpenRLHF** | 5K+ | 社区 | 开源 RLHF | ⭐⭐ |
| 10 | **Torchtune** | 5K+ | PyTorch | PyTorch 官方微调库 | ⭐⭐⭐ |

---

## 2. 详细评测（按 Hyphae 推荐顺序）

### #1 LLaMA-Factory（Hyphae 默认首选）

**仓库**：`hiyouga/LLaMA-Factory`
**Stars**：68.4K（2026-06 第一）
**许可**：Apache 2.0

**核心特性**：
- 一站式 WebUI（LlamaBoard），浏览器配置 + 启动训练
- 支持 **100+ LLM / VLM**（Llama / Qwen / DeepSeek / GLM / Yi / Mistral / Gemma / 多模态等）
- 支持所有训练方法：SFT / DPO / PPO / RLHF / 持续预训练 / 全参 / LoRA / QLoRA / DoRA / GaLore
- 集成 Unsloth + Liger Kernel + FlashAttention-2（速度优化）
- 支持 GGUF 导出（直接给 Ollama / llama.cpp 用）

**为什么 Hyphae 首选**：
- 中小组织用户最友好（WebUI 不需要写 Python）
- 中文社区活跃（原作者北航，中文文档完善）
- 业内最广模型覆盖（客户拿什么开源模型都能跑）

**Hyphae 集成方式**：
- 内置在 Hyphae 部署包里
- HyperCapital 包 A 用 WebUI 演示给客户
- 训练好的 LoRA 权重直接给 vLLM 推理

### #2 Unsloth（Hyphae 单 GPU 加速首选）

**仓库**：`unslothai/unsloth`
**Stars**：53.9K
**许可**：Apache 2.0

**核心特性**：
- **2-5x 训练加速**（vs FlashAttention 2）
- **80% 少 VRAM**（手写 Triton 内核 + 智能梯度检查点）
- 支持 Llama / Mistral / Gemma / Qwen / Phi
- 一键导出 GGUF / vLLM / Ollama
- **限制**：仅单 GPU（多 GPU 收费版）

**为什么 Hyphae 推**：
- 中小组织 90% 是单 GPU 场景 → Unsloth 完美匹配
- 同样硬件能跑更大模型（7B → 13B → 30B）
- Hugging Face 官方文档推荐

**Hyphae 集成方式**：
- 与 LLaMA-Factory 组合使用（LLaMA-Factory 调度，Unsloth 加速内核）
- 客户单 RTX 4090 上跑 30B 模型

### #3 Axolotl（Hyphae 多 GPU 工程化首选）

**仓库**：`OpenAccess-AI-Collective/axolotl`
**Stars**：11.4K
**许可**：Apache 2.0

**核心特性**：
- YAML 配置驱动（可复现）
- **多 GPU 训练**（DeepSpeed + FSDP）
- 支持所有主流 PEFT 方法
- CI/CD 友好

**为什么 Hyphae 推**（v1.5+）：
- HyperCapital 标准化训练流程时用（YAML 模板可分享）
- 客户多 GPU 时使用
- 适合行业模板批量跑训练

### #4 Hugging Face PEFT

**仓库**：`huggingface/peft`
**Stars**：17K+
**许可**：Apache 2.0

**核心特性**：
- 业界 **PEFT 标准库**
- 支持 LoRA / QLoRA / DoRA / IA3 / Prefix Tuning / P-Tuning / Prompt Tuning / AdaLoRA / LoHa / LoKr 等
- 与 transformers / accelerate / bitsandbytes 深度集成

**Hyphae 集成方式**：
- LLaMA-Factory / Unsloth / Axolotl 底层全部依赖 PEFT
- 直接 import 用，不需要单独"工具"

### #5 TRL（Transformer Reinforcement Learning）

**仓库**：`huggingface/trl`
**Stars**：17.6K
**许可**：Apache 2.0

**核心特性**：
- RLHF / DPO / PPO / ORPO / GRPO 官方实现
- 与 PEFT 深度集成

**Hyphae 用场景**：
- 客户需要"对齐"（让 AI 输出符合公司价值观 / 拒绝某些话题）
- HyperCapital 包 C 进阶服务

### #6 DeepSpeed

**仓库**：`microsoft/DeepSpeed`
**Stars**：35K+
**许可**：Apache 2.0

**核心特性**：
- ZeRO 分布式优化器（大模型必备）
- MoE / 推理优化 / 通信优化

**Hyphae 用场景**：
- 仅 HyperCapital 包 C（70B+ 训练）
- 中小组织日常不用

### #7-10 其他

- **Megatron-LM**: 仅头部 lab 用，Hyphae 不直接用
- **OpenRLHF**: 开源 RLHF 替代品，可作 TRL 备选
- **Torchtune**: PyTorch 官方，可能未来变重要，目前生态弱
- **microsoft/LoRA**: 教学价值大，生产用 LLaMA-Factory / Unsloth

---

## 3. 硬件配置全表

### 3.1 按模型规模 + 训练方法

| 模型 | 全参微调 | LoRA | QLoRA |
|:---:|:---|:---|:---|
| **3B** | 24 GB | 8-12 GB | **4-6 GB** |
| **7B** | 48 GB | 12-16 GB | **6-10 GB** |
| **13B** | 96 GB | 24 GB | **12-16 GB** |
| **30B** | 240 GB | 48 GB | **24-30 GB** |
| **70B** | 560 GB | 88 GB | **46-50 GB** |
| **180B** | 1.4 TB | 240 GB | **128 GB** |

### 3.2 推荐硬件对应表

| 客户预算 | 硬件 | VRAM | 能 QLoRA 多大 | 适合 |
|:---|:---|:---:|:---:|:---|
| ¥3-8k | RTX 3060 12GB | 12 GB | **7B** | 个人 / 微型团队 |
| ¥6-12k | RTX 4060 Ti 16GB | 16 GB | **13B** | 个人 / 微型 |
| ¥15-30k | RTX 4090 24GB | 24 GB | **30B** | 中小组织主流 |
| ¥30-50k | Mac Studio M4 Max 128GB | 128 GB | **70B**（慢）| 中小组织高端 |
| ¥50-80k | RTX 5090 48GB | 48 GB | **70B**（QLoRA）| 中型组织 |
| ¥150-300k | A100 80GB | 80 GB | **70B**（QLoRA 快）| 高端 / 实验室 |
| ¥500万+ | 8×H100 80GB | 640 GB | **180B+** 全参 | HyperCapital 包 C |

### 3.3 Hyphae 默认硬件推荐（中小组织）

```
┌─────────────────────────────────────────────────┐
│  入门级（10-30 人组织）                            │
│  ─ Mac Studio M4 Pro 64GB ≈ ¥25k                │
│  ─ 跑 7-13B QLoRA / RAG                         │
│  ─ Hyphae Lite                                  │
├─────────────────────────────────────────────────┤
│  标准级（30-100 人组织）⭐ 主推                    │
│  ─ 服务器 + RTX 4090 24GB ≈ ¥30-40k             │
│  ─ 跑 13-30B QLoRA / 复杂 Agent / RAG           │
│  ─ Hyphae 标准                                  │
├─────────────────────────────────────────────────┤
│  专业级（100-200 人组织）                          │
│  ─ 服务器 + 2×RTX 5090 48GB ≈ ¥120-150k         │
│  ─ 跑 70B QLoRA 或并行多任务                     │
│  ─ Hyphae Pro                                   │
├─────────────────────────────────────────────────┤
│  企业级（>200 人或特殊场景）                       │
│  ─ HyperCapital 包 C 借用云端 H100              │
│  ─ 仅训练用，训练完权重下回客户机房              │
└─────────────────────────────────────────────────┘
```

---

## 4. Hyphae 训练栈默认组合

```
┌─────────────────────────────────────────────────┐
│  调度层：LLaMA-Factory + LlamaBoard WebUI         │
├─────────────────────────────────────────────────┤
│  加速层（单 GPU）：Unsloth + FlashAttention-2 +  │
│                  Liger Kernel                    │
├─────────────────────────────────────────────────┤
│  多 GPU 工程化：Axolotl + DeepSpeed (仅大客户)   │
├─────────────────────────────────────────────────┤
│  底层：Hugging Face PEFT + transformers +        │
│       bitsandbytes (QLoRA 量化)                 │
├─────────────────────────────────────────────────┤
│  推理输出：vLLM / Ollama / llama.cpp + GGUF     │
└─────────────────────────────────────────────────┘
```

---

## 5. 一句话

> **Hyphae 默认栈 = LLaMA-Factory（调度 + WebUI）+ Unsloth（单 GPU 加速）+ HF PEFT（底层）**。
> **中小组织主推 RTX 4090 24GB（¥30-40k）跑 13-30B QLoRA，覆盖 80% 场景**。

---

## 参考来源

- [LLaMA-Factory GitHub](https://github.com/hiyouga/LlamaFactory)
- [Unsloth GitHub](https://github.com/unslothai/unsloth)
- [Axolotl GitHub](https://github.com/OpenAccess-AI-Collective/axolotl)
- [Hugging Face PEFT](https://github.com/huggingface/peft)
- [Top 10 Open-Source Libraries to Fine-Tune LLMs Locally](https://www.analyticsvidhya.com/blog/2026/05/open-source-libraries-to-fine-tune-llm-locally/)
- [QLoRA Fine-Tuning Hardware Requirements](https://llmhardware.io/guides/llm-fine-tuning-hardware-requirements)
- [Profiling LoRA/QLoRA on Consumer GPUs](https://arxiv.org/pdf/2509.12229)
