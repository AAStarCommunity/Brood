# PGL Manifest Specification（公约清单规范）

> 版本：v0.2（三角色弹性区间） · 最后更新：2026-05-15
> 文件名：`pgl.yml`（放在仓库根目录）

---

## 1. 设计目标

`pgl.yml` 是签署 [数字公共物品公约](./CHARTER.md) 的**机器可读凭证**，同时声明：

1. 作品的元数据（名称、类型、原 license）
2. 公约签署状态
3. 三角色分账（Supplier / Wrapper / Seller）+ 内部分配
4. 接入分发渠道的方式（Docker / Service / Agent24-native / UI-module）
5. 收益结算路由 + 数据敏感度分类（Local-first 路由）

---

## 2. 完整 Schema

```yaml
# ===== 必填：版本与基本信息 =====
pgl_version: "0.2"

work:
  name: "Awesome PDF Scanner"           # Wrapper 产品名（可与 Supplier 原作品不同）
  slug: "awesome-pdf-scanner"           # URL 安全短名（小写、连字符）
  type: "agent"                          # agent | app | model | skill | library | dataset | tutorial
  category: ["productivity", "ocr"]      # 自由标签，便于 Store 搜索
  description_zh: "一句话中文描述（不超过50字）"
  description_en: "One-line English description (max 80 chars)"
  base_license: "Apache-2.0"             # 必须是 SPDX 标识符
  homepage: "https://github.com/wrapper-team/awesome-pdf-scanner"
  derived_from:                          # 可选：Wrapper 主导的作品需声明 Supplier 原作
    work_slug: "marker-pdf-core"
    supplier_homepage: "https://github.com/alice/marker-pdf"

# ===== 必填：公约签署 =====
charter:
  signed: true
  version: "0.1"                         # 公约文本版本
  signed_at: "2026-05-15T10:00:00Z"
  signatures:                            # 所有相关方签名（Supplier 必签）
    - role: "supplier"
      name: "Alice Wang"
      airaccount: "0xAlice..."
      signed_at: "2026-05-14T08:00:00Z"
      signature: "0x..."
    - role: "wrapper"
      name: "Team X"
      airaccount: "0xWrapperTeam..."
      signed_at: "2026-05-15T10:00:00Z"
      signature: "0x..."

# ===== 必填：三角色分账（顶层切分）=====
roles:
  supplier:
    name: "Alice (OCR Model Author)"
    airaccount: "0xAlice..."
    percent: 70                          # 区间 50-90，默认 70
    internal_split:                      # 可选：Supplier 内部再分配
      - address: "0xAlice"
        share: 90                        # 70% 的 90% = 63% 总收入
        role: "core author"
      - address: "0xUpstreamMarkerAuthor"
        share: 10                        # 70% 的 10% = 7% 总收入
        role: "upstream OSS (Marker library)"

  wrapper:                               # 可选；若无 Wrapper 此字段省略且 supplier.percent = 90
    name: "Team X (UX & Integration)"
    airaccount: "0xWrapperTeam..."
    percent: 20                          # 区间 0-40，默认 20
    work_summary:                        # Wrapper 做的工作摘要（供 Supplier + 用户判断）
      - "Docker 化"
      - "Web GUI 适配"
      - "多语种 UI"
      - "Mother Test 通过"
    internal_split:                      # 可选：Wrapper 团队内部
      - address: "0xDesigner"
        share: 30
        role: "UI designer"
      - address: "0xEngineer"
        share: 50
        role: "integration engineer"
      - address: "0xTester"
        share: 20
        role: "tester + docs"

  seller:
    name: "AgentStore for Public Goods"
    airaccount: "0xAgentStoreDAO..."
    percent: 10                          # 固定 10%，不可降

  # 硬约束（链上合约 enforce）：
  # 1. supplier.percent >= 50
  # 2. seller.percent == 10
  # 3. supplier + wrapper + seller == 100
  # 4. wrapper.percent <= 40

# ===== 必填：接入方式 =====
integration:
  type: "docker"                         # docker | service | agent24 | ui-module | hybrid
  
  docker:                                # 若 type=docker
    image: "ghcr.io/wrapper-team/awesome-pdf-scanner:v1.2.0"
    expose_port: 7860
    healthcheck_path: "/health"
    api_path: "/api/v1"
    resources:
      cpu: "1.0"
      memory: "2Gi"
      gpu: "optional"
  
  service:                                # 若 type=service
    endpoint_template: "https://api.example.com"
    auth: "bearer-token"
    openapi_spec_url: "..."
  
  agent24:                                # 若 type=agent24
    skill_package: "@team-x/pdf-scanner-skill"
    skill_version: ">=1.0.0"
    entry: "src/index.ts"
    interface_version: "agent24-v1"
  
  ui_module:                              # 若 type=ui-module
    mount_path: "/tools/pdf-scanner"
    framework: "react"
    bundle_url: "https://cdn.../bundle.js"
    spec_version: "ui-module-v0.1"

# ===== 必填：分发与定价 =====
distribution:
  tiers:
    - tier: "free"
      enabled: true
      reputation_reward: true            # 用户点赞累积作者声誉
    - tier: "paid"
      enabled: true
      price_pnts: 50                     # 用 xPNTs 计价
      price_usd_equivalent: 0.50
      billing: "per-use"                 # one-time | subscription | per-use
  end_user_friendly: true                # 是否能直接给普通用户用
  requires_user_setup: false             # 是否需要用户额外配置

# ===== 必填：Local-first 数据路由 =====
data_routing:
  data_classes:                          # 声明本作品处理什么数据
    - class: "personal_sensitive"        # 个人敏感（身份/财务/健康/私信）
      route: "local_only"                # 强制本地，不允许走远程
    - class: "personal_general"          # 一般个人（笔记/文档/照片）
      route: "local_first"               # 本地优先，用户可选远程
    - class: "anonymized"                # 已脱敏数据
      route: "user_choice"               # 用户/作者自由选
    - class: "public"                    # 公开数据
      route: "any"                       # 自由
  prohibited_uses:                       # 道德条款
    - "military"
    - "mass_surveillance"

# ===== 可选：合规与隐私 =====
compliance:
  privacy_policy_url: "https://..."
  data_retention: "session"              # none | session | 30-days | permanent
  gdpr_compliant: true

# ===== 验证与扩展 =====
verification:
  github_repo: "wrapper-team/awesome-pdf-scanner"
  proof_of_open_source: "https://github.com/.../LICENSE"
  mother_test_passed: true               # 妈妈测试通过标记
  audit_reports: []
  manifest_checksum: "sha256:..."        # 整个 manifest 内容的 hash（不含本字段）
  splits_locked: true                    # 顶层分账锁定（不可改）
```

