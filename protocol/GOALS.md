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

### A. DSR Papers（`~/Dev/jhfnetboy/DSR-Research-Flow/`）

✅ **已纳入 Brood 扫描** (`scripts/scan-repo-status.py` 的 `WATCHED_PERSONAL_REPOS`)
进度源：`~/Dev/jhfnetboy/DSR-Research-Flow/writing/progress.md`

| Paper | 主题 | 状态 | 投稿目标 | KR1 |
|:---|:---|:---|:---|:---:|
| paper0 | SuperPaymaster（早期） | 历史归档 | — | — |
| paper1 | CometENS | 待启动 | — | 候选 |
| paper2 | MyTasks-GasMarket | 待启动 | — | 候选 |
| **paper3** | SuperPaymaster: AOA in Account Abstraction | ✅ **已投稿 BRA**（v7.9-PathE）| Ledger / BRA | ⭐ |
| paper4 | AirAccount: D2D MultiSig | Not started | — | Q4 评估 |
| paper5 | SocialRecovery | Not started | — | Q4 评估 |
| paper6 | Gasless EOA Bridge (7702) | Not started | — | Q4 评估 |
| **paper7** | CommunityFi: Reputation-Backed Credit | 🔧 P6 Done, Step 4 进行中（IET 投稿包就绪 + v12 校对完成）| JBBA / IET | ⭐ |
| paper8 | ChiangMai-Connect / SuperPaymasterV2 | 🔧 P1 Scaffolding | — | 候选 |

**作者信息**：Huifeng Jiao (Jason) · ICDI, Chiang Mai University · 学号 662455802 / PhD Program 1.1

---

### B. AI Agent 协作网络系列（`~/Dev/auraai/AgentSocial/`）

✅ **已在 `auraai/AgentSocial` repo 中**（与 TASK-34 iDoris.ai 关联）

**仓库三层定位**（来自 README）：

> **核心使命**：让 AI Agent 从"可调用的能力容器"进化为"角色承载的社会化协作者"

| 层 | 名称 | 论文 | 关键缩写 |
|:---|:---|:---:|:---|
| **网络层** | **ASN — Agent Social Network**（论文正文称 ACN, Agent Collaboration Network）| **Paper 1** | ASN / ACN |
| **协议层** | **ASM — Agent Social Messaging**（角色承载型 agent 之间的通信协议）| **Paper 2** | ASM |
| **实现层** | **Social Agent**（基于 Pi/pi-mono 的参考实现）| **Paper 3** | ASN-Agent |

**与 KR3 的关键关联**：
- README 明文：「配套参赛**第八届浙江大学校友创新创业大赛**(ZUAEC, **提交截止 2026-08-31**)」
- **AgentSocial 3 篇论文 + 参赛项目 = 杭州公司路径的核心交付物**
- 这是 KR1（论文）和 KR3（杭州公司）的**双重承载**

### orchestrator 提醒规则（合并 A+B）

- 当任何一篇关键论文（DSR paper3/7 + AgentSocial paper1/2/3）距上次提交 > 14 天且离投稿/比赛 deadline < 30 天，主动提示「⚠️ 论文 X 已 N 天无进展，距离 deadline 还有 M 天」

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

### 杭州公司路径 —— 第八届浙江大学校友创新创业大赛

**赛程时间表**（⚠️ orchestrator 主动提醒节点）：

| 阶段 | 时间 | 我们的动作 |
|:---|:---|:---|
| **项目征集 / 报名** | **2026-05 ～ 2026-08** | ⚠️ **8 月底前必须完成报名**（核心团队需至少 1 名浙大校友）|
| 分区赛 | 2026-09 ～ 2026-11 | 4 大国内赛区（东部/南部/西部北部/浙江）+ 2 大海外赛区（亚太/欧美）|
| 行业赛 | 2026-12 ～ 2027-04 | ~100 个项目进行业赛，分类路演 + 行业评审 |
| 总决赛 | 2027-05 | ~20 个项目晋级，浙大百卅校庆献礼 |

**赛道选项**：
- 地方赛区（按地理）— 浙江赛区由杭州校友会承办
- 学者创新专场（校内教师创业）
- 乡村振兴专场
- 百强直通车赛道（特别优秀的项目）

**资格**：核心团队（股东或经营管理层）至少 1 名浙大校友 ✅

**参赛项目载体**：`~/Dev/auraai/AgentSocial`（ASN/ASM/Social Agent 三层 + 3 篇论文，README 已明文锁定提交截止 **2026-08-31**）

**公司路径与比赛的依赖**：

| 阶段 | 状态 | 触发条件 |
|:---|:---|:---|
| 报名提交 | ⬜ **本月～8 月**必须完成 | 浙大校友身份确认 + 项目材料准备 |
| 公司主体注册 | ⬜ 等分区赛进展 | 比赛进展顺利 → 顺理成章成立 → 商业初始投资 |
| 初始投资到位 | ⬜ 等注册 | — |
| 业务规划（规模/成本/收入）| 🔧 草稿阶段 | 在比赛期间同步打磨 |

> **orchestrator 提醒规则**：
> 1. 当今天 ≥ 2026-08-01 且 ZUAEC 报名状态仍为 ⬜，每次 introduce-suggestion 必须红字提示「⚠️ ZUAEC 报名截止 2026-08-31 逼近，AgentSocial 项目是否已报名？」
> 2. AgentSocial repo 静默 > 7 天且今天距 2026-08-31 < 30 天 → 提示「⚠️ AgentSocial 项目最近 N 天无进展，距 ZUAEC 提交还有 M 天」

### 泰国公司路径

| 阶段 | 状态 | 当前进展 |
|:---|:---|:---|
| 政策调研 | ✅ 完成 | 初步政策调研已完成 |
| 主体规划 | 🔧 计划中 | 在计划中尚未启动 |
| 法律合规研究 | ⬜ | 待启动 |
| 业务定位 | ⬜ | 与杭州公司协同分工后定 |

> **orchestrator 提醒规则**：泰国公司目前在「计划中尚未启动」阶段，等杭州公司路径明朗后再决定泰国的启动时机和定位（避免双线消耗）。

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
