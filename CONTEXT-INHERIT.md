# 如何为你的 Repo 引入 Mycelium Protocol 生态上下文

> 文档类型：工程指引
> 维护者：BroodBrain | 最后更新：2026-04-27

---

## 背景

每个 repo 的 Claude Code 默认没有生态全局视野——它不知道你的 repo 与其他 repo 的关系，不知道你所在组织的使命，也不知道协议层的整体规划。

BroodBrain 是 Mycelium Protocol 的神经系统，存放了三层上下文：
- **L0 协议层**: `protocol/` — 菌丝协议的使命、生态图、参与方式
- **L1 组织层**: `orgs/` — 各组织的名片（PROFILE.md）和接口（INTERFACES.md）
- **L2 任务层**: `backlog/` — AAstar 当前的任务进度和路线图

本文档说明如何在你的 repo 里继承这些上下文。

---

## 方法一：@-include（推荐，本地开发）

在你 repo 的 `CLAUDE.md` 中，使用 Claude Code 的 `@file` 语法直接引用 BroodBrain 的文件：

### AAstar 组织下的 repo（推荐）

```markdown
# [Your Repo] CLAUDE.md

## Mycelium Protocol 生态上下文

@/Users/jason/Dev/Brood/protocol/MISSION.md
@/Users/jason/Dev/Brood/orgs/aastar/PROFILE.md
@/Users/jason/Dev/Brood/orgs/aastar/INTERFACES.md

## [Your Repo] 特定说明

...（repo 专属配置、指令）
```

### AuraAI 组织下的 repo

```markdown
## Mycelium Protocol 生态上下文

@/Users/jason/Dev/Brood/protocol/MISSION.md
@/Users/jason/Dev/Brood/orgs/auraai/PROFILE.md
@/Users/jason/Dev/Brood/orgs/auraai/INTERFACES.md
```

### MushroomDAO 组织下的 repo

```markdown
## Mycelium Protocol 生态上下文

@/Users/jason/Dev/Brood/protocol/MISSION.md
@/Users/jason/Dev/Brood/orgs/mycelium/PROFILE.md
@/Users/jason/Dev/Brood/orgs/mycelium/INTERFACES.md
```

**前提**：Brood 已克隆到 `/Users/jason/Dev/Brood`（默认路径）。

---

## 方法二：生态地图引用（最小化）

如果不想引入完整文件，在 `CLAUDE.md` 中只添加一个指引段落：

```markdown
## 生态上下文

本 repo 属于 Mycelium Protocol 生态 / [组织名] 组织。
完整上下文见 BroodBrain（github.com/AAStarCommunity/Brood）：
- 协议使命: `protocol/MISSION.md`
- 组织名片: `orgs/[org-id]/PROFILE.md`
- 组织接口: `orgs/[org-id]/INTERFACES.md`
- 生态全景: `protocol/ECOSYSTEM_MAP.md`
```

---

## 方法三：快照内联（适合团队协作，多人使用）

如果团队成员的 Brood 路径不同，或 repo 将由没有克隆 Brood 的人使用，可以将关键上下文内联复制到 repo 的 `CLAUDE.md` 中。

步骤：
1. 从 `orgs/[org-id]/PROFILE.md` 复制 `## 我们是谁` 等核心段落
2. 粘贴到 repo 的 `CLAUDE.md` 中，注明来源和日期
3. 当 PROFILE.md 更新时，手动同步

**注意**：这是静态快照，需要手动维护同步。推荐仅在方法一不可行时使用。

---

## 上下文继承的价值

引入这些上下文后，Claude Code 在你的 repo 里能：

- 自动理解当前 repo 在生态中的位置和依赖关系
- 了解跨 repo 的接口约定（不需要你每次解释）
- 知道哪些决策需要与其他组织对齐
- 在建议时考虑协议层的约束和价值观

---

## 最简模板

复制以下内容到你的 repo 的 `CLAUDE.md` 顶部，按需修改 `[占位符]`：

```markdown
## Mycelium Protocol 上下文
> 本 repo 属于 [组织名] 组织，参与 Mycelium Protocol 生态建设。

@/Users/jason/Dev/Brood/protocol/MISSION.md
@/Users/jason/Dev/Brood/orgs/[org-id]/PROFILE.md
@/Users/jason/Dev/Brood/orgs/[org-id]/INTERFACES.md

> 生态全景、任务看板见: github.com/AAStarCommunity/Brood
```

将 `[org-id]` 替换为 `aastar`、`auraai` 或 `mycelium`。

---

## 更多资源

| 文件 | 说明 |
|-----|------|
| `protocol/MISSION.md` | 菌丝协议使命愿景、意义经济、数字公共物品 |
| `protocol/FOUNDER.md` | 创始人背景（Jason）、价值观、决策逻辑 |
| `protocol/ECOSYSTEM_MAP.md` | 生态全景图 |
| `protocol/HOW_TO_JOIN.md` | 如何加入协议 |
| `orgs/aastar/PROFILE.md` | AAstar 组织名片 |
| `orgs/aastar/INTERFACES.md` | AAstar 接口规范 |
| `orgs/auraai/PROFILE.md` | AuraAI 组织名片 |
| `orgs/auraai/INTERFACES.md` | AuraAI 接口规范 |
| `orgs/mycelium/PROFILE.md` | MushroomDAO 名片 |
| `orgs/mycelium/INTERFACES.md` | MushroomDAO 接口规范 |
| `docs/ECOSYSTEM_MAP.md` | 仓库级生态地图（含本地路径） |
