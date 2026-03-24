---
schema_version: "1.0"
org_id: auraai
org_name: AuraAI
layer: ai
status: active
protocols:
  - mycelium
provides:
  - capability: ai-education
    interface: 编程/AI 教育课程内容
    repo: github.com/AuraAIHQ/courses
depends_on:
  - org: aastar
    capability: gas-abstraction
    optional: true
contact:
  github: github.com/AuraAIHQ
---

# AuraAI 组织名片

## 我们是谁

AuraAI 是 Mycelium Protocol 生态中的 **AI 能力层**（待补充详细定位）。

目前已知活跃的方向：面向儿童的 AI/编程教育课程（AuraAI/courses）。

## 待补充

> 此名片为初稿，基于现有 GitHub 仓库自动生成。
> 请 AuraAI 团队补充：
> - 核心产品和能力定义
> - 与 AAstar / Mycelium Protocol 的集成计划
> - 对外提供的 AI 接口/服务
> - 需要的资源和合作

## 已知仓库

| 仓库 | 用途 |
|-----|------|
| courses | 面向儿童的 AI/编程教育（5个课程） |
