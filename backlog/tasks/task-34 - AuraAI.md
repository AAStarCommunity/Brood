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

### 📊 进度报告 (2026-04-27 扫描)

**🚀 预估进度: 35%** | 多仓库持续活跃：agent-speaker（group chat + TUI + SQLite 完成）、Agent-WeChat-SDK（@agent-wechat/core + CLI 启动）、relay（Docker 稳定）

**✅ AC 完成情况**:
- ✅ Aura 建立 — `jhfnetboy/AuraAI` + `AuraAIHQ` org 建立，Apache 2.0 license 全量合规
- 🔧 OpenCrab/Agent24 PC 版 — **AuraAIHQ/Agent24** pluggable eval（codex/agent-speaker/dual）、MemPalace memory、/setup onboarding skill；近期以 license 合规为主
- 🔧 Bot（WeChat 第二位）— **MushroomDAO/Agent-WeChat-SDK** @agent-wechat/core + CLI + simple-agent submodule 已实现，wechat-agent-bridge 设计文档完成
- ✅ 通信基础设施 — **AuraAIHQ/agent-speaker**（group chat + TUI Bubble Tea + SQLite + NIP-44 加密，PR #3 merge）+ **MushroomDAO/agent-speaker-relay**（strfry Docker + restart.sh + Alpine/Ubuntu 双构建）完成度高
- ⬜ iDoris 三层结构、Mycelium Network、AK47 — 未启动

**📝 近期动态**:
- 04-27: agent-speaker: fix(tui): send messages + close DB + bounds-check npub slices（PR review 修复）
- 04-26: Agent-WeChat-SDK: feat: @agent-wechat/core + CLI + simple-agent submodule
- 04-21: agent-speaker: group chat 全测试覆盖 + TUI Bubble Tea（feat merge）
- 04-12: agent-speaker-relay: restart.sh + Alpine 构建优化 + OOM 修复

💡 通信基础设施（Nostr relay + agent-speaker）趋于成熟，WeChat SDK 启动。Agent24 执行框架框架完整。剩余 65%：iDoris 三层（社区AI/大模型/训练服务）、Mycelium Network、AK47 工具库。
<!-- SECTION:DESCRIPTION:END -->
