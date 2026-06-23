# PAPERS_AND_RESEARCH.md — 关键论文与研究思路

> 目的：让工程师 + 研究者快速锁定该读什么、什么时候用什么。

---

## 1. 核心论文 12 篇（按推荐阅读顺序）

### 1.1 PEFT / LoRA 系列（Hyphae 主战场）

| # | 论文 | 年 | 影响力 | 一句话 | Hyphae 用 |
|:---:|:---|:---:|:---:|:---|:---:|
| 1 | **LoRA** (Hu et al., Microsoft) | 2021 | ⭐⭐⭐⭐⭐ | 低秩矩阵分解，冻结 base + 训练 0.5% 参数 | ✅ 必读 |
| 2 | **QLoRA** (Dettmers et al., U.Washington) | 2023 | ⭐⭐⭐⭐⭐ | 4-bit 量化 + LoRA，单 GPU 65B 模型 | ✅ 必读 |
| 3 | **DoRA** (NVIDIA) | 2024 | ⭐⭐⭐⭐ | Weight-Decomposed LoRA，效果常优于 LoRA | ✅ 用 |
| 4 | **IA3** (Liu et al.) | 2022 | ⭐⭐⭐ | 更少参数的 PEFT（只调 Key/Value 缩放）| 备选 |
| 5 | **Prefix Tuning** (Li & Liang) | 2021 | ⭐⭐⭐ | 在 prompt 前加可训练 prefix | 早期 PEFT |
| 6 | **AdaLoRA** | 2023 | ⭐⭐⭐ | 动态分配 LoRA rank | 进阶 |
| 7 | **GaLore** (Zhao et al., CMU) | 2024 | ⭐⭐⭐⭐ | Gradient Low-Rank Projection，全参微调内存降 65% | ✅ LLaMA-Factory 已集成 |

### 1.2 隐私保护训练系列

| # | 论文 | 年 | 影响力 | 一句话 | Hyphae 用 |
|:---:|:---|:---:|:---:|:---|:---:|
| 8 | **DP-SGD** (Abadi et al., Google) | 2016 | ⭐⭐⭐⭐ | 差分隐私 SGD 奠基论文 | ✅ Opacus 实现 |
| 9 | **FedAvg** (McMahan et al., Google) | 2017 | ⭐⭐⭐⭐⭐ | 联邦学习开山论文 | ✅ Flower / FLARE 基础 |
| 10 | **FedProx** (Li et al.) | 2020 | ⭐⭐⭐⭐ | 改进 FedAvg 处理非 IID 数据 | ✅ 多组织实际场景 |
| 11 | **DP-FedAvg** (Geyer et al.) | 2017 | ⭐⭐⭐ | 联邦 + 差分隐私结合 | 进阶 |
| 12 | **GPU Travelling** (CCS25) | 2025 | ⭐⭐⭐ | TEE GPU 协作训练新方案 | 前沿参考 |

---

## 2. 论文要点速记（工程师 30 秒理解）

### LoRA (2021)
```
全参微调：W' = W + ΔW   （ΔW 维度 = W 维度，d×k）
LoRA：    W' = W + BA   （B 维度 d×r，A 维度 r×k，r << d/k）

只训练 B 和 A，参数减少 d×k → 2×r×(d+k)，r=8 时减少 99%+
推理时把 BA 合并回 W，速度无损
```

### QLoRA (2023)
```
1. base model 量化到 4-bit (NF4)，VRAM 减 4x
2. 计算时 dequantize 到 16-bit
3. 在 16-bit 上加 LoRA
4. Paged Optimizers (NVIDIA unified memory) 防 OOM
结果：65B 模型在单张 48GB GPU 上微调
```

### DoRA (2024)
```
LoRA: ΔW = BA
DoRA: 把 W 分解为方向 V 和幅度 m，分别训练
       W = m × (V / ||V||)
       ΔV 用 LoRA，m 直接训
效果：r=16 + all-linear，0.5% 参数捕捉行为变化
```

### DP-SGD (2016)
```
每步梯度：
  1. clip 单样本梯度 (限制 L2 范数到 C)
  2. 加 Gaussian 噪声 N(0, σ²C²I)
  3. 累加 + 更新
隐私预算：ε-DP, smaller ε = stronger privacy
代价：模型质量损失 15-30%
```

### FedAvg (2017)
```
1. 服务器分发当前模型 w_t 给 K 客户
2. 每客户在本地数据上跑 E epoch
3. 客户发回更新后的 w_t+1^k
4. 服务器加权平均：w_t+1 = Σ (n_k/n) w_t+1^k
通信代价 = 模型大小 × 客户数 / 轮
```

