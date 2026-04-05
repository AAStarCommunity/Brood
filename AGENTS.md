# AGENTS.md — BroodBrain Project Guide

This file provides essential information for AI coding agents working on the BroodBrain project.

## Project Overview

**BroodBrain** is a static, read-only project backlog publishing system for the Mycelium Protocol ecosystem. It manages tasks, documentation, and architecture decisions as markdown files, then exports them as a fully static Single Page Application (SPA) with JSON API files.

**Key Characteristics:**
- **Zero-backend architecture**: The deployed site is pure HTML/CSS/JS/JSON served from CDN (GitHub Pages or Cloudflare Pages)
- **Local build, direct push**: All build computation happens locally; `dist/` is committed to git and deployed as-is
- **Tamper-proof**: No POST/PUT/DELETE endpoints exist on the deployed site — static file servers return 405 Method Not Allowed
- **Bilingual**: Project language is Chinese/English; README and UI elements are in Chinese

## Technology Stack

| Component | Technology |
|-----------|------------|
| Build Tool | Node.js (ES Modules) + `npx backlog` CLI |
| Package Manager | pnpm |
| Frontend | Backlog CLI's built-in browser (scraped and exported) |
| Deployment | GitHub Pages (default) + Cloudflare Pages (optional) |
| Content Format | Markdown with YAML frontmatter |

## Project Structure

```
/Users/jason/Dev/Brood/
├── backlog/                    # Source content (markdown files)
│   ├── config.yml              # Backlog CLI configuration
│   ├── tasks/                  # Task files (task-{N} - [Type] Name.md)
│   ├── docs/                   # Documentation files (doc-{N} - Title.md)
│   ├── decisions/              # Architecture Decision Records (decision-{N}-Title.md)
│   ├── milestones/             # Milestone definitions (m-{N} - Title.md)
│   ├── completed/              # Completed/archived tasks
│   ├── archive/                # Archived content
│   └── drafts/                 # Draft content
├── dist/                       # Generated static site (committed to git)
│   ├── index.html              # Main SPA entry (with injected read-only protection)
│   ├── api/                    # JSON API files
│   ├── docs/                   # Copied static HTML docs
│   └── _headers/_redirects/    # Deployment config files
├── scripts/                    # Build and utility scripts
│   ├── export-backlog.js       # Main build script
│   └── serve-dist.js           # Local static file server
├── .claude/skills/             # Custom Claude skills
│   └── sync-progress/          # GitHub repo progress scanner
├── .github/workflows/          # CI/CD workflows
│   └── deploy.yml              # GitHub Pages deployment
├── package.json                # Minimal package config
├── build.sh                    # Convenience build script
├── preview.sh                  # Convenience preview script
└── update-task.sh              # Convenience commit-push-deploy script
```

## Build Commands

```bash
# Build static site (exports to dist/)
pnpm run build
# or: node scripts/export-backlog.js

# Preview built site locally on port 3000
pnpm run preview
# or: npx serve dist

# Deploy to Cloudflare Pages (requires wrangler login)
pnpm run deploy:cf
# or: npx wrangler pages deploy dist --project-name brood --branch main

# Quick update workflow (stage, commit, push, deploy)
bash update-task.sh
```

**Note:** No dependencies are declared in `package.json`. All tools run via `npx`.

## Build Architecture

The build process (`scripts/export-backlog.js`) works as follows:

1. **Spawn local backlog server** on port 8422 (`npx backlog browser --no-open`)
2. **Fetch and parse** `index.html` for static asset URLs (CSS, JS, images)
3. **Download all assets** to `dist/`
4. **Compute weighted milestone progress** from task files (Done=100%, In Progress=estimated%, To Do=0%)
5. **Patch JS bundle** to replace simple progress formulas with weighted calculations
6. **Inject read-only protection script** into `index.html` before `</head>`:
   - Intercepts POST/PUT/DELETE/PATCH fetch calls → shows Chinese toast notification
   - Appends `.json` suffix to `/api/` fetch URLs (avoids Unix directory/file collision)
   - Spoofs empty `[]` for failed or HTML-fallback API responses
   - Mocks `EventSource` and `WebSocket` to suppress "Server disconnected" errors
   - Hides delete buttons via CSS injection