---

## 3. 字段验证规则

| 字段 | 规则 | 错误示例 |
|:---|:---|:---|
| `pgl_version` | 必须匹配 PGL 当前主版本 | `"0.0"` |
| `work.slug` | `^[a-z0-9][a-z0-9-]{1,40}$` | `"My App"` |
| `work.base_license` | 必须是 SPDX 标识符 | `"my-own-license"` |
| `charter.signed` | 必须 `true` | `false` |
| `charter.signatures[].role=supplier` | **必须至少一个** | 没有 Supplier 签名 |
| `roles.supplier.percent` | **50 ≤ percent ≤ 90** | 40（低于硬下限） |
| `roles.wrapper.percent` | **0 ≤ percent ≤ 40**（若存在） | 50（超过上限） |
| `roles.seller.percent` | **必须 = 10** | 5 / 15 |
| 顶层三比例加总 | **必须 = 100** | 50+30+10=90 |
| `roles.{*}.internal_split[].share` | 同一角色内 share 加总 = 100 | 60+30+5=95 |
| `data_routing.data_classes[].route` | 枚举值 | `"custom"` |

链上 Registry 注册时由合约 enforce 这些约束。任何字段不合规直接拒绝。

---

## 4. 签名协议（四场景）

每个 manifest 的有效性由所有相关方 AirAccount 签名共同背书。设计原则：**永远存在三方签名**（Supplier + Wrapper + Seller），但具体路径因发起方而异。