### GPU Travelling (2025)
```
问题：H100 CC 单 GPU 训练慢，多 GPU 拼起来又破坏 TEE
方案：
  1. 数据 chunk 加密，每 chunk 用不同 GPU 的 TEE 解密训练
  2. 中间梯度走加密通道
  3. 4x 数据传输速度（vs 传统加密通道）
```

---

## 3. 业界研究方向（2026 热点）

### 3.1 PEFT 前沿

- **Mixture of LoRA Experts (MoLE)**：多个 LoRA 像 MoE 一样路由
- **LongLoRA**：长上下文专用 LoRA
- **Continual LoRA**：增量学习不遗忘
- **Spectrum**：基于 SNR 自动选层微调

### 3.2 联邦学习前沿

- **Asynchronous Federated Learning**（异步联邦，解决慢节点问题）
- **Personalized FL**（每客户保留个性化层）
- **Federated LoRA**（仅交换 LoRA 权重而非全模型梯度）
- **Cross-silo Hierarchical FL**（组织内集中 + 组织间联邦）

### 3.3 TEE / 机密计算前沿

- **Multi-GPU TEE**（多卡 TEE 组网，挑战巨大）
- **TEE with FHE**（TEE + 全同态加密双重保护）
- **Decentralized Attestation**（去中心化远程证明）

### 3.4 RAG + Fine-tune 混合

- **RAFT** (Retrieval-Augmented Fine-Tuning, 2024)：用 RAG 数据训练模型学会 RAG 风格
- **HyDE** (Hypothetical Document Embeddings)：先生成假设答案再检索
- **GraphRAG** (Microsoft)：构建知识图谱辅助检索

---

## 4. Hyphae 必读清单（按角色）

### 工程师必读 5 篇
1. LoRA
2. QLoRA
3. DoRA
4. FedAvg
5. GaLore

### 商业 / PM 必读 3 篇
1. **RAG vs Fine-tuning** (Databricks blog) — 决策框架
2. **2024 State of Open-Source LLMs** (Hugging Face)
3. **Confidential Computing 综述** (Spheron / Phala blogs)

### 隐私 / 合规必读 4 篇
1. DP-SGD
2. FedAvg + FedProx
3. Confidential Computing on H100 GPU benchmark
4. GPU Travelling (CCS25)

---

## 5. 数据集（用于训练 + 评测）

### 通用数据集

| 名称 | 用途 | 大小 |
|:---|:---|:---|
| **Alpaca / Vicuna ShareGPT** | 通用 instruction tuning | 50k-500k 样本 |
| **OpenAssistant OASST** | 多语言对话 | 160k 样本 |
| **UltraChat** | 高质量多轮对话 | 1.5M 样本 |
| **HuatuoGPT-II** | 医疗中文 | ~1M |
| **MOSS** | 中文通用对话 | 1M+ |

### 评测基准

| 名称 | 评测 |
|:---|:---|
| **MMLU** | 通用知识 |
| **C-Eval / CMMLU** | 中文知识 |
| **GSM8K** | 数学推理 |
| **HumanEval** | 代码生成 |
| **MT-Bench / AlpacaEval** | 指令遵循 |

---

## 6. 推荐 GitHub 实战教程

| 教程 | 适合 |
|:---|:---|
| `unsloth/notebooks` | 单 GPU 快速上手（Colab 可跑）|
| `hiyouga/LLaMA-Factory/tree/main/examples` | 各种训练方法示例 |
| `OpenAccess-AI-Collective/axolotl/tree/main/examples` | 多 GPU 工程化 |
| `huggingface/peft/tree/main/examples` | PEFT 各种方法 |
| `Adap/flower/tree/main/examples` | 联邦学习入门 |
| `NVIDIA/NVFlare/tree/main/examples` | 生产级联邦学习 |

---

## 7. Hyphae 建议研究投入

| 投入 | 时长 | 收益 |
|:---|:---:|:---|
| 工程师读完 LoRA + QLoRA + DoRA + 跑 Unsloth notebook | 1 周 | 能给客户做基础微调 |
| + GaLore + AdaLoRA + Axolotl 工程化 | + 2 周 | 能做产品化模板 |
| + Flower + NVIDIA FLARE 联邦实验 | + 1 月 | 能做联邦试点 |
| + H100 CC + Intel TDX 部署 | + 1 月 | 能做 TEE 训练服务 |

总计 **~3 月**完成 Hyphae Training 完整能力建设。

---

## 8. 一句话

> **Hyphae 研究投入 = QLoRA/DoRA 基础（1 周）→ 工程化（2 周）→ 联邦学习（1 月）→ TEE 训练（1 月） = 3 个月达到生产能力**。
> **不需要发论文，复用现有成熟方案即可**。
