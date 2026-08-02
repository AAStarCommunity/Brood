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

**🚀 预估进度: 70%** | 近30天活跃仓库缩减：agent-speaker 仍在迭代（kind:1111 comment 支持 + blossom tweaks + publish fix）；Agent24 仅 1 commit（code owner）；simple-agent 仅 license；整体无重大新功能

**✅ AC 完成情况**:
- ✅ Aura 建立 — `iDoris-ai` org 全量建立
- ✅ Agent24 = AgentStore 承载平台 — BoxLite service container (M3+M4) 完成
- ✅ iDoris-SDK M2/M3/M4/M5 全部完成
- ✅ Nostr 通信层：TUI Chat + NIP-86 role commands + jq helpers + serve --auth/--eager-auth
- ✅ agent-speaker：kind:1111 comment publish + blossom ipv6 fix + profile flags
- 🔧 AgentSocial：Paper3 设计就绪，工程化待启动
- ⬜ iDoris 三层结构（云端大模型 + 训练服务）、Mycelium Network、AK47 — 未启动

**📝 近期动态** (iDoris-ai/agent-speaker):
- 2026-07-07: publish: allow kind:1111 comment, force --comment flag
- 2026-07-06: two blossom tweaks（ipv6 + blossom）
- 2026-07-06: publish: proper root/reply tags + read from arguments
- 2026-07-05: admin: color flag is int now
- Agent24/simple-agent: 静默（仅 license/owner 维护提交）

💡 agent-speaker 功能稳定扩展中（Nostr 发布层细化）。iDoris.ai 其他仓库进入静默期，大功能（iDoris 云端 + Mycelium Network）尚未启动。剩余 30%：核心平台工程化。
<!-- SECTION:DESCRIPTION:END -->
