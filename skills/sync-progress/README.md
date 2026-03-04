# Sync Progress — Claude Code Skill

扫描 backlog 中所有 "In Progress" 任务关联的 GitHub 仓库，通过本地 git commit 历史和 CHANGELOG 分析开发进度，自动估算完成百分比并回写到任务文件。

## 前置条件

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 已安装
- 项目使用 [backlog](https://www.npmjs.com/package/backlog) CLI 管理任务
- 任务文件中的 `references:` 字段包含 GitHub 仓库 URL

## 安装

将 `SKILL.md` 复制到你项目的 `.claude/skills/sync-progress/` 目录：

```bash
# 在你的 backlog 项目根目录下执行
mkdir -p .claude/skills/sync-progress
cp skills/sync-progress/SKILL.md .claude/skills/sync-progress/SKILL.md
```

如果你的项目不是从本仓库 clone 的，可以直接下载：

```bash
mkdir -p .claude/skills/sync-progress
curl -o .claude/skills/sync-progress/SKILL.md \
  https://raw.githubusercontent.com/jhfnetboy/Brood/main/skills/sync-progress/SKILL.md
```

## 使用

在项目目录下启动 Claude Code，输入：

```
/sync-progress
```

## 配置

### 仓库扫描路径

默认扫描项目根目录的 **父目录**（如项目在 `~/Dev/MyProject`，则扫描 `~/Dev/` 下所有 git 仓库）。

如果你的关联仓库不在同级目录，设置环境变量指定扫描根路径：

```bash
# 写入 shell 配置持久生效
echo 'export SYNC_SCAN_ROOT="$HOME/projects"' >> ~/.zshrc
```

### 任务关联

在 backlog web 界面为 In Progress 任务添加 References，填入 GitHub 仓库 URL：

- `https://github.com/owner/repo` — 扫描默认分支
- `https://github.com/owner/repo/tree/branch-name` — 扫描指定分支

没有 GitHub 引用的任务会被跳过。

## 工作原理

```
/sync-progress
    |
    v
1. 扫描 backlog/tasks/*.md → 找到 In Progress 任务
    |
    v
2. 提取 references 中的 GitHub URL → 解析 owner/repo/branch
    |
    v
3. 在本地 $SCAN_ROOT 下匹配 git remote → 定位本地仓库
    |
    v
4. git pull + git log + 读取 CHANGELOG → 采集开发数据
    |
    v
5. AC/DoD vs commits/changelog 语义匹配 → 估算进度百分比
    |
    v
6. 写入任务 Description section → web UI 可见
    |
    v
7. pnpm run build + update-task.sh → 构建静态站点并提交推送
```

## 示例输出

```
=== BroodBrain 进度扫描报告 ===
扫描时间: 2026-03-04 14:00

| 任务 | 进度 | 仓库 | 最近提交 | 摘要 |
|------|------|------|----------|------|
| TASK-18 KMS/TEE | 75% | AirAccount (KMS) | 今天 | v0.16.4 stable beta |
| TASK-8 Paymaster V4 | 60% | SuperPaymaster | 今天 | V4.3 稳定币已合并 |
| TASK-9 Comet ENS | — | 无关联仓库 | — | 跳过 |
```
