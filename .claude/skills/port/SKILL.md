---
name: port
description: 列出当前电脑正在监听的本地 web 服务（端口、可点击网址、页面 title、进程/PID），并支持按列表 ID kill 掉对应服务。当用户说 /port、"看看本地起了哪些服务"、"哪些端口在监听"、"把第 N 个服务杀掉"、"kill 5173" 时使用。
---

# port — 本地 web 服务列表与按 ID kill

所有逻辑都在 `scripts/port.py`（本 skill 目录下），不要用内联 bash 拼 lsof/curl 管道。

## list（默认动作）

用户说 `/port` 或 `/port list` 时：

```bash
python3 .claude/skills/port/scripts/port.py list
```

脚本会：

1. 用 `lsof` 扫出所有 LISTEN 中的 TCP 端口（当前用户可见的进程）
2. 并发对每个端口探测 `http://localhost:PORT/`（失败再试 https），能响应 HTTP 的才算"有效 web 服务"
3. 抓取页面 `<title>`
4. 输出 markdown 表格：`ID | Title | URL | Port | 进程 | PID`
5. 把 ID→pid/port 的映射写入 `~/.cache/claude-port/state.json`，供后续 kill 使用

**把脚本输出的表格原样展示给用户**（markdown 表格里的 URL 在终端可点击），不要改写或省略行。表格下方如提示"另有 N 个非 HTTP 监听端口"，一并转告；用户想看全部时加 `--all` 重跑。

## kill

用户说 `/port kill 1`、"把第 1 个杀掉"、"kill 3" 时（数字指上次 list 表格里的 ID 列）。支持一次杀多个，含区间写法：

```bash
python3 .claude/skills/port/scripts/port.py kill 1
python3 .claude/skills/port/scripts/port.py kill 2 4 6-9
```

- 脚本 kill 前会**重新扫描核对**该端口的 pid 是否仍与记录一致，不一致会拒绝执行——此时转告用户并重新 list，绝不猜测目标。
- 默认发 SIGTERM 并等待确认；脚本提示进程仍存活时，询问用户后再用 `kill <ID> -9` 强杀。
- 用户如果说的是端口号而不是 ID（如 "kill 5173" 且 5173 不像小序号），先对照上次表格找到对应 ID 再执行；拿不准就重新 list 让用户确认。
- 杀完后把脚本输出（杀掉了哪个 title/url/pid）转告用户。

## 注意

- 距上次 list 超过几分钟再 kill 时，建议先重新 list 一次刷新编号。
- 脚本只列当前用户的进程；需要 root 进程时用户需自行 sudo，本 skill 不主动提权。
