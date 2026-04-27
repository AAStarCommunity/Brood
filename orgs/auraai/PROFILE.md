---
schema_version: "1.0"
org_id: auraai
org_name: AuraAI
layer: ai
status: active
protocols:
  - mycelium
provides:
  - capability: ai-agent-framework
    interface: Claude Code 代理执行框架（eval + memory）
    repo: github.com/AuraAIHQ/Agent24
  - capability: agent-communication
    interface: Nostr NIP-44 加密消息层（agent 通信基础设施）
    repo: github.com/AuraAIHQ/agent-speaker
  - capability: wechat-agent-bridge
    interface: 微信 ↔ Nostr agent 桥接（@agent-wechat/core npm 包）
    repo: github.com/MushroomDAO/Agent-WeChat-SDK
  - capability: ai-knowledge-base
    interface: Web3 + AI 领域知识库（Markdown，可作 RAG 数据源）
    repo: github.com/jhfnetboy/AuraAI
  - capability: ai-education
    interface: AI/编程教育课程内容（面向儿童，5门，Apache 2.0）
    repo: github.com/AuraAIHQ/courses
depends_on:
  - org: aastar
    capability: gas-abstraction
    optional: true
  - org: mycelium
    capability: nostr-relay
    optional: false
contact:
  builder: jason
  github: github.com/AuraAIHQ
---

# AuraAI 组织名片

## 我们是谁

AuraAI 是 Mycelium Protocol 生态中的 **AI 能力层**，专注于构建面向社区和个人的 AI 代理基础设施。

核心定位：**让 AI 代理成为每个人的数字分身**——不仅能执行任务，还能通过熟悉的渠道（微信、Nostr）协作，并有持久化记忆。

## 我们做什么

三个核心方向：

| 方向 | 产品 | 状态 |
|-----|------|------|
| **Agent 框架** | Agent24（Claude Code 代理框架） | 活跃 |
| **Agent 通信** | agent-speaker + WeChat SDK | 活跃（今日发布 @agent-wechat/core） |
| **AI 教育** | AuraAI/courses（5门课程，儿童向） | 活跃 |

## 我们提供什么

- **对开发者**: Agent24 框架 + agent-speaker 通信库，快速构建 AI 代理
- **对用户**: 通过熟悉渠道（微信）与 AI 代理交互，无需切换工具
- **对生态**: AI 知识库（jhfnetboy/AuraAI）作为共享知识资产

## 我们需要什么

- **AAstar 集成**: 为 AI 代理提供 AirAccount 身份 + SuperPaymaster gasless 执行
- **Nostr relay**: 依赖 MushroomDAO/agent-speaker-relay 作为通信基础设施
- **社区使用场景**: 真实的社区 AI 代理应用场景，推动 Agent24 演进

## 当前路线图

核心里程碑（见 BroodBrain TASK-34 AuraAI 任务看板）：
- Phase 1: Agent 通信基础设施 — agent-speaker + WeChat SDK 发布 ✅（2026-04-26）
- Phase 2: Agent 记忆系统 — MemPalace 模块完善
- Phase 3: Agent ↔ Web3 集成 — 通过 AirAccount/SuperPaymaster 实现链上操作
