# GITHUB_TOP20.md — GitHub Agent 框架 Top 20+ 调研与打分

> 数据时间：2026-06-23（gh CLI 实时搜索）
> 打分标准：见 [REQUIREMENTS.md](./REQUIREMENTS.md)（MOD/EVO/MEM/KB/LOCAL/SMB/OSS 七维加权）
> 说明：star 数为 2026-06 快照。本表按"对 Hyphae 适配度"分 5 组，而非单纯按 star 排名。

---

## 1. 总览：5 组分类

```
┌─────────────────────────────────────────────────────────────────┐
│  Group A — 本地优先 / 隐私 / 自托管（Hyphae 最贴合）              │
│   AnythingLLM · Cherry Studio · LocalAGI · ARGO · OwnPilot ·     │
│   Open WebUI · local-operator                                    │
├─────────────────────────────────────────────────────────────────┤
│  Group B — 记忆系统（Hyphae MEM 层候选）                        │
│   mem0 · Letta(MemGPT) · hindsight · memU · A-mem               │
├─────────────────────────────────────────────────────────────────┤
│  Group C — 自我演进（Hyphae EVO 层候选）                        │
│   GenericAgent · AgentEvolver · Agent0 · EvoAgentX             │
├─────────────────────────────────────────────────────────────────┤
│  Group D — 通用 Agent 编排框架（Hyphae 内核候选）              │
│   AgentScope · Qwen-Agent · smolagents · CrewAI · LangGraph ·  │
│   pydantic-ai · MetaGPT · CAMEL · microsoft/agent-framework    │
├─────────────────────────────────────────────────────────────────┤
│  Group E — RAG / 知识 / 工作流平台（Hyphae KB / 工作流候选）    │
│   Dify · Flowise · txtai · langflow · ruoyi-ai(中) · n8n       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Group A — 本地优先 / 隐私 / 自托管 ⭐ 最贴合

| 框架 | Stars | 语言 | License | 一句话 |
|:---|:---:|:---|:---|:---|
| **AnythingLLM** | 62.0K | JS | MIT-ish | Local-first 全功能 agent + RAG + 向量库 + 多模态 |
| **Open WebUI** | 142.7K | JS | BSD-ish | Ollama 的事实标准 UI，插件 + RAG + 多模型 |
| **Cherry Studio** | 47.7K | TS | 自定义 | 桌面 AI 工作室，300+ 助手 + MCP + agent + 本地模型 |
| **LocalAGI** (mudler) | 1.8K | Go | MIT | 自托管 AI Agent 平台，最大隐私，drop-in 替代 OpenAI |
| **ARGO** (xark-argo) | 793 | Python | 自定义 | "Local Manus" 到桌面，一键下模型 + LangGraph + DeepSeek |
| **OwnPilot** | 420 | TS | MIT | 隐私优先个人 AI，自主 agent + 工具编排 + 多 provider |
| **local-operator** | 206 | Python | 开源 | 本地 agent 工作区，后台干活的个人助理团队 |

### 打分

| 框架 | MOD | EVO | MEM | KB | LOCAL | SMB | OSS | 加权 |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **AnythingLLM** | 4 | 2 | 3 | **5** | **5** | **5** | 4 | **4.05** ⭐ |
| **Cherry Studio** | 4 | 2 | 3 | 4 | **5** | **5** | 3 | **3.85** |
| **ARGO** | 4 | 3 | 3 | 4 | **5** | 4 | 3 | **3.85** ⭐ |
| **LocalAGI** | 4 | 2 | 3 | 3 | **5** | 3 | **5** | **3.70** |
| **Open WebUI** | 3 | 1 | 2 | 4 | **5** | **5** | 4 | **3.45** |
| **OwnPilot** | 4 | 2 | 3 | 3 | 4 | 3 | **5** | **3.45** |
| **local-operator** | 3 | 2 | 3 | 3 | 4 | 3 | 4 | **3.20** |

**点评**：
- **AnythingLLM** — RAG + 本地 + 一键部署最均衡，中小组织开箱即用首选
- **ARGO** — "Local Manus" 定位，desktop + langgraph + 一键下模型，最接近"小组织 AI 大脑"形态
- **Cherry Studio** — 桌面体验最好、中文社区强，但 license 偏限制、偏"工具箱"非"框架"
- **LocalAGI** — Go 写、隐私最强、drop-in 替代，适合做底层 runtime

---

## 3. Group B — 记忆系统 ⭐ Hyphae MEM 层

| 框架 | Stars | 语言 | 一句话 |
|:---|:---:|:---|:---|
| **mem0** | 59.2K | Python | 通用记忆层，AI Agent 的"universal memory"，可全本地 |
| **Letta (MemGPT)** | 23.5K | Python | 有状态 agent 平台，高级记忆 + 自学习自改进 |
| **hindsight** (vectorize) | 17.0K | Python | "会学习的 agent 记忆" |
| **memU** (NevaMind) | 13.9K | Python | "从工作区到 agent 记忆" |
| **A-mem** (agiresearch) | 1.1K | Python | NeurIPS'25 论文，agentic memory |

### 打分（只评 MEM 相关维度 + LOCAL/OSS）

| 框架 | MEM | EVO | LOCAL | OSS | 备注 |
|:---|:---:|:---:|:---:|:---:|:---|
| **Letta** | **5** | 4 | 4 | **5** | 分层记忆 + 自我改进，Apache 2.0 ⭐ |
| **mem0** | **5** | 3 | 4 | 4 | 最流行，可本地（Qdrant + Ollama）⭐ |
| **hindsight** | 4 | 4 | 3 | 4 | 强调"学习型"记忆 |
| **memU** | 4 | 3 | 3 | 4 | 较新 |
| **A-mem** | 4 | 4 | 3 | 4 | 学术，参考价值 |

**点评**：
- **Letta（前 MemGPT）** — Hyphae MEM 层首选。分层记忆 + 自我改进 + Apache 2.0 + 可接本地模型，与"自我演进"诉求重叠
- **mem0** — 最流行、生态好、可全本地（Qdrant + Ollama），作为轻量替代

---

## 4. Group C — 自我演进 ⭐ Hyphae EVO 层

| 框架 | Stars | 一句话 |
|:---|:---:|:---|
| **GenericAgent** (lsdefine) | 13.0K | 自我演进 agent：从 3.3K 行种子长出技能树，6x 更省 token，含 memory-system |
| **AgentEvolver** (modelscope) | 1.5K | 阿里达摩，高效自我演进 agent 系统 |
| **Agent0** (aiming-lab) | 1.2K | ICML'26，从零数据自我演进 |
| **EvoAgentX / 各 survey** | 0.3-2.3K | 自我演进综述 + 资源库 |

### 打分

| 框架 | EVO | MOD | MEM | LOCAL | OSS | 备注 |
|:---|:---:|:---:|:---:|:---:|:---:|:---|
| **GenericAgent** | **5** | 4 | 4 | 4 | **5** | 技能树生长 + 计算机控制 + 记忆系统，MIT ⭐ |
| **AgentEvolver** | 4 | 3 | 3 | 3 | 4 | 阿里出品，工程化好 |
| **Agent0** | 4 | 2 | 3 | 3 | 4 | 偏研究 |

**点评**：
- **GenericAgent** — "从种子长技能树"正是用户说的"自我演进"。**Hyphae 不一定直接用，但其设计模式（skill tree growth + 经验回写）应被 Hyphae EVO 层借鉴**
- 自我演进整体仍偏研究阶段，生产采用需谨慎

---

## 5. Group D — 通用 Agent 编排框架 ⭐ Hyphae 内核候选

| 框架 | Stars | 语言 | 一句话 |
|:---|:---:|:---|:---|
| **MetaGPT** | 69.0K | Python | 多 agent 软件公司，自然语言编程 |
| **CrewAI** | 54.2K | Python | 角色扮演多 agent 编排 |
| **LangGraph** | 35.5K | Python | 构建有韧性的 agent（状态图）|
| **AgentScope** | 27.1K | Python | 阿里，可见可信的 agent + 完整 runtime/studio 生态 |
| **smolagents** | 28.0K | Python | HuggingFace，极简 code-thinking agent |
| **pydantic-ai** | 17.9K | Python | Pydantic 式类型安全 agent |
| **Qwen-Agent** | 16.6K | Python | 基于 Qwen，Function Calling + MCP + Code Interpreter + RAG |
| **CAMEL** | 17.2K | Python | 多 agent，研究 scaling law |
| **microsoft/agent-framework** | 11.6K | Python | 微软，编排 + 部署 |

### 打分

| 框架 | MOD | EVO | MEM | KB | LOCAL | SMB | OSS | 加权 |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Qwen-Agent** | **5** | 2 | 3 | 4 | **5** | 3 | 4 | **3.95** ⭐ |
| **AgentScope** | **5** | 3 | 3 | 3 | 4 | 3 | 4 | **3.75** ⭐ |
| **smolagents** | 4 | 2 | 2 | 3 | 4 | 3 | **5** | **3.40** |
| **LangGraph** | **5** | 2 | 3 | 3 | 4 | 2 | 4 | **3.55** |
| **CrewAI** | 4 | 2 | 3 | 3 | 3 | 3 | 4 | **3.20** |
| **pydantic-ai** | 4 | 1 | 2 | 2 | 4 | 2 | 4 | **2.95** |
| **MetaGPT** | 4 | 2 | 2 | 2 | 3 | 2 | 4 | **2.85** |

**点评**：
- **Qwen-Agent** — Hyphae 内核首选候选。原生 Qwen（Hyphae 主力模型）+ MCP + RAG + Code Interpreter + 本地友好，与 Hyphae 技术栈天然对齐 ⭐
- **AgentScope** — 阿里出品，生态最完整（runtime + studio + samples），可视化好，企业级 ⭐
- **smolagents** — 极简优雅，适合做轻量内核，但功能需自己补
- **LangGraph** — 状态图强大但偏底层，SMB 友好度低

---

## 6. Group E — RAG / 知识 / 工作流平台

| 框架 | Stars | 一句话 |
|:---|:---:|:---|
| **langflow** | 150.0K | 可视化构建 AI 工作流 |
| **Dify** | 146.2K | 生产级 agentic workflow 平台 |
| **Flowise** | 53.9K | 可视化构建 AI agents |
| **txtai** | 12.7K | 一体化语义搜索 + LLM 编排 + 工作流 |
| **ruoyi-ai** (中) | 5.4K | 中文企业级 AI 应用框架，知识库 + 多模型接入 |
| **n8n** | (大) | 通用工作流自动化（可接 Ollama）|

### 打分

| 框架 | MOD | KB | LOCAL | SMB | OSS | 加权 | 备注 |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| **Dify** | **5** | **5** | 4 | 4 | 4 | **4.4** | 工作流 + RAG + agent 一体，本地可部署 ⭐ |
| **txtai** | 4 | **5** | **5** | 3 | **5** | **4.3** | 全本地语义搜索 + 编排，轻量 ⭐ |
| **Flowise** | **5** | 4 | 4 | 4 | 4 | **4.1** | 可视化 agent，低代码 |
| **ruoyi-ai** | 4 | **5** | 4 | 4 | 4 | **4.2** | 中文企业 + 知识库，本土友好 ⭐ |
| **langflow** | **5** | 4 | 3 | 4 | 4 | **3.9** | 可视化强但偏重 |

**点评**：
- **Dify** — 工作流 + RAG + agent 全包，中小组织"无代码搭 AI 应用"最强，可本地部署 ⭐
- **txtai** — 最轻量的全本地知识 + 编排，适合嵌入 Hyphae 做 KB 层
- **ruoyi-ai** — 中文企业级，知识库强，本土生态友好，值得作为参考/起点

---

## 7. Hyphae 适配度 Top 12 总排名（跨组加权）

| 排名 | 框架 | 组 | 加权 | 在 Hyphae 中的角色 |
|:---:|:---|:---:|:---:|:---|
| 1 | **AnythingLLM** | A | 4.05 | 一体化壳 + RAG（开箱即用基线）|
| 2 | **Qwen-Agent** | D | 3.95 | Agent 编排内核（Qwen 对齐）|
| 3 | **Cherry Studio** | A | 3.85 | 桌面 UX 壳（终端用户触点）|
| 3 | **ARGO** | A | 3.85 | "Local Manus" 桌面形态参考 |
| 5 | **AgentScope** | D | 3.75 | 企业级编排内核（备选）|
| 6 | **LocalAGI** | A | 3.70 | 隐私 runtime 底层 |
| 7 | **Dify** | E | 4.4* | 工作流 + RAG（*仅 E 组维度）|
| 8 | **Letta** | B | 5.0* | 记忆层（*仅 MEM 维度）|
| 9 | **mem0** | B | 5.0* | 记忆层轻量替代 |
| 10 | **GenericAgent** | C | 5.0* | 自我演进模式借鉴 |
| 11 | **txtai** | E | 4.3* | 知识层轻量嵌入 |
| 12 | **ruoyi-ai** | E | 4.2* | 中文企业起点参考 |

> 注：带 * 的是单维度满分（记忆/演进/知识专精），不能与全维度加权直接比较。

---

## 8. 关键发现

1. **没有单一框架满足全部 5 条要求** —— 必须分层组合
2. **本地优先框架（Group A）SMB 友好但编排弱**；**编排框架（Group D）灵活但需技术**
3. **记忆 + 自我演进是分离的专精领域** —— Letta/mem0（记忆）+ GenericAgent（演进）
4. **Qwen-Agent 与 Hyphae 技术栈天然对齐**（都用 Qwen + 本地 + MCP）
5. **中文生态有专门玩家**（Cherry Studio / AgentScope / ruoyi-ai / Qwen-Agent）——本土化优势
6. **自我演进仍偏研究**，生产采用需谨慎，建议借鉴模式而非直接依赖

→ 完整组合方案见 [SYNTHESIS_RECOMMENDATION.md](./SYNTHESIS_RECOMMENDATION.md)。

---

## 参考（GitHub 仓库）

- AnythingLLM: github.com/Mintplex-Labs/anything-llm
- Cherry Studio: github.com/CherryHQ/cherry-studio
- LocalAGI: github.com/mudler/LocalAGI
- ARGO: github.com/xark-argo/argo
- OwnPilot: github.com/ownpilot/OwnPilot
- Open WebUI: github.com/open-webui/open-webui
- mem0: github.com/mem0ai/mem0
- Letta: github.com/letta-ai/letta
- GenericAgent: github.com/lsdefine/GenericAgent
- AgentScope: github.com/agentscope-ai/agentscope
- Qwen-Agent: github.com/QwenLM/Qwen-Agent
- smolagents: github.com/huggingface/smolagents
- Dify: github.com/langgenius/dify
- txtai: github.com/neuml/txtai
- ruoyi-ai: github.com/ageerle/ruoyi-ai
