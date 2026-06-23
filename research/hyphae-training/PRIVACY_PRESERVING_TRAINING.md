# PRIVACY_PRESERVING_TRAINING.md — 隐私保护训练三大路径

> ⭐ **这是 Hyphae Training 商业模式的核心**：怎么在保证客户数据隐私的前提下，提供训练服务并赚钱。

---

## 1. 问题：HyperCapital 训练服务的隐私悖论

```
客户矛盾：
  · 想用 HyperCapital 的 H100 加速训练（自己 4090 太慢）
  · 但不能把数据上传我们的服务器（合规 / 担心数据泄露）
                  ↓
       这就是 Firework 完全无解的问题
                  ↓
       Hyphae 必须有"隐私保护训练"才能赚训练钱
```

---

## 2. 三大隐私保护路径对比

| 路径 | 数据所在位置 | 模型权重所在位置 | 我们能看到啥 | 性能损失 | Hyphae 用法 |
|:---|:---|:---|:---|:---:|:---|
| **A. 纯本地训练** | 客户机房 | 客户机房 | 什么都看不到 | 0 | 默认模式（包 A）|
| **B. 联邦学习** | 各方机房 | 各方持有 + 聚合 | 仅看聚合梯度 | 10-30% | 多组织协作（v2） |
| **C. TEE 机密计算** | 我们的 H100 CC | 加密 GPU 内 | **加密的密文** | 2-5% | ⭐ 训练服务核心 |
| D. 差分隐私 | 任意 | 任意 | 看到加噪数据 | 15-30% | 可选叠加 |

---

## 3. 路径 A：纯本地训练（默认）

### 3.1 模式

客户在自己机房：
- 数据本地准备
- LLaMA-Factory + Unsloth 在客户 GPU 训练
- LoRA 权重存客户本地
- HyperCapital 只在远程辅导（看不到任何数据）

### 3.2 优缺点

✅ **隐私强度最高**（我们零接触）
✅ **合规无忧**（医疗 / 律所 / 政府放心）
✅ **成本最低**（无云端 GPU 费）

❌ **慢**（客户 4090 跑 13B QLoRA 可能要 1-3 天）
❌ **大模型不行**（70B 需要 ≥ 46GB VRAM，多数中小组织买不起）
❌ **运维复杂**（客户自己装环境）

### 3.3 HyperCapital 怎么赚钱

- **服务包 A**：远程辅导 ¥499-5000 一次性
  - 教客户装 LLaMA-Factory + Unsloth
  - 给客户数据准备脚本
  - 帮客户跑通第一次训练
  - 不接触数据
- **服务包 B 月度运维**：¥299-2999 / 月

### 3.4 适合谁

- 数据极度敏感（医院 / 律所 / 政府）
- 模型规模 ≤ 13B
- 客户能买得起 RTX 4090

---

## 4. 路径 B：联邦学习（Federated Learning）⭐ v2 核心

### 4.1 模式

```
┌────────────────────────────────────────────────────────────┐
│  联邦协调器（HyperCapital 提供）                              │
│                  ↑↑↑                                       │
│              聚合梯度                                       │
│                  ↑↑↑                                       │
│   ┌──────┴───────┬────────┐                                │
│   │              │        │                                │
│  律所 A         律所 B    律所 C                             │
│  本地训练       本地训练   本地训练                          │
│  数据不出门      数据不出门 数据不出门                        │
│                                                            │
│  每家律所贡献"梯度更新"，协调器聚合，                         │
│  形成共同的"律所行业 LoRA 权重"                              │
└────────────────────────────────────────────────────────────┘
```

### 4.2 GitHub Top 联邦学习框架

| 框架 | 公司 | 定位 | Hyphae 用 |
|:---|:---|:---|:---:|
| **NVIDIA FLARE** | NVIDIA | ⭐ 生产级，企业部署 | ⭐⭐⭐⭐⭐ |
| **Flower** | Adap (CMU) | 研究 / 原型，与 FLARE 集成 | ⭐⭐⭐⭐ |
| **FedML** | USC | 平衡（usability + scalability）| ⭐⭐⭐ |
| **OpenFL** | Intel | 开源，与 SGX 集成 | ⭐⭐⭐ |
| **IBM Federated Learning** | IBM | 企业级（闭源）| — |
| **FATE** | 微众银行 | 中国生态，跨组织联邦 | ⭐⭐⭐⭐ |
| **PySyft** | OpenMined | 隐私 PET 全栈 | ⭐⭐ |
| **Owkin Substra** | Owkin | 医疗联邦突出 | 医疗场景 |

> ⭐ **Hyphae v2 推荐栈**：NVIDIA FLARE（生产）+ Flower（开发原型）+ FATE（中国生态）

