# Brood Context 验证步骤

## 目标

验证：在一个已添加 Brood @-include 的 repo（如 SuperPaymaster）里打开 Claude Code，AI 是否自动具备正确的生态上下文。

---

## 前置条件

- [ ] Brood 已克隆到 `/Users/jason/Dev/Brood`
- [ ] 目标 repo 的 `CLAUDE.md` 已添加 @-include（见 `CONTEXT-INHERIT.md`）

---

## 验证方法

### Step 1: 进入目标 repo

```bash
cd /Users/jason/Dev/aastar/SuperPaymaster
claude
```

### Step 2: 让 AI 描述自己所在的生态上下文

在 Claude Code 里输入：

```
你是否了解 Mycelium Protocol？请描述：
1. 这个协议的使命是什么？
2. SuperPaymaster 在生态中的位置和依赖关系是什么？
3. AirAccount 和 SuperPaymaster 的接口关系是什么？
```

**期望回答包含**：
- ✅ "构建让合作更快、更多样的去中心化协作网络"（来自 MISSION.md）
- ✅ SuperPaymaster 是 AAstar 的 Gas 抽象支付模块（来自 PROFILE.md）
- ✅ validatePaymasterUserOp / postOp 接口（来自 INTERFACES.md）
- ✅ 依赖 AirAccount 做账户验证（来自 INTERFACES.md 依赖关系）

### Step 3: 验证进度上下文（可选）

如果 PROFILE.md 里有路线图：

```
SuperPaymaster 当前的开发进度和路线图状态是什么？
```

**期望**：能描述 Phase 1 完成状态、UUPS 升级等具体进展

### Step 4: 验证跨 repo 关联意识

```
如果我要在 SuperPaymaster 里添加对 AuraAI 的支付结算支持，
你会建议从哪里入手？涉及哪些现有接口？
```

**期望**：
- ✅ 提到 AuraAI 在生态中是 AI 能力层
- ✅ 提到 SuperPaymaster 的 xPNTs / 积分支付机制可以用于 AI 服务结算
- ✅ 提到需要通过 AirAccount 管理 AI 代理的链上身份

---

## 通过标准

| 检查项 | 期望结果 |
|-------|---------|
| 协议使命 | 能准确描述菌丝协议核心理念 |
| 组织定位 | 知道 SuperPaymaster 是 AAstar 组织的 Gas 抽象模块 |
| 接口关系 | 知道与 AirAccount 的依赖关系 |
| 跨组织意识 | 在建议中考虑其他组织（AuraAI/MushroomDAO）的存在 |

---

## 失败诊断

如果 AI 不知道协议上下文：

1. 检查 `CLAUDE.md` 的 @-include 路径是否正确：
   ```bash
   cat /Users/jason/Dev/aastar/SuperPaymaster/CLAUDE.md | head -10
   ```

2. 检查被引用的文件是否存在：
   ```bash
   ls /Users/jason/Dev/Brood/protocol/MISSION.md
   ls /Users/jason/Dev/Brood/orgs/aastar/PROFILE.md
   ls /Users/jason/Dev/Brood/orgs/aastar/INTERFACES.md
   ```

3. 重启 Claude Code 后再次尝试（@-include 在会话启动时加载）
