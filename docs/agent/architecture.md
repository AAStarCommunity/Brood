# Brood Architecture — 技术骨架与不可破边界

## 两个产物，一个仓库

| 产物 | 是什么 | 入口 |
|:---|:---|:---|
| **BroodBrain 站点** | 只读静态 SPA + JSON API，发布 Mycelium 生态进度 | `scripts/export-backlog.js` → `dist/` |
| **pilot skill** | 可安装的仓库级开发操作系统 | `plugins/pilot/skills/pilot/` |

两者共用 `backlog/`（前者展示它，后者不碰它）。

## 站点侧：本地构建，直推产物

```
backlog/*.md ──(backlog.md CLI :8422)──> export-backlog.js ──> dist/ ──(git)──> GitHub Pages / CF
```

**不可破的边界：**

1. **`dist/` 入库，CI 不构建。** 部署原样上传 `dist/`。所以「改了内容没重新 build」
   等于发布了旧站点——这正是 `dist/ matches a fresh build` 守卫存在的原因。
2. **导出产物必须可复现。** 任何随机/时钟/机器相关的东西都要在
   `sanitizeApiPayload()` 里清洗掉（绝对路径、mtime），清洗不掉的（如任务平均年龄）
   在比对前归一化，**而不是从 payload 里删掉**——删了会让线上站点少一个真实数字。
3. **只读**。注入的拦截脚本挡住所有写方法，并把 `/api/` 请求补 `.json` 后缀。

## pilot 侧：分层强制

```
① GitHub 分支保护（服务端，不可绕）  ← 唯一真正的机械保证
② PreToolUse hook（TASK-40，未建）   ← SKILL.md 自称的首要手段，目前为空
③ git-guard.sh / safe-cleanup.sh    ← best-effort 便利包装 + 纵深防御
④ SKILL.md 的散文约束               ← 靠模型自觉
```

**边界：越往下越不可信。** 任何「这条护栏保证了 X」的说法，必须能指到 ① 或 ③ 的
具体代码行；指不到就只是 ④。今天三个「守卫跑不起来」的教训都出在把 ③ 当成 ① 来信。

**放权必须先建立证据。** `--allow-trunk` 放松「合到哪里」但要求服务端证明分支保护要求审批；
`--squash-merged` 放松 `-D` 但要求 GitHub 证明某个已合并 PR 引入了该 commit。
**先证据、后放权**，不是「为了让守卫能跑就削弱它」。

## 外部依赖：只按契约，不 import

- **PR 评审**：外部服务，契约见 `reference/review-contract.md`。pilot 不启动、不感知后端。
- **文档源（飞书 / Notion）**：契约见 `reference/doc-sources.md`。运行时只探测，不 import。

这条边界是花了 6 轮评审从一次 daemon 硬耦合里拆出来的，**不要因为「pilot 是入口」就写回去**。
