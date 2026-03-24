---
schema_version: "1.0"
org_id: your-org-id              # 小写，无空格，例: aastar
org_name: Your Org Name
layer: infrastructure            # infrastructure | ai | application | protocol | community
status: active                   # active | stealth | archived
protocols:
  - mycelium
provides:
  - capability: your-capability
    interface: 接口描述（API / SDK / 服务）
    repo: github.com/your-org/your-repo
    version: v0.1.0              # 可选
depends_on:
  - org: aastar                  # 依赖的其他组织
    capability: gas-abstraction
    optional: true
contact:
  builder: your-name
  github: github.com/your-org
---

# [组织名] 组织名片

## 我们是谁

[一段话描述：你们是谁，在 Mycelium Protocol 生态中的角色]

## 我们做什么

[核心产品/服务/能力，建议用表格]

| 模块 | 功能 | 状态 |
|-----|------|------|
| 产品A | 功能描述 | 状态 |

## 我们提供什么

- 对谁提供什么能力
- 对外接口/集成方式

## 我们需要什么

- 需要的合作/资源/反馈类型

## 加入流程

1. Fork `Brood` 仓库
2. 复制 `orgs/template/PROFILE.md` 到 `orgs/your-org-id/PROFILE.md`
3. 填写所有字段
4. 提 PR，标题格式：`chore: add [org-name] to Mycelium Protocol`
5. 维护者 review 后合并
