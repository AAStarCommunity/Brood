# 外部文档源接口契约（飞书 / Notion）

需求、设计、验收标准常常**不在仓库里** —— 在飞书云文档或 Notion 页面上。这份契约说明
pilot 怎么用它们，以及**不做什么**。

## pilot 不拥有这些能力

和 [`review-contract.md`](review-contract.md) 是同一个原则:

> pilot **不安装、不启动、不封装**任何文档源。它只在运行时**探测**能力是否存在,
> 有就用,没有就降级。装没装、装在哪、用哪个账号,都是环境的事,不是 pilot 的事。

原因很实际:pilot 会装到很多仓库、很多机器上。把飞书/Notion 的具体调用写进 pilot,
等于让每一台没配 token 的机器都带着一个坏掉的依赖 —— 这正是 pr-daemon 那次耦合的教训。

**这些能力是全局 skill,不是 pilot 的一部分。** 任何仓库、任何会话都能直接用它们,
不需要先进 pilot;pilot 只是在 `plan` / `run` 需要外部需求文档时**指个路**。

## 探测(机械的,不要凭印象)

| 源 | 可用的判据 | 命令 |
|:---|:---|:---|
| **飞书** | `lark-cli` 存在 **且** user 身份 `ready` | `lark-cli auth status --json --verify` → `identities.user.status` |
| **Notion** | integration token 存在且 `users/me` 返回 200 | `GET https://api.notion.com/v1/users/me` |

飞书那条的**关键**:`identity` 显示 `bot` 不代表能读你的文档。bot 身份只能看
「共享给这个应用的东西」,**读用户自己的云文档必须 user 身份**。
只看 `ok: true` 或 `bot: ready` 就当作可用,是这份契约里最容易犯的错。

user 身份缺失时的补法(要用户在浏览器里点):

```bash
lark-cli auth login --domain docs,drive,wiki --no-wait --json   # 拿 verification_url
lark-cli auth login --device-code <上一步的 device_code>          # 用户授权后收尾
```

Notion 的对应坑:token 有效 **≠** 能看到目标页面。Notion integration 只能看到
**显式 share 给它的页面**,`/v1/search` 返回的就是全部可见范围 —— 少了就去 Notion 里
把那一页(或它的父页面)share 给 integration,这一步只能人在 UI 里做。

## pilot 侧只读

`plan` / `run` 从这些源**只读取**,绝不写回。需求文档是人在维护的事实来源,
agent 往里写等于在没人看着的时候改需求。产出要发出去,是**另一件事**,由用户显式发起。

## 拿不到的时候(降级路径)

按顺序,不要停在第一步:

1. **探测失败** → 如实说明缺什么(是没装 CLI、还是 user 身份没授权、还是页面没 share),
   把补齐的命令给出来;
2. **不阻塞** → 请用户把文档内容直接贴进对话,或指一个仓库内的等价文件,照常开工;
3. **绝不猜内容。** 没读到就是没读到 —— 编一份需求文档出来,比没有需求文档危险得多。

> 完全没有外部文档源的仓库是**正常情况**(需求本来就写在 `docs/` 里)。
> 这时这份契约不适用,直接读仓库里的规划文档即可。
