# FEDERATED_LEARNING.md — 联邦学习专项调研（适配 Hyphae 流程与模式）

> **触发**：创始人 2026-06-24 要求 —— 单独调研适合 Hyphae 流程和模式的联邦学习框架。
> **场景前提**：同行业多个小组织（小服装厂群 / 民宿群 / 诊所群 / 培训机构群），单家数据不够，但不愿/不能共享原始数据，需要联合训出一个"行业模型"。
> **状态**：v0.1（2026-06-24）
> **关联**：[hyphae-training/PRIVACY_PRESERVING_TRAINING.md](./PRIVACY_PRESERVING_TRAINING.md) §4 · [hyphae/POSITIONING.md](../hyphae/POSITIONING.md) §4

---

## 0. 一句话结论

> **Hyphae 联邦学习选型：FATE-LLM（中文企业级 / 合规）或 FedML-FedLLM（生产 / 跨公司行业模型）做底座，采用 FedALT 式"个性化 LoRA + 共享行业 LoRA"算法，只交换 LoRA delta（8-40MB/轮）。这与 Hyphae 的"客户 LoRA + 行业 LoRA"两层架构天然同构。**

---

## 1. 为什么 Hyphae 需要联邦学习（不是可选，是关键拼图）

### 1.1 业务问题

```
单个小服装厂：
  数据量小（几千条订单/客户记录）→ 训不出好的行业 AI

10 家小服装厂联合：
  数据量够了，但——
  ❌ 不愿共享原始数据（客户名单 = 商业机密）
  ❌ 互为竞争对手，不信任中心化托管
  ❌ 监管/合规不允许数据出门
```

### 1.2 联邦学习的解

```
每家在本地训练 → 只上传"模型更新（LoRA delta）" → 聚合成"行业 LoRA"
  ✓ 原始数据永不出门
  ✓ 共享的是"行业智慧"，不是"客户数据"
  ✓ 每家拿回更强的行业模型 + 保留自己的个性化层
```

### 1.3 2026 年才实用的技术拐点 ⭐

> 联邦学习 2019 年不实用、2026 年实用的根本原因：**主流微调方法从全参变成了 LoRA。**

| 指标 | 全参联邦（旧）| LoRA 联邦（新）|
|:---|:---:|:---:|
| 每轮通信量 | ~14 GB | **8-40 MB** |
| 普通宽带可行 | ❌ | ✅ |
| 小组织参与门槛 | 极高 | 低 |

→ 只交换 LoRA delta,让"小组织用普通网络参与联邦"成为现实。

---

## 2. 框架全景（按对 Hyphae 适配度）

| 框架 | 出品 | 定位 | LLM/LoRA 支持 | 中文 | Hyphae 适配 |
|:---|:---|:---|:---:|:---:|:---:|
| **FATE-LLM** | 微众银行(WeBank) | 工业级 + 隐私 hub + IP 保护 | ✅ FATE-LLM | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **FedML / FedLLM** | FedML Inc. | 生产级 + 跨公司域模型 | ✅ FedLLM | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Flower / FlowerTune** | Adap (CMU) | 研究→生产 + HF 集成 | ✅ + FlowerTune 基准 | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **NVIDIA FLARE** | NVIDIA | 生产级编排 + 可靠性 | ✅ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **FederatedScope-LLM** | 阿里达摩 | 全面 LLM FL 套件 | ✅ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **OpenFedLLM** | 学术 | 指令微调 + PEFT 研究 | ✅ | ⭐⭐ | 参考 |
| **Shepherd** | 学术 | 轻量(Alpaca-LoRA+PEFT) | ✅ | ⭐⭐ | ⭐⭐⭐（轻量起步）|
| **OpenFL** | Intel | 开源 + SGX 集成 | 部分 | ⭐⭐ | ⭐⭐ |

---

## 3. 三个首选详评

### 3.1 FATE-LLM（中文合规首选）⭐⭐⭐⭐⭐

