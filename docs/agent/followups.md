# Follow-ups ledger（append-only · 永不删行 · 提交进仓库）

> pilot 的 review triage 把「真问题但不阻塞（B）」和延后项记在这里。
> 主线 task 全部完成后，由 `pilot run` 批量合成一个 cleanup PR 做掉，逐条标 [x] done=PR#n。
> `- [ ]`=OPEN，`- [x]`=DONE。GitHub PR comment 是永久兜底。

> **⚠️ 更正（append-only 不删行，所以更正写在这里）**
>
> **FU-2 末尾给的判据是错的，不要照它实现。** 它写的是「存在 `headRefName==该分支` 且
> `state==MERGED` 的 PR」——**只按分支名匹配会同时犯两个错**：
> ① 漏删（`work-pr18` / `fix-pr18-round2` / `worktree-agent-*` 的分支名从没当过 PR head，
> 但它们的 tip 就是 PR#18/#23 的已合并 head）；
> ② 误删（分支名可复用，同名分支删掉重开后内容全不同，旧的 MERGED PR 仍然是 MERGED）。
>
> **以 FU-4 的判据为准**：本地 tip **==** 或 **是任何一个**已合并 PR 的 `headRefOid` 的祖先
> （先 `git fetch origin pull/N/head` 把 head 抓到本地再算祖先）。这一条同时挡住上面两种错。
>
> **⚠️ 再更正（实现时找到更好的）**：FU-4 的祖先算法是对的，但**实现用的不是它**。
> GitHub 有 `GET /repos/{owner}/{repo}/commits/{sha}/pulls`，直接回答「哪个 PR 把这个 commit
> 引入了仓库」。它同样按 commit 判、两种错都没有，而且**每个分支只要一次 API 调用**、
> 不用把所有 PR head 抓到本地 —— dry-run 因此保持零写入。四种形状实测通过：
> squash 后的 head ✓、分支中间的 commit ✓、CLOSED 未合并 → 无证据 ✓、从未开过 PR → 无证据 ✓。
> 落地在 `safe-cleanup.sh` 的 `merged_pr_for()`。

- [ ] FU-1 · B · src=PR#39 review [Low] · 2026-08-05 · git-guard merge-pr 拒绝 gh flag 用的是黑名单(--admin/--repo/-R 及其粘连形式)。黑名单追不上新 flag —— 以后 gh pr merge 若新增能绕过分支保护的 flag,这里不会自动知道。改成白名单(只放行 --squash/--merge/--rebase 等已知安全 flag)更耐久
- [ ] FU-2 · B · src=2026-08-05 合并 #38/#39/#40/#41 后实测 · 2026-08-05 · safe-cleanup.sh 在 squash-merge 仓库里永远清不掉任何分支:本仓库 28 个本地分支,git branch --merged main 返回 0 个,因为 squash 后原 commit 不是 main 的祖先,而 safe-cleanup 只用 -d 永不 -D。这是继 #39(死代码)、#40(随机红灯)之后同一家族的第三个『守卫跑不起来』。正确改法:用 gh 核实『存在 headRefName==该分支且 state==MERGED 的 PR』作为已合并证据,再允许 -D;不能简单放开 -D
- [ ] FU-3 · C · src=PR#42 review [Low] · 2026-08-05 · check-version-sync.sh 只比对 plugin.json 与 SKILL.md 两处。今天 README 没有硬编码版本号(核过),所以没问题;但哪天 README 加上版本,这条守卫不会知道。在脚本里写一句把范围钉住:『目前只有这两处声明版本』
- [ ] FU-4 · B · src=PR#42 review [Low] + 2026-08-05 清理 28 个分支的实测 · 2026-08-05 · 补充 FU-2 的实现要点(今天手工做过一遍,算法已验证):① git branch --merged 和 git cherry 在 squash 仓库里【全部失效】—— cherry 对 12 个分支全报『未在 main』,因为 squash 重写补丁、patch-id 永不匹配;② 可用判据是『本地 tip == 或 是 任何一个已合并 PR 的 headRefOid 的祖先』,要先 git fetch origin pull/N/head 把 head 抓到本地;③ 【不能只按分支名匹配 PR】—— work-pr18 / fix-pr18-round2 / worktree-agent-* 这三个分支名从没当过 PR head,但 tip 就是 PR#18/#23 的已合并 head,按名字匹配会漏掉;④ 反向风险(评审提的):分支名可复用,同名分支删掉重开后内容不同,旧 MERGED PR 仍在 —— 祖先检查恰好挡住这种情况(重开的 tip 不会是旧 head 的祖先),但若改成只按名字匹配就会误删
