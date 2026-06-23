# 新員工 VPN 接入指南

> 5 分鐘完成開發環境接入，連接公司內部網絡

---

## 你是誰？

這份指南適用於：新入職的開發者，需要連接到泰國開發服務器做代碼開發。

---

## 第 1 步：安裝 NetBird 客戶端

### macOS

```bash
brew install netbirdio/netbird/netbird
```

### Windows

打開 PowerShell（管理員模式），運行：

```powershell
Invoke-WebRequest -Uri https://pkgs.netbird.io/install.ps1 | Invoke-Expression
```

### Linux (Ubuntu/Debian)

```bash
curl -fsSL https://pkgs.netbird.io/install.sh | bash
```

---

## 第 2 步：連接公司 VPN

**管理員會給你一串 Setup Key**，類似這樣：

```
NB-A1B2C3D4E5F6G7H8
```

運行以下命令（替換 `<你的-Setup-Key>`）：

```bash
netbird up \
  --management-url https://vpn.brood.com:33073 \
  --admin-url https://vpn.brood.com \
  --setup-key <你的-Setup-Key>
```

等待約 10 秒，看到 `Connected` 就完成了。

---

## 第 3 步：驗證連接

```bash
# 查看網絡中的所有節點
netbird status

# 應該看到類似：
# Peers:
#  ✓ thailand-dev-server  (100.64.0.1)  — Direct
#  ✓ alice-macbook         (100.64.0.5)  — Direct
```

```bash
# 測試連接到泰國開發服務器
ping 100.64.0.1

# SSH 登錄泰國服務器
ssh your-username@100.64.0.1
```

---

## 第 4 步：開始開發

```bash
# Git clone 代碼
git clone ssh://git@100.64.0.1:/home/git/repos/your-project.git

# 或通過機器名訪問
git clone ssh://git@thailand-dev-server:/home/git/repos/your-project.git
```

---

## 常見問題

### Q: 顯示 "Connection failed"

檢查：
1. 網絡是否正常（能上網）
2. Setup Key 是否過期（聯繫管理員要新的）
3. 公司防火牆是否阻斷（嘗試切換網絡環境）

### Q: 連接成功但 ping 不通

可能是 ACL 策略問題，聯繫管理員確認你的帳號有訪問權限。

### Q: 延遲很高

- 中國南方 ↔ 泰國正常約 60-80ms
- 中國北方 ↔ 泰國正常約 100-150ms
- 如果更高，聯繫管理員檢查是否需要切換協議

---

## 注意事項

- **Setup Key 是個人專用的，不要分享給其他人**
- 離職時管理員會撤銷你的帳號，VPN 會立即失效
- 僅用於工作相關的開發活動
- 遇到問題 → 聯繫管理員：[管理員聯繫方式]

---

> 最後更新：2026-06-23
> 管理後台：https://vpn.brood.com（僅管理員可訪問）
