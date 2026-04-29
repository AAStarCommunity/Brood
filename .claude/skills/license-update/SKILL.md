---
name: license-update
description: 扫描所有活跃 repo 的 License 合规状态，确保每个 repo 包含完整的七件套文件（LICENSE 五件套 + CONTRIBUTING.md + CLA Action），同步模板变更，创建 PR 到 main。当用户想检查 license 合规、初始化新 repo 的 license、或批量更新 TRADEMARK/CLA 政策时使用。
allowed-tools: Bash(git *), Bash(python3 *), Bash(ls *), Bash(cp *), Read, Glob, Grep, Edit, Write
---

# License Update — 生态 License 合规同步器

你是一个开源合规工程师。你的任务是确保 Mycelium Protocol 生态所有活跃 repo 的七件套文件符合组织标准，并为每个 repo 创建 `chore/license-compliance` PR 到 main。

## 标准七件套

所有生态 repo 统一使用以下文件组合：

| 文件 | 内容 | 是否参数化 | 说明 |
|:---|:---|:---|:---|
| `LICENSE` | Apache License 2.0 全文 + MushroomDAO 版权声明 | 否 | 英文，法律效力版 |
| `NOTICE` | 产品归属声明 + 商标提示（双语） | 是，第一行含 repo 名 | 英文 + 中文双语 |
| `TRADEMARK.md` | MushroomDAO 商标政策全文 | 否 | 英文 |
| `LICENSE-zh.md` | Apache 2.0 非官方中文参考译本 | 否 | 含免责声明 |
| `TRADEMARK-zh.md` | MushroomDAO 商标政策中文版 | 否 | 中文 |
| `CONTRIBUTING.md` | 贡献指南（CLA 说明 + Apache 2.0 白话解释 + 流程） | 否 | 精简版，链接 protocol/ |
| `.github/workflows/cla.yml` | CLA Assistant GitHub Action | 否 | 自动拦截 PR 要求签名 |

**模板来源**（Single Source of Truth）：

```
$REPO_ROOT/protocol/license-templates/
  ├── LICENSE
  ├── LICENSE-zh.md
  ├── NOTICE.template          # {{REPO_NAME}} 占位符
  ├── TRADEMARK.md
  ├── TRADEMARK-zh.md
  ├── CONTRIBUTING.md          # 精简版贡献指南模板
  └── cla-action.yml           # CLA GitHub Action 模板（复制为 .github/workflows/cla.yml）

$REPO_ROOT/protocol/
  ├── CONTRIBUTING.md          # 完整版（各 repo CONTRIBUTING.md 的链接目标）
  ├── CLA.md                   # 正式 CLA 协议文本（英文）
  └── CLA-zh.md                # CLA 中文参考译本
```

## README License 节标准格式

每个 repo 的 README.md 末尾必须包含以下格式（必须含全部 5 个链接）：

```markdown
## License

This project is licensed under the [Apache License, Version 2.0](LICENSE).  
Copyright 2024-present MushroomDAO Contributors.  
See [NOTICE](./NOTICE) · [TRADEMARK.md](./TRADEMARK.md) · [LICENSE-zh.md](./LICENSE-zh.md) · [TRADEMARK-zh.md](./TRADEMARK-zh.md) for details.
```

## 前置：动态路径检测

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
SCAN_ROOT=$(dirname "$REPO_ROOT")
TEMPLATES="$REPO_ROOT/protocol/license-templates"
```

## 执行流程

### Phase 0：读取生态 repo 列表

从 `$REPO_ROOT/docs/ECOSYSTEM_MAP.md` 提取所有活跃 repo 的本地路径和 GitHub URL。
排除：
- Brood 自身
- GPL-3.0 fork（UltraRelay-AAStar、agent-speaker-relay 等）
- 已归档 repo（AAStar_SDK 等）

### Phase 1：合规状态扫描

对每个 repo，用 Python 脚本批量检查七件套 + README 格式：

```python
import subprocess, os

def check_repo(path, branch="main"):
    name = os.path.basename(path)
    results = {}
    # 五件套文件
    for f in ["LICENSE","NOTICE","TRADEMARK.md","LICENSE-zh.md","TRADEMARK-zh.md"]:
        r = subprocess.run(["git","-C",path,"show",f"{branch}:{f}"], capture_output=True)
        results[f] = "OK" if r.returncode==0 else "MISSING"
    # CONTRIBUTING.md
    r = subprocess.run(["git","-C",path,"show",f"{branch}:CONTRIBUTING.md"], capture_output=True)
    results["CONTRIBUTING"] = "OK" if r.returncode==0 else "MISSING"
    # CLA action
    r = subprocess.run(["git","-C",path,"show",f"{branch}:.github/workflows/cla.yml"], capture_output=True)
    results["cla.yml"] = "OK" if r.returncode==0 else "MISSING"
    # README 5-file format
    for readme in ["README.md","Readme.md"]:
        r = subprocess.run(["git","-C",path,"show",f"{branch}:{readme}"],capture_output=True,text=True)
        if r.returncode==0:
            results["README"] = "OK" if "TRADEMARK-zh" in r.stdout else "OUTDATED"
            break
    else:
        results["README"] = "MISSING"
    return results
