# PGL 接入指南 / Onboarding Guide

> 版本：v0.2（三个动作流程 + 四种接入方式） · 最后更新：2026-05-15
> 面向：希望签署「数字公共物品公约」并把作品上架「数字 Agent 商店」的开源贡献者

---

## 0. 你需要几分钟

| 阶段 | 时间 | 难度 |
|:---|:---:|:---:|
| 注册 AirAccount | 3 分钟 | 极易（指纹/Passkey） |
| 写 `pgl.yml` | 5-15 分钟 | 易 |
| 选接入方式并完成接入 | 30 分钟 - 半天 | 取决于接入类型 |
| 链上注册（复用 SuperPaymaster v5 角色，零新合约）| 1 分钟 | 极易 |
| 通过妈妈测试审核 | 1-3 天（人工 + 自动）| 取决于作品质量 |

---

## 1. 加入 PGL 的「三个动作」

PGL 加入流程极简，只有三步：

```
┌──────────────────────────────────────────────────────────┐
│  动作 1 · 仓库声明                                         │
│  ────────────────                                          │
│  在仓库根目录添加：                                          │
│    • PGL_CHARTER.md       公约文本（中英双语）              │
│    • pgl.yml              接入清单（机器可读元数据）         │
│                                                          │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│  动作 2 · 链上注册                                          │
│  ────────────────                                          │
│  通过 SuperPaymaster v5 现有合约 `registerRole()` 注册角色： │
│                                                          │
│    ROLE_AGENTSTORE_SUPPLIER     原作者                     │
│    ROLE_AGENTSTORE_WRAPPER      UX 适配者（可选）           │
│                                                          │
│  注册时附 Charter hash 的 AirAccount 签名 → 写入 metadata │
│  **零新合约**，复用 v5 的 stake / ticket / exit 机制       │
│                                                          │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│  动作 3 · 设置分账与接入                                    │
│  ────────────────                                          │
│  在 pgl.yml 中：                                            │
│    • 选择分账（默认 70/20/10 或区间内自定义）                │
│    • 选择接入方式（四种选一，见第 3 节）                     │
│    • 声明数据敏感度（Local-first 路由）                     │
│                                                          │
└──────────────────────────────────────────────────────────┘

---

## 2. 加入分账模型说明

PGL 收益采用 **三角色弹性区间模型**（详见 [`REVENUE_MODEL.md`](./REVENUE_MODEL.md)）：

| 角色 | 区间 | 默认 | 你是谁 |
|:---|:---:|:---:|:---|
| **Supplier** | 50%-90% | 70% | 写核心代码/算法/模型的人 |
| **Wrapper** | 0%-40% | 20% | 把作品包装成普通人能用的人（可选）|
| **Seller** | 固定 10% | 10% | AgentStore 渠道 |

### 我该作为哪个角色加入？

| 你的情况 | 角色 |
|:---|:---|
| 我是原仓库作者，作品基本能用，想直接上架 | **Supplier**（无 Wrapper，90/0/10）|
| 我是原作者，作品技术强但用户用不了，找人帮包装 | **Supplier** + 邀请 **Wrapper** 联签 |
| 我看上了某个开源项目，想包装成产品上架（项目作者还在）| **Wrapper**，邀请原作者作为 Supplier 联签 |
| 项目作者长期未响应，但我想给社区做点事 | **Wrapper**，用代理签名流程（DAO 仲裁通过后启用）|
| 我是 AgentStore 运营方 | **Seller**（不需要单独签约，DAO 资格）|

---

## 3. 四种接入方式详解（与分账模型正交）

接入方式说的是"作品如何让用户用起来"，与"收益怎么分"无关。任何分账组合都可以选任何接入方式。

### 3.1 接入方式 A：Docker

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

### 3.2 接入方式 B：Service 接口

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

### 3.3 接入方式 C：Agent24 原生

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

### 3.4 接入方式 D：UI 模块

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

## 4. 写 `pgl.yml` 的最小例子

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

## 5. 校验与签名（链上注册流程）

PGL **不需要单独的 CLI 工具**。校验和签名都走现成的基础设施：

### 5.1 manifest 校验（本地）

在你的 IDE（VS Code 推荐）安装 **Red Hat YAML 插件**，并在 `pgl.yml` 顶部添加 schema 引用：

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/AAStarCommunity/Brood/main/protocol/PGL/schemas/pgl.schema.json
pgl_version: "0.2"
...
```

保存时自动校验字段格式、必填项、enum 值。**5 分钟搞定，零安装。**

### 5.2 签名 + 注册（Web 端 + AirAccount）

不用命令行，直接在 AgentStore Web 上架界面操作：

```
1. 打开 https://agentstore.mushroom.cv/publish
2. 粘贴你的 GitHub 仓库 URL（含 pgl.yml）
3. 点 "Connect AirAccount" → passkey/指纹解锁
4. 系统自动读取 pgl.yml → 显示分账预览
5. 点 "签署并上链" → AirAccount 签名 → 调用 SuperPaymaster v5 registerRole()
6. 链上确认（约 15 秒）→ 进入妈妈测试审核队列
```

所有事都通过 AirAccount + SuperPaymaster v5 完成，**不部署新合约，不安装 CLI，不写脚本**。

### 5.3 签名协议（四场景）

谁需要签字、按什么路径签 —— 详细规则见 [`MANIFEST_SPEC.md §4`](./MANIFEST_SPEC.md#4-签名协议四场景)。核心要点：

| 场景 | 你是 | 流程要点 |
|:---|:---|:---|
| A | Supplier 主动 | 自签 → Wrapper 可选加入 → Seller 自动 |
| B | Wrapper 主动（Supplier 在线）| 提 PR → 协商 → 双签 |
| C | Wrapper 主动（Supplier 不可达）| 提 PR → **30 天公示** → 自动生效 + escrow |
| D | Wrapper 已上架（Supplier 迟到）| 协商 → 新版本上链 |

**关键**：Wrapper 主导时必须向 Supplier 原仓库提 PR，PR 内容包括 `PGL_CHARTER.md` + `pgl.yml` + 公开说明。GitHub 公开记录作为客观证据，无需主观仲裁。

### 5.4 如果你只想要 CLI（高级场景）

CI/CD 自动化、批处理需求等场景，可以用 Mycelium 通用合约调用工具：

```bash
# 复用 Mycelium ecosystem 现有 SDK
npm i -g @aastar/sdk
aastar register-role \
  --role ROLE_AGENTSTORE_SUPPLIER \
  --manifest ./pgl.yml \
  --account alice.pgl.eth
```

这不是 PGL 专用工具，是 Mycelium 生态通用工具的一部分。

---

## 6. 上架前的硬性验收：「妈妈测试 / Mother Test」

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

## 7. 接入后能拿到什么

- **AgentStore 上架** + 搜索 + 用户安装漏斗
- **链上声誉**（SBT）随用户使用量累积
- **付费销售自动分账**（如果开启 `tier_paid`）
- **Agent24 生态访问**（可装入 Agent24 客户端）
- **Mycelium 生态信任凭证**（参与 DAO 治理、OpenPNTs 信用等）

---

## 8. 退出公约

只需删除仓库中的 `pgl.yml` 文件并提交。Registry 监听到 manifest 缺失会自动从 Store 下架你的作品（已发生的销售记录链上保留不可改）。

---

## 9. 常见问题

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
