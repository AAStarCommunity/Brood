# PGL 接入指南 / Onboarding Guide

> 版本：v0.1（草稿） · 最后更新：2026-05-15
> 面向：希望签署「数字公共物品公约」并把作品上架「数字 Agent 商店」的开源贡献者

---

## 0. 你需要几分钟

| 阶段 | 时间 | 难度 |
|:---|:---:|:---:|
| 注册 AirAccount | 3 分钟 | 极易（指纹/Passkey） |
| 写 `pgl.yml` | 5-15 分钟 | 易 |
| 选接入方式并完成接入 | 30 分钟 - 半天 | 取决于接入类型 |
| 提交 PGL Registry 注册 | 1 分钟 | 极易 |

---

## 1. 整体流程

```
1. 注册 AirAccount（一次性，全生态通用）
       │
       ▼
2. 在仓库根目录创建 pgl.yml
       │
       ▼
3. 选择接入类型（四选一或混合）
       │
       ├─ A. Docker 接入
       ├─ B. Service 接口接入
       ├─ C. Agent24 原生接入
       └─ D. UI 模块接入
       │
       ▼
4. 用 pgl-cli 校验 pgl.yml
       │
       ▼
5. 用 AirAccount 签名 manifest
       │
       ▼
6. 提交到 PGL Registry（链上）
       │
       ▼
7. AgentStore 自动收录
```

---

## 2. 四种接入方式详解

### 2.1 接入方式 A：Docker

**适用场景**：复杂应用、需要本地推理、用户隔离环境、对运行环境有要求

**作者需要提供**：
- 推送到 GitHub Container Registry 或 Docker Hub 的镜像
- 暴露的 HTTP API 端口
- 健康检查端点（`/health` 推荐）
- 资源需求声明（CPU / RAM / GPU）

**示例 `pgl.yml` 片段**：
```yaml
integration:
  type: "docker"
  docker:
    image: "ghcr.io/alice/pdf-scanner:v1.2.0"
    expose_port: 7860
    healthcheck_path: "/health"
    api_path: "/api/v1"
    resources:
      cpu: "1.0"
      memory: "2Gi"
      gpu: "optional"
```

**Store 侧自动做的事**：
- 用户点击安装时，AgentStore 客户端拉取镜像并本地启动
- 内置反向代理把用户请求转给容器
- 资源不足时自动提示用户

### 2.2 接入方式 B：Service 接口

**适用场景**：你的服务已部署在云上，希望开放给所有 AgentStore 用户调用

**作者需要提供**：
- 一个稳定的公开 API 端点（或可分配子域名的模板）
- OpenAPI/Swagger 规范文件
- 鉴权方式声明（bearer token / passkey / 公开）

**示例 `pgl.yml` 片段**：
```yaml
integration:
  type: "service"
  service:
    endpoint_template: "https://api.alice.dev/pdf-scan"
    auth: "passkey"           # 用 AirAccount 的 passkey 鉴权
    openapi_spec_url: "https://github.com/alice/pdf-scanner/blob/main/openapi.yaml"
```

**Store 侧自动做的事**：
- 根据 OpenAPI 自动生成 UI 表单（"傻瓜调用界面"）
- 处理鉴权握手
- 用 SuperPaymaster 赞助调用 Gas（如果作者收费）

### 2.3 接入方式 C：Agent24 原生

**适用场景**：你的工作本质上是个 AI agent 或 skill，希望直接装入 Agent24

**作者需要提供**：
- 符合 Agent24 Skill 接口的 npm 包
- 入口文件 + 接口版本声明

**示例 `pgl.yml` 片段**：
```yaml
integration:
  type: "agent24"
  agent24:
    skill_package: "@alice/pdf-scanner-skill"
    skill_version: ">=1.0.0"
    entry: "src/index.ts"
    interface_version: "agent24-v1"
```

**Store 侧自动做的事**：
- 用户在 Agent24 中一键启用此 skill
- 调用次数自动记录到链上声誉
- 付费 skill 通过 SuperPaymaster 结算

**Agent24 Skill 接口要求**（v1 草稿）：
```typescript
// 你的包必须 export 这个对象
export interface Agent24Skill {
  name: string;
  description: string;
  triggers: string[];  // 触发词
  invoke(context: SkillContext, args: any): Promise<SkillResult>;
}
```

详细 Skill 接口规范见 [`agent24/SKILL_SPEC.md`](./agent24/SKILL_SPEC.md)（待补）。

### 2.4 接入方式 D：UI 模块

**适用场景**：作品是一个独立的 Web UI 应用（例如 PPT 工具、电子宠物）

**作者需要提供**：
- 打包好的 JS bundle（CDN 可访问）
- 框架声明（React / Vue / Svelte / Vanilla）
- 符合 PGL UI Module v0.1 规范的入口

**示例 `pgl.yml` 片段**：
```yaml
integration:
  type: "ui-module"
  ui_module:
    mount_path: "/tools/pdf-scanner"
    framework: "react"
    bundle_url: "https://cdn.alice.dev/pdf-scanner.js"
    spec_version: "ui-module-v0.1"
```

详细 UI Module 规范见 [`UI_MODULE_SPEC_v0.1.md`](./UI_MODULE_SPEC_v0.1.md)。

