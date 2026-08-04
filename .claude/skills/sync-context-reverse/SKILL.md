---
name: sync-context-reverse
description: 反向同步：扫描所有生态 repo，将接口/版本/状态/依赖变更回流到 Brood 的 INTERFACES.md、PROFILE.md 和 ECOSYSTEM_MAP.md。当用户想检查上下文健康度、同步接口变更、或验证所有 repo 的 @-include 完整性时使用。
allowed-tools: Bash(git *), Bash(find *), Bash(python3 *), Bash(ls *), Read, Glob, Grep, Edit, Write
---

# Sync Context — 生态上下文反向同步器

你是一个生态上下文维护工程师。你的任务是扫描所有 Mycelium Protocol 生态 repo，检测接口/版本/状态的变更，将变更反向同步到 Brood 的 L0/L1 上下文文件中。

## 前置：动态路径检测

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)   # Brood 根目录
SCAN_ROOT=$(dirname "$REPO_ROOT")            # ~/Dev
```

打印确认：
```
📍 Brood 根目录: /Users/xxx/Dev/Brood
🔍 扫描范围: /Users/xxx/Dev
```

## 执行流程

严格按以下 Phase 执行。每个 Phase 完成后打印摘要再进入下一个。

---

### Phase 1：@-include 健康检查

扫描 ECOSYSTEM_MAP.md 中所有 🟢 Active 和 🟡 Moderate 状态的 repo，验证每个 repo 的 CLAUDE.md 中包含完整的 @-include 块。

**执行步骤**：

1. 读取 `$REPO_ROOT/docs/ECOSYSTEM_MAP.md`，提取所有本地路径（`/Dev/` 前缀行）
2. 过滤状态为 🟢 或 🟡 的 repo
3. 对每个 repo，检查：
   - `CLAUDE.md` 是否存在
   - 是否包含 `## Mycelium Protocol` section
   - 是否包含 `@...protocol/MISSION.md` 引用
   - 是否包含 `@...orgs/{org}/PROFILE.md` 引用
   - 是否包含 `@...orgs/{org}/INTERFACES.md` 引用
   - @-include 路径中的 Brood 根目录是否与当前 `$REPO_ROOT` 一致

4. 输出报告：
```
=== Phase 1: @-include 健康检查 ===
✅ 18/22 repo 引用完整
⚠️  缺失 CLAUDE.md: repo-A, repo-B
⚠️  引用不完整: repo-C (缺 INTERFACES.md)
⚠️  路径过时: repo-D (引用 /old/path/Brood, 应为 /new/path/Brood)
```

5. **自动修复**（用 Edit 工具）：
   - 缺失 CLAUDE.md → 用 init-brood-context.sh 创建（如果脚本存在）
   - 引用不完整 → 插入缺失的 @-include 行
   - 路径过时 → 替换旧路径为当前 `$REPO_ROOT`
   - 修复后打印 `🔧 已修复: repo-X (原因)`

---

### Phase 2：版本号同步

从每个 repo 提取当前版本号，与 PROFILE.md 和 INTERFACES.md 中记录的版本号对比。

**版本号提取策略**（按优先级）：

1. **CLAUDE.md** — 搜索 `版本`、`version`、`v[0-9]` 模式
2. **package.json** — `"version"` 字段
3. **Cargo.toml** — `version =` 字段
4. **foundry.toml** 或合约源码 — `version()` 函数返回值
5. **CHANGELOG.md** — 最新版本条目
6. **git tag** — 最新语义版本 tag

对每个 repo 执行：

```bash
# package.json 版本
[ -f "$repo/package.json" ] && python3 -c "import json; print(json.load(open('$repo/package.json')).get('version',''))" 2>/dev/null

# git tag 版本
git -C "$repo" tag --sort=-v:refname | head -1
```

用 Grep 工具搜索 CLAUDE.md 中的版本模式：
```
grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' "$repo/CLAUDE.md"
```

**对比与更新**：

1. 读取 `$REPO_ROOT/orgs/{org}/PROFILE.md` 的 YAML frontmatter `provides:` 中每个 capability 的 `version:` 字段
2. 读取 `$REPO_ROOT/orgs/{org}/INTERFACES.md` 中每个产品 section 的 `**版本**:` 行
3. 如果 repo 实际版本 ≠ 记录版本：
   - 用 Edit 工具更新 PROFILE.md 的 `version:` 字段
   - 用 Edit 工具更新 INTERFACES.md 的版本行
   - 打印 `📌 版本更新: {product} {旧版本} → {新版本}`

4. 输出报告：
```
=== Phase 2: 版本号同步 ===
📌 AirAccount: v0.16.7 → v0.16.8 (PROFILE.md + INTERFACES.md 已更新)
📌 SuperPaymaster: v4.4.0 → v4.5.0 (INTERFACES.md 已更新)
✅ 其余 8 个产品版本一致
```

---

### Phase 3：接口变更检测

扫描每个活跃 repo 的 CLAUDE.md，提取接口信息，与 INTERFACES.md 做语义对比。

**接口提取策略**：

1. **HTTP API** — 从 CLAUDE.md 或 README.md 中提取 `GET/POST/PUT/DELETE /path` 模式
2. **Solidity 合约** — 从 CLAUDE.md 的合约接口 section 提取，或用 Grep 扫描 `*.sol` 文件中的 `function` 签名（限 `src/` 或 `contracts/src/`）：
   ```
   grep -E "function\s+\w+\(" --include="*.sol" -r "$repo/contracts/src/" "$repo/src/"
   ```
