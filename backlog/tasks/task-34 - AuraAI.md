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

### 📊 进度报告 (2026-06-12 扫描)

**🚀 预估进度: 65%** | 5 个关联仓库共 35 次提交（30 天）；**iDoris-SDK M2-M5 全部完成** + 新增 **AgentSocial** 仓库（Paper3 设计） + auraai-packages 全面结构化

**✅ AC 完成情况**:
- ✅ Aura 建立 — `AuraAIHQ` org 全量建立
- ✅ Agent24 = AgentStore 承载平台 — BoxLite service container (M3+M4) 完成
- ✅ **iDoris-SDK M2/M3/M4/M5 全部完成**：WeChatBridge + InboxAgent + CLI + 集成验证
- ✅ **包重命名整合**：@auraai/ai-bridge → @auraaihq/idoris（AI gateway 产品定位）
- ✅ Nostr 通信层：agent-speaker TUI Bubble Tea 完成 + v0.25.0 agent profile + auto-reply daemon
- 🔧 **AgentSocial 新仓库**（2026-05-29 起）：Paper3 设计决策 + milestone plan + 13-report survey + Agentic Design Patterns 框架综述
- ⬜ iDoris 三层结构（云端大模型 + 训练服务）、Mycelium Network、AK47 — 未启动

**📝 近期动态** (6 仓库聚合):
- AgentSocial 2026-05-29: Paper3 design-decision doc + milestone plan + 21-pattern taxonomy + RAG deep-dive
- iDoris-SDK 2026-05-21: AiToEarn 平台研究报告 (M6 bridge roadmap) + M5 InboxAgent session lifecycle 验证
- iDoris-SDK 2026-05-15: M4 @idoris/cli + M2/M3 WeChatBridge + InboxAgent
- auraai-packages 2026-05-29: BoxLite OCI client 提取 + ModuleManifest Agent24 runtime 字段
- Agent24 2026-05-15: BoxLite service container 运行时 + M3 community installer + newsletter system (Listmonk)
- agent-speaker 2026-05-13: TUI chat 完整版 + 安全 fix（npub bounds check）

💡 iDoris-SDK 已经从 M2 走到 M5，从 SDK → CLI → 实际集成验证全链路打通。AgentSocial 是 Paper3 工程化的新落点。剩余 35% 主要为 iDoris 云端三层结构 + Mycelium Network 启动。
<!-- SECTION:DESCRIPTION:END -->
