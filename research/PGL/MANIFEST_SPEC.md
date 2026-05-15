# PGL Manifest Specification（公约清单规范）

> 版本：v0.1（草稿） · 最后更新：2026-05-15
> 文件名：`pgl.yml`（放在仓库根目录）

---

## 1. 设计目标

`pgl.yml` 是签署 [数字公共物品公约](./CHARTER.md) 的**机器可读凭证**，同时声明：

1. 作品的元数据（名称、类型、原 license）
2. 公约签署状态
3. 上游依赖及其分账比例
4. 接入分发渠道的方式（Docker / Service / Agent24-native / UI-module）
5. 收益结算路由

---

## 2. 完整 Schema

```yaml
# ===== 必填：基本信息 =====
pgl_version: "0.1"

work:
  name: "Awesome PDF Scanner"           # 作品名称
  slug: "awesome-pdf-scanner"           # URL 安全短名（小写、连字符）
  type: "agent"                          # agent | app | model | skill | library | dataset | tutorial
  category: ["productivity", "ocr"]      # 自由标签，便于 Store 搜索
  description_zh: "一句话中文描述（不超过50字）"
  description_en: "One-line English description (max 80 chars)"
  base_license: "Apache-2.0"             # 必须是 SPDX 标识符
  homepage: "https://github.com/alice/awesome-pdf-scanner"

# ===== 必填：公约签署 =====
charter:
  signed: true
  version: "0.1"                         # 签的是 Charter 哪个版本
  signed_at: "2026-05-15T10:00:00Z"
  signed_by:
    name: "Alice Wang"
    airaccount: "0xAuthorAirAccountAddress"  # AirAccount 主地址
    ens: "alice.pgl.eth"                     # 可选，CometENS
  signature: "0xHexSignedManifestHash"   # 用 AirAccount 签整个 manifest 的 SHA-256

# ===== 必填：分账路由（响应 Charter 第三条）=====
royalty:
  contract: "0xPGL_Router_Sepolia_TBD"   # 链上路由合约地址
  authors:
    - airaccount: "0xAuthorAirAccountAddress"
      percent: 70                         # 默认 70%
      display_name: "Alice"
  upstreams:                              # 上游依赖（你借鉴了谁）
    - work_slug: "pdf-core"
      airaccount: "0xUpstreamA"
      percent: 15
    - work_slug: "ocr-base-model"
      airaccount: "0xUpstreamB"
      percent: 5
  channel:
    name: "AgentStore for Public Goods"
    percent: 10
  # ↑ 三块加总必须 = 100；如果作品无上游依赖，作者可拿到 90，渠道 10

# ===== 必填：接入方式（Onboarding type）=====
integration:
  type: "docker"                          # docker | service | agent24 | ui-module | hybrid
  
  # —— 若 type=docker，提供以下字段 ——
  docker:
    image: "ghcr.io/alice/pdf-scanner:v1.2.0"
    expose_port: 7860
    healthcheck_path: "/health"
    api_path: "/api/v1"
    resources:
      cpu: "1.0"
      memory: "2Gi"
      gpu: "optional"                     # required | optional | none
  
  # —— 若 type=service，提供以下字段 ——
  service:
    endpoint_template: "https://{user_host}/api"
    auth: "bearer-token"                  # bearer-token | passkey | none
    openapi_spec_url: "https://github.com/alice/pdf-scanner/openapi.yaml"
  
  # —— 若 type=agent24，提供以下字段 ——
  agent24:
    skill_package: "@alice/pdf-scanner-skill"  # npm 包名
    skill_version: ">=1.0.0"
    entry: "src/index.ts"
    interface_version: "agent24-v1"
  
  # —— 若 type=ui-module，提供以下字段 ——
  ui_module:
    mount_path: "/tools/pdf-scanner"      # 在 Store 中的子路径
    framework: "react"                    # react | vue | svelte | vanilla
    bundle_url: "https://cdn.../pdf-scanner.js"
    spec_version: "ui-module-v0.1"        # 见 UI_MODULE_SPEC.md

# ===== 必填：用户使用模式 =====
distribution:
  tiers:
    - tier: "free"
      enabled: true
      reputation_reward: true             # 用户点赞会累积作者声誉
    - tier: "paid"
      enabled: true
      price_pnts: 100                     # 用 OpenPNTs 计价
      price_usd_equivalent: 1.00
      billing: "one-time"                 # one-time | subscription | per-use
  
  end_user_friendly: true                 # 是否有一键安装 / 普通用户可用
  requires_user_setup: false              # 是否需要用户额外配置

# ===== 可选：合规与隐私 =====
compliance:
  privacy_policy_url: "https://..."
  data_processed: ["pdf-files"]           # 处理什么类型的用户数据
  data_retention: "none"                  # none | session | 30-days | permanent
  prohibited_uses: ["military", "surveillance"]   # 禁止用途（道德条款）

# ===== 可选：验证与扩展 =====
verification:
  github_repo: "alice/awesome-pdf-scanner"
  proof_of_open_source: "https://github.com/alice/awesome-pdf-scanner/blob/main/LICENSE"
  audit_reports: []                       # 如有第三方审计
  manifest_checksum: "sha256:..."         # 整个 manifest 内容的 hash（不含本字段）
```