### 4.3 联邦学习的真实痛点（必须诚实告诉客户）

| 痛点 | 程度 | 应对 |
|:---|:---:|:---|
| **网络通信开销大** | 高 | 仅传梯度 + 量化 + 压缩 |
| **客户数据 IID 假设难成立** | 高 | 用 FedProx / FedAvgM 等改进算法 |
| **客户掉线频繁** | 中 | 异步联邦 + 容错 |
| **梯度反演攻击仍可能泄露数据** | 中 | 叠加差分隐私（DP-FedAvg）|
| **协调器仍需信任** | 中 | 用 TEE 跑协调器 |

### 4.4 HyperCapital 怎么赚钱

- **联邦运营服务**：¥3-10k / 月 / 联盟
- **行业联邦项目费**：¥50k-200k 一次性（搭建一个行业的联邦网络）
- **联邦协调器订阅**：¥999-9999 / 月 / 参与方
- **示例**：5 家律所联合训练"律所行业 LoRA" → HyperCapital 收每家 ¥2k/月 = 月入 ¥10k

### 4.5 适合场景

- 同行业多家中小组织合作（10+ 家律所、5+ 家小医院）
- 单家数据不够但合在一起足够
- 各家都希望"分享智慧而非数据"

---

## 5. 路径 C：TEE 机密计算 ⭐ HyperCapital 训练服务核心

### 5.1 模式

```
客户数据                              我们的 H100 CC GPU
  ↓                                        ↓
[本地加密]                          [TEE 加密容器]
  ↓                                        ↓
  ────────  TLS + Attestation ────────────→
  ↓                                        ↓
  我们只看到密文                       GPU 内解密 + 训练
                                            ↓
                                    [训练完的 LoRA 权重加密]
                                            ↓
  ←──────  TLS + Attestation  ────────────
  ↓
[本地解密]
  ↓
LoRA 权重存客户机房

我们全程能看到的：
  · 客户连接（IP）
  · 加密数据传输（密文）
  · GPU 算力使用量（用于计费）
  · 训练时长

我们看不到：
  · 训练数据原文
  · 模型权重明文
  · 训练过程中的中间状态
```

### 5.2 硬件支持

| GPU | TEE 支持 | 备注 |
|:---|:---:|:---|
| **NVIDIA H100 SXM5 / PCIe** | ✅ | Confidential Computing 模式 |
| **NVIDIA H200 SXM5** | ✅ | 同上 |
| **NVIDIA B200 SXM6** | ✅ | 同上 |
| **NVIDIA GB200 (Grace-Hopper)** | ✅ | CPU + GPU 集成 TEE |
| RTX 4090 / 5090 | ❌ | 消费级无 TEE |
| A100 | ❌ | 早期产品 |
| AMD MI300 | 部分 | 不成熟 |

**CPU 侧配套**：
- Intel TDX（推荐）
- AMD SEV-SNP（备选）

**完整栈**：CPU TEE（Intel TDX）+ GPU TEE（H100 CC）+ 加密内存（HBM 加密）

### 5.3 性能开销

- **NVIDIA 公布**：H100 CC 模式 LLM 推理开销 **2-5%**
- **训练**：开销略高，但 Intel TDX + H100 组合在数据传输环节 **4x 速度提升**
- **2025-2026 拐点**：业界从"太风险" → "如何快速部署"

### 5.4 第三方供应商（可借力）

| 供应商 | 提供 | Hyphae 合作 |
|:---|:---|:---|
| **Phala Network** | TEE GPU 算力 + Web3 集成 | ⭐ 首选合作 |
| **Together AI** | H100 CC 推理（训练待发布）| 备选 |
| **OpenRouter** | GPU TEE 推理已上 | 推理用 |
| **Spheron** | TEE GPU 云租用 | 灵活 |
| **AWS Nitro Enclaves** | 通用 TEE 云 | 企业级 |
| **Azure Confidential VMs** | 同上 | 企业级 |

> ⭐ Hyphae 建议先用 Phala（Web3 友好 + 我们的 aPNTs 计费可集成），用量大后自建 H100 CC 集群。

### 5.5 HyperCapital 怎么赚钱

- **TEE 训练服务**：按 GPU 小时计费
  - H100 CC：约 \$8-12/h（比 Firework \$7-12 略贵一点点，但有 TEE 隐私加成）
  - 客户单次训练 13B QLoRA：~6-12 小时 = ¥350-1000
  - 客户单次训练 70B QLoRA：~20-50 小时 = ¥1200-5000