**出品**：微众银行（WeBank），FATE 是中国最成熟的开源联邦学习生态。

**为什么适合 Hyphae**：
- **中文生态最强** —— 文档、社区、合规对齐中国市场
- **隐私 hub**：集成多种 IP 保护 + 隐私保护机制（同态加密 / 差分隐私 / 安全聚合）
- **工业级**：金融级合规验证，适合诊所/培训等数据敏感行业
- **跨组织（cross-silo）**：天然为"多机构联合"设计，正是 Hyphae 同行联邦场景

**适用**：中国市场 + 数据极敏感行业（诊所/律所/教育）的行业联邦。

### 3.2 FedML / FedLLM（跨公司行业模型首选）⭐⭐⭐⭐⭐

**出品**：FedML Inc.，生产级联邦学习生态。

**为什么适合 Hyphae**：
- **FedLLM 明确支持"跨不同公司协作训练领域专属 LLM"** —— 这就是 Hyphae"同行业多组织共训行业模型"的标准用例
- **生产就绪**：模型管理 + 训练编排 + 跨平台（含边缘设备）
- 开源模板支持联邦 BERT/GPT 训练

**适用**：跨公司行业模型训练的主力框架。

### 3.3 Flower / FlowerTune（HF 集成 + 灵活）⭐⭐⭐⭐

**出品**：Adap（CMU 系）。

**为什么适合 Hyphae**：
- **与 HuggingFace Transformers 深度集成** —— 与 Hyphae 的 LLaMA-Factory/PEFT 栈对接顺畅
- **FlowerTune**：跨域联邦微调基准，可直接参考评测
- 语言无关 API + 跨设备/跨机构 + 自定义策略灵活
- 可与 NVIDIA FLARE 运行时集成（开发用 Flower，生产跑 FLARE）

**适用**：开发原型 + 与现有 PEFT 栈集成。

---

## 4. 关键算法：FedALT 式个性化 LoRA ⭐ 与 Hyphae 架构同构

### 4.1 Hyphae 两层 LoRA = 联邦个性化 LoRA

> 这是本调研最重要的发现：**Hyphae 早已设计的"客户 LoRA + 行业 LoRA"两层架构，正好是联邦学习前沿的"个性化 LoRA"范式。**

```
学术界（FedALT, 2025）          Hyphae（早已设计）
─────────────────────          ──────────────────
个性化 LoRA（每客户本地）    =   客户 LoRA（每组织本地，数据不出门）
       +                              +
Rest-of-World 共享 LoRA      =   行业 LoRA（联邦聚合，跨同行共享）
```

每个客户：
- 持续训练**自己的个性化 LoRA**（本地，数据不出门）
- 通过独立的**共享 LoRA 组件**吸收行业共识

### 4.2 相关前沿算法（2025-2026）

| 算法 | 年 | 解决什么 | Hyphae 用 |
|:---|:---:|:---|:---:|
| **FedALT** | 2025 | 个性化 LoRA + Rest-of-World 共享 | ⭐ 主参考 |
| **SDFLoRA** | 2025 | 异构客户的选择性解耦联邦 LoRA | 异构组织 |
| **FedMomentum** | 2026 | 保留 LoRA 训练动量 | 收敛优化 |
| **Ravan** | 2026 | 多头低秩适配联邦微调 | 进阶 |

> Hyphae 不需要自研算法，直接采用 FedALT 式范式 + FATE-LLM/FedML 工程实现即可。

---

## 5. Hyphae 联邦学习落地方案

### 5.1 推荐技术栈

