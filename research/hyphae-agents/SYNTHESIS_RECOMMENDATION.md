# SYNTHESIS_RECOMMENDATION.md — 综合分析 + Hyphae 选型推荐（最终答案）

> ⭐ **这是用户要的答案**：在 Hyphae（中小组织专属智能菌丝）业务前提下，应该用什么方案、什么场景才能最好适配。
> 整合 [REQUIREMENTS](./REQUIREMENTS.md) + [GITHUB_TOP20](./GITHUB_TOP20.md) + [XHS_DIGEST](./XHS_DIGEST.md) + [MEMORY_KNOWLEDGE_LOCALMODEL](./MEMORY_KNOWLEDGE_LOCALMODEL.md)。
> **声明**：Claude 基于 2026-06 公开信息的综合判断，非最终工程决定。

---

## 0. 一句话结论

> **不要找"一个框架"，要搭"一套分层组合"：Ollama/MLX（模型）+ Qwen-Agent 或 AgentScope（编排内核）+ Letta/mem0（记忆）+ AnythingLLM/txtai（知识库）+ GenericAgent 模式（自我演进）+ Cherry Studio/ARGO（桌面壳），再叠加 Hyphae 行业 LoRA + 决策框架。**
>
> **理由**：用户的 5 条要求（自定义/自我演进/记忆/知识库/本地小模型）**没有任何单一框架能全满足**——每一条都有专精的成熟开源方案，组合起来才是最优解。

---

## 1. 核心判断（5 条）

### 判断 1：单体框架是陷阱，分层组合是正道

所有"号称全包"的框架（AnythingLLM / Dify / Cherry Studio）在某一维度强、其他维度弱。
强行用单体 = 在某一维度被卡死。
**分层组合**让每层选最优，且每层可独立替换升级。

### 判断 2：本地小模型把候选池砍掉一大半

一票否决线（LOCAL ≥ 2）直接淘汰了大量"实质只能调 GPT/Claude"的框架。
**剩下的真本地玩家**：AnythingLLM / Cherry Studio / ARGO / LocalAGI / Open WebUI / Qwen-Agent / AgentScope / txtai / Ollama 生态。

### 判断 3：Qwen 生态是 Hyphae 的天然主场

- 模型：Qwen 2.5/3（中文 + Function Calling + 本地友好）
- 编排：Qwen-Agent（原生 Qwen + MCP + RAG + Code Interpreter）
- 可视化：AgentScope（阿里，生态完整）
- 三者同源，集成成本最低，中文最强。

### 判断 4：记忆 + 自我演进可以"一箭双雕"

**Letta（MemGPT）** 同时覆盖"分层记忆"和"自我改进"两个维度。
选 Letta 作记忆层，等于免费拿到一部分自我演进能力。
更激进的"技能树生长"借鉴 GenericAgent 的模式，不必直接依赖。

### 判断 5：中小组织的真 gap 不是技术，是"组织级 + 业务落地 + 部署服务"

- 小红书印证：个人知识库已爆，**组织级几乎空白**
- 技术栈全是开源现成的，**护城河在 HyperCapital 的部署 + 行业 know-how**（见 hyphae-training）

---

## 2. Hyphae 推荐技术栈（分层定稿）

```
┌────────────────────────────────────────────────────────────────────┐
│  L6 终端触点    浏览器 / 钉钉 / 飞书 / 微信 / 桌面客户端              │
├────────────────────────────────────────────────────────────────────┤
│  L5 UX 壳       Cherry Studio（中文桌面首选）                        │
│                 或 ARGO（Local Manus 形态）                          │
│                 或 AnythingLLM（开箱即用 + RAG 内置）                │
├────────────────────────────────────────────────────────────────────┤
│  L4 Agent 编排   Qwen-Agent（首选，Qwen 对齐）                       │
│                 或 AgentScope（企业级，可视化）                      │
│                 ─ 模块化工具 + MCP + 子 agent + SOP 编排            │
├────────────────────────────────────────────────────────────────────┤
│  L3 三大能力子系统（全部客户本地）                                   │
│   ┌─────────────┬──────────────┬───────────────────┐              │
│   │ 记忆 MEM    │ 知识库 KB    │ 自我演进 EVO       │              │
│   │ Letta/mem0  │ AnythingLLM  │ GenericAgent 模式  │              │
│   │             │ /txtai/RAGFlow│ (技能树+经验回写)  │              │
│   └─────────────┴──────────────┴───────────────────┘              │
├────────────────────────────────────────────────────────────────────┤
│  L2 模型层      Qwen 2.5/3 + 行业 LoRA + 客户 LoRA                  │
│                 （LoRA 见 hyphae-training）                          │
├────────────────────────────────────────────────────────────────────┤
│  L1 推理 runtime Ollama（默认）/ MLX（Mac 极速）                    │
├────────────────────────────────────────────────────────────────────┤
│  L0 硬件        Mac Studio 32/64/128GB（小组织 AI 大脑）            │
└────────────────────────────────────────────────────────────────────┘
```

