---
id: doc-8
title: PR-Daemon review 系统改进 digest(from 91 reviews)
type: other
created_date: '2026-08-03 12:34'
---

从 PR-Daemon 的 91 个已 post review + 17 万行 review-watch.log 里挖出的**针对系统本身**的改进建议(非单个 PR 的代码修复),按「复现次数 × 影响」排序。已把可执行项立成 TASK-39 ~ TASK-45。

## 两个最高杠杆

- **A. `/sync-progress` 在编造生态状态** → **TASK-39**。Brood#23 铁证:不存在的 repo(404)虚增进度、编造的 commit、stale cache 当 last-commit 得假静默日期。修法:写入前每个 repo/date/commit/tag 过 live gh-api 200-OK 校验。这是 Brood 自己的旗舰 skill 在往权威上下文写 confabulation,最高优先。
- **B. `git-guard.sh` 靠模型自觉路由才生效,无机械强制** → **TASK-40**。护栏在 `~/.claude/skills/` 里、repo 内 grep 找不到,模型忘了调用就静默绕过。pilot 已做成 plugin(#29),用 `hooks/hooks.json` PreToolUse 钩子在工具边界机械拦截 `git add -A` / 推主干。

## review pipeline 本身(反复出现)

1. **DeepSeek R1a 在非平凡 PR 上几乎全噪音/漏报**(#22 漏光 5 真、#29 漏光 3 真),**但 R1b 安全轮偶尔独中全场最有价值一击**(Self-FDE#85 抓到 `Sec-Fetch-Site` 零鉴权绕过,5/5)。→ 非对称处理:压 R1a 噪音、升 R1b 命中。[×15+]
2. **Codex R3 是真阳性主力,但 `codex exec` 等 stdin-EOF 挂死**,降级成乱猜的 DeepSeek(challenge 几乎全错)。根因已定位:命令补 `< /dev/null`。[×5 降级 / 7478 log 命中]
3. **R4 Opus 全量重扫经常独家发现前三轮全漏的 blocker**(#29 Apache-vs-GPL license、#23 假日期、#193 输出丢失)。→ 别因省 token 跳过 R4。[×5]
4. **SQLite 单写锁是真瓶颈**:213 次 "database is locked",GitHub 评了但本地 state 没更新 → **重复评审同一 PR**(#194 一天重跑 3 次、6 个 request-changes 文件)。→ post 后 finalize(UPDATE+归档)做成不可被 SIGTERM 打断的短事务;手动单-PR review 前先查 current-review.json 防自撞。[×3 + 213]
5. **scan_error 风暴** = 本地死代理 127.0.0.1:7890 connection reset,非逻辑错。→ **已修**(注释 .zshrc 死代理 + load_pr_daemon_env.sh 空 PR_DAEMON_*_PROXY 强制 unset 继承代理)+ **TASK-41**(重启应用 + GraphQL retry-backoff)。[49 次]

## 跨 PR 系统性质量问题

- **改名从不做全仓 `grep -r`**,残留引用还让 sync-progress dedup 追加重复 URL(功能 bug)→ **TASK-42**(R1 prompt 加 rename-grep 步)。[×2:#22 #29]
- **docs refresh 断言端口/路径/endpoint/JSON 与真实代码不符,修时还引入新错**(#18 幻影 UI:8080、非法 JSON、frps 证书表述反复)→ doc PR 必须对真实代码验证;curl body 过 JSON-lint;arch 图从真实路由重画。[×2:#18 #193]
- **可执行运维工具塞 docs/ 逃过 lint/CI** → **TASK-44**(移 scripts/)。[#193]
- **`dist/` 提交进 git 但无自动校验可否从 generator 复现**(#21 靠人肉 byte-diff)→ 该做成 CI gate。[#21]
- **涉钱任务验收只有 type-check/lint** → **TASK-43**(机器可验收断言,如 gas ≤ N× cap)。[#450]
- **serial-run 输出解析歧义** → **TASK-45**(nonce 分隔的机器可读结果,一改关 3 个 bug)。[#193]

## 已完成(本轮)
- scan_error 根因修复(.zshrc + load_pr_daemon_env.sh,已验证;待 daemon 重启生效)
- pilot 已打包为 plugin marketplace(#29);License 统一 Apache(根 LICENSE GPL v3 → Apache 2.0)

来源文件:`~/Dev/tools/PR-Daemon/reviews/*.md`(91 个),重点 `Brood-23-request-changes-90adddb`、`Brood-22-request-changes-8b78874`、`Brood-18-request-changes-54fd285`、`Self-FDE-WorkBench-85-*`、`AirAccount-193-request-changes-5173488`、`YetAnotherAA-450-approve-99fb4b6`。