7. **Download all API endpoints** as JSON files into `dist/api/`
8. **Fetch individual items** (docs, decisions, milestones) as separate JSON files
9. **Merge completed tasks** from `backlog/completed/` into `tasks.json`
10. **Write deployment configs** (`_headers`, `_redirects`, `_routes.json`, `vercel.json`)
11. **Copy static HTML docs** from `docs/` to `dist/docs/`
12. **Kill the local server**

## Content Structure

All content lives in `backlog/` as markdown with YAML frontmatter:

### Task Files (`backlog/tasks/task-{N} - [Type] Name.md`)

```yaml
---
id: TASK-10
title: '[Feature] Sign90 - Smart Account Core'
status: In Progress  # To Do | In Progress | Done
assignee: []
created_date: '2026-02-28 11:15'
updated_date: '2026-03-13 14:38'
labels:
  - feature
  - sign90
  - smart-contract
milestone: m-1       # m-1 | m-2 | m-3 | m-r
dependencies:
  - TASK-7
references:
  - 'https://github.com/owner/repo'
priority: medium     # low | medium | high
---

## Description
<!-- SECTION:DESCRIPTION:BEGIN -->
Task description here...
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] Criterion 1
- [x] Criterion 2 (completed)
<!-- AC:END -->
```

### Document Files (`backlog/docs/doc-{N} - Title.md`)

```yaml
---
id: doc-1
title: "🧠 BroodBrain Readme"
type: other
created_date: '2026-02-28 04:02'
updated_date: '2026-03-01 04:03'
---

Content in Markdown...
```

### Decision Records (`backlog/decisions/decision-{N}-Title.md`)

```yaml
---
id: decision-1
title: Start MushroomDAO Cold Launch
date: '2026-02-28 12:01'
status: accepted    # proposed | accepted | rejected | deprecated
---

## Context / 背景
...

## Decision / 决策
...

## Consequences / 影响
...
```

### Milestones (`backlog/milestones/m-{N} - Title.md`)

```yaml
---
id: m-1
title: "Phase 1: Genesis Launch"
---

## Description
Milestone description...
```

## Configuration (`backlog/config.yml`)

```yaml
project_name: "BroodBrain"
default_status: "To Do"
statuses: ["To Do", "In Progress", "Done"]
labels: []
date_format: yyyy-mm-dd
max_column_width: 20
default_editor: "zed"
auto_open_browser: true
default_port: 6420
remote_operations: true
auto_commit: false
bypass_git_hooks: false
check_active_branches: true
active_branch_days: 30
task_prefix: "task"
```

## Static API Structure

The exported `dist/api/` contains JSON files:

| Endpoint | Description |
|----------|-------------|
| `tasks.json` | All tasks (active + merged completed) |
| `docs.json` | List of all documents |
| `decisions.json` | List of all decisions |
| `milestones.json` | List of all milestones |
| `config.json` | Project configuration |
| `statuses.json` | Available statuses |
| `version.json` | Version info |
| `search.json` | Search index |
| `docs/{id}.json` | Individual document |
| `decisions/{id}.json` | Individual decision |
| `milestones/{encodedTitle}.json` | Individual milestone |

**Note:** The injected fetch interceptor in `index.html` automatically appends `.json` to `/api/` requests at runtime.

## Deployment

### GitHub Pages (Default)

Configured via `.github/workflows/deploy.yml`:
- Triggers on push to `main` branch
- Simply uploads `dist/` directory as-is
- No build step in CI (already built locally)

### Cloudflare Pages

**Option 1: CLI Deployment**
```bash
pnpm run deploy:cf
```

**Option 2: Git Integration (Recommended)**
1. In Cloudflare dashboard: "Connect to Git" → select this repo
2. Build command: leave empty or `echo "No build"`
3. Build output directory: `dist`

## Custom Claude Skills

### `/sync-progress` — GitHub Repository Progress Scanner

Located at `.claude/skills/sync-progress/SKILL.md`

**Purpose:** Scans all "In Progress" tasks, analyzes linked GitHub repositories via local git history and CHANGELOG files, estimates completion percentage, and updates task files.

