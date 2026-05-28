---
id: TASK-34
title: AuraAI
status: In Progress
assignee: []
created_date: '2026-03-07 15:39'
updated_date: '2026-03-07 15:39'
labels: []
milestone: m-3
dependencies: []
references:
  - 'https://github.com/jhfnetboy/AuraAI'
  - 'https://github.com/AuraAIHQ/Agent24'
  - 'https://github.com/AuraAIHQ/agent-speaker'
  - 'https://github.com/MushroomDAO/agent-speaker-relay'
  - 'https://github.com/MushroomDAO/Agent-WeChat-SDK'
  - 'https://github.com/AuraAIHQ/simple-agent'
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
AI（社区AI+个人AI+AI workshop）, bot(tele第一位，wechat第二位，找个技术栈），以赋能社区，自由个体为目标；Aura建立✅

1. OpenCrab/Agent24, PC版和Mobile版个人agent，提供全套服务，PC版有本地模型
2. iDoris，就是本项目，提供三层结构：社区成员本地AI模型、社区自有大模型和AI服务（提供数据和运行iDoris训练后的模型）、iDoris核心训练服务（训练经过脱敏的数据）
3. EIP-8004, x402,以及Agent经济的自动网络：Mycelium Network
4. Skill、Swarm和Native AI的武器库：AK47

### 📊 进度报告 (2026-05-28 扫描)

**🚀 预估进度: 55%** | 5 个关联仓库共 74 次提交，最近 Agent24 2026-05-15；Agent24 = AgentStore 承载平台（PGL 集成）+ iDoris-SDK (前 Agent-WeChat-SDK) 已迁移到 AuraAIHQ + newsletter system 规划完成

**✅ AC 完成情况**:
- ✅ Aura 建立 — `AuraAIHQ` org 全量建立，Apache 2.0 license 五件套合规
- 🔧 OpenCrab/Agent24 PC 版 — Agent24 框架稳定（pluggable eval + MemPalace），Agent24-Desktop 持续迭代
- 🔧 Bot（WeChat）— `@agent-wechat/core` + `@agent-wechat/cli` 已发布，wechat-agent-bridge 子模块就位
- 🔧 Nostr 通信层 — agent-speaker 吸收 upstream 多项 fix（blossom decode/nsite path traversal/publish nil panic），relay 端 X-Real-IP hack 修复
- 🔧 simple-agent (Level 1 agent) — `@aura/simple-agent` + StorageAgent 初版
- ⬜ iDoris 三层结构、Mycelium Network、AK47 — 未启动

**📝 近期动态** (5 仓库聚合):
- Agent24-Desktop 2026-05-11、agent-speaker/Agent24/OpenCrab 2026-04-29
- Agent-WeChat-SDK: 实现 `@agent-wechat/core` + `@agent-wechat/cli`，pnpm workspace + 设计文档
- simple-agent: 初代 StorageAgent 落地
- agent-speaker: 多项安全 fix 与 PR 合入

💡 通信层 + WeChat 桥 + Nostr relay 三件套已成型，Agent-WeChat-SDK 核心可用。剩余 50% 的主要缺口仍是 iDoris/Mycelium Network/AK47。
<!-- SECTION:DESCRIPTION:END -->
