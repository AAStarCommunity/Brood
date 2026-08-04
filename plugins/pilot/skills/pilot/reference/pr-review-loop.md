# 全局假设：外部 pr-daemon review 回路

pilot **不自己裁决 PR**。生态里有一个独立的 **pr-daemon** 仓库跑一个轮询 loop 负责 review 所有仓库的 PR。所有装了 pilot 的仓库共享这个假设：**你只管提交 PR，5–20 分钟内会收到 review 结果。**

## 前置条件:pr-daemon 不随 pilot 一起安装

**装了 pilot ≠ 有了评审能力。** pilot 包里没有 pr-daemon 的任何代码——它是一个**独立的外部进程**,
pilot 只负责「确保它活着」并等回执。没有它,`pilot run` 开出去的 PR **不会有任何人评审,会一直挂着**。

装法(一次性,全机器共用,不是每个仓库一份):

```bash
git clone https://github.com/jhfnetboy/PR-daemon.git ~/Dev/tools/PR-Daemon
# 装在别处就在 .pilot.yml 里写 pr_daemon_root,或设 $PILOT_PR_DAEMON_ROOT
# 本仓库还必须出现在 daemon 的扫描清单里(~/.config/prbot/repos.conf),否则它不会来看你的 PR
```

**不打算装怎么办**(完全合理——个人项目、或团队已有人工 review):
`pilot run` 仍然可用,但你要自己承担裁决那一步。把这件事讲清楚,不要让 PR 悄悄挂死:

- `doctor` / `status` 会报 `PR_DAEMON: not found`,这是**预期**,不是故障;
- `run` 开完 PR 后**不要进入等回执的循环**——直接告诉用户「本机没有评审 daemon,这个 PR 需要人工 review」,
  然后回主循环去做下一个 task,别空转;
- 合并仍然走正常流程(人 approve 后 `git-guard.sh merge-pr`)。

**`not found`(rc=2)和 `not running`(rc=3)是两回事**:前者是没装,重试一百次也没用;
后者是装了但没跑起来,`ensure` 就能解决。别把前者当后者反复重试。

## pr-daemon 怎么工作

- **节奏**：默认 **10 分钟**一轮；参与开发者多、提交频繁的仓库可调到 **5 分钟**。
- **范围**：轮询一个**仓库列表**（维护在 pr-daemon 仓库的上下文里，可增可减）。**本仓库必须在这个列表里**，否则 PR 不会被自动 review。
- **触发**：每轮找列表内所有仓库中「新开的 PR」或「收到 request-change 后又推了新 commit 的 PR」，review 或再 review。
- **产出**：给出 `APPROVE` 或 `REQUEST_CHANGES`。基本是持续轮询直到 approve。

## review 深度（pr-daemon 内部逻辑，仓库侧了解即可）

| 变更类型 | 轮数 | 参与者 |
|:---|:---|:---|
| 简单 / 纯文档 | 2 轮 | 基础 review |
| 复杂 or >100 行 or 涉安全 or 涉钱 | 4 轮 | Opus 自我挑战 + Codex 挑战 + Sonnet + DeepSeek 一二轮挑战 |

对仓库侧的含义：**涉钱/涉安全/大改动的 PR 会被更严格地审**，所以这类 task 在 PR 前的自测和自审要格外扎实（见 `pr-quality.md`），否则会来回 request-change 拖慢。

## 仓库侧（pilot）的职责

1. **开好 PR**：base 指向集成分支，body 写清 task、验收命令、自测结果，diff 干净。
2. **监控回执**：用 `scripts/pr-monitor.sh` 按 5/10/15 分钟节奏（或直接靠 `/loop 10m pilot run`）扫 `reviewDecision`。
3. **按结果行动**：`APPROVED` → 合并进集成分支 + 标 DONE + 清分支；`CHANGES_REQUESTED` → 读意见、修、推新 commit（daemon 会自动再 review）。
4. **确保在列表里**：`doctor` 检查本仓库是否在 pr-daemon 轮询列表；不在则提示加入。

## 本机现有实现

本机的 `pr-daemon-loop` / `pr-daemon-status` / `pr-fix` skill 就是这套 daemon 的实现。pilot 与之衔接而非重造：pilot 负责「造 PR + 收回执 + 合并」，pr-daemon 负责「review + 裁决」。