### 每层选型理由速查

| 层 | 首选 | 备选 | 理由 |
|:---|:---|:---|:---|
| L5 UX 壳 | Cherry Studio | ARGO / AnythingLLM | 中文桌面体验 + MCP + 本地模型 |
| L4 编排 | Qwen-Agent | AgentScope | Qwen 同源 + MCP + RAG + 本地 |
| L3 记忆 | Letta | mem0 | 分层记忆 + 自我改进双覆盖 |
| L3 知识库 | AnythingLLM | txtai / RAGFlow | 开箱 RAG + 本地向量库 |
| L3 演进 | GenericAgent 模式 | AgentEvolver | 借鉴技能树，不强依赖 |
| L2 模型 | Qwen 2.5/3 | DeepSeek 蒸馏 | 中文 + Function Call + LoRA |
| L1 runtime | Ollama | MLX / LM Studio | 易用 + OpenAI 兼容 |
| L0 硬件 | Mac Studio M4 Max 128GB | M4 Pro 64GB | 跑 70B + 多模型并存 |

---

## 3. 三种落地形态（按客户复杂度）

### 形态 A — 开箱即用（入门，60% 客户）

```
AnythingLLM（一体化：UI + agent + RAG + 本地模型）
   + Ollama + Qwen 14B
   + 客户文档导入知识库
```
- HyperCapital 包 A 部署，30-60 分钟
- 适合：只要"会读我们文档的 AI 助手"的客户
- 不含：复杂 agent 编排、自我演进

### 形态 B — 标准组合（主流，30% 客户）⭐

```
Cherry Studio（壳）
   + Qwen-Agent（编排内核）
   + Letta（记忆）
   + AnythingLLM/txtai（知识库）
   + Ollama + Qwen 32B + 行业 LoRA
```
- HyperCapital 包 A2/B 部署 + 运维
- 适合：要"业务流程辅助 + 记忆 + 知识库"的组织
- 含：模块化工具、记忆、知识库；演进为轻量

### 形态 C — 进阶全栈（高端，10% 客户）

```
形态 B + GenericAgent 自我演进模式
        + 客户 LoRA 月度增量训练
        + TEE 训练（见 hyphae-training）
        + 多 agent SOP 编排（AgentScope）
```
- HyperCapital 包 C 定制项目
- 适合：要"战略决策辅助 + 自我演进"的组织
- 含：全部 5 条要求

---

## 4. 对应 Hyphae 业务场景的适配

| Hyphae 业务诉求（见 hyphae-training）| 用哪层 | 形态 |
|:---|:---|:---:|
| 写朋友圈/海报/文案（入门）| L2 LoRA + L4 编排 | A |
| 读公司文档/合同/规范 | L3 知识库（AnythingLLM）| A |
| 记住客户/门店历史决策 | L3 记忆（Letta）| B |
| 业务流程 SOP 辅助 | L4 编排（Qwen-Agent）+ L3 记忆 | B |
| 获客/提效综合决策 | L4 多 agent + L3 全部 + 实时 Tool | C |
| 战略决策 + 自我迭代 | L3 演进 + 客户 LoRA 增量 | C |

---

## 5. 关键决策：买 vs 拼 vs 造

| 选项 | 做法 | 评价 |
|:---|:---|:---|
| **买**（单一框架）| 直接用 AnythingLLM / Dify 全套 | ❌ 被单体局限卡死，难差异化 |
| **拼**（分层组合）⭐ | 组合各层最优开源 + Hyphae 黏合层 | ✅ **推荐**：灵活 + 可控 + 可差异化 |
| **造**（从零自研）| 自己写 agent 框架 | ❌ 重复造轮子，浪费 12+ 月 |

