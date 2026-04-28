---
name: license-update
description: 扫描所有活跃 repo 的 License 合规状态（Apache 2.0 + NOTICE + TRADEMARK.md），初始化缺失文件或同步模板变更。当用户想检查 license 合规、初始化新 repo 的 license、或批量更新 TRADEMARK 政策时使用。
allowed-tools: Bash(git *), Bash(ls *), Bash(md5 *), Bash(diff *), Bash(cp *), Read, Glob, Grep, Edit, Write
---

# License Update — 生态 License 合规同步器

你是一个开源合规工程师。你的任务是确保 Mycelium Protocol 生态所有活跃 repo 的 License 三件套（LICENSE + NOTICE + TRADEMARK.md）符合组织标准。

## 标准五件套

所有生态 repo 统一使用以下 License 文件组合（英文三件套 + 中文两件）：

| 文件 | 内容 | 是否参数化 | 语言 |
|:---|:---|:---|:---|
| `LICENSE` | Apache License 2.0 全文 + MushroomDAO 版权声明 | 否，完全相同 | 英文（法律效力） |
| `NOTICE` | 产品归属声明 + 商标提示（双语） | 是，第一行含 repo 名 | 英文 + 中文 |
| `TRADEMARK.md` | MushroomDAO 商标政策全文 | 否，完全相同 | 英文 |
| `LICENSE-zh.md` | Apache 2.0 非官方中文参考译本（含免责声明） | 否，完全相同 | 中文 |
| `TRADEMARK-zh.md` | MushroomDAO 商标政策中文版 | 否，完全相同 | 中文 |

> **国际惯例**：Apache 基金会明确规定只有英文版 LICENSE 具有法律效力。中文版为参考译本，
> 顶部标注免责声明。TRADEMARK 为我们自定义政策，中英文版本效力相同。

**模板来源**（单一来源 / Single Source of Truth）：

```
$REPO_ROOT/protocol/license-templates/
  ├── LICENSE            # 标准 Apache 2.0（完全一致复制）
  ├── LICENSE-zh.md      # Apache 2.0 中文参考译本（完全一致复制）
  ├── NOTICE.template    # NOTICE 双语模板（{{REPO_NAME}} 占位符）
  ├── TRADEMARK.md       # 标准商标政策·英文（完全一致复制）
  └── TRADEMARK-zh.md    # 标准商标政策·中文（完全一致复制）
```

## 前置：动态路径检测

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)   # Brood 根目录
SCAN_ROOT=$(dirname "$REPO_ROOT")            # ~/Dev
TEMPLATES="$REPO_ROOT/protocol/license-templates"
```

打印确认：
```
📍 Brood 根目录: {REPO_ROOT}
🔍 扫描范围: {SCAN_ROOT}
📄 模板目录: {TEMPLATES}
```

验证模板目录存在且三个文件齐全，否则报错退出。

## 执行流程

### Phase 1：收集活跃 repo 列表

1. 读取 `$REPO_ROOT/docs/ECOSYSTEM_MAP.md`
2. 提取所有 🟢 Active 和 🟡 Moderate 状态的 repo，记录：
   - 本地路径（如 `/Dev/aastar/SuperPaymaster`）
   - Repo 名（路径最后一段，如 `SuperPaymaster`）
3. 验证每个路径实际存在且是 git 仓库
4. **排除 Brood 自身**（Brood 使用 GPLv3，不参与 Apache 2.0 合规检查）

输出：
```
📋 扫描目标: {N} 个活跃 repo（排除 Brood）
```

### Phase 2：检查合规状态

对每个 repo，检查五个文件的存在性和内容一致性：

**逐文件检查逻辑**（LICENSE / TRADEMARK.md / LICENSE-zh.md / TRADEMARK-zh.md）：
```bash
md5 -q "$repo_path/{FILE}"
md5 -q "$TEMPLATES/{FILE}"
```
- 文件不存在 → 标记 `MISSING`
- hash 不一致 → 标记 `OUTDATED`（可能是旧格式或被修改）
- hash 一致 → 标记 `OK`

**NOTICE 检查**（特殊，含参数化内容）：
1. 文件不存在 → 标记 `MISSING`
2. 文件存在 → 检查第一行是否为 `Mycelium Protocol — {RepoName}`
3. 用模板生成期望内容（替换 `{{REPO_NAME}}`），逐行对比除第一行外的内容
4. 第一行产品名正确 + 其余内容一致 → `OK`
5. 其余内容不一致 → `OUTDATED`

**输出状态表**：
```
=== Phase 2: License 合规状态 ===

