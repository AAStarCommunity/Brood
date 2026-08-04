# 贡献指南 / Contributing Guide

> 适用于所有 Mycelium Protocol 生态仓库（AAStarCommunity · iDoris-ai · MushroomDAO）

---

## Apache 2.0 是什么？（2 分钟白话版）

我们所有项目都使用 **Apache License 2.0**，这是一个对所有人完全开放的许可证。

### 你可以做什么（几乎任何事）

| 行为 | 是否允许 |
|------|---------|
| 免费使用代码 | ✅ |
| 商业使用、卖钱 | ✅ |
| 修改代码 | ✅ |
| 集成进自己的闭源产品（不用开源） | ✅ |
| 分发给别人 | ✅ |

### 必须遵守的 4 条规则

1. **保留版权行** — 代码里 `Copyright 2024-present MushroomDAO Contributors` 那行不能删
2. **保留 NOTICE 文件** — 分发时必须附带 NOTICE 文件
3. **标注修改** — 如果你改了某个文件，在文件里注明"modified"
4. **不能蹭品牌** — 不能用 MushroomDAO、Mycelium Protocol 等名称为自己背书（详见 TRADEMARK.md）

### 和 GPL 最大的区别

GPL 要求"改了代码必须开源"，Apache 2.0 **不要求**。你可以改了代码后做成闭源产品，完全合法。

---

## CLA 是什么？为什么要签？

### 问题背景

Apache 2.0 给了用户使用代码的权利。但当你向项目提交代码（PR）时，项目方需要确认：**你真的同意把这段代码授权给项目在 Apache 2.0 下使用**。

没有这个确认，就存在法律漏洞——万一你后来反悔，说"我没授权你们用我的代码"，项目就会面临法律风险。

### CLA 是什么

**CLA（Contributor License Agreement，贡献者许可协议）** 是你签署的一份声明：

> "我确认我写的这段代码是我的原创（或我有权提交），并授权 MushroomDAO 在 Apache 2.0 协议下使用、修改和分发。"

签完之后，项目对所有贡献的代码都有清晰的法律授权链。

### 历史贡献者怎么办

你在提交新 PR 时，机器人会自动请你签名。已有历史贡献的同学，签一次就覆盖所有历史提交。

### 如何签署

1. 提交 PR 后，`@cla-assistant` 机器人会自动评论
2. 点击评论中的链接，用 GitHub 账号登录并签名
3. 签名后 PR 自动解锁，流程就完成了

签名是永久有效的，只需签一次。

---

## 贡献流程

```
Fork → 新建分支 → 写代码 → 提交 PR → 签 CLA → Code Review → Merge
```

1. **Fork** 目标仓库到你的 GitHub 账号
2. **新建分支**，命名规范：`feat/xxx`、`fix/xxx`、`docs/xxx`
3. **提交代码**，commit message 遵循 [Conventional Commits](https://www.conventionalcommits.org/)
4. **开 PR**，描述清楚做了什么、为什么
5. **签署 CLA**（首次贡献需要，机器人自动引导）
6. 等待 Code Review，根据反馈修改
7. Merge 🎉

---

## CLA 全文

完整协议见 [CLA.md](./CLA.md)（英文，法律效力版）| [CLA-zh.md](./CLA-zh.md)（中文参考译本，非官方）

---

## 问题与反馈

- GitHub Issues：在对应仓库提 Issue
- 社区讨论：[MushroomDAO GitHub Discussions](https://github.com/MushroomDAO)
- 邮件：contact@mushroom.land
