# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BroodBrain is a static, read-only project backlog publishing system for the Mycelium Protocol ecosystem. It uses the `backlog` CLI (via npx) to manage tasks/docs/decisions as markdown files, then exports them as a fully static SPA with JSON API files. There is no backend — the deployed site is pure HTML/CSS/JS/JSON served from CDN.

The project language is bilingual (Chinese/English). README and UI toast messages are in Chinese.

## Commands

```bash
pnpm run build       # Export static site to dist/ (spawns local backlog server, scrapes it, injects read-only protection)
pnpm run preview     # Serve dist/ locally on port 3000
pnpm run deploy:cf   # Deploy dist/ to Cloudflare Pages via wrangler
```

There are no dependencies in package.json — everything runs via `npx`. There is no test framework.

## Build Architecture

The build process (`scripts/export-backlog.js`) works as follows:

1. Spawns a local `backlog` CLI server on port 8422 (`npx backlog browser --no-open`)
2. Fetches `index.html` and parses it for static asset URLs (CSS, JS, images)
3. Downloads all assets to `dist/`
4. **Injects read-only protection script** into `index.html` before `</head>`:
   - Intercepts POST/PUT/DELETE/PATCH fetch calls → shows Chinese toast notification
   - Appends `.json` suffix to `/api/` fetch URLs (avoids Unix directory/file collision)
   - Spoofs empty `[]` for failed or HTML-fallback API responses
   - Mocks `EventSource` and `WebSocket` to suppress "Server disconnected" errors
   - Hides delete buttons via CSS injection
5. Downloads all API endpoints as JSON files into `dist/api/`
6. Fetches individual docs, decisions, and milestones as separate JSON files
7. Writes deployment config files (`_headers`, `_redirects`, `_routes.json`, `vercel.json`)
8. Kills the local server

**Key design principle**: Local build, direct push. `dist/` is committed to git. GitHub Actions deploys it as-is with no cloud build step.

## Deployment

- **GitHub Pages** (default): Automatic via `.github/workflows/deploy.yml` on push to `main`. Simply commits `dist/` and pushes.
- **Cloudflare Pages**: Either `pnpm run deploy:cf` (CLI) or connect repo in CF dashboard with build output dir `dist` and empty build command.

## Content Structure

All content lives in `backlog/` as markdown with YAML frontmatter:

- `backlog/config.yml` — Project config (statuses, task prefix, port, etc.)
- `backlog/tasks/task-N - [Type] Name.md` — Task files with id, title, status, assignee, labels, milestone, dependencies, priority
- `backlog/docs/doc-N.md` — Documentation files
- `backlog/decisions/decision-N.md` — Architecture Decision Records (Context/Decision/Consequences format)
- `backlog/archive/` — Archived tasks, drafts, milestones

Task statuses: `To Do`, `In Progress`, `Done`. Task prefix: `task`. IDs use format `TASK-N`.

## Static API

The exported `dist/api/` contains JSON files mirroring the backlog CLI's REST API:

- `tasks.json`, `docs.json`, `decisions.json`, `milestones.json` — List endpoints
- `docs/{id}.json`, `decisions/{id}.json`, `milestones/{encodedTitle}.json` — Individual items
- `config.json`, `statistics.json`, `search.json`, `status.json`, `statuses.json`, `version.json`

The injected fetch interceptor in `index.html` automatically appends `.json` to `/api/` requests at runtime.

## Custom Skills

### `/sync-progress` — GitHub 仓库进度扫描

扫描所有 "In Progress" 任务，通过本地 git commit 历史和 CHANGELOG 分析开发进度，估算完成百分比并更新任务文件。

- 任务需要在 `references:` frontmatter 中包含 `github.com` URL（通过 web 界面 Add References 添加）
- 纯本地操作：自动在 `/Users/jason/Dev/` 下查找匹配的本地仓库，找不到则 clone 到 `/Users/jason/Dev/tmp/`
- 进度写入任务文件的 `## Progress Report` 区域（`<!-- SECTION:PROGRESS:BEGIN/END -->` 标记）

Skill 定义: `.claude/skills/sync-progress/SKILL.md`

## Git Workflow

- Single `main` branch, direct commits
- Commit style: conventional commits (`fix:`, `chore():`, `docs():`)
- `dist/` is tracked in git (intentionally — no cloud build)
- `update-task.sh` is a convenience script that stages, commits with `fix: update task`, and pushes
