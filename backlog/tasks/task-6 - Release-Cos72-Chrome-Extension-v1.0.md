---
id: TASK-6
title: '[Release] Cos72 - Chrome Extension v1.0'
status: To Do
assignee: []
created_date: '2026-02-28 11:15'
updated_date: '2026-03-13 14:26'
labels:
  - release
  - cos72
  - phase-1-genesis
  - Phase-1
milestone: m-1
dependencies: []
references:
  - 'https://github.com/jhfnetboy/AirAccount-Plugin/tree/basic-register-box'
priority: high
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Release the first version of Cos72 Chrome Extension, integrating SuperPaymaster and AirAccount for seamless onboarding.
...

### 📊 进度报告 (2026-03-13 扫描)

**🚀 预估进度: 40%** | 近 30 天 11 次提交，最近一次 2026-03-08（milestone7: hardening）

**✅ AC 完成情况**:
- 🔧 基础框架已完成 — basic-register-box 分支，milestone1~7 均已落地
- ✅ Forest domain 拦截 + IPFS 内容渲染 — feat: intercept forest domains + fetch IPFS content
- ✅ Gasless 更新流程 — feat: add forest controller gasless update flow
- 🔧 SuperPaymaster/AirAccount 集成 — 架构已设计（forest RPC settings + resolver reads），deep integration 待完成
- ⬜ 发布 v1.0 Chrome 扩展 — 仍在 milestone 阶段，未到发布就绪状态

**📝 近期动态** (basic-register-box 分支):
- 03-08: milestone7: hardening + permissions tightening
- 03-07: docs: add workers wildcard deploy guide
- 03-06: milestone6: gateway fallback + env path fix
- 03-05: feat: add forest controller gasless update flow
- 03-04: Add unit tests and dashboard storage

💡 Chrome 扩展已完成 7 个 milestone（forest domain 拦截、IPFS、gasless 更新、单元测试），SuperPaymaster/AirAccount 深度集成和发布打包是剩余主要工作。
<!-- SECTION:DESCRIPTION:END -->
