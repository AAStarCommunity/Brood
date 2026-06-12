# Mycelium Protocol — 半年期 OKR 与里程碑节奏

> 维护：Brood Orchestrator | 周期：2026 H2（6 月 ～ 12 月）
> 最后更新：2026-06-12
> 关联：[`MISSION.md`](./MISSION.md) | [`../docs/REPO_STATUS.md`](../docs/REPO_STATUS.md) | [`../backlog/docs/doc-7 - 📊-Progress-Report.md`](../backlog/docs/doc-7%20-%20📊-Progress-Report.md)

---

## 半年期核心目标（North Star）

> **启动 Launch 并获得基础可持续的第一笔收入。**

这是 H2 全部工作的统领。所有仓库的优先级、激活时机、资源分配都以「是否服务于 launch + 第一笔可持续收入」为锚。

「可持续」的定义：能覆盖 gasless 垫付、域名/服务器/CDN、最小维护工时 —— 不是商业暴利，是协议层不亏钱。

---

## 三个关键前提（KR）

| # | 前提 | 状态判定 |
|:---:|:---|:---|
| **KR1** | 至少 **2 篇论文 AK 发布**（已被期刊接收/出版） | Paper3 已投稿 BRA · Paper7 v2 数据收集中 |
| **KR2** | **所有 beta 版（beta-1/2/3）测试完备 + OP 主网部署**，给出"可上主网"结论 | v5.3.3-beta.2 已 Sepolia 部署，beta-3 待规划 |
| **KR3** | **泰国 + 杭州公司**稳步推进，有基础规划（规模/成本/收入来源） | 杭州依赖浙大创业比赛 · 泰国独立推进 |

---

## KR1 · 论文 AK ≥ 2

| 论文 | 仓库 | 当前状态 | 下一步 | 截止 |
|:---|:---|:---|:---|:---|
| **Paper3** SuperPaymaster AOA in ERC-4337 | `aastar/SuperPaymaster` (代码) + DSR repo (论文) | ✅ 已正式投稿 BRA | 等待评审 → revision | Q3 |
| **Paper7** CommunityFi Reputation-Backed Credit | `aastar/aastar-sdk/community/research` | 🔧 第二版 v7 long-horizon + Sankey + 可复现 artifacts 中 | 完成 v2 → JBBA 正式投稿 | Q3 |
| Paper6 Gasless EOA Bridge (7702) | DSR repo | ⬜ Not started | 队列中 | Q4 评估 |
| Paper4 AirAccount D2D MultiSig | DSR repo | ⬜ Not started | 队列中 | Q4 评估 |
| Paper5 SocialRecovery | DSR repo | ⬜ Not started | 队列中 | Q4 评估 |

### 额外：AI agent 协作网络相关论文（3 篇）

位置：`~/jhfnetboy/dsr/`（个人目录，不在三大 org 内，**Brood 默认不扫描**）

| 论文 | 状态 | 与 Mycelium 的关系 |
|:---|:---|:---|
| AI Agent 协作网络 论文 #1 | 进行中 | 为 Mycelium Network / Agent24 / AgentSocial 提供理论基础 |
| AI Agent 协作网络 论文 #2 | 进行中 | 同上 |
| AI Agent 协作网络 论文 #3 | 进行中 | 同上 |

> 提醒：jhfnetboy/dsr 目录不在三大 org 追踪范围；如需进度同步，可手动告知 Brood 或临时把 DSR 路径加入 sync-progress 扫描。

---

## KR2 · Beta 全测 + OP 主网部署

| 子系统 | Beta 进度 | 主网部署 | 关联仓库 |
|:---|:---|:---|:---|
| **SuperPaymaster** | v5.3.3-beta.2 ✅ Sepolia | ⬜ OP 主网 | `aastar/SuperPaymaster` |
| **AirAccount** | 2026-06-11 全量审计 P0+H 修完 + MX93 适配 | ⬜ OP 主网 | `aastar/AirAccount` |
| **UltraRelay (Bundler)** | aastar-dev 分支稳定 | ⬜ OP 主网 | `aastar/UltraRelay-AAStar` |
| **CometENS** | 生产化重启，KV bindings 上线 | ⬜ 主网 .cv 域名映射 | `mycelium/CometENS` |
| **GToken / SaleContractV2** | EIP-7702 gasless 3-flow UX | ⬜ OP 主网 | `mycelium/launch` |
| **Cos72 核心模块** | MyShop M1 ✅ · MyTask Sprint 1 ✅ · MyVote ⬜ | ⬜ | `mycelium/{MyShop,MyTask,MyVote}` |

### 主网上线**前置依赖**（必须完成）