---

## 3. 字段验证规则

| 字段 | 规则 | 错误示例 |
|:---|:---|:---|
| `pgl_version` | 必须匹配 PGL 当前主版本 | `"0.0"` |
| `work.slug` | `^[a-z0-9][a-z0-9-]{1,40}$` | `"My App"` |
| `work.base_license` | 必须是 SPDX 标识符 | `"my-own-license"` |
| `charter.signed` | 必须 `true`，否则不予收录 | `false` |
| `royalty.{*}.percent` | 三块加总必须 = 100 | 80+20+20 = 120 |
| `royalty.{*}.airaccount` | 必须是有效以太坊地址 | `0x123`（长度不够）|
| `integration.type` | 枚举值 | `"custom"`（未支持）|

`pgl.yml` 在 PGL Registry 入库时由智能合约 + 链下校验器双重验证。任何字段不合规直接拒绝收录。

---

## 4. 签名机制

manifest 的有效性由作者 AirAccount 签名背书：

```
1. 计算 manifest 除 verification.manifest_checksum 之外的所有内容的 SHA-256
2. 用 AirAccount（TEE 内 KMS 私钥）对 hash 签名
3. 签名结果写入 charter.signature
4. 写入 verification.manifest_checksum
5. 任何字段后续被篡改 → 校验失败 → Store 自动下架
```

---

## 5. 与原 license 的关系

| 维度 | 原 license（如 Apache 2.0） | PGL Manifest |
|:---|:---|:---|
| 法律效力 | 有 | 无（社会契约）|
| 文件位置 | `LICENSE` | `pgl.yml` |
| 强制性 | 强制（含 NOTICE 保留）| 自愿（不签 = 不入 Store） |
| 是否可撤销 | 否（已发布的不可撤销） | 是（删除 `pgl.yml` 即视为退出公约）|
| 上游归属 | NOTICE 中的 attribution 文本 | `royalty.upstreams[]` 结构化字段 |

**关键原则**：`pgl.yml` 增强但不替代原 license 的法律义务。`LICENSE` 和 `NOTICE` 文件依然必须保留并完整。

---

## 6. 与 SuperPaymaster v5 角色的对接

PGL 复用 SuperPaymaster v5 的角色体系：

| PGL 概念 | SuperPaymaster v5 角色 |
|:---|:---|
| 公约签署者 | `ROLE_COMMUNITY` 子角色 `ROLE_PGL_AUTHOR` |
| 分发渠道（AgentStore） | `ROLE_PGL_CHANNEL`（白名单内） |
| Curator（社区策展人） | `ROLE_PGL_CURATOR` |
| 链上声誉 | 复用现有 SBT 系统 |

注册 / 撤销作者身份通过 SuperPaymaster v5 `registerRole` / `exitRole` 完成，PGL Registry 监听对应事件。

---

## 7. 完整示例

见 [`examples/pgl.yml`](./examples/pgl.yml)。

---

## 8. 后续工作

- [ ] 编写 JSON Schema 用于 IDE 自动补全
- [ ] 部署 PGL Registry 合约到 Sepolia
- [ ] 实现 manifest 校验 CLI (`pgl-cli validate ./pgl.yml`)
- [ ] 与 SuperPaymaster v5 集成测试
