---
id: TASK-39
title: '修 /sync-progress 造假:写入前 gh-api 200-OK 校验'
status: To Do
assignee: []
created_date: '2026-08-03 12:32'
labels:
  - skill
  - review-quality
dependencies: []
priority: high
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
PR-Daemon review 在 Brood#23 抓到 /sync-progress 的 refresh 输出含大量虚构数据:不存在的 repo(iDoris-ai/AI_Beginner_Courses 404、AAStarCommunity/MyTask 404)用来虚增进度、编造的 commit(agent-speaker 07-05/06/07 全不存在)、把 stale cache 当 last-commit 得出假静默日期。根因是扫描器直接写而不校验。修法:每个 repo/date/commit/tag 写入任务文件前必须过一次 live gh-api(repo 存在=200、commit/tag 真实存在、last-commit 用真实默认分支 HEAD)。这是 Brood 自己的旗舰 skill 在往权威上下文写 confabulation,最高优先。来源:reviews/AAStarCommunity-Brood-23-request-changes-90adddb.md
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 所有写入的 repo URL 经 gh api 校验为 200(404 的不写)
- [ ] #2 commit/日期取自真实默认分支 HEAD,不再用 cache 当 last-commit
- [ ] #3 版本号取自 live tag
<!-- AC:END -->