- ⚠️ SuperPaymaster v5.4 关键 issue 落地（特别是 `#210 L-A Registry 压缩`，阻塞 H-4 + M-2）
- ⚠️ AirAccount 跨链能力启动（TASK-5 当前 70%，剩 30% 是 cross-chain）
- ⚠️ MyVote 启动（TASK-13 Cos72 Core 卡住的环节）
- ⚠️ CometENS 真实生产域名（.cv / .box / .zparty）上线 1 个验证生产可用性

---

## KR3 · 公司组织推进

```
开源组织 (MushroomDAO)
  └─ 持续运营，靠协议层最低收入维持
     └─ 商业组织 (HyperCapital)
        ├─ 杭州公司（依赖：浙大创业比赛进展）
        │   └─ 比赛进展顺利 → 顺理成章成立 → 商业初始投资
        └─ 泰国公司（独立推进）
            └─ 规模 / 成本 / 收入来源 等基础规划
```

### 杭州公司路径

| 阶段 | 状态 | 阻塞点 |
|:---|:---|:---|
| 浙大创业比赛 | 🔧 进行中 | ⬜ 比赛结果不确定 |
| 公司主体注册 | ⬜ 等比赛 | 取决于比赛 |
| 初始投资到位 | ⬜ 等注册 | — |
| 业务规划（规模/成本/收入）| 🔧 草稿阶段 | 需要在比赛期间同步打磨 |

### 泰国公司路径

| 阶段 | 状态 |
|:---|:---|
| 主体规划 | 🔧 进行中 |
| 法律合规研究 | 🔧 |
| 业务定位 | 🔧 与杭州公司协同分工 |

---

## 节奏感：仓库激活时机

> 这一节是 orchestrator 帮你判断**本周该不该提醒激活某仓库**的依据。

| 仓库 | 当前状态 | 服务于 | 必须激活时机 | 当前距激活 |
|:---|:---|:---|:---|:---|
| `mycelium/MyVote` | 🟡 静默 41 天 | KR2（Cos72 核心模块完整）+ Phase 1 Genesis | Q3 末前必须有 v0.1 | ⚠️ **建议本月启动**，否则 Q3 兜不住 |
| `aastar/Cos72` | 🟡 静默 44 天 | KR2（Cos72 主仓库主网准备） | Q3 中需配合主网部署联调 | 待 Cos72 模块齐备 |
| `aastar/airaccount-contract` | 🟢 活跃 | KR2（AirAccount 主网部署）| 主网部署前持续 | 进行中 |
| `aastar/SuperPaymaster` | 🟢 活跃（v5.4 18 issues）| KR1 + KR2 | 持续 | 进行中 |
| `mycelium/launch` | 🟢 活跃 | KR2（GToken 主网） | Q3 中主网 | 进行中 |
| `mycelium/CometENS` | 🟢 活跃 | KR2（.cv 域名服务）| Q3 末前 1 个生产域名 | 进行中 |
| `auraai/AgentSocial` | 🟢 活跃 | KR1（Paper3 工程化） | 与论文同步 | 进行中 |
| `auraai/iDoris-SDK` | 🟢 活跃（M5 完成）| 商业（个人 AI agent 接入产品形态）| Q4 商业演示 | 进行中 |
| `aastar/SDSS` | 💤 静默 381 天 | 未明确 | 若 H2 不动 → 评估 archive | **建议本 sprint 决策** |
| `aastar/captcha-bot` | 💤 静默 641 天 | 未明确 | 若 H2 不动 → 评估 archive | **建议本 sprint 决策** |
| `aastar/demo` | 🔴 静默 245 天 | TASK-2 Cos72 Cards | 本月用还是承认放弃 | **本月决策** |

---

## 自动发现机制

orchestrator 应该主动注意以下信号（不依赖用户提醒）：

1. **新 repo 出现但没在 backlog 注册** —— `sync-progress` Phase 0 已能识别，会自动加入 `docs/ECOSYSTEM_MAP.md` 并尝试匹配 backlog 任务的 `references:`
2. **关键仓库长期静默但 OKR 还依赖它** —— `REPO_STATUS.md` 关注列表 + 本文件的"节奏感"表交叉检查
3. **里程碑 deadline 临近但前置仓库还没启动** —— 本文件「必须激活时机」列与今天对比
4. **跨 repo 接口冲突或重复造轮子** —— 通过 `DEPENDENCY_GRAPH.md`（待建）识别

---

## 季度 / 月度复盘节奏

| 节奏 | 操作 | 数据源 |
|:---|:---|:---|
| **每次 sync-progress** | 自动刷新 doc-7 + REPO_STATUS | task/repo 视角 |
| **每月** | 评审本文件（一次） | OKR 进度 |
| **每季度** | 重写本文件「KR 状态」+「节奏感」+ Brood 内 `decision-N.md` 记录关键决策 | 全数据 |

---

## 版本历史

| 版本 | 日期 | 变更 |
|:---|:---|:---|
| v0.1 | 2026-06-12 | 初稿：H2 半年期 OKR + 三个 KR + 节奏感表 |
