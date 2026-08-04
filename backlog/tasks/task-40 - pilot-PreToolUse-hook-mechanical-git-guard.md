---
id: TASK-40
title: pilot: PreToolUse hook mechanically blocks git add -A / push-to-main
status: To Do
assignee: []
created_date: '2026-08-03 12:33'
labels:
  - pilot
  - safety
dependencies: []
priority: high
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
现在 git-guard.sh 只在模型主动路由调用时才生效,护栏在 ~/.claude/skills/ 里、repo 内 grep 都找不到,模型一旦忘了调用就静默绕过。真正兜底只有 GitHub 分支保护。pilot 已做成 Claude Code plugin(#29),正好用 plugin 的 hooks/hooks.json PreToolUse 钩子在工具边界机械拦截 git add -A 和推 protected 分支——钩子不会被模型忘记。这是把 pilot 做成 plugin 的真正价值。来源:reviews YetAnotherAA-450、Self-FDE-85、Brood-29 review 的 Suggestions 段。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 plugins/pilot/hooks/hooks.json 存在,PreToolUse 拦截裸 git add -A/./--all
- [ ] #2 拦截 push 到 base/protected 分支
- [ ] #3 钩子与 git-guard.sh 规则一致(复用其判定)
<!-- AC:END -->
