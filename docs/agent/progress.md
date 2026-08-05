# Brood Progress — 实时状态

> 「此刻在做什么」。规划见 [`roadmap.md`](roadmap.md)，任务台账见 [`tasks.md`](tasks.md)。
> 本文件由 `pilot run` 持续更新。最后更新：2026-08-05

## 当前分支与工作区

- 集成分支：`main`（**单主干**，无 preview；见 `.pilot.yml` 的说明）
- 本地分支：`main` + `cla-signatures`（CLA 签名存储，永久保留）+ `feat/pilot-auto-commit`（TASK-49 的原型，待做）
- 工作区：干净

## 在途 PR

- **#45** `feat(pilot): FU-1/FU-2/FU-4 —— flag 改白名单 + safe-cleanup 支持 squash 仓库` — 等外部评审裁决

## 2026-08-05 已交付

八个 PR 合并：#36 → #40 → #39 → #38 → #41 → #42 → #43 → #44。

主线是**把三个「跑不起来的守卫」修好**——三个都是本仓库自己写的，三个都是**用的时候**才现形，
没有一个是审出来的：

| PR | 病症 |
|:---|:---|
| #39 | `merge-pr` 因 `gh repo view --repo`（不存在的 flag）对任何仓库都必死 |
| #40 | dist 可复现守卫被一个按墙钟算的字段带成随机红灯（15 分钟内就翻） |
| #45（在途） | `safe-cleanup` 在 squash 仓库里永远清不掉分支（`git branch --merged` 恒返回 0） |

其余：#38 定下「pilot 是唯一入口、配套能力按契约探测」；#41 输出 Cloudflare vs 官方定价选型分析；
#42/#43/#44 逐条做掉评审的 Low 并把方法记进账本。

同期：本地分支 28 → 3（每个删除都过机械核实）；必需检查 3 → 4 项（新增版本同步）。

## 当前阻塞

无硬阻塞。两个已知缺口记在 `followups.md`，都不阻塞主线。

## 下一步

1. 等 #45 裁决 → 合并 → `install.sh --copy` 发布到全局
2. 走一轮完整 `pilot run` 交付一个真 task，验证「整机能跑」而不只是「配件好使」
