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

### 📊 进度报告 (2026-04-26 扫描)

**🚀 预估进度: 30%** | 多仓库活跃：Agent24（20次提交）、agent-speaker（23次）、relay（15次）、Agent-WeChat-SDK（4次，今天！）

**✅ AC 完成情况**:
- ✅ Aura 建立 — `jhfnetboy/AuraAI` + `AuraAIHQ` org 建立，Apache 2.0 license 完成
- 🔧 OpenCrab/Agent24 PC 版 — **AuraAIHQ/Agent24** 活跃：pluggable eval system（codex/agent-speaker/dual）、MemPalace memory、/setup onboarding skill、staged evaluation；Codex 5轮审查通过
- 🔧 Bot（WeChat 第二位）— **MushroomDAO/Agent-WeChat-SDK** 今日启动：@agent-wechat/core + CLI + simple-agent submodule + wechat-agent-bridge 设计文档
- 🔧 通信基础设施 — **AuraAIHQ/agent-speaker** (Nostr 消息 + TUI + SQLite + NIP-44 加密) + **MushroomDAO/agent-speaker-relay** (strfry Nostr relay Docker)
- ⬜ iDoris 三层结构、Mycelium Network、AK47 — 未启动

**📝 近期动态**:
- 04-26: feat: Agent-WeChat-SDK — @agent-wechat/core + CLI + simple-agent（今天！）
- 04-21: agent-speaker: group chat + TUI Bubble Tea + SQLite storage
- 04-12: agent-speaker-relay: strfry Docker + CI/CD for Nostr relay
- 04-10: Agent24: pluggable eval system + MemPalace memory + org sync

💡 AuraAI 生态从知识库阶段全面进入代码实现阶段：Agent24 执行框架 + Nostr 通信 + WeChat SDK 同步推进。目前缺少 iDoris 核心和 Mycelium Network（剩余 70%）。
<!-- SECTION:DESCRIPTION:END -->
