# Hyphae — 中小组织的专属智能菌丝

> ⚠️ **权威口径见 [POSITIONING.md](./POSITIONING.md)（2026-06-24 定稿）**。本 README 部分早期表述（"HyperCapital 辅导/运维服务"）已由"产品化持续价值 + 运营合伙人分润 + 口碑闭环"取代，冲突处以 POSITIONING 为准。

> **一句话定位**：
> **Hyphae 帮特定场景的小组织，在保护隐私的前提下，训练出适合他们自己的 AI。开源全栈本地部署、token 免费；最难也最值钱的是"找到正确的训练路径"。**

---

## 0. 状态

- 版本：v0.1 草稿（2026-06-23）
- 维护：Brood orchestrator
- License：MIT（研究文档）/ Apache 2.0（参考实现）
- 关联生态：iDoris.ai（姊妹品 iDoris / Agent24）+ AAStar 基础设施 + MushroomDAO 协议

## 1. 定位的三个钉子

| 钉子 | 内容 | 钉死意义 |
|:---|:---|:---|
| **谁** | 中小组织（10-200 人的公司、社区、协会、学校、医院、律所、本地服务等）| 不与 Firework 正面竞争（他们服务 Notion/Cursor 这种 AI 原生 mid-market+） |
| **什么** | **完整智能栈**：硬件 + OS + 模型 + 微调 + 推理 + Agent | 不是 wrapper、不是 API 中间商，**是一整套交付**|
| **怎么收钱** | 订阅式产品价值（碎片流程AI化+数据同步+持续进化+判断推送）+ 行业模型训练；落地由运营合伙人分润完成 | **本地 token 永久免费**；数据不出门；**不靠贴身人力服务**（见 POSITIONING）|

## 2. 与 iDoris / iDoris.ai 的关系（必须钉死）

```
iDoris.ai 体系（同 org）
   │
   ├─ iDoris：个人 AI（手机/笔电边缘，自进化，Token Free）
   │
   ├─ Agent24：跨平台 Agent 框架（Electron + 插件）
   │
   └─ Hyphae（新）：组织 AI 全栈
        ├─ 本地推理：iDoris 实例 + 组织微调模型
        ├─ Agent 编排：Agent24 + 业务 Agent
        ├─ 硬件 / OS / 部署：区域/行业运营合伙人（分润落地）
        └─ 溢出 API：组织本地跑不动时调用云端
```

**对外口径**：
- iDoris = 个体细胞
- Hyphae = 组织菌丝（一根菌丝里跑多个 iDoris 服务组织成员）

## 3. 与 Firework AI 的对比（90 秒版）

| 维度 | Firework AI | Hyphae |
|:---|:---|:---|
| 客户 | mid-market 到 enterprise（Cursor / Notion / Vercel / Uber） | **中小组织**（Firework 不覆盖） |
| 估值 / ARR | $40 亿（10/2025）→ $150 亿在谈（5/2026）；ARR ~$800M | 早期 |
| 部署 | 100% 云端（Firework 自家 GPU） | **本地优先 + 按需上云** |
| Token 计费 | 按 token，$0.50–$40 / M 训练 token | **本地 token 免费** |
| 客户能力假设 | 假设客户懂 fine-tune / RL | 假设客户**完全不懂** AI |
| 平台代码 | 闭源 | **全开源（Apache 2.0）** |
| 数据主权 | 数据传 Firework | **数据 100% 不出门** |

## 4. 文档索引

| 顺序 | 文档 | 内容 |
|:---:|:---|:---|
| 1 | [README.md](./README.md) | 本文件 |
| 2 | [FIREWORK_MOAT.md](./FIREWORK_MOAT.md) | Firework AI 护城河深度分析（技术 / 团队 / 资本 / 客户）|
| 3 | [OUR_MOAT.md](./OUR_MOAT.md) | Hyphae 护城河（ERP 业务经验 + 开源生态 + 中小组织聚焦 + Mycelium 协同）|
| 4 | [BP_5PAGES.md](./BP_5PAGES.md) ⭐ | **5 页 BP**（封面 + 问题 + 方案 + 竞争 + 商业模式 / 团队 / Ask）|
| 5 | [BP_5PAGES.pdf](./BP_5PAGES.pdf) | BP 的 PDF 版本（pandoc + xelatex 渲染）|

## 5. 下一步

- [ ] 用户确认 BP 5 页的内容（团队 / Ask 这两项需要用户填实数）
- [ ] 决定 v0.1 MVP 边界（参考 FangPay LITE_SCOPE 模式）
- [ ] 招募 2-3 个种子小组织试点
- [ ] 评估硬件配置参考（4080 / Mac Studio / H100 单卡）
