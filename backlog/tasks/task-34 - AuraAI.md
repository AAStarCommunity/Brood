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
  - 'https://github.com/iDoris-ai/Agent24'
  - 'https://github.com/iDoris-ai/agent-speaker'
  - 'https://github.com/iDoris-ai/agent-speaker-relay'
  - 'https://github.com/iDoris-ai/iDoris-SDK'
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

### 📊 进度报告 (2026-08-17 扫描)

**🚀 预估进度: 72%** | Agent24 近30天 96 次提交（Sin90 内核集成 SPIKE-00 端到端 + Rust core）+ agent-speaker 49 次提交（M1 完成，2026-08-12 正式改名 **Hyphae**）；其余 4 仓库静默

**✅ AC 完成情况**:
- ✅ Aura 建立 — `iDoris-ai` org 全量建立
- ✅ Agent24 = AgentStore 承载平台 — Rust core（ADR-026）+ agent24-sin90 纯域 crate/store/agent24d 路由端到端（#99-#104）+ H9 explorer 安全加固 v0.2.1
- ✅ iDoris-SDK M2/M3/M4/M5 全部完成：WeChatBridge + InboxAgent + CLI + 集成验证
- ✅ 包重命名整合：@auraai/ai-bridge → @auraaihq/idoris
- ✅ Nostr 通信层 — agent-speaker **M1 完成 + M2 unblocked**（#32）；StoredMessage hex-encode / d-tag 唯一性修复；2026-08-12 改名 **Hyphae**（菌丝网络定位，多端瘦壳接入）
- 🔧 AgentSocial：Paper3 设计 + milestone plan 已就绪（5-29 起，本期无提交）
- ⬜ iDoris 三层结构（云端大模型 + 训练服务）、Mycelium Network、AK47 — 未启动

**📝 近期动态** (6 仓库聚合):
- 08-12: Agent24 — README 架构校准至 Rust core 现状（ADR-026）+ Hyphae 菌丝网络多端定位 (#105-#107)
- 08-09/10: Agent24 — agent24-sin90 纯域 crate（类型+状态机+Proposal 校验 #99）+ sin90-store（CAS 幂等 apply + 纯回放对账 #100）+ agent24d 挂 Sin90 路由（SPIKE-00 端到端 #103/#104）
- 08-10: Agent24 — 通用 EventBody::Module 事件信封 (#101) + CompletionRequest.response_format 结构化输出 (#102)
- 08-12: agent-speaker → **Hyphae** 改名（rename commit）
- 07-29: Hyphae — M1 done + M2 scope 确认 (#32)；V1→V2 架构图与联调计划 (#31)
- iDoris-SDK / simple-agent / agent-speaker-relay / AuraAI(jhfnetboy 本地未 clone): 本期无提交

💡 Agent24×Sin90 内核集成是本期最大突破（个人 OS 域模型进 Rust 内核，事件闭环跑通）；Hyphae 改名标志 Nostr 层升级为菌丝网络基础设施定位。剩余 28%：iDoris 云端三层结构 + Mycelium Network + AgentSocial 工程化。
<!-- SECTION:DESCRIPTION:END -->