```
┌──────────────────────────────────────────────────────────┐
│  联邦编排：FATE-LLM（中文/合规）或 FedML-FedLLM（生产）    │
├──────────────────────────────────────────────────────────┤
│  算法范式：FedALT 式个性化 LoRA                            │
│  ─ 客户 LoRA（本地个性化，数据不出门）                     │
│  ─ 行业 LoRA（联邦聚合，跨同行共享）                       │
├──────────────────────────────────────────────────────────┤
│  本地训练：LLaMA-Factory + Unsloth + PEFT（每个组织节点）  │
├──────────────────────────────────────────────────────────┤
│  隐私加固：安全聚合 + 差分隐私（可选）+ TEE 协调器（可选）  │
├──────────────────────────────────────────────────────────┤
│  通信：只传 LoRA delta（8-40MB/轮），普通宽带即可          │
└──────────────────────────────────────────────────────────┘
```

### 5.2 与 Hyphae 商业模式的契合（见 POSITIONING §4）

| 联邦学习能力 | 对应 Hyphae 价值 |
|:---|:---|
| 同行多组织共训行业 LoRA | "行业 playbook"产品化的技术实现 |
| 数据不出门 | 隐私保护前提（卖点 + 合规）|
| 经验自动汇集 | "找路径"的护城河自动加深（合伙人行业经验 → 数据资产）|
| LoRA delta 轻通信 | 小组织低门槛参与 |

### 5.3 商业设计：联邦如何赚钱 + 不踩坑

- **行业联邦订阅**：参与某行业联邦的组织付订阅费，拿回持续更新的行业 LoRA
- **运营合伙人组织联邦**：区域/行业合伙人负责"拉同行入伙 + 落地"，分润（见 POSITIONING §3.1）
- **隐私是硬前提**：任何一次数据泄露事故 = 整个行业联邦信任崩塌，必须 TEE/安全聚合兜底
- **冷启动**：第一个行业先用"创始人行业经验 + 合成数据"做出种子行业 LoRA，再用联邦持续增强

---

## 6. 落地路线

| 阶段 | 动作 | 周期 |
|:---:|:---|:---:|
| v1 | 单组织本地 LoRA（无联邦），验证"找路径"产品化 | 已在 training 路线 |
| v1.5 | 2-3 家同行试点联邦（Flower 原型 + FedALT 范式）| +6 周 |
| v2 | FATE-LLM / FedML 生产部署，首个行业联邦（如服装厂群）| +12 周 |
| v2.5 | 运营合伙人组织多行业联邦 + 隐私加固（安全聚合/TEE）| +持续 |

---

## 7. 一句话

> **联邦学习是 Hyphae"行业 playbook 产品化"和"护城河自动加深"的技术底座。**
> **选型：FATE-LLM（中文/合规）或 FedML-FedLLM（跨公司行业模型），算法用 FedALT 式个性化 LoRA —— 它与 Hyphae 早已设计的"客户 LoRA + 行业 LoRA"两层架构天然同构。**
> **只传 LoRA delta（8-40MB/轮）让小组织能用普通宽带参与，这是 2026 年才成立的实用拐点。**

---

## 参考来源

- [FedALT: Federated Fine-Tuning through Adaptive Local Training with Rest-of-World LoRA (arXiv 2503.11880)](https://arxiv.org/abs/2503.11880)
- [SDFLoRA: Selective Decoupled Federated LoRA (arXiv 2601.11219)](https://arxiv.org/pdf/2601.11219)
- [FedMomentum (arXiv 2603.08014)](https://arxiv.org/pdf/2603.08014)
- [FlowerTune: Cross-Domain Benchmark for Federated Fine-Tuning of LLMs (arXiv 2506.02961)](https://arxiv.org/html/2506.02961v1)
- [A Deep Dive into Federated Learning of LLMs (ADaSci)](https://adasci.org/a-deep-dive-into-federated-learning-of-llms/)
- [Federated Learning on GPU Cloud 2026 Guide (Spheron)](https://www.spheron.network/blog/federated-learning-gpu-cloud/)
- [Synergizing Foundation Models and Federated Learning: A Survey (arXiv 2406.12844)](https://arxiv.org/pdf/2406.12844)
- FATE-LLM (WeBank) · FedML/FedLLM (FedML Inc.) · FederatedScope-LLM (Alibaba) · OpenFedLLM · Shepherd