```

输出状态表：
```
| Repo | LICENSE | NOTICE | TRADEMARK | LICENSE-zh | TRADEMARK-zh | CONTRIBUTING | cla.yml | README |
```

### Phase 2：创建合规分支并修复所有问题

对每个 repo，在 `chore/license-compliance` 分支上执行修复：

**Step 1 — 创建分支**
```bash
git -C {path} fetch origin
git -C {path} checkout main   # 或 master
git -C {path} pull origin main
git -C {path} checkout -b chore/license-compliance 2>/dev/null || git -C {path} checkout chore/license-compliance
```

**Step 2 — 复制五件套文件**
- LICENSE、TRADEMARK.md、LICENSE-zh.md、TRADEMARK-zh.md：直接从模板复制
- NOTICE：读取模板，将 `{{REPO_NAME}}` 替换为 repo 名，写入

**Step 3 — 复制 CONTRIBUTING.md**
从 `$TEMPLATES/CONTRIBUTING.md` 复制到 repo 根目录。

**Step 4 — 复制 CLA Action**
从 `$TEMPLATES/cla-action.yml` 复制到 `{repo}/.github/workflows/cla.yml`（自动创建目录）。

**Step 5 — 更新 README License 节**

如果 README 存在但缺少或格式不正确：找到 `## License` 节，替换至文件末尾为标准格式。
如果 README 不存在：创建最小化 README：
```markdown
# {RepoName}

> Part of [Mycelium Protocol](https://github.com/AAStarCommunity/Brood) ecosystem.

## License

This project is licensed under the [Apache License, Version 2.0](LICENSE).  
Copyright 2024-present MushroomDAO Contributors.  
See [NOTICE](./NOTICE) · [TRADEMARK.md](./TRADEMARK.md) · [LICENSE-zh.md](./LICENSE-zh.md) · [TRADEMARK-zh.md](./TRADEMARK-zh.md) for details.
```

**Step 6 — 检查 .sol SPDX 头**

如果 repo 包含 `src/*.sol` 文件：
- 跳过 `lib/`、`node_modules/`、`out/`、`broadcast/` 目录
- 将 `// SPDX-License-Identifier: MIT` 改为 `Apache-2.0`
- 保留 `GPL-3.0`、`UNLICENSED` 等不动（可能是上游代码）

**Step 7 — Commit 并推送**
```bash
git -C {path} add -A
git -C {path} commit -m "chore: Apache 2.0 license compliance (5-file set, CONTRIBUTING, CLA action, README)"
git -C {path} push origin chore/license-compliance
```

对有 Rust pre-commit hook 的 repo（super-relay）加 `--no-verify`。

**Step 8 — 创建 PR**
```bash
gh pr create --repo {org/repo} \
  --title "chore: Apache 2.0 license compliance" \
  --body "$(cat <<'EOF'
## Summary
- 5-file Apache 2.0 license set (LICENSE, NOTICE bilingual, TRADEMARK.md, LICENSE-zh.md, TRADEMARK-zh.md)
- CONTRIBUTING.md with CLA signing instructions and Apache 2.0 plain-language explanation
- .github/workflows/cla.yml — CLA Assistant auto-checks all PRs
- README License section updated to link all 5 files

## CLA Setup Required
After merging: add `CLA_TOKEN` org secret at org Settings → Secrets → Actions.
See protocol/CLA.md for full CLA text.
EOF
)"
```

### Phase 3：验证

全部 repo 处理完后，用 Python 脚本重新扫描，验证所有 repo 七件套齐全 + README 格式正确，打印验证结果。**禁止在未经验证的情况下汇报"已完成"。**

```python
# 验证脚本
ok, fail = [], []
for path, branch in repos:
    name = os.path.basename(path)
    checks = check_repo(path, branch)
    if all(v=="OK" for v in checks.values()):
        ok.append(name)
    else:
        fail.append(f"{name}: {[k for k,v in checks.items() if v!='OK']}")
print(f"✅ {len(ok)}/{len(repos)} PASS")
if fail:
    print("❌ FAIL:", fail)
```

### Phase 4：汇总报告

```
══════════════════════════════════════════
   License Update 完成报告  {YYYY-MM-DD}
══════════════════════════════════════════
扫描: {N} 个 repo

七件套验证: {N}/N ✅
README 验证: {N}/N ✅

PR 列表:
  https://github.com/AAStarCommunity/SuperPaymaster/pull/XXX
  https://github.com/MushroomDAO/Sin90/pull/XXX
  ...

跳过 (GPL fork/archived):
  UltraRelay-AAStar (GPL-3.0 fork)
  AAStar_SDK (archived)

下一步:
  1. Merge 上述 PR
  2. 各 org 添加 CLA_TOKEN secret:
     github.com/organizations/{org}/settings/secrets/actions
══════════════════════════════════════════
```

## 注意事项

- **汇报前必须验证**：用脚本实际 check，不能凭记忆断言
- **删除操作前核对 remote**：`git remote get-url origin` 确认再删，名字相似≠同一仓库
- **Bash 命令保持简单**：rtk hook 会拦截复杂管道，用 Python 脚本代替复杂 shell
- **GPL fork 跳过 Apache 文件**：UltraRelay、agent-speaker-relay 等保持原有 GPL-3.0
- **super-relay 需 --no-verify**：有 Rust clippy pre-commit hook
- **不自动 push 到 main**：一律走 PR 流程，main 分支保护
- **NOTICE 产品名保留**：更新时第一行 `Mycelium Protocol — {Name}` 不被覆盖
