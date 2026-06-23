# Hyphae Agents — Agent 框架选型调研

> **触发**：用户 2026-06-23 —— 在 Hyphae（中小组织专属智能菌丝）业务前提下，调研 GitHub + 小红书的 Agent 框架，找出最适配方案。
> **要求**：能自定义/模块化 + 自我演进 + 自有记忆和知识库 + 用本地小模型 + 适配 Mac 32-128GB 小组织硬件。
> **状态**：v0.1 完整调研（2026-06-23）
> **维护**：Brood orchestrator
> **关联**：[research/hyphae](../hyphae)（主项目）+ [research/hyphae-training](../hyphae-training)（训练栈）

---

## 0. 一句话结论

> **不要找"一个框架"，要搭"一套分层组合"**：
> **Ollama/MLX（模型）+ Qwen-Agent（编排）+ Letta/mem0（记忆）+ AnythingLLM/txtai（知识库）+ GenericAgent 模式（自我演进）+ Cherry Studio/ARGO（桌面壳）**，叠加 Hyphae 行业 LoRA + 决策框架 + HyperCapital 部署服务。
>
> 用户的 5 条要求没有任何单一框架能全满足——每条都有专精的成熟开源方案，组合才是最优解。

---

## 1. 文档索引（建议阅读顺序）

| # | 文档 | 内容 | 阅读对象 |
|:---:|:---|:---|:---|
| 1 | [README.md](./README.md) | 本文件 | 所有人 |
| 2 | [REQUIREMENTS.md](./REQUIREMENTS.md) | 5 条要求形式化为 7 维评分 rubric | 决策者 |
| 3 | [GITHUB_TOP20.md](./GITHUB_TOP20.md) | GitHub Agent 框架 Top 20+ 分 5 组打分 | 工程师 |
| 4 | [XHS_DIGEST.md](./XHS_DIGEST.md) | 小红书调研——中文用户真实需求信号 | 产品 / 运营 |
| 5 | [MEMORY_KNOWLEDGE_LOCALMODEL.md](./MEMORY_KNOWLEDGE_LOCALMODEL.md) | 记忆/知识库/本地模型三子系统详评 | 工程师 |
| 6 | [SYNTHESIS_RECOMMENDATION.md](./SYNTHESIS_RECOMMENDATION.md) ⭐ | **最终答案：分层组合 + 三种落地形态 + 路线** | **决策者必读** |

---

## 2. 调研方法

| 数据源 | 工具 | 覆盖 |
|:---|:---|:---|
| **GitHub** | gh CLI（agent-reach 底层）| 30+ 框架实时 star/lang/license/topics |
| **小红书** | xhs CLI（agent-reach 底层）| 6 个关键词 × 高赞内容 |
| **Web** | WebSearch / WebFetch | 补充技术细节 |

> agent-reach v1.5.0 状态：13 平台 11 可用（GitHub + 小红书 + X + Reddit + B站 + YouTube + ... 全绿；仅 LinkedIn / Exa 未配）。

---

## 3. 核心结论速览

### 3.1 推荐技术栈（分层）

```
L5 UX 壳      Cherry Studio / ARGO / AnythingLLM
L4 编排       Qwen-Agent（首选）/ AgentScope
L3 记忆       Letta / mem0
L3 知识库     AnythingLLM / txtai / RAGFlow
L3 演进       GenericAgent 模式（借鉴）
L2 模型       Qwen 2.5/3 + 行业 LoRA + 客户 LoRA
L1 runtime    Ollama / MLX
L0 硬件       Mac Studio 32/64/128GB
```

### 3.2 三种落地形态

| 形态 | 组合 | 客户占比 | HyperCapital 包 |
|:---:|:---|:---:|:---|
| **A 开箱** | AnythingLLM + Ollama + Qwen 14B | 60% | 包 A |
| **B 标准** ⭐ | + Qwen-Agent + Letta + Cherry Studio | 30% | 包 A2/B |
| **C 进阶** | + 自我演进 + 客户 LoRA + 多 agent | 10% | 包 C |

### 3.3 买 vs 拼 vs 造

> **拼**（分层组合）✅ 推荐 —— 不买单体（被局限）、不从零造（浪费 12 月）。
> Hyphae 工程重点 = 黏合层 + 行业 LoRA + 决策框架 + 部署服务，**不是重写 agent 框架**。

---

## 4. 关键发现

1. **没有单一框架满足全部 5 条** → 必须分层组合
2. **本地小模型一票否决** → 砍掉一半"只能调 GPT"的框架
3. **Qwen 生态是天然主场**（模型 Qwen + 编排 Qwen-Agent + 可视化 AgentScope 同源）
4. **Letta 一箭双雕**（记忆 + 自我改进）
5. **小红书印证**：知识库/记忆是中文第一刚需（个人级已爆，**组织级空白 = Hyphae 无人区**）
6. **"数字同事"叙事已破圈** → Hyphae 营销语言现成
7. **真护城河不在框架**（都开源）→ 在黏合层 + 行业 LoRA + HyperCapital 服务 + 组织级卡位

---

## 5. Top 12 框架适配排名

| # | 框架 | 角色 | Stars |
|:---:|:---|:---|:---:|
| 1 | AnythingLLM | 一体化壳 + RAG | 62.0K |
| 2 | Qwen-Agent | 编排内核 | 16.6K |
| 3 | Cherry Studio | 桌面壳 | 47.7K |
| 3 | ARGO | Local Manus 形态 | 793 |
| 5 | AgentScope | 企业级编排 | 27.1K |
| 6 | LocalAGI | 隐私 runtime | 1.8K |
| 7 | Dify | 工作流 + RAG | 146.2K |
| 8 | Letta | 记忆层 | 23.5K |
| 9 | mem0 | 记忆层轻量 | 59.2K |
| 10 | GenericAgent | 自我演进模式 | 13.0K |
| 11 | txtai | 知识层嵌入 | 12.7K |
| 12 | ruoyi-ai | 中文企业起点 | 5.4K |

---

## 6. 下一步

| P0 | 用户 review 分层组合方向 |
|:---:|:---|
| **P0** | v0.1 形态 A PoC（AnythingLLM + Ollama + Qwen 14B + 1 种子组织）|
| **P1** | Qwen-Agent + Letta 集成 PoC（形态 B 内核）|
| **P1** | 评估 Cherry Studio / ARGO / AnythingLLM 壳的商用 license |
| **P2** | GenericAgent 自我演进模式拆解 → Hyphae EVO 层设计 |
| **P2** | "组织 AI 硬件配置计算器"（小红书印证吸量）|

---

## 7. License

研究文档 MIT。
