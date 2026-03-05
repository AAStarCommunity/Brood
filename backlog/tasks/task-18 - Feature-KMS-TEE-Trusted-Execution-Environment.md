---
id: TASK-18
title: '[Feature] KMS/TEE - Trusted Execution Environment'
status: "Done"
assignee:
  - jhfntboy
created_date: '2026-02-28 10:16'
updated_date: '2026-03-05 05:15'
labels:
  - feature
  - security
  - sign90
  - phase-2
milestone: 'Phase 2: Community Expansion'
dependencies:
  - TASK-7
references:
  - 'https://github.com/AAStarCommunity/AirAccount/tree/KMS-stm32'
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Integrate KMS/TEE for secure key management and execution within Sign90.
- STM32MP157F-DK2, power and connect to Mac mini
- Config network and rebuild STLinux distribution version
- Deploy and publish to Internet and test
- Refine or add some APIs

### 📊 进度报告 (2026-03-04 扫描)

**🚀 预估进度: 75%** | 近 30 天 42 次提交，最近一次 2026-03-04

**✅ AC 完成情况**:
- ✅ Select TEE provider — OP-TEE on STM32MP157F-DK2 (Cortex-A7 650MHz)
- ✅ Implement KMS interface — AWS KMS 兼容 REST API v0.16.4，含 rate limit、circuit breaker、API Key 认证、SQLite 持久化、live stats dashboard
- ✅ Verify secure execution — P-256 PassKey 双重验证 (CA + TA p256-m)、config-driven multi-origin WebAuthn (rpId)、beta test suite
- 🔧 KMS.aastar.io 生产部署 — graceful deploy (queue drain)、DK2 pipeline、QEMU 部署方案已完成，外网持久运行待验证

**📝 近期动态** (本地 kms/CHANGELOG.md + git log):
- 03-04: v0.16.4 — live stats dashboard 作为默认页面
- 03-04: v0.16.3 — graceful deploy with queue drain
- 03-04: v0.16.0-0.16.1 — multi-origin WebAuthn + wildcard origin matching
- 03-03: v0.15.22 — rate limit 100 req/min, Version API, Test UI, 文档补全
- 03-02: v0.14.0 — SQLite 持久化, WebAuthn 仪式, API Key 认证
- 03-01: v0.10.0 — KMS API server 异步架构, DK2 部署 pipeline

💡 功能已迭代至 v0.16.4 (stable beta tag: KMS-stable-beta-0.16.3)，含 graceful deploy 和运维仪表盘。剩余 25% 主要是 KMS.aastar.io 外网持久化运行验证。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Select TEE provider,Implement KMS interface,Verify secure execution
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Check https://github.com/jhfnetboy/STM32MP157F-DK2
Working on branch KMS-imigration in AirAccount
<!-- SECTION:PLAN:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 KMS.aastar.io is running with permanant storage for private key
<!-- DOD:END -->
