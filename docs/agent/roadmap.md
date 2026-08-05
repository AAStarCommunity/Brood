# Brood Roadmap — Milestone → Feature

> ⚠️ **本文件是视图，不是事实来源。** Brood 的规划事实来源是 `backlog/`（backlog.md CLI 管理），
> 里程碑在 `backlog/milestones/`，任务在 `backlog/tasks/`。这里只做 pilot 需要的 M→F 摘要，
> **不复制内容**——改规划请改 `backlog/`，不要改这里。
>
> 为什么需要这个文件：pilot 的起跑门禁 `check-docs.sh` 只认 `docs_dir` 下这七个文件名，
> 认不出 `backlog/` 这种等价（且更完整）的规划。这是 pilot 的一个已知缺口，记在
> `docs/agent/followups.md`。记录日期：2026-08-05

## M1 — Phase 1: Genesis Launch

目标：把生态的核心基础设施做出来，让「普通人无门槛用上 Web3」这条路第一次跑通。

- **F1.1 Cos72 Chrome Extension** — 社区入口，Cards / Points / Perks 与核心模块（MyTask、MyShop、MyView）
- **F1.2 AirAccount** — 隐形加密账户（抽象账户），用户不需要理解私钥
- **F1.3 SuperPaymaster** — gas 代付，把「上链要先有币」这道门槛去掉
- **F1.4 Sign90 / Comet ENS** — 签名基础版与 ENS 子域名服务

## M2 — Phase 2: Community Expansion

目标：从「能用」走到「社区能自己运转」。

- **F2.1 KMS / TEE** — 可信执行环境，托管类能力的信任底座
- **F2.2 Zu.Coffee** — 第一个真实商业 DApp，验证闭环
- **F2.3 Bundler / OpenCrab** — 交易打包与面向个人的 agent

## M3 — Phase 3: Ecosystem Maturity

目标：从单点产品走到协议与网络效应。

- **F3.1 Asset3** — 个人资产管理协议
- **F3.2 Spores** — 病毒式传播 SDK
- **F3.3 OpenNest / Park / TradeStar / CoinJar** — 扩容协议、可持续公共物品、交易训练、自托管存钱罐

## M-R — Research（与 M1/M2/M3 并行，不排在它们之后）

目标：论文与文章产出。研究任务可以横向关联到任意阶段的开发任务。

- **FR.1 协议侧研究** — EOA Bridge、SuperPaymaster、CommunityFi
- **FR.2 生态与教育** — iDoris.ai 课程、全球网络与 KMS 部署调研
- **FR.3 成本与选型** — 见 `research/cloudflare-workers-ai/`

## 当前重心

M1 有 5 个 In Progress 任务，是主战场；M-R 有 5 个，属于并行产出。
M2（2 个）、M3（3 个）已经起步但不是当前焦点。
