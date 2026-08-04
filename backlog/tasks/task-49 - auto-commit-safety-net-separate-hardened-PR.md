---
id: TASK-49
title: "auto-commit safety net: separate hardened PR before merging into pilot"
status: To Do
assignee: []
created_date: '2026-08-03 17:10'
labels:
  - pilot
  - safety
dependencies: []
priority: medium
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
auto-commit.sh + auto-commit-loop.sh(定时10min+定量>3文件/>200行 的 WIP 防丢失 checkpoint)从 pilot #28 移除——它是多轮 review bug 的主要来源(密钥正则/解析、detached HEAD、单误报 exit-3 DoS、保护分支名单与 git-guard 分裂、偷锁竞争),作为非核心 scale 附加功能不该卡住核心护栏发布。硬化版代码在 git 历史(feat/repo-pilot-latest 的 5c6630a:skills/pilot/scripts/auto-commit*.sh,已修 7 个 daemon 发现的 bug)。以后单独开 PR、走完整 4 轮对抗评审充分硬化后再并入。关键待办:抽出与 git-guard 共享的 lib/protected.sh(三处保护分支判定别再各写一份)。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 auto-commit + loop 单独 PR,过 4 轮真 Opus 评审无 blocking
- [ ] #2 保护分支判定与 git-guard 共用一份 lib/protected.sh
- [ ] #3 detached HEAD/rebase/bisect、密钥正则、单误报不废整体 等已修项保留
<!-- AC:END -->
