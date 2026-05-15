# AuraAI — 对外接口规范

> 文档类型：接口契约（Interface Contracts）
> 维护者：AuraAI 团队 | 最后更新：2026-04-27
> 关联：`orgs/auraai/PROFILE.md`

---

## 我们提供 / What We Provide

### 1. AuraAI Knowledge Base — AI 知识库

**仓库**: `github.com/AuraAIHQ/AuraAI`（Apache 2.0）
**状态**: 活跃（In Progress, 35%）

知识库内容：Web3 + AI 领域研究，面向 Mycelium Protocol 生态
- 格式：Markdown 文档，结构化知识
- 使用方式：直接引用文档 / 作为 RAG 数据源

---

### 2. Agent24 — 个人 AI 代理框架

**仓库**: `github.com/AuraAIHQ/Agent24`
**状态**: 活跃（Claude Code 代理执行框架 + eval system + memory）

| 能力 | 说明 |
|-----|------|
| 任务执行 | 基于 Claude Code 的自主任务执行框架 |
| 记忆管理 | MemPalace 模块（持久化 agent 记忆） |
| 评估系统 | agent 输出质量评估 |

---

### 3. agent-speaker — Nostr 通信层

**仓库**: `github.com/AuraAIHQ/agent-speaker`
**版本**: v0.25.0
**状态**: 活跃（NIP-44 加密 + TUI + SQLite）

| 接口 | 说明 |
|-----|------|
| Nostr relay | NIP-44 加密消息（Agent-WeChat-SDK 使用） |
| TUI 界面 | 终端用户交互 |
| SQLite 存储 | 消息持久化 |

**集成方式**：配合 `agent-speaker-relay`（MushroomDAO Nostr relay）

---

### 4. Agent-WeChat-SDK — 微信 Agent 桥接

**仓库**: `github.com/MushroomDAO/Agent-WeChat-SDK`
**状态**: 活跃（@agent-wechat/core 已发布）

| 接口 | 说明 |
|-----|------|
| @agent-wechat/core | npm 包，微信 agent 桥接核心 |
| WeChat → Nostr 转发 | 微信消息 → Nostr 协议转换 |
| agent 响应 | AI 代理响应通过 Nostr 返回微信 |

---

### 5. AuraAI Courses — AI/编程教育内容

**仓库**: `github.com/AuraAIHQ/courses`（Apache 2.0）
**状态**: 活跃（5门课程，面向儿童）

| 课程 | 说明 |
|-----|------|
| 计算机科学基础 | 图灵、冯·诺依曼等关键人物与概念 |
| AI 基础 | 面向儿童的 AI 入门 |
| 编程基础 | 儿童编程课程框架 |

**集成方式**：内容资源（Markdown），可嵌入社区工具（Cos72）

---

## 我们消费 / What We Consume

| 来源组织 | 能力 | 用途 | 可选性 |
|--------|------|------|------|
| AAstar / AirAccount | 账户身份 | AI 代理身份管理（规划中） | 可选 |
| AAstar / SuperPaymaster | Gas 抽象 | AI 代理 gasless 操作（规划中） | 可选 |
| MushroomDAO / agent-speaker-relay | Nostr relay | agent 通信基础设施 | 核心 |
| MushroomDAO / Cos72 | 社区 OS | 课程内容分发平台（规划中） | 可选 |

---

## 待完善 / To Be Defined

> 以下接口规范尚在规划中，欢迎 AuraAI 团队补充：

- **iDoris AI 推理接口**: 边缘计算 AI 模型的 API 规范
- **AI 激励结算**: AI 服务如何通过 SuperPaymaster 收费
- **跨 agent 协作协议**: 多 agent 协作的通信规范

---

## 联系 / Contact

- GitHub Org: https://github.com/AuraAIHQ
- 主要维护者: @jhfnetboy (jason)
