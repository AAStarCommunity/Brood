# Brood Acceptance — 用户视角「算不算做好了」

> Brood 有两类使用者，验收标准完全不同。混着谈会得出错误结论。

## 使用者一：读进度的人（BroodBrain 站点）

**他要的**：打开站点就知道 Mycelium 生态各仓库在做什么、到哪一步了。

算做好了：

1. `pnpm run build` 成功，`dist/` 里 `index.html` 与 `api/tasks.json` 都非空
2. 站点是**纯静态**的：无后端、无写接口；任何写操作被拦截并给出中文提示
3. `dist/` 与源码**可复现**——CI 的 `dist/ matches a fresh build` 为绿
   （时钟派生字段除外，见 `.github/workflows/verify.yml` 里的说明）
4. 任务 YAML 全部可解析（CI 的 `Task frontmatter is valid YAML`）——
   历史上一个未加引号的 `:` 曾让 10 个任务变成空记录进了公开搜索索引

## 使用者二：用 pilot 的开发者（本仓库分发的 skill）

**他要的**：装上 pilot 之后，仓库里的危险动作被拦住，而且拦得住的东西是**真拦得住**。

算做好了：

1. **护栏真的能跑**——不是「代码看起来对」。判据是**用一次**：
   `git-guard.sh` 的 add/push/pr-create/merge-pr 四条路径、`preflight` 戳记、
   `grade-change` 定级、`safe-cleanup` 清理，每条都在真实仓库跑通过至少一次
2. **fail-closed**：查不到证据时拒绝，而不是放行。且「查不了」与「没有」在输出上**必须可区分**
3. **文档与脚本不脱节**：`reference/*.md` 与 `scripts/*.sh` 零悬空引用；
   放宽任何一条承诺时，README / SKILL.md / reference 三处同步改
4. **版本一致**：`plugin.json` 与 `SKILL.md` 声明同一个版本（CI 的 `pilot version matches in both files`）

## 已知未达标项（不掩盖）

- **三阶段主流程（status / plan / run / doctor）从未端到端跑过。** 脚本层验证充分，
  整机未验证。本文件所在的 `docs/agent/` 就是为了让 `run` 能起跑而补的。
- **SKILL.md 自称的「首要强制手段」PreToolUse hook 不存在**（TASK-40 仍是 To Do）。
  现在真正兜底的只有 GitHub 分支保护，它管 PR 合并，**管不到 `git add -A` 和直推**。
