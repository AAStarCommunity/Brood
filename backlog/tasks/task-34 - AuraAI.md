---
id: TASK-34
title: iDoris.ai
status: In Progress
assignee: []
created_date: '2026-03-07 15:39'
updated_date: '2026-03-07 15:39'
labels: []
milestone: m-3
dependencies: []
references:
  - 'https://github.com/jhfnetboy/AuraAI'
  - 'https://github.com/iDoris-ai/Agent24'
  - 'https://github.com/iDoris-ai/agent-speaker'
  - 'https://github.com/MushroomDAO/agent-speaker-relay'
  - 'https://github.com/MushroomDAO/Agent-WeChat-SDK'
  - 'https://github.com/iDoris-ai/simple-agent'
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
AI（社区AI+个人AI+AI workshop）, bot(tele第一位，wechat第二位，找个技术栈），以赋能社区，自由个体为目标；Aura建立✅

1. OpenCrab/Agent24, PC版和Mobile版个人agent，提供全套服务，PC版有本地模型
2. iDoris，就是本项目，提供三层结构：社区成员本地AI模型、社区自有大模型和AI服务（提供数据和运行iDoris训练后的模型）、iDoris核心训练服务（训练经过脱敏的数据）
3. EIP-8004, x402,以及Agent经济的自动网络：Mycelium Network
4. Skill、Swarm和Native AI的武器库：AK47

### 📊 进度报告 (2026-07-07 扫描)

**🚀 预估进度: 68%** | agent-speaker 最近提交 2026-06-20 `feat: TUI Chat Interface (#4)`（静默 ≈ 17 天，本期 main 无新提交）；Agent24/simple-agent 仅 license/owner 维护，整体无重大新功能

**✅ AC 完成情况**:
- ✅ Aura 建立 — `iDoris-ai` org 全量建立
- ✅ Agent24 = AgentStore 承载平台 — BoxLite service container (M3+M4) 完成
- ✅ iDoris-SDK M2/M3/M4/M5 全部完成：WeChatBridge + InboxAgent + CLI + 集成验证
- ✅ Nostr 通信层：agent-speaker TUI Chat 完整 PR #4 合入 + serve --auth/--eager-auth flags + bunker 连接冲突修复 + --jq flag on fetch/event commands
- 🔧 AgentSocial：Paper3 设计 + milestone plan 已就绪
- ⬜ iDoris 三层结构（云端大模型 + 训练服务）、Mycelium Network、AK47 — 未启动

**📝 近期动态** (iDoris-ai/agent-speaker):
- 2026-06-20: feat: TUI Chat Interface (PR #4) — 合入 main（本期唯一 feature 提交）
- Agent24 / simple-agent / OpenCrab / courses 本期主要为 license 合规（Apache 2.0 五件套）+ @clestons code owner

💡 agent-speaker 完成工程化第二阶段（TUI + serve auth + bunker 修复）后进入静默；iDoris.ai 其他仓库亦静默，大功能（iDoris 云端三层结构 + Mycelium Network）尚未启动。剩余 32%：核心平台工程化 + 三层结构启动。
<!-- SECTION:DESCRIPTION:END -->
