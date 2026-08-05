# Brood Spec — 数据模型 / 状态机 / 错误处理

## 数据模型：任务文件

`backlog/tasks/task-N - <标题>.md`，YAML frontmatter + markdown 正文。

| 字段 | 说明 | 坑 |
|:---|:---|:---|
| `id` | `TASK-N` | |
| `title` | 标题 | **含 `:` 必须加引号**——未加引号曾让解析器吐出空记录，10 个任务一次坏掉，且空记录仍带原始 markdown 进了公开搜索索引 |
| `status` | `To Do` / `In Progress` / `Done` | 实测存在 `Done` 与 `"Done"` 两种写法并存，消费方要容忍 |
| `milestone` | `m-1` / `m-2` / `m-3` / `m-r` | |
| `dependencies` | 任务 id 列表 | 未 Done 的依赖会挡住挑选 |
| `references` | 含 `github.com` URL 时 `sync-progress` 才能扫它 | |

正文里 `<!-- SECTION:DESCRIPTION:BEGIN/END -->` 之间是 `sync-progress` 写进度的位置，
`<!-- AC:BEGIN/END -->` 之间是验收标准。**改这些标记要同步改写入方**。

## 导出契约（`/api/*.json`）

- `tasks.json` 只含活动任务；`backlog/completed/` 由 `export-backlog.js` 单独合并进去，
  合并前 `.sort()`（readdir 顺序依赖文件系统，不排序会让可复现守卫无理由报红）
- `statistics.json` 的 `projectHealth.averageTaskAge` **按当前时间算**，
  十几分钟就会跳一个数——比对前归一化，不删字段（SPA bundle 在读它）
- 所有 payload 过 `sanitizeApiPayload()`：丢 `lastModified`，把
  `filePath`/`projectPath`/`rootConfigPath` 转成仓库相对路径

## 状态机：一个改动到 main 的路径

```
feature 分支
  → git-guard.sh add <显式路径>        （拒 -A / 目录 / glob / pathspec magic）
  → git commit
  → git-guard.sh push origin <branch>  （拒推保护分支，解析所有 refspec 形态）
  → preflight.sh run                   （跑 .pilot.yml preflight + scripts/ci/*.sh + build，
                                         成功才写戳记，戳记绑定 HEAD sha）
  → git-guard.sh pr-create             （无戳记 / 戳记属于别的 commit → 拒绝）
  → 外部评审                            （契约：约 20 分钟出裁决）
  → git-guard.sh merge-pr --allow-trunk （要求分支保护要求审批 + 该 PR 已 APPROVED）
  → safe-cleanup.sh [--squash-merged]  （squash 仓库需要证据才 -D）
```

**每一步的失败都必须 fail-closed。** 判据：把该步依赖的外部条件拿掉（gh 卸载、
token 无权限、分支无保护、戳记过期），它必须**拒绝并说明缺什么**，而不是放行、也不是
沉默。「查不了」与「没有」在输出上必须能区分——这条踩过一次：子 shell 里设的状态
返回后丢失，导致「无法核实」永远打印成「没有可清理的」。

## 错误处理约定

- 脚本用 `set -euo pipefail`；退出码 `2`=用法错、`3`=被护栏拒绝
- 拒绝消息必须说**怎么修**，不能只说不行——只说「refused」的护栏会被绕过
- 解析外部 JSON 时**只取 stdout**：把 stderr 折进来会让 shell hook 的诊断行污染 JSON，
  于是每条分支都退化成「读不到」
