# ETHGlobal Faucet — 每日自動領取機器人

每天自動從 [ETHGlobal Faucet](https://ethglobal.com/faucet/) 領取 18 條測試鏈的測試幣。

## 原理

```
setup.js (一次性)        claim.js (每天定時)
     │                        │
     └──► browser-profile/ ◄──┘
          (Playwright persistent context)
          保存 cookies / localStorage / indexedDB
```

登錄態保存在 `browser-profile/` 目錄，一般能保持 7-30 天。

## 快速開始

```bash
cd scripts/ethglobal-faucet

# 1. 安裝
pnpm install
npx playwright install chromium

# 2. 初次登錄
node setup.js
# → 瀏覽器打開 → 手動登錄 ETHGlobal → 回終端按 Enter

# 3. 測試
node claim.js --dry-run          # 模擬（不點擊）
node claim.js --dry-run --headed # 顯示窗口

# 4. 正式領取
node claim.js                    # 全部可領取
node claim.js --chain sepolia-11155111-eth  # 單鏈
```

## 每日定時任務

```bash
crontab -e
# 每天 10:01（避開整點）
1 10 * * * /Users/jason/Dev/Brood/scripts/ethglobal-faucet/daily-claim.sh
```

## 日誌

`logs/claim-YYYYMMDD-HHMMSS.log`，保留 30 天。

## 故障

| 問題 | 解決 |
|:---|:---|
| 未找到 browser-profile | `node setup.js` |
| 登錄態過期 | `node setup.js` |
| 找不到 Claim 按鈕 | `--headed` 肉眼確認頁面 |
