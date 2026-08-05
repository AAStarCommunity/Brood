# Follow-ups ledger（append-only · 永不删行 · 提交进仓库）

> pilot 的 review triage 把「真问题但不阻塞（B）」和延后项记在这里。
> 主线 task 全部完成后，由 `pilot run` 批量合成一个 cleanup PR 做掉，逐条标 [x] done=PR#n。
> `- [ ]`=OPEN，`- [x]`=DONE。GitHub PR comment 是永久兜底。

- [ ] FU-1 · B · src=PR#39 review [Low] · 2026-08-05 · git-guard merge-pr 拒绝 gh flag 用的是黑名单(--admin/--repo/-R 及其粘连形式)。黑名单追不上新 flag —— 以后 gh pr merge 若新增能绕过分支保护的 flag,这里不会自动知道。改成白名单(只放行 --squash/--merge/--rebase 等已知安全 flag)更耐久
- [ ] FU-2 · B · src=2026-08-05 合并 #38/#39/#40/#41 后实测 · 2026-08-05 · safe-cleanup.sh 在 squash-merge 仓库里永远清不掉任何分支:本仓库 28 个本地分支,git branch --merged main 返回 0 个,因为 squash 后原 commit 不是 main 的祖先,而 safe-cleanup 只用 -d 永不 -D。这是继 #39(死代码)、#40(随机红灯)之后同一家族的第三个『守卫跑不起来』。正确改法:用 gh 核实『存在 headRefName==该分支且 state==MERGED 的 PR』作为已合并证据,再允许 -D;不能简单放开 -D