---

## 3. 写 `pgl.yml` 的最小例子

如果你只想签公约 + 走 Docker 接入，**这份 25 行的 manifest 就够了**：

```yaml
pgl_version: "0.1"

work:
  name: "Awesome PDF Scanner"
  slug: "awesome-pdf-scanner"
  type: "agent"
  description_zh: "把扫描件 PDF 一键转 Markdown"
  description_en: "Convert scanned PDFs to Markdown in one click"
  base_license: "Apache-2.0"
  homepage: "https://github.com/alice/awesome-pdf-scanner"

charter:
  signed: true
  version: "0.1"
  signed_at: "2026-05-15T10:00:00Z"
  signed_by:
    name: "Alice"
    airaccount: "0xAlice..."
  signature: "0x..."   # 用 pgl-cli 自动生成

royalty:
  authors:
    - airaccount: "0xAlice..."
      percent: 90      # 无上游依赖，作者拿 90%
  channel:
    name: "AgentStore for Public Goods"
    percent: 10

integration:
  type: "docker"
  docker:
    image: "ghcr.io/alice/pdf-scanner:v1.2.0"
    expose_port: 7860
    healthcheck_path: "/health"

distribution:
  tiers:
    - tier: "free"
      enabled: true
    - tier: "paid"
      enabled: true
      price_pnts: 100
      billing: "per-use"
```

---

## 4. 校验与签名（命令行流程）

```bash
# 安装 pgl-cli
npm i -g @mycelium/pgl-cli

# 校验 manifest
pgl-cli validate ./pgl.yml

# 用 AirAccount 签名
pgl-cli sign ./pgl.yml --account alice.pgl.eth

# 注册到链上 Registry
pgl-cli register ./pgl.yml --network sepolia

# 检查上架状态
pgl-cli status --slug awesome-pdf-scanner
```

`pgl-cli` 是 Phase 2 交付物，本 Phase 1 阶段先用手工 SDK 调用。

---

## 4.5 上架前的硬性验收：「妈妈测试 / Mother Test」

> ⚠️ **这是 AgentStore 上架的硬门槛。任何作品不论技术多牛，过不了妈妈测试就不收。**

「妈妈测试」很简单：

> **把你的作品递给一个不懂技术的家人（妈妈/外婆/小孩），3 分钟内 ta 能不能用上？**

### 验收标准（必须 5 项全过）

| # | 标准 | 怎么算过 |
|:---:|:---|:---|
| 1 | **首次启动 ≤ 60 秒** | 从点击安装到看到能用的界面 |
| 2 | **无需配置文件** | 不能要求改 .env、改 config.yml、复制 API key |
| 3 | **错误信息说人话** | 不能出现 stacktrace；要说"网络不太好，重试一下" |
| 4 | **核心功能 3 步内可达** | 主功能不超过 3 次点击 |
| 5 | **不假设用户懂 CLI/网络/Git** | 普通人词汇 + 视觉化操作 |

### 如何自测

- 找一个不懂技术的家人/朋友亲自试（**真做，不要自己脑补**）
- 录屏（无声）3 分钟，看 ta 在哪里卡住
- 卡住的地方就是 UX 缺口

### Store 审核流程中的妈妈测试

AgentStore 审核员会在 **Linux + macOS + Windows 三种系统**上跑你的作品的"妈妈测试"。任何一项卡超过 30 秒，作品被退回修改。

通过妈妈测试的作品会获得 **「妈妈认证 / Mother-Approved」** 标记，在 Store 中享有更高曝光权重。

---

## 5. 接入后能拿到什么

- **AgentStore 上架** + 搜索 + 用户安装漏斗
- **链上声誉**（SBT）随用户使用量累积
- **付费销售自动分账**（如果开启 `tier_paid`）
- **Agent24 生态访问**（可装入 Agent24 客户端）
- **Mycelium 生态信任凭证**（参与 DAO 治理、OpenPNTs 信用等）

---

## 6. 退出公约

只需删除仓库中的 `pgl.yml` 文件并提交。Registry 监听到 manifest 缺失会自动从 Store 下架你的作品（已发生的销售记录链上保留不可改）。

---

## 7. 常见问题

**Q：我的项目用 GPL / AGPL，能签 PGL 吗？**
能。PGL 是叠加层，与原 license 无冲突。你的下游再分发依然受 GPL 强 copyleft 约束。

**Q：我可以同时签 PGL 又卖给企业客户吗？**
完全可以。PGL 仅约束「通过 AgentStore 渠道的分发」。你保留所有其它商业模式（直销、SaaS、企业授权）的自由度。

**Q：如果我有 10 个共同作者怎么分？**
在 `royalty.authors[]` 中列出每位作者及其内部比例，加总 = 70%（或你自定的作者总额）。

**Q：上游作品没签 PGL 也能列入 `upstreams` 吗？**
可以，但他们无法收到链上自动分账。建议你联系上游作者邀请他们签署。

**Q：用户使用过程中产生的数据归谁？**
归用户。Charter 没有数据所有权条款，作者按 manifest 中 `compliance.data_processed` 声明的范围处理用户数据，遵守作品所在地法律。
