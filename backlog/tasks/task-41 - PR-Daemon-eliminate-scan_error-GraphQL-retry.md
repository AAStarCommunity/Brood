---
id: TASK-41
title: PR-Daemon: eliminate scan_error (proxy) + GraphQL retry-backoff
status: To Do
assignee: []
created_date: '2026-08-03 12:33'
labels:
  - pr-daemon
  - infra
dependencies: []
priority: medium
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
scan_error(49次)根因:用户 .zshrc 活跃导出死代理 127.0.0.1:7890,daemon 继承后 gh GraphQL 扫描 connection reset;且 load_pr_daemon_env.sh 的 proxy_pick 会保留继承值、空 PR_DAEMON_*_PROXY 盖不掉。已修:(a) 注释 .zshrc:320-321 死代理;(b) load_pr_daemon_env.sh 加'空 PR_DAEMON_*_PROXY 即强制 unset 继承代理'(已验证)。剩:重启 daemon 应用 + 给 GraphQL 扫描加 retry-with-backoff 兜住真实瞬时网络抖动。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 daemon 重启后进程 env 无 7890 代理
- [ ] #2 GraphQL scan 加 retry-backoff,瞬时 reset 不再冒 scan_error
<!-- AC:END -->
