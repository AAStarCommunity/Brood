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

### 📊 进度报告 (2026-06-29 扫描)

**🚀 预估进度: 70%** | 近30天 50 次提交，最近一次 2026-06-20；agent-speaker TUI Chat #4 合入 + Nostr NIP-86 role commands + jq date helpers；Agent24 bunker 修复 + serve auth 体系化

**✅ AC 完成情况**:
- ✅ Aura 建立 — `AuraAIHQ` org 全量建立
- ✅ Agent24 = AgentStore 承载平台 — BoxLite service container (M3+M4) 完成
- ✅ iDoris-SDK M2/M3/M4/M5 全部完成
- ✅ Nostr 通信层：TUI Chat #4 合入 + NIP-86 role commands + jq date helpers + --jq-raw flag + serve --auth/--eager-auth
- ✅ bunker 连接冲突修复（client + server authorization）
- 🔧 AgentSocial：Paper3 设计就绪，工程化待启动
- ⬜ iDoris 三层结构（云端大模型 + 训练服务）、Mycelium Network、AK47 — 未启动

**📝 近期动态** (Agent24 + agent-speaker + simple-agent):
- 2026-06-20: admin: new nip86 "role" commands
- 2026-06-?: add --jq-raw flag + jq examples to README + date function helpers
- 2026-06-?: fix conflicts with running bunker connections (client/server)
- 2026-06-13: feat: TUI Chat Interface (#4 合入)

💡 agent-speaker Nostr 层功能持续扩展（NIP-86 role + jq helpers），serve auth 体系完整。剩余 30%：iDoris 云端三层结构 + Mycelium Network 工程化启动。
<!-- SECTION:DESCRIPTION:END -->
