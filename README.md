# BroodBrain Backlog

这是一个基于 `backlog.md` 打造的纯静态、只读版本项目发布系统。

## 纯静态发版只读系统导出方案

我们已经抛弃了之前产生严重排版不一致问题的 Vitepress 方案，转而编写了一个基于 backlog browser 本地浏览器的自动化打版抓取脚本。这样能保证 **100% 保留原来的原生 UI 展示效果**。

同时为了满足“优雅展示错误、防止被他人修改”的要求，脚本中注入了前端防篡改保护器。

### 本方案核心设计思想：本地构建、直推发版
为了节省 GitHub 云端的计算资源（省钱且避免浪费免费的 CI 通道）、加快构建速度和避免复杂的云端环境依赖配置，本方案采用的是**本地执行运算，GitHub 原样发版**的机制：
所有的 `HTML/JS/CSS/API JSON` 生成和抓取均在你的本地电脑瞬间完成，而后直接随源代码 PUSH 到代码库中供 GitHub Pages 发布。

## 绝对的防篡改安全性 (Zero-Backend Security)
**您完全不用担心黑客通过 HTTP 请求（如 Postman、CURL 等）绕过前端按钮来删改文件。**

因为我们导出并且托管在网上的 `dist/` 文件夹**仅仅是一堆静态的 HTML、CSS 和只读的 JSON 文本文件**。网上的代码库**根本不存在所谓的“后端”**或者 Node.js 运行环境！
当前端或者黑客试图对这些静态文件发起 `POST`, `PUT`, `DELETE` 等修改请求时，GitHub Pages 或 Cloudflare 的 CDN 服务器在底层会直接返回 `405 Method Not Allowed` 或是 `404 Not Found`。攻击者即便分析透了代码，也面对的是一堵死墙，因为后端修改大门早就被物理“拆除”了。

## 发布指南指引 (Deployment)

### 选项 A：发布到 GitHub Pages (默认开启)
由于我们配置了 Github Actions 工作流：
每一次你修改了任务或者文档，只需要在本地：
1. **生成静态快照**：
   ```bash
   pnpm run build
   ```
2. **（可选）本地预览**：
   ```bash
   pnpm run preview
   # 或者直接运行 npx serve dist
   ```
   这会启动一个本地服务器供你查看发布后的只读排版和气泡效果。

3. **推送代码至主分支**：
   ```bash
   git add .
   git commit -m "update tasks or docs"
   git push
   ```
云端会自动检测您的推送，并将 `dist/` 目录的内容极其快速地直接推向 GitHub Pages。

### 选项 B：发布到 Cloudflare Pages
通过 Cloudflare 有两种极简的发布方式：

**方式一：CLI 命令行直推（本地直发）**
如果您急需将当前本地计算好的 `dist` 直接糊到 Cloudflare 上，只需运行我们内置的脚本（需要您以前登录过 wrangler）：
```bash
pnpm run deploy:cf
```
首次运行会提示您登录 Cloudflare 并一键上传。

**方式二：Cloudflare 后台关联 Github (推荐)**
在 Cloudflare Pages 的网页控制台上：
1. 点击 "Connect to Git"，选中本仓库。
2. 设置 **Build command** 留空或者填入 `echo "No build"` (因为已经本地 build 过了)。
3. 设置 **Build output directory** 为 `dist`。
这样以后你每次 `git push` 给 Github，Cloudflare 也一样会自动拉取 `dist/` 并秒速部署到它的全球 CDN 上。

---

## 上下文体系 / Context Architecture

BroodBrain 是 Mycelium Protocol 的神经系统，通过三层上下文实现跨 repo 协作感知：

### 三层结构

| 层 | 位置 | 内容 | 更新频率 |
|:---|:---|:---|:---|
| **L0** 协议层 | `protocol/` | 使命愿景、生态全景图、加入方式 | 很少（重大方向调整时） |
| **L1** 组织层 | `orgs/{org}/` | 组织名片 (PROFILE.md)、接口规范 (INTERFACES.md) | 偶尔（org 定位/接口变更时） |
| **L2** 仓库层 | 各 repo 的 `CLAUDE.md` | 项目专属说明 + @-include 引用 L0/L1 | 频繁（每次开发自然演进） |

### 数据流

```
┌─────────────────────────────────────┐
│  L0  protocol/MISSION.md            │ ← 很少改，重大方向调整时
│  L1  orgs/{org}/PROFILE.md          │ ← org 定位变化时
│      orgs/{org}/INTERFACES.md       │ ← 接口/依赖关系变化时
└──────────────┬──────────────────────┘
               │ @-include（自动向下传播）
               ▼
┌─────────────────────────────────────┐
│  L2  {repo}/CLAUDE.md               │ ← 每次 repo 开发时自然演进
│      - 系统区（@-include，不动）      │
│      - 项目区（自由更新）             │
└──────────────┬──────────────────────┘
               │ /sync-context-reverse（自动反向回流）
               ▼
┌─────────────────────────────────────┐
│  Brood orgs/ + protocol/            │ ← 版本/接口/状态变更自动同步
└─────────────────────────────────────┘
```

**向下传播**：L0/L1 文件一改，所有 repo 下次启动 Claude Code 时自动生效（@-include 是实时引用）。

**反向回流**：在 Brood 中运行 `/sync-context-reverse`，自动扫描所有 repo 的版本号、接口签名、依赖关系，将变更同步回 INTERFACES.md / PROFILE.md / ECOSYSTEM_MAP.md。

### 初始化新 repo

```bash
# 一条命令接入生态上下文
./scripts/init-brood-context.sh ~/Dev/{org}/{repo} {org-id}
# org-id: aastar | auraai | mycelium
```

### Custom Skills

| Skill | 命令 | 用途 |
|:---|:---|:---|
| **sync-progress** | `/sync-progress` | 扫描 In Progress 任务的 GitHub 进度，更新任务文件 |
| **sync-context-reverse** | `/sync-context-reverse` | 反向同步接口/版本/状态变更到 Brood |
| **license-update** | `/license-update` | Apache 2.0 + NOTICE + TRADEMARK 合规检查与批量同步 |

详见 `CONTEXT-INHERIT.md`。

---

## Local plist
-   # 查看状态（PID 和退出码）
  launchctl list | grep backlog

  # 停止
  launchctl stop com.jason.backlog-browser

  # 启动
  launchctl start com.jason.backlog-browser

  # 重启（stop + start）
  launchctl stop com.jason.backlog-browser && launchctl start com.jason.backlog-browser

  # 完全卸载（停止并移除）
  launchctl unload ~/Library/LaunchAgents/com.jason.backlog-browser.plist

  # 重新加载 plist（修改 plist 后用这个）
  launchctl unload ~/Library/LaunchAgents/com.jason.backlog-browser.plist
  launchctl load ~/Library/LaunchAgents/com.jason.backlog-browser.plist

  # 查看日志
  tail -f /tmp/backlog-browser.out.log
  tail -f /tmp/backlog-browser.err.log


