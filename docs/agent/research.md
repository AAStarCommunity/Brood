# Brood Research — 立项依据与已有调研

> 完整调研文档在 `research/` 与 `backlog/docs/`。本文件只做索引 + 立项依据。

## 为什么有 Brood

Mycelium 生态横跨三个 org（AAStarCommunity / iDoris-ai / MushroomDAO）、几十个仓库。
问题有两个，且性质不同：

1. **对外**：没人（包括参与者自己）说得清「现在整体到哪一步了」。
   → BroodBrain：把 `backlog/` 导出成只读静态站点，零后端、CDN 直发。
2. **对内**：每个仓库的开发流程靠人记，危险动作（`git add -A`、直推主干、
   没跑检查就开 PR）全靠自觉。
   → pilot skill：把「有经验程序员的默认」固化成脚本层的确定性护栏。

## 关键选型依据

### 站点：为什么本地构建 + `dist/` 入库

云端构建需要在 CI 里装 backlog.md CLI 并起服务，慢且脆；而站点更新频率低。
代价是「改了内容忘记 build」——用 CI 守卫（`dist/ matches a fresh build`）补上。
**这是一个已知取舍，不是疏忽。**

### AI 模型与成本：见 `research/cloudflare-workers-ai/`

两份文档：
- `README.md` — Cloudflare Workers AI 能不能直接提供最新开源模型（结论：能，27 个 skill 可用）
- `cost-analysis-api-vs-coding-plan.md` — **Cloudflare 照搬官方牌价，没有成本优势**；
  结论是「日常开发买 coding plan、评审走官方 API」，并指出 Claude Code 的非交互用量
  自 2026-06-15 起走独立额度——那可能才是 $200 不够用的真正原因

### 评审：为什么解耦

历史上 pilot 直接启动一个 PR-Daemon 进程。结果是 pilot 和那个 daemon 死锁在一起，
装了 pilot 的机器都被迫带上一个可能坏掉的依赖。花 6 轮评审拆成纯接口契约
（`reference/review-contract.md`）。**这是本仓库最贵的一条教训，写进了架构边界。**

## License 边界

Apache 2.0 + NOTICE + TRADEMARK 三件套，模板在 `protocol/license-templates/`，
由 `/license-update` skill 批量同步到生态各 repo。

## 待研究

- **TASK-40 的 PreToolUse hook 怎么实现**——SKILL.md 称它是首要强制手段，
  但没人验证过 Claude Code plugin hook 能否可靠拦下模型真正要跑的命令。
  这是 pilot 从「劝告」变成「强制」的唯一路径，值得先做一个最小验证。
- **pilot 门禁支持可配置的规划源**——本仓库的规划在 `backlog/`，
  而门禁只认 `docs_dir` 下七个固定文件名，于是一个规划完备的仓库被判「未就绪」。