> ⭐ Hyphae 的工程重点 = **"黏合层" + "行业 LoRA" + "决策框架" + "HyperCapital 部署服务"**，而不是重写 agent 框架。
> 把开源组件当乐高，Hyphae 的价值在"怎么拼 + 拼给谁 + 拼完怎么服务"。

---

## 6. 与 Brood 生态 / 已有研究的衔接

| 关联 | 说明 |
|:---|:---|
| **hyphae（主项目）** | 本调研为 Hyphae 的 Agent 技术选型，填充主 BP 的"技术栈"细节 |
| **hyphae-training** | L2 模型层（行业 LoRA + 客户 LoRA + TEE 训练）由 training 研究覆盖 |
| **iDoris.ai iDoris / Agent24** | Agent24 可作为 L5 桌面壳的自研替代；iDoris 是组织内个人 AI |
| **AAStar AirAccount** | 组织成员 passkey 登录 agent |
| **HyperCapital** | L5-L0 全栈的部署 + 运维服务承接 |
| **MCP 生态** | L4 编排层统一用 MCP 接入工具（与 Claude / 生态对齐）|

---

## 7. 落地路线（v0.1 → v2）

| 阶段 | 形态 | 技术栈 | 周期 |
|:---:|:---|:---|:---:|
| **v0.1 Lite** | 形态 A | AnythingLLM + Ollama + Qwen 14B | 4 周 |
| **v1** | 形态 B | + Qwen-Agent + Letta + Cherry Studio 壳 | +8 周 |
| **v1.5** | 形态 B+ | + 行业 LoRA + 客户 LoRA 增量 | +8 周 |
| **v2** | 形态 C | + GenericAgent 演进 + AgentScope 多 agent + TEE | +12 周 |

---

## 8. 风险与应对

| 风险 | 应对 |
|:---|:---|
| 分层组合集成复杂 | HyperCapital 标准化"黏合层"脚本 + 部署模板 |
| 开源组件版本漂移 | 锁版本 + 季度升级评估 + 自动化测试 |
| Letta/mem0 等较新，稳定性 | v0.1 先用 AnythingLLM 内置记忆，v1 再上 Letta |
| 自我演进不成熟 | v2 才做，先借鉴模式不强依赖 |
| 本地小模型能力不足复杂决策 | 形态 C 复杂决策可溢出调云端大模型（脱敏）|
| Cherry Studio license 限制 | 评估商用条款，必要时换 AnythingLLM/ARGO 或自研壳 |

---

## 9. 最终一句话（给用户的直接答案）

> **Hyphae 应该"拼"不该"买"也不该"造"。**
>
> **推荐组合**：Mac Studio + Ollama/MLX + Qwen 系列 + Qwen-Agent（编排）+ Letta（记忆）+ AnythingLLM（知识库）+ GenericAgent 模式（演进）+ Cherry Studio（桌面壳），叠加 Hyphae 自己的行业 LoRA + 决策框架 + HyperCapital 部署服务。
>
> **最适配的场景**：从"组织第二大脑"（知识库 + 记忆）切入（小红书印证个人级已爆、组织级空白），先做形态 A/B 跑通中小组织高频刚需，再渐进到形态 C 的战略决策与自我演进。
>
> **真正的护城河不在框架选型**（都开源），**在 Hyphae 的黏合层 + 行业 LoRA + HyperCapital 服务 + 组织级无人区卡位**。

---

## 10. 下一步动作

| 优先级 | 动作 | 责任 |
|:---:|:---|:---|
| P0 | 用户 review 本推荐，确认分层组合方向 | jhfnetboy |
| P0 | v0.1 形态 A PoC：AnythingLLM + Ollama + Qwen 14B 跑通 1 个种子组织 | 工程 |
| P1 | 评估 Cherry Studio / ARGO / AnythingLLM 三者作为 L5 壳的商用 license | 法务 + 工程 |
| P1 | Qwen-Agent + Letta 集成 PoC（形态 B 内核）| 工程 |
| P2 | GenericAgent 自我演进模式拆解 + Hyphae EVO 层设计 | 研究 |
| P2 | "组织 AI 硬件配置计算器"（小红书印证的吸量工具）| 产品 |