**Requirements:**
- Tasks must have `references:` in frontmatter containing `github.com` URLs
- Or URLs can be auto-extracted from task body and written to frontmatter

**Process:**
1. Collect all "In Progress" tasks
2. Extract GitHub URLs from references (auto-add if missing)
3. Locate local repositories in `/Users/jason/Dev/` (or `SYNC_SCAN_ROOT` env var)
4. Clone missing repos to temporary directory if needed
5. Pull latest code and analyze:
   - Commit history (last 30 days)
   - CHANGELOG files
6. Evaluate progress against Acceptance Criteria
7. Update task's `## Description` section with progress report
8. Calculate Phase weighted progress and update `doc-7`
9. Rebuild and commit

**Usage:**
```bash
# Set custom scan root (optional)
export SYNC_SCAN_ROOT="$HOME/projects"

# Then invoke via Claude with the skill
```

## Development Conventions

### Git Workflow

- **Single branch**: `main` only, direct commits
- **Commit style**: Conventional commits (`fix:`, `chore():`, `docs():`)
- **`dist/` is tracked**: Intentionally committed (no cloud build)
- **Update script**: `update-task.sh` stages, commits with "fix: update task", and pushes

### File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Tasks | `task-{N} - [Type] Name.md` | `task-10 - Feature-Sign90-Smart-Account-Core.md` |
| Docs | `doc-{N} - Title.md` | `doc-1 - 🧠-BroodBrain-Readme.md` |
| Decisions | `decision-{N}-Title.md` | `decision-1-Start-MushroomDAO-Cold-Launch.md` |
| Milestones | `m-{N} - Title.md` | `m-1 - Phase 1 Genesis Launch.md` |

### Task ID Format

- Format: `TASK-{N}` (e.g., `TASK-10`)
- Frontmatter `id` field must match filename
- `dependencies` and `references` use full ID with prefix

### Milestone Mapping

| Key | Canonical Names | Phase |
|-----|-----------------|-------|
| `m-1` | m-1, phase 1, genesis | Phase 1: Genesis Launch |
| `m-2` | m-2, phase 2, community | Phase 2: Community Expansion |
| `m-3` | m-3, phase 3, ecosystem | Phase 3: Ecosystem Maturity |
| `m-r` | m-r, research | Research |

## Testing

**There is no test framework** in this project. Testing is manual:

1. Build: `pnpm run build`
2. Preview: `pnpm run preview`
3. Verify in browser:
   - All tasks load correctly
   - Kanban board shows progress bars
   - Clicking tasks shows details
   - Attempting to modify shows read-only toast (Chinese)
   - No console errors about WebSocket/EventSource

## Security Considerations

### Read-Only Protection

The deployed site is inherently tamper-proof because:

1. **No backend exists**: Only static files on CDN
2. **HTTP methods blocked**: POST/PUT/DELETE/PATCH return 405 or 404
3. **Client-side interception**: Injected script intercepts fetch calls and shows Chinese toast: "只读展示模式：无法修改或删除项目数据"
4. **UI cleanup**: Delete buttons hidden via CSS

### Local Development

- The `backlog` CLI server runs locally on port 8422 (build) or 6420 (dev)
- No authentication required for local access
- Do not expose these ports publicly

## Troubleshooting

### Build Failures

```bash
# If build hangs, check if backlog server is already running
lsof -i:8422

# Kill existing backlog processes
lsof -i:8422 -t | xargs kill -9

# Then retry build
pnpm run build
```

### Preview Port Conflicts

```bash
# Default preview uses port 3000
# If occupied, use alternative
npx serve dist -l 3001
```

### Milestone Progress Not Updating

1. Check task files have valid `milestone` frontmatter
2. Verify `status` field values match config (`To Do`, `In Progress`, `Done`)
3. Rebuild: `pnpm run build`
4. Check browser console for `window.__milestoneProgress`

## External Resources

- **Backlog CLI**: The underlying task management tool (accessed via `npx backlog`)
- **Project Website**: Deployed at GitHub Pages / Cloudflare Pages
- **Mycelium Protocol**: The ecosystem this backlog tracks