### 4.0 签名前置条件

签名方必须满足：
1. 拥有 AirAccount（用 TEE 内 KMS 私钥签名）
2. 在 Mycelium 生态有 SBT（参与凭证）
3. 签名内容 = SHA-256(license文本 + 具体分配比例 + 关联 PR URL)
4. 签名结果链上记录，可追溯、可复合

### 4.1 场景 A：Supplier 主动发起

```
1. Supplier 在自己的仓库添加 PGL_CHARTER.md + pgl.yml（提议默认 70/20/10 或自定义）
2. Supplier 用 AirAccount 签名 → 写入 charter.signatures[role=supplier]
3. （可选）Wrapper 加入：
   - Wrapper 审视 Supplier 提议的分配比例
   - 可接受 → 签字
   - 想协商 → 双方在区间内谈定 → 各自签字
   - 不参与 → manifest 无 Wrapper 角色，Supplier 拿 90%
4. Seller（AgentStore DAO）作为常规运营自动签字
5. 三方签名完整 → 提交 Registry → 上链 → 进入妈妈测试审核
```

### 4.2 场景 B：Wrapper 主动发起（Supplier 在线）

```
1. Wrapper 写 pgl.yml，提议分配（如 70/20/10 或 60/30/10）
2. Wrapper 用 AirAccount 签名 → 写入 charter.signatures[role=wrapper]
3. Wrapper 向 Supplier 原仓库提 PR：
   PR 内容：
     - PGL_CHARTER.md（公约文本）
     - pgl.yml（接入清单，含提议分配）
     - 公开说明（为何包装、做了什么、提议什么比例）
4. Supplier 在 GitHub 上响应（merge / comment / reject）
5a. Supplier 接受 → 用 AirAccount 签字 → 三方完整 → 上链
5b. Supplier 协商 → 在 PR 中讨论 → 调整 pgl.yml → 双方重新签字 → 上链
5c. Supplier 拒绝 → manifest 作废，Wrapper 不能上架（首 30 天 Supplier 有否决权）
```

### 4.3 场景 C：Wrapper 主动发起（Supplier 不可达）

```
1. Wrapper 写 pgl.yml，提议分配（推荐 50/40/10 — Wrapper 最有利方案）
2. Wrapper 用 AirAccount 签名
3. Wrapper 向 Supplier 原仓库提 PR（同场景 B）
4. 公示期：**30 天客观等待**（以 PR 提交时间为准，GitHub 公开记录）
5a. 30 天内 Supplier 响应：转入场景 B 流程
5b. 30 天内无响应：
    - Wrapper 携 PR URL 作为客观证据，提交 Registry
    - Registry 校验：PR 已存在 ≥ 30 天 + Supplier 无任何 GitHub 行为响应
    - 校验通过 → Wrapper 的 pgl.yml 生效 → 上链
    - Supplier 应得份额（≥ 50%）进入**链上托管**（escrow）
6. Seller（AgentStore DAO）签字
```

**关键设计**：场景 C 不需要 DAO 主观仲裁，**全部用 GitHub PR + 时间戳作为客观证据**。无人为干预、可审计、可追溯。

### 4.4 场景 D：Supplier 迟到响应（≥ 30 天后）

Supplier 在场景 C 启动并上链后才出现：

