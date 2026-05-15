# PGL · 数字公共物品公约 / Digital Public Goods Charter

> **状态**：Phase 1 规范草稿（v0.1） · 最后更新：2026-05-15

---

## 一句话定位

> **数字 Agent 商店是普通人能用、本地优先、原作者拿大头的 AI 应用商店。**

让开源贡献者通过签署 **数字公共物品公约**，把自己的工作上架到 **数字 Agent 商店（AgentStore for Public Goods）**，获得用户、声誉与销售分成，同时阻止信息差套利者抹署名牟利。

→ 完整价值定位见 [`VALUE.md`](./VALUE.md)

---

## 核心架构

```
法律层    Apache 2.0 / MIT / GPL（不动，OSI 兼容）
   │
社会层    数字公共物品公约（Charter）— 自愿签署的精神约定
   │
技术层    pgl.yml Manifest — 机器可读的接入声明
   │
分发层    数字 Agent 商店 — Web + Agent24 双轨
   │
链上层    复用 Mycelium 生态（SuperPaymaster v5 + AirAccount + OpenPNTs + CometENS）
```

---

## 文件索引

| 文件 | 内容 |
|:---|:---|
| [`VALUE.md`](./VALUE.md) | **核心价值定位** —— 三大用户支柱 + 三大用户层级 + 竞品对比（营销/PR 取词处）|
| [`CHARTER.md`](./CHARTER.md) | 公约正文（中英双语，五条承诺，~500 字） |
| [`MANIFEST_SPEC.md`](./MANIFEST_SPEC.md) | `pgl.yml` 完整 schema + 字段规则 + 签名机制 |
| [`REVENUE_MODEL.md`](./REVENUE_MODEL.md) | 70/20/10 分配模型 + 链上合约接口 + 税务建议 |
| [`ONBOARDING.md`](./ONBOARDING.md) | 接入指南 + 四种接入方式 + **「妈妈测试」上架硬门槛** + FAQ |
| [`UI_MODULE_SPEC_v0.1.md`](./UI_MODULE_SPEC_v0.1.md) | UI 模块接入规范（早期草稿，会随实际反馈演进） |
| [`CITY_REP.md`](./CITY_REP.md) | **城市声誉网络（RFC）** —— AgentStore 之上的下游网络层，"虚拟股东"机制 |
| [`examples/pgl.yml`](./examples/pgl.yml) | 完整 manifest 示例（假想项目 Awesome PDF Scanner） |
| [`DISCUSSION.md`](./DISCUSSION.md) | 决策过程、备选方案、前置参考 |

---

## 锁定的关键决议

| # | 决议 | 备注 |
|:---:|:---|:---|
| 1 | **叠加层**而非新 license | 不动 Apache 2.0，保 OSI 兼容 |
| 2 | **完全自愿**签署 | 不签亦可使用原协议；签则享分发与分账 |
| 3 | **双轨分发**：独立 web Store + Agent24 内嵌 | |
| 4 | **强制链上结算** | 复用 SuperPaymaster + AirAccount |
| 5 | Phase 1 = 先做规范（本目录） | |
| 6 | 默认分配 **作者 70% / 上游 20% / 渠道 10%** | manifest 内可调整 |
| 7 | **避免 "share" 等证券化词汇** | 改用「销售分成 / 版税 / 贡献记录」 |
| 8 | 四种接入：Docker / Service / Agent24 / UI-module | |

---

## 命名对照表

| 概念 | 中文名 | 英文名 |
|:---|:---|:---|
| 商店品牌 | 数字 Agent 商店 | **AgentStore for Public Goods** |
| 签约文件 | 数字公共物品公约 | **Digital Public Goods Charter** |
| 接入清单 | `pgl.yml` | **PGL Manifest** |
| 链上分账合约 | 公约分账路由 | **PGL Royalty Router** |
| 收益分配单位 | 销售分成 / 版税 | **Royalty** |
| 贡献凭证 | 贡献记录 | **Contribution Record** |

---

## 下一步（Phase 2 计划）

1. 部署 PGL Registry 合约到 Sepolia（复用 SuperPaymaster v5 角色体系）
2. 实现 `pgl-cli`（校验 + 签名 + 注册三件套）
3. 与 SuperPaymaster v5 集成测试（注册 `ROLE_PGL_AUTHOR` / `ROLE_PGL_CHANNEL`）
4. 自家生态首批签约：Brood / AirAccount / CometENS / Agent24 / SuperPaymaster
5. 数字 Agent 商店 Web MVP（搜索 + 一键安装 + 打赏入口）

---

## 反馈与讨论

PGL 仍在快速迭代。如有意见，请提 issue 到 [AAStarCommunity/Brood](https://github.com/AAStarCommunity/Brood/issues)，标签 `pgl`。