3. **npm 包** — 从 package.json 的 `name` 字段提取包名
4. **CLI 命令** — 从 CLAUDE.md 的 Commands section 提取

**对比逻辑**：

对每个 org 的 INTERFACES.md：
1. 解析每个 `### N. ProductName` section 的接口表格
2. 与 repo 中提取的接口列表对比
3. 标记差异类型：
   - `🆕 新增接口`: repo 中存在但 INTERFACES.md 中没有
   - `❌ 已删除接口`: INTERFACES.md 中有但 repo 中已不存在
   - `📝 接口变更`: 签名/路径/说明有变化

4. **不自动修改 INTERFACES.md 的接口表格**——接口变更涉及语义理解，只输出变更建议，由用户确认后手动或指示 Claude 更新。

5. 输出报告：
```
=== Phase 3: 接口变更检测 ===

AAstar / SuperPaymaster:
  🆕 新增: mintTicket (Solidity) — 合约中存在但 INTERFACES.md 未记录
  📝 变更: burnTicket → 签名新增 amount 参数

iDoris.ai / agent-speaker:
  ✅ 无接口变更

MushroomDAO / CometENS:
  🆕 新增: batchRegister (Solidity) — 批量注册子域名
  ❌ 移除: FreePlugin — 已被 RegistrarPlugin 替代

💡 建议: 3 处接口变更需要确认，是否逐一更新？[y/N]
```

如果用户确认，则用 Edit 工具更新 INTERFACES.md 对应 section。

---

### Phase 4：依赖关系验证

检查 PROFILE.md 中 `depends_on:` 声明的依赖关系是否仍然准确。

**执行步骤**：

1. 读取三个 org 的 PROFILE.md `depends_on:` 列表
2. 对每条依赖，检查是否在目标 org 的 `provides:` 中存在对应 capability
3. 扫描各 repo 的 CLAUDE.md 和 import/dependency 文件，发现未声明的跨 org 依赖：
   - Solidity: `import` 语句引用其他 org 的合约
   - Node.js: package.json `dependencies` 中包含 `@aastar/`、`@mushroom/`、`@auraai/` 等
   - CLAUDE.md: 提及其他 org 产品的使用
4. 输出报告：
```
=== Phase 4: 依赖关系验证 ===
✅ aastar depends_on auraai/ai-inference: 仍存在 (optional)
⚠️  未声明依赖: mycelium/MyTask → aastar/AirAccount (package.json 中引用 @aastar/sdk)
✅ 所有已声明依赖在目标 org 中存在
```

---

### Phase 5：ECOSYSTEM_MAP 状态刷新

类似 sync-progress 的 Phase 0，但独立执行不依赖任务扫描。

1. 对 ECOSYSTEM_MAP.md 中每个 repo，获取最近 commit 日期：
```bash
git -C "$repo_path" log -1 --format="%ad" --date=short 2>/dev/null
```

2. 根据日期重新计算状态：
   - 90 天内 → 🟢 Active
   - 3-12 个月 → 🟡 Moderate
   - 超过 12 个月 → 🔴 Dormant

3. 如果状态有变化，用 Edit 工具更新 ECOSYSTEM_MAP.md 对应行
4. 更新文件顶部的"最后更新"日期

5. 输出报告：
```
=== Phase 5: 生态地图状态刷新 ===
📊 扫描 35 个 repo
🟢 Active: 22 | 🟡 Moderate: 5 | 🔴 Dormant: 8
状态变更: 2 个
  Spores: 🟡 → 🔴 (最后提交 2025-11-15, 超过 12 个月)
  mushroom.github.io: 🟡 → 🔴 (最后提交 2025-07-28)
```

---

### Phase 6：更新时间戳 & 汇总

1. 更新所有被修改文件的"最后更新"时间戳为今天日期
2. 输出最终汇总：

```
══════════════════════════════════════════════
   🍄 Sync Context 完成报告
   扫描时间: {YYYY-MM-DD HH:MM}
══════════════════════════════════════════════

📋 扫描范围: {N} 个 repo ({N} 个活跃)

Phase 1 — @-include 健康:  ✅ {N}/{M} 完整, 🔧 修复 {K} 个
Phase 2 — 版本同步:        📌 {N} 个版本更新
Phase 3 — 接口变更:        🆕 {N} 新增, ❌ {N} 移除, 📝 {N} 变更
Phase 4 — 依赖关系:        ✅ {N} 已验证, ⚠️ {N} 未声明
Phase 5 — 生态地图:        🔄 {N} 个状态变更

修改的文件:
  - orgs/aastar/INTERFACES.md (版本 + 接口)
  - orgs/aastar/PROFILE.md (版本)
  - docs/ECOSYSTEM_MAP.md (状态)
  - {repo}/CLAUDE.md × {N} (修复引用)
══════════════════════════════════════════════
```

---

## 重要注意事项

- **严格本地优先**：所有数据从本地 git 仓库和文件中提取，不调用 GitHub API
- **接口变更不自动写入**：Phase 3 的接口变更只输出建议，需用户确认后更新（版本号和状态可以自动更新）
- **幂等性**：多次运行结果一致，不会重复写入
- **保守原则**：如果信息不足以判断变更，标注为"需人工确认"而非自动修改
- **输出语言**：中文
- **Bash 命令保持简单**：每个 Bash 调用只做一件事，避免管道链和内联脚本（rtk 兼容）