```
1. Supplier 仍可认领 escrow 中的份额（需 AirAccount 证明身份匹配仓库历史 commit）
2. 但不能单方面更改已生效的分配比例（作品已在用户中运行）
3. 想调整分配 → 必须与 Wrapper 重新协商：
   - 双方达成新比例 → 各自重新签字
   - 在原 manifest 基础上创建新版本（旧版本归档）
   - 新版本上链 → 此后销售按新比例分配
   - 历史已发生的销售不追溯调整
4. 双方协商不成 → 维持原比例运行；Supplier 仍可领 escrow 历史份额
```

### 4.5 防篡改与撤销

```
- manifest 任意字段被改 → SHA-256 校验失败 → Store 自动下架
- Supplier 退出公约：删除 pgl.yml → Registry 监听 → 下架（已发生销售记录链上保留）
- Wrapper 退出：自己的 manifest 失效；Supplier 可邀请其他 Wrapper 重新包装
- 极端冲突（如人身攻击、抄袭指控）：可上诉 PGL DAO 仲裁，但仅作为最后手段
```

---

## 5. 与原 license 的关系

| 维度 | 原 license（如 Apache 2.0）| PGL Manifest |
|:---|:---|:---|
| 法律效力 | 有 | 无（社会契约+商业合同）|
| 文件位置 | `LICENSE` | `pgl.yml` |
| 强制性 | 强制 | 自愿（不签 = 不入 Store） |
| 是否可撤销 | 否（已发布的不可撤销）| 是（删除 `pgl.yml` = 退出公约） |
| 上游归属 | NOTICE 中的 attribution | `roles.supplier.internal_split` 结构化字段 |

**关键原则**：`pgl.yml` 增强但不替代原 license 的法律义务。`LICENSE` 和 `NOTICE` 文件必须保留并完整。

---

## 6. 与 SuperPaymaster v5 角色的对接

PGL 复用 SuperPaymaster v5 角色体系，**不部署新合约**：

| PGL 概念 | SuperPaymaster v5 角色 | 注册方式 |
|:---|:---|:---|
| Supplier | `ROLE_AGENTSTORE_SUPPLIER`（v5 现有 ROLE_COMMUNITY 子角色） | `registerRole()` |
| Wrapper（可选）| `ROLE_AGENTSTORE_WRAPPER` | `registerRole()` |
| Seller（AgentStore）| `ROLE_AGENTSTORE_SELLER` | `registerRole()`（限定 DAO） |
| Curator（未来）| `ROLE_AGENTSTORE_CURATOR` | TBD |
| 链上声誉 | 复用现有 SBT 系统 | 自动累积 |

每个角色都有 v5 现成的 stake / ticket / exit / slash 机制。

---

## 7. 完整示例

见 [`examples/pgl.yml`](./examples/pgl.yml)。

---

## 8. 与旧版本（v0.1）的差异

| 字段 | v0.1（旧） | v0.2（新） |
|:---|:---|:---|
| 顶层切分 | `royalty.{authors, upstreams, channel}` | `roles.{supplier, wrapper, seller}` |
| 分配模型 | 固定 70 / 20 / 10 | 弹性区间 50-90 / 0-40 / 固定 10 |
| 上游 OSS | 顶层 `upstreams[]` 20% 强制 | Supplier 内部 `internal_split` 自愿 |
| 包装者 | （不存在）| `wrapper` 顶层角色 |
| 数据敏感度 | 单一 `data_processed` | 多类 `data_routing.data_classes[]` |
| 妈妈测试 | 不在 manifest | `verification.mother_test_passed` |
| 签名机制 | 单一作者签 | 多方（Supplier + Wrapper）共签 |

迁移 v0.1 → v0.2 的脚本待补（PGL DAO 提供）。

---

## 9. 后续工作

- [ ] 编写 JSON Schema 用于 IDE 自动补全（VS Code Red Hat YAML 插件）
- [ ] 在 SuperPaymaster v5 中定义三个新角色的数据结构
- [ ] 实现 manifest 校验逻辑（Web 端，免 CLI）
- [ ] 与 AirAccount 签名流程集成
