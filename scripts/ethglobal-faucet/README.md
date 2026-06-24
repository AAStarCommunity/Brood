# ETHGlobal Faucet — 每日自動領取機器人

> 每天自動從 [ETHGlobal Faucet](https://ethglobal.com/faucet/) 領取 18 條測試鏈的測試幣
> 為 Brood 團隊提供穩定測試網 token 供給

## 架構

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   setup.js      │ ──► │  browser-profile/ │ ◄── │   claim.js      │
│  (一次性 30s)    │     │  (完整 Profile)   │     │  (每天 cron)     │
│                 │     │                  │     │                 │
│ 複製 Chrome     │     │ Cookies          │     │ headless        │
│ Default Profile│     │ IndexedDB        │     │ 掃描 18 條鏈     │
│ 手動登錄一次    │     │ Local Storage    │     │ 逐鏈 Claim       │
│ 驗證後保存     │     │ Session Storage  │     │ 記錄 CD 時間     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

**技術棧**: Playwright + playwright-extra (Stealth Plugin) + Chrome Profile 複製
**繞過挑戰**: Cloudflare 防機器人 (Stealth + channel:chrome)、ETHGlobal 登錄態持久化

## 開發歷程

### 嘗試過的路徑

| 嘗試 | 方法 | 結果 |
|:---|:---|:---|
| 1 | Playwright 開空白 Chrome → 手動登錄 | ❌ 用戶不想重登 |
| 2 | CDP 連接到已有 Chrome | ❌ macOS 禁止在預設 profile 開 debug port |
| 3 | 複製 Profile + CDP | ❌ Chrome 要求非預設 user-data-dir |
| 4 | Playwright persistent context + 部分 profile 複製 | ⚠️ 列表頁 ok，detail 頁無登錄態 |
| 5 | **完整 Profile 複製 + Playwright persistent context** | ✅ 當前方案 |

### 方案 5 原理

1. **setup.js**: 關閉 Chrome → 複製完整 `Default/` profile（Cookies + IndexedDB + Session + Service Workers）到 `browser-profile/` → 用 Playwright 打開驗證 detail 頁登錄態
2. **claim.js**: 用 `launchPersistentContext` + `channel: 'chrome'` + Stealth Plugin → headless 模式 → 掃描列表頁 → 逐鏈點擊 Claim
3. 每 23.5h 自動 CD 追蹤，跳過未到時間的鏈

## 使用

### 前置條件

- macOS + Chrome（已用 jhfnetboy@gmail.com 登錄 ETHGlobal）
- Node.js 18+
- pnpm

### 1. 安裝

```bash
cd scripts/ethglobal-faucet
pnpm install
```

### 2. 初次設置（30 秒，只需一次）

```bash
node setup.js
```

流程：
1. 腳本自動關閉 Chrome
2. 複製你完整的 Chrome Profile 到 `browser-profile/`
3. 打開瀏覽器驗證
4. 如果 detail 頁面顯示 "Login to access faucet" → 手動登錄一次 → 按 Enter
5. 保存 session，重開 Chrome

### 3. 測試

```bash
node claim.js --dry-run          # 模擬掃描，不點擊
node claim.js --dry-run --headed # 顯示瀏覽器窗口
node claim.js --chain sepolia-11155111-eth --dry-run  # 單鏈測試
```

### 4. 正式領取

```bash
node claim.js                    # 全部可領取鏈
node claim.js --chain sepolia-11155111-eth  # 單鏈
node claim.js --headed           # 顯示窗口調試
```

### 5. 每日定時

```bash
crontab -e
# 每天上午 10:01（留 30min buffer 給 24h CD）
1 10 * * * /Users/jason/Dev/Brood/scripts/ethglobal-faucet/daily-claim.sh
```

## 支持的鏈（18 條 Available）

| 鏈 | 每日額度 |
|:---|:---|
| Ethereum Sepolia | 0.05 ETH |
| Ethereum Sepolia (USDC) | 1 USDC |
| Optimism Sepolia | 0.05 ETH |
| Base Sepolia | 0.05 ETH |
| Zora Sepolia | 0.05 ETH |
| Arbitrum Sepolia | 0.05 ETH |
| zkSync Sepolia | 0.05 ETH |
| Polygon Amoy | 0.05 POL |
| Scroll Sepolia | 0.05 ETH |
| Filecoin Calibration | 0.05 FIL |
| Gnosis Chiado | 0.05 XDAI |
| ApeChain Testnet | 0.05 APE |
| World Chain Sepolia | 0.05 ETH |
| Unichain Sepolia | 0.05 ETH |
| Zircuit Garfield Testnet | 0.05 ETH |
| Citrea Testnet | 0.005 CBTC |
| Flow EVM Testnet | 0.05 FLOW |
| Celo Sepolia | 0.05 CELO |

## 容錯設計

| 場景 | 處理 |
|:---|:---|
| Cloudflare 挑戰 | Stealth Plugin + channel:chrome 繞過 |
| Unavailable 鏈 | 掃描階段自動過濾 |
| Claim 按鈕 disabled | 跳過並記錄 |
| 點擊後長時間無響應 | 2 分鐘超時 |
| 登錄態過期 | 中斷並報錯（需重跑 setup.js） |
| 網絡超時 | load → domcontentloaded 降級 |

## 日誌

`logs/claim-YYYYMMDD-HHMMSS.log`，保留 30 天。

`claim-log.json` 記錄每條鏈的上次領取時間。

## 相關文件

- `package.json` — 依賴
- `setup.js` — 一次性環境設置
- `claim.js` — 每日領取核心
- `daily-claim.sh` — cron wrapper
- `browser-profile/` — Chrome Profile 副本（.gitignore）
- `claim-log.json` — CD 追蹤
- `logs/` — 運行日誌

## 故障

| 問題 | 解決 |
|:---|:---|
| `未找到 browser-profile/` | `node setup.js` |
| detail 頁面顯示需登錄 | `node setup.js`，在打開的瀏覽器中手動登錄 |
| Cloudflare "Just a moment" | 檢查 stealth plugin 是否安裝: `pnpm install` |
| 0 條鏈被發現 | `node claim.js --headed` 可視化調試 |