| Repo | LICENSE | NOTICE | TRADEMARK | LICENSE-zh | TRADEMARK-zh | 状态 |
|:---|:---:|:---:|:---:|:---:|:---:|:---|
| SuperPaymaster | OK | OK | OK | MISSING | MISSING | ⚠️ 缺中文版 |
| AirAccount | MISSING | MISSING | MISSING | MISSING | MISSING | ❌ 全部缺失 |
| blog | OUTDATED | OK | OK | MISSING | MISSING | ⚠️ LICENSE 旧+缺中文 |
```

### Phase 3：初始化缺失文件

对所有 `MISSING` 的文件，直接创建：

**LICENSE（MISSING）**：
```bash
cp "$TEMPLATES/LICENSE" "$repo_path/LICENSE"
```

**NOTICE（MISSING）**：
用 Read 工具读取 `$TEMPLATES/NOTICE.template`，将 `{{REPO_NAME}}` 替换为 repo 名，用 Write 工具写入 `$repo_path/NOTICE`。

**TRADEMARK.md（MISSING）**：
```bash
cp "$TEMPLATES/TRADEMARK.md" "$repo_path/TRADEMARK.md"
```

**LICENSE-zh.md（MISSING）**：
```bash
cp "$TEMPLATES/LICENSE-zh.md" "$repo_path/LICENSE-zh.md"
```

**TRADEMARK-zh.md（MISSING）**：
```bash
cp "$TEMPLATES/TRADEMARK-zh.md" "$repo_path/TRADEMARK-zh.md"
```

每个操作打印日志：
```
📝 初始化: AirAccount/LICENSE（从模板创建）
📝 初始化: AirAccount/NOTICE（Mycelium Protocol — AirAccount）
📝 初始化: AirAccount/TRADEMARK.md（从模板创建）
📝 初始化: AirAccount/LICENSE-zh.md（中文参考译本）
📝 初始化: AirAccount/TRADEMARK-zh.md（商标政策中文版）
```

### Phase 4：同步模板变更

对所有 `OUTDATED` 的文件，用模板覆盖更新：

**重要**：在覆盖前，先用 `diff` 展示差异让用户确认。

```
📌 模板变更: blog/LICENSE
   差异: 缩进格式不同（官方 Apache 模板 vs 组织标准格式）
   是否更新？[y/N/skip-all]
```

- 用户输入 `y` → 覆盖更新
- 用户输入 `N` → 跳过
- 用户输入 `skip-all` → 跳过所有 OUTDATED 文件

对 NOTICE 的 OUTDATED：
1. 保留第一行的产品名（不改变）
2. 仅更新第一行之后的模板内容

对 TRADEMARK.md 的 OUTDATED：
1. 直接用模板覆盖（TRADEMARK 政策变更需要全量同步）

### Phase 5：Git 提交

对每个被修改的 repo，执行 git 暂存和提交：

```bash
git -C "$repo_path" add LICENSE NOTICE TRADEMARK.md LICENSE-zh.md TRADEMARK-zh.md
git -C "$repo_path" status
```

**不自动 commit**，而是输出建议命令让用户确认：

```
=== 待提交的变更 ===

以下 repo 有 license 文件变更待提交:

  cd ~/Dev/aastar/AirAccount && git add LICENSE NOTICE TRADEMARK.md LICENSE-zh.md TRADEMARK-zh.md && git commit -m "chore: Apache 2.0 license + NOTICE + TRADEMARK（含中文版）"
  cd ~/Dev/aastar/aastar-sdk && git add NOTICE TRADEMARK.md LICENSE-zh.md TRADEMARK-zh.md && git commit -m "chore: add NOTICE + TRADEMARK + 中文版"
  cd ~/Dev/mycelium/CometENS && git add LICENSE NOTICE TRADEMARK.md LICENSE-zh.md TRADEMARK-zh.md && git commit -m "chore: Apache 2.0 license + NOTICE + TRADEMARK（含中文版）"

是否批量执行？[y/N]
```

如果用户确认 `y`，逐个执行 commit（不 push，push 由用户自行决定）。

### Phase 6：汇总报告

```
══════════════════════════════════════════════
   📄 License Update 完成报告
   扫描时间: {YYYY-MM-DD HH:MM}
══════════════════════════════════════════════

📋 扫描范围: {N} 个活跃 repo

状态汇总:
  ✅ 合规: {N} 个（三件套完整且一致）
  📝 新建: {N} 个（缺失文件已初始化）
  📌 更新: {N} 个（模板变更已同步）
  ⏭️ 跳过: {N} 个（用户选择不更新）

变更的 repo:
  - AirAccount: +LICENSE +NOTICE +TRADEMARK.md（全新初始化）
  - aastar-sdk: +NOTICE +TRADEMARK.md
  - CometENS: +LICENSE +NOTICE +TRADEMARK.md
  ...

Git 状态:
  已提交: {N} 个 | 待提交: {N} 个 | 待推送: {N} 个
══════════════════════════════════════════════
```

## 重要注意事项

- **Brood 自身排除**：Brood 使用 GPLv3，不参与 Apache 2.0 合规检查
- **模板是唯一来源**：`protocol/license-templates/` 下的文件是标准，其他 repo 向它对齐
- **NOTICE 的产品名保留**：更新 NOTICE 时第一行的 `Mycelium Protocol — {Name}` 不被覆盖
- **不自动 push**：commit 后由用户决定何时推送
- **OUTDATED 需确认**：已存在但内容不同的文件不会静默覆盖，需要用户确认
- **Bash 命令保持简单**：每个 Bash 调用只做一件事（rtk 兼容）
- **输出语言**：中文

## 模板维护

当需要更新 License 政策时：

1. 编辑 `$REPO_ROOT/protocol/license-templates/` 下的模板文件
2. 运行 `/license-update`
3. Phase 4 会自动检测差异并提示同步到所有 repo

例如：更新 TRADEMARK.md 中新增保护名称 →  编辑模板 → 运行 skill → 全量同步。
