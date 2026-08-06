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

- [x] FU-1 · B · src=PR#39 review [Low] · 2026-08-05 · git-guard merge-pr 拒绝 gh flag 用的是黑名单(--admin/--repo/-R 及其粘连形式)。黑名单追不上新 flag —— 以后 gh pr merge 若新增能绕过分支保护的 flag,这里不会自动知道。改成白名单(只放行 --squash/--merge/--rebase 等已知安全 flag)更耐久 · done=PR#47
- [x] FU-2 · B · src=2026-08-05 合并 #38/#39/#40/#41 后实测 · 2026-08-05 · safe-cleanup.sh 在 squash-merge 仓库里永远清不掉任何分支:本仓库 28 个本地分支,git branch --merged main 返回 0 个,因为 squash 后原 commit 不是 main 的祖先,而 safe-cleanup 只用 -d 永不 -D。这是继 #39(死代码)、#40(随机红灯)之后同一家族的第三个『守卫跑不起来』。正确改法:用 gh 核实『存在 headRefName==该分支且 state==MERGED 的 PR』作为已合并证据,再允许 -D;不能简单放开 -D · done=PR#45
- [x] FU-3 · C · src=PR#42 review [Low] · 2026-08-05 · check-version-sync.sh 只比对 plugin.json 与 SKILL.md 两处。今天 README 没有硬编码版本号(核过),所以没问题;但哪天 README 加上版本,这条守卫不会知道。在脚本里写一句把范围钉住:『目前只有这两处声明版本』 · done=PR#43
- [x] FU-4 · B · src=PR#42 review [Low] + 2026-08-05 清理 28 个分支的实测 · 2026-08-05 · 补充 FU-2 的实现要点(今天手工做过一遍,算法已验证):① git branch --merged 和 git cherry 在 squash 仓库里【全部失效】—— cherry 对 12 个分支全报『未在 main』,因为 squash 重写补丁、patch-id 永不匹配;② 可用判据是『本地 tip == 或 是 任何一个已合并 PR 的 headRefOid 的祖先』,要先 git fetch origin pull/N/head 把 head 抓到本地;③ 【不能只按分支名匹配 PR】—— work-pr18 / fix-pr18-round2 / worktree-agent-* 这三个分支名从没当过 PR head,但 tip 就是 PR#18/#23 的已合并 head,按名字匹配会漏掉;④ 反向风险(评审提的):分支名可复用,同名分支删掉重开后内容不同,旧 MERGED PR 仍在 —— 祖先检查恰好挡住这种情况(重开的 tip 不会是旧 head 的祖先),但若改成只按名字匹配就会误删 · done=PR#45
- [ ] FU-5 · B · src=2026-08-05 pilot 端到端测试(doctor+plan) · 2026-08-05 · pilot 的起跑门禁只认 docs_dir 下七个固定文件名,认不出等价(且更完整)的规划源。实测:Brood 的规划在 backlog/(4 个 milestone + 49 个带验收标准的 task + 2 个 ADR),check-docs.sh --strict 报 0/7、run 直接 fail-closed 拒跑;而 plan.md A.3 又明写『已有规划 → 不要重复造』—— 两条同时遵守不可能。本次用 docs/agent/ 做适配层(指向 backlog/ 的视图,不复制内容)绕过去了,但根治要给 check-docs.sh 加可配置规划源(如 .pilot.yml 声明 planning_source: backlog),否则每个用 backlog/issues/Jira 管规划的仓库都会被判未就绪
- [x] FU-6 · C · src=2026-08-05 pilot 端到端测试(doctor) · 2026-08-05 · doctor 第 4 步在单主干仓库里会误导:无 .pilot.yml 时默认 integration_branch=preview,doctor 发现它不存在就『提示先建』—— 但对单主干仓库正确答案是 integration_branch=main + 合并时用 --allow-trunk,不是去建一个 preview 分支。doctor 不知道这两件事是连着的。改法:检测到 preview 不存在但 default branch 存在时,提示单主干配置法并指向 --allow-trunk · done=PR#48
- [ ] FU-7 · B · src=2026-08-05 从 PR#45 拆出 PR#47 时实测 · 2026-08-05 · 『dist/ matches a fresh build』这条 CI 检查会随日期自己变红,与代码无关。实测:在 main(5549b8b)上不改任何代码只跑一次 preflight,dist/api/statistics.json 就变了 —— averageTaskAge 98→99,那是按天算的任务平均年龄。也就是说 main 放几天不动,下一个 PR 无论改什么都要顺带提交一次无关的 dist 变更,否则红灯。这是继 #39(死代码)、#40(随机红灯)、FU-2(守卫清不掉东西)之后同一家族的第四个『守卫自己不可靠』。改法二选一:① 比对时把时间派生字段(averageTaskAge、recentActivity 里的相对时间)剔除再 diff;② 导出时就不把这类字段写进 dist。⚠️ pilot 冻结期内不做,记账待解冻
- [x] FU-7 **撤回(误报)** · 2026-08-05 同日核实 · append-only 不删行,所以更正写在这里:**这条不成立,不要去修。** verify.yml 第 96–122 行**已经**在比对前把 `averageTaskAge` pin 到 `git show HEAD:` 里的 committed 值(正是 PR#40『归一化那一个字段』做的,注释里连 04:15 UTC 测到 98、十五分钟后 99 都记了),所以 CI 不会因它变红。我立 FU-7 时只看到本地 `git status` 有 diff 就下了结论,没读 CI 脚本 —— **本地 dist 会漂 ≠ CI 会红**,这两件事被我混成一件。真实结论:本地跑完 build 看到 statistics.json 变了,**不需要**提交,CI 会自己 pin 掉。教训比这条 bug 本身有用:报「守卫不可靠」之前先读那个守卫的实现,别只看症状 · done=PR#47(撤回)
- [ ] FU-8 · B · src=PR#47 review R3(Codex)+R4 建议 · 2026-08-05 · **每个守卫必须校验自己的选择器,而不只是 flag** —— 这条纪律要写进 reference/。来源:PR#47 的白名单把 gh flag 管得很严(不认识就拒),却从没看过 merge-pr 的第一个位置参数,而 `gh pr merge` 接受 `[<number>|<url>|<branch>]`,URL 选择器完全无视 `--repo`(gh 2.92.0 实测),于是所有闸门读本仓库、合并落到另一个仓库。已在 PR#47 修掉那一处实例(选择器必须是纯数字),但**纪律本身没落地**,下一个守卫照样可能只查 flag。这是本仓库同一家族的第五个:#39 死代码 / #40 随机红灯 / FU-2 清不掉东西 / FU-7(我自己的误报) / 本条 —— 共同形状是『读起来很严、但有一个输入它从来不检查』。落地时和 #45 一起收口,不要再往 PR#47 里加东西(它被拆出来就是因为 #45 装了四件事)
- [ ] FU-9 · B · src=PR#45 review R4 [Low] · 2026-08-05 · safe-cleanup 的 §3(--remote)只用 `git branch -r --merged` 找候选,而那个判据在 squash 仓库里按构造恒返回 0 行 —— 也就是说在【这个功能存在的理由所指的那种仓库形态里,第 3 节是死代码】,而 run.md 又把 --remote 写成合并后的远程清理手段。--squash-merged 没有延伸到远程。第五轮先只让它把话说清楚(为空时打印『没查,不是没有』,并指向手工清理 / GitHub auto-delete),没有实现远程的证据检查 —— 那要对每个远程分支再花一次 gh 调用,且远程路径没有 -d 兜底,风险高于本地,值得单独一个 PR 想清楚。这是同一家族的第六个『守卫在它最该起作用的场景里跑不起来』(#39 死代码 / #40 随机红灯 / FU-2 清不掉 / FU-7 我的误报 / FU-8 只查 flag 不查选择器 / 本条)
- [x] FU-2/FU-4 **收敛(2026-08-06)** · append-only 不删行,所以改法写在这里:**squash 清理最终只『列』不『删』**。PR#45 在这个能力上走了六轮评审,每轮都挖出实测复现的真缺陷(同名 tag 劫持→删掉未合并分支 / 恢复句柄打印另一个分支名(bash 3.2 的 local 语义) / 丢掉 git 自带的 worktree 占用拒绝 / TOCTOU / 拿本地判据在服务端删掉同事未合并的工作)。没有一条是评审吹毛求疵。**结论不是防得更严,而是:自动执行不可逆删除、判据又必须从服务端推断,所需的把握程度配不上它买到的东西 —— 它买到的只是不用敲 `git branch -D <名字>`。那六个缺陷全是「删」的属性,不是「列」的属性。** 所以脚本做难的那半(逐条给出合并证据),不可逆的那半留给人;远程分支交给 GitHub auto-delete-on-merge。FU-9(远程在 squash 仓库里是死代码)一并作废 —— 那一节现在也只列不删 · done=PR#45
- [ ] FU-10 · C · src=PR#45 第八轮 [Low] · 2026-08-06 · **注释与文档漂移(收口时未清)**:safe-cleanup.sh 里若干注释仍在引用已删掉的东西 —— :150-151 / :247 / :317 提到 `update-ref` 的 expected-old-value(那个函数已删)、:501 附近说 §3「deletes on the SERVER」(已改成完全不处理)。另外 run.md:76 写「不加 --delete-branch,远程分支删除统一交给 safe-cleanup」,但 safe-cleanup 已不处理远程、git-guard 又硬拒 --delete-branch,于是**远程 head 分支的清理在文档流程里没有主人**,只剩 GitHub 的 auto-delete-on-merge,而 skill 既不检查该设置是否打开、也没在任何地方教人去开。改法:清一遍过时注释;在 doctor 里加一条只读检查「本仓库是否开了 auto-delete-on-merge」并在关闭时提示
- [ ] FU-11 · C · src=PR#45 第八轮 [Low] · 2026-08-06 · §1b 现在是个纯报告,但计价没变:每个候选分支一次 gh API 调用(本仓库约 25 次 / 20.6 秒),而 status.md 让它在**每次** `pilot status` 都跑。改法二选一:① 按 tip sha 做本地缓存(tip 没动就不重查);② 在 status.md 里把 `--squash-merged` 改成显式 opt-in,默认不带
- [ ] FU-12 · C · src=PR#45 第八轮 [Low] · 2026-08-06 · §1b 会把「某个活着的 worktree 正在 rebase/bisect 的分支」当成游离分支列出来并打印 `git branch -D <b>`,而同一次运行里 §2 对那个 worktree 打的是 KEEP —— **同一份输出自相矛盾**。已验证无害(git 2.50 会拒绝 `cannot delete branch 'x' used by worktree`,分支完好,rebase --continue 正常),所以只是输出问题。顺带记一句:这也说明删掉 `ref_in_use_by_worktree` 是对的 —— `git branch -D` 自带那个拒绝,而 `update-ref -d` 没有