- **训练辅导服务**（包 A 附加）：+¥999 帮客户配置 TEE 通道
- **合规审计报告**：¥2-5k 一份（给监管 / 客户法务）

### 5.6 适合场景

- 客户硬件不够 + 数据敏感 + 不能上普通云
- 模型 ≥ 30B（客户买不起 H100，但需要 H100 算力）
- 医疗 / 金融 / 政府刚需合规

### 5.7 关键卖点

> **"你的数据加密上传我们的 H100 CC GPU，在 GPU 内部解密 + 训练 + 加密回传 — 整个过程我们能看到的只有密文。NVIDIA 硬件级保证，连我们自己也偷不到你的数据。"**

---

## 6. 路径 D：差分隐私（DP-SGD）—— 可选叠加

### 6.1 原理

训练时每步在梯度上加噪声，使得"是否包含某条数据"在数学上不可区分。

### 6.2 工具

| 工具 | 公司 | 用法 |
|:---|:---|:---|
| **Opacus** | Meta | PyTorch 标准 DP 库 |
| **TensorFlow Privacy** | Google | TF 生态 |
| **JAX-Privacy** | DeepMind | JAX 生态 |

### 6.3 优缺点

✅ 数学可证的隐私保证（ε-差分隐私）
✅ 防止"成员推理攻击"（reverse-engineer 训练数据）

❌ **性能损失 15-30%**（噪声损害模型质量）
❌ 调参复杂（ε / δ / 噪声量级）

### 6.4 Hyphae 用法

**仅作叠加层**，不是主要路径。在路径 C 上额外开启 DP 选项（多收 ¥500-2000 / 单次训练）。

---

## 7. 综合建议：Hyphae 隐私分级产品

```
┌─────────────────────────────────────────────────────────────┐
│  Tier 1 - 普通：路径 A 本地训练                                │
│   ─ 客户自己机房，HyperCapital 远程辅导                        │
│   ─ ¥499-5000 一次性                                          │
│   ─ 适合：90% 客户场景                                         │
├─────────────────────────────────────────────────────────────┤
│  Tier 2 - 协作：路径 B 联邦学习                                │
│   ─ 多组织联邦，HyperCapital 协调                              │
│   ─ ¥3-10k / 月 / 联盟                                        │
│   ─ 适合：行业联盟（律所群 / 医院群）                          │
├─────────────────────────────────────────────────────────────┤
│  Tier 3 - 隐私加速：路径 C TEE 训练（⭐ 核心商业模式）          │
│   ─ HyperCapital 提供 H100 CC GPU                            │
│   ─ 按 GPU 小时计费 ¥56-90/h                                  │
│   ─ 适合：客户硬件不够 + 数据敏感                              │
├─────────────────────────────────────────────────────────────┤
│  Tier 4 - 极致隐私：C + D 组合                                │
│   ─ TEE + 差分隐私双重保护                                    │
│   ─ 加价 +¥500-2000 / 训练                                    │
│   ─ 适合：监管要求"数学可证"隐私                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. 一句话

> **Hyphae 训练服务的隐私护城河 = 本地默认（路径 A）+ TEE 机密计算（路径 C）+ 未来联邦协作（路径 B）**。
> **Firework 完全没有这块** —— 他们必须把数据传到自家普通 GPU 上跑。
> **这就是我们能赚训练服务钱的根本原因**：不只是便宜，而是"我们看不到你的数据"。

---

## 参考来源

- [Confidential GPU Computing NVIDIA TEE 2026](https://www.spheron.network/blog/confidential-gpu-computing-nvidia-tee-encrypted-vram/)
- [GPU Travelling: Efficient Confidential Collaborative Training (CCS25)](https://gzs715.github.io/pubs/GPUTRAVEL_CCS25.pdf)
- [Phala: Confidential LLMs](https://phala.com/learn/Confidential-LLMs)
- [Phala: How NVIDIA Enable Confidential AI](https://phala.com/learn/How-Nvidia-Enable-Confidential-AI)
- [Phala: AMD SEV vs Intel TDX vs NVIDIA GPU TEE](https://phala.com/learn/AMD-SEV-vs-Intel-TDX-vs-NVIDIA-GPU-TEE)
- [Confidential Computing on NVIDIA H100 GPU Performance Benchmark](https://arxiv.org/html/2409.03992v2)
- [Federated Learning GPU Cloud 2026 Guide](https://www.spheron.network/blog/federated-learning-gpu-cloud/)
- [Benchmarking Federated Learning Frameworks (arXiv 2511.00037)](https://arxiv.org/abs/2511.00037)
- [Supercharging Federated Learning with Flower and NVIDIA FLARE (arXiv 2407.00031)](https://arxiv.org/abs/2407.00031)
