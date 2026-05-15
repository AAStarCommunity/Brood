# UI Module Spec v0.1（UI 接入规范草稿）

> 版本：v0.1（**草稿**） · 最后更新：2026-05-15
> 状态：⚠️ **此规范处于早期阶段，会随首批 UI 接入项目实际反馈持续演进**
> 适用：选择 `integration.type: "ui-module"` 接入 AgentStore 的项目

---

## 1. 设计哲学

UI Module 规范的目标是让**普通 Web 应用作品**（PPT 工具、电子宠物、绘图工具等）能以**最小改造**接入 AgentStore，同时为 Store 提供**一致的用户体验**。

我们刻意**不过度规范**。规则只覆盖三件事：

1. **进入点**：作品在 Store 中应该出现在哪里
2. **基础元素**：哪些 UI 元素必须存在（如登录态、声誉显示）
3. **退出点**：用户如何回到 Store 首页

其余 UI 设计（颜色、布局、字体）**完全由作者自由发挥**。

---

## 2. 必备结构（最小契约）

每个 UI Module 必须 export 三个对象：

```typescript
// 你的 index.ts / main.js 必须 export:
export interface PGLUIModule {
  // 1. 元数据
  metadata: {
    slug: string;             // 与 pgl.yml 中的 work.slug 一致
    title: string;
    icon: string;             // URL 或 SVG 字符串
    short_description: string;
  };

  // 2. 挂载函数
  mount(container: HTMLElement, context: PGLContext): UnmountFn;

  // 3. 卸载函数（用户离开时调用）
  // 由 mount 返回，必须释放所有资源（事件监听、定时器、网络连接）
}

type UnmountFn = () => void;

interface PGLContext {
  // Store 注入的上下文
  user: {
    airaccount: string | null;  // 用户 AirAccount 地址（未登录时 null）
    ens: string | null;
    locale: "zh" | "en";
  };
  store: {
    api_base: string;           // Store API 基础 URL
    back_to_home: () => void;   // 调用此函数返回 Store 首页
  };
  payments: {
    // 用 SuperPaymaster 发起付费的标准接口
    request_payment: (amount_pnts: number, purpose: string) => Promise<PaymentReceipt>;
  };
  telemetry: {
    // 上报使用事件（用于声誉累积）
    record_event: (event: "open" | "use" | "complete" | string) => void;
  };
}
```

---

## 3. 必备 UI 元素

每个 UI Module 必须在可见区域包含以下三个元素：

### 3.1 顶部导航条（Store 注入，作者无需自己实现）

Store 自动在 iframe 顶部注入一条 32px 高的导航条，包含：

- 左侧：**返回 Store** 按钮
- 中间：**作品 title** + **作者署名**（点击跳转作者主页）
- 右侧：**用户头像**（点击进入用户中心）

**作者只需保证自己的 UI 不与顶部 32px 区域冲突**。

### 3.2 作者署名区（作者自己实现）

在作品 UI 内部任意位置，必须有不可隐藏的署名区，至少包含：

- 作者名称（与 pgl.yml `signed_by.name` 一致）
- 原仓库 GitHub 链接（与 pgl.yml `work.homepage` 一致）
- "本作品基于 [数字公共物品公约](...) 发布" 字样

Store 在审核时会检查这部分内容。**抹掉署名 = 失去推荐位**。

### 3.3 反馈与声誉触发点（作者实现，Store 提供组件）

UI 中至少包含一个明显的"点赞 / 评价"入口，调用：

```typescript
context.telemetry.record_event("endorsement");
```

或使用 Store 提供的预制组件：

```html
<pgl-endorse-button data-slug="awesome-pdf-scanner"></pgl-endorse-button>
```

---

## 4. 推荐布局（参考，非强制）

```
┌────────────────────────────────────────────┐
│ ← Store · Awesome PDF Scanner · @alice  👤│  ← Store 注入（32px）
├────────────────────────────────────────────┤
│                                            │
│           [ 作品自由布局区域 ]              │
│                                            │
│                                            │
│                                            │
├────────────────────────────────────────────┤
│  作者: Alice · github.com/alice/...       │  ← 必备署名区
│  基于「数字公共物品公约」发布 · 👍 给作者点赞 │
└────────────────────────────────────────────┘
```

---

## 5. 框架支持矩阵

| 框架 | 状态 | 备注 |
|:---|:---:|:---|
| React 18+ | ✅ 支持 | 推荐 |
| Vue 3+ | ✅ 支持 | 推荐 |
| Svelte 4+ | ✅ 支持 | |
| Vanilla JS | ✅ 支持 | 最轻量 |
| Solid.js | ⚠️ 实验性 | |
| 其他 SPA 框架 | ⚠️ 实验性 | 需自行验证生命周期兼容 |

---

## 6. 沙箱与安全

每个 UI Module 在 iframe 中以下列 `sandbox` 属性运行：

```html
<iframe sandbox="allow-scripts allow-forms allow-popups-to-escape-sandbox allow-same-origin">
```

**禁止行为**：
- 访问 `parent.window`（除通过 `context` API）
- 跨域 cookies
- 自动重定向到外部域名
- 加载 ad-tech / 追踪脚本

违规模块将被自动下架。

---

## 7. 演进路径

| 版本 | 计划 | 时间 |
|:---|:---|:---|
| **v0.1** | 当前规范，最小契约 | 已发布 |
| v0.2 | 加入移动端响应式约束 | Q3 2026 |
| v0.3 | 加入暗色模式标准 | Q3 2026 |
| v0.4 | 加入国际化标准（i18n） | Q4 2026 |
| v1.0 | 稳定版 | 2027 |

**变更原则**：规范升级**向后兼容**。v0.1 模块在 v1.0 Store 中仍可运行。

---

## 8. 反馈渠道

UI 接入是 PGL 中**最不成熟**的部分。我们极度欢迎首批接入项目反馈：

- 在 Brood 仓库提 issue：`https://github.com/AAStarCommunity/Brood/issues`
- 标签：`pgl-ui-module-feedback`
- 你的反馈会直接影响 v0.2 规范方向

---

## 9. 完整示例

```tsx
// my-pdf-scanner/src/main.tsx
import { createRoot } from 'react-dom/client';
import type { PGLUIModule, PGLContext, UnmountFn } from '@mycelium/pgl-types';
import App from './App';

const module: PGLUIModule = {
  metadata: {
    slug: "awesome-pdf-scanner",
    title: "Awesome PDF Scanner",
    icon: "/icon.svg",
    short_description: "一键 PDF → Markdown",
  },

  mount(container: HTMLElement, context: PGLContext): UnmountFn {
    const root = createRoot(container);
    root.render(<App context={context} />);
    
    return () => {
      root.unmount();   // 必须清理
    };
  },
};

export default module;
```
