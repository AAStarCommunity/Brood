# 方案三：Headscale — 自建 Tailscale 控制平面

> 推薦指數：⭐⭐⭐ (生態最成熟，但對中國網絡優化不如 EasyTier)
> 官網：https://headscale.net
> GitHub：https://github.com/juanfont/headscale
> 最新版本：v0.28.0 (2026-02) | Stars: 40,000+

---

## 一、項目背景與原理

### 1.1 是什麼

Headscale 是 Tailscale 控制服務器的開源實現。它實現了 Tailscale 的協調協議（基於 [Tailscale 的 OSS 代碼](https://github.com/tailscale/tailscale)），讓你可以：

- 用 **Tailscale 官方客戶端**（全平台，包括 iOS/Android）
- 但控制平面完全在你自己的服務器上
- Tailscale 的閉源部分（coordination server）被 Headscale 替代

### 1.2 Tailscale 閉源 vs 開源

```
Tailscale 開源部分：
├── 客戶端代碼（client/tailscaled）← BSD 協議
├── WireGuard-go (用戶態) 或 內核 WireGuard
├── DERP 中繼服務器代碼
└── 各種集成庫

Tailscale 閉源部分：
├── Coordination Server (控制平面) ← Headscale 就是替換這個
├── Web 管理儀表板 (admin console)
├── SSO/IdP 集成邏輯
└── 部分 DERP 中繼節點（但你可以自建）

Headscale 做的事情：
├── 重新實現了 coordination server 的協議 ← 主功能
├── 提供 CLI 和基本 Web API 管理
├── 支持 ACL JSON（與 Tailscale 格式兼容）
└── 支持自建 DERP 中繼
```

### 1.3 架構原理

```
┌─────────────────────────────────────────────────────────┐
│                     你的 VPS (香港/新加坡)                │
│                                                         │
│  ┌──────────────────────┐   ┌──────────────────────┐   │
│  │    Headscale         │   │    DERP Server        │   │
│  │    (控制平面)         │   │    (中繼服務器)        │   │
│  │                      │   │                      │   │
│  │  • 協調協議           │   │  • NAT 穿透失敗時      │   │
│  │  • 密鑰分發           │   │    轉發加密流量        │   │
│  │  • ACL 策略           │   │  • 端口 443 (HTTPS)   │   │
│  │  • DNS 配置           │   │  • 無狀態, 不解密      │   │
│  │                      │   │                      │   │
│  │  端口: 443, 50443    │   │  端口: 3478, 443     │   │
│  └──────────┬───────────┘   └──────────┬───────────┘   │
└─────────────┼──────────────────────────┼───────────────┘
              │                          │
        ┌─────┴─────────┐          ┌─────┴─────────┐
        │ Tailscale 客戶端│          │ 數據包轉發     │
        │ (官方, 任何平台) │          │ (加密, 不解密) │
        └───────────────┘          └───────────────┘
              │
    ┌─────────┴──────────┐
    │  P2P WireGuard     │ ← 穿透成功時直連
    │  (不經 VPS)         │
    └────────────────────┘
```

#### 關鍵流程

```
Step 1: 客戶端首次連接
  tailscale up --login-server https://vpn.brood.com
  → 打開瀏覽器 → 登錄 Headscale Web UI → 註冊節點

Step 2: 控制平面同步
  Headscale → 分發網絡配置: "你的 IP 是 100.64.0.5, 
             網絡裡有這些節點: [100.64.0.1: 公鑰A, ...]"
  
Step 3: 節點互連
  Tailscale A ↔ Tailscale B:
    ① 嘗試 UDP 直連 (通過 STUN 獲取公網地址)
    ② 打洞失敗 → 通過 DERP 中繼轉發
    ③ WireGuard 握手 → 加密隧道建立

Step 4: DERP 降級（中國場景常見）
  如果 UDP 被阻斷或 NAT 穿透失敗:
    節點 A → DERP (你的 VPS) → 節點 B
    DERP 只看加密包頭，不解密內容
    延遲 = A→VPS + B→VPS (但至少能用)
```

---

## 二、完整搭建步驟

### 2.1 環境準備

#### 架構規劃

```
┌──────────────────────────────────────────────────────┐
│            VPS (香港/新加坡)                            │
│            Ubuntu 22.04, 2C2G                          │
│            域名: vpn.brood.com                         │
│                                                       │
│  ┌──────────────────┐  ┌──────────────────┐          │
│  │ Headscale        │  │ Caddy (反向代理)   │          │
│  │ :8080            │  │ :443 → :8080      │          │
│  │                  │  │ :50443 → :50443   │          │
│  │ /var/lib/        │  │ Let's Encrypt TLS │          │
│  │   headscale/     │  └──────────────────┘          │
│  │   db.sqlite      │                                │
│  └──────────────────┘                                │
│                                                       │
│  ┌──────────────────┐                                │
│  │ DERP Server      │                                │
│  │ :3478 (STUN)     │                                │
│  │ :443 (DERP)      │ ← 或單獨端口                    │
│  └──────────────────┘                                │
└──────────────────────────────────────────────────────┘
```

### 2.2 步驟一：安裝 Headscale

```bash
# SSH 到 VPS
ssh root@vpn.brood.com

# 方法一：官方安裝腳本（推薦）
curl -fsSL https://raw.githubusercontent.com/juanfont/headscale/main/install.sh | bash

# 方法二：手動下載
HEADSCALE_VERSION="0.28.0"
wget https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_amd64.deb
dpkg -i headscale_${HEADSCALE_VERSION}_linux_amd64.deb

# 方法三：Docker（適合已有 Docker 環境）
# 見下方 Docker 方案
```

### 2.3 步驟二：配置 Headscale

```bash
# 創建配置目錄
mkdir -p /etc/headscale

# 生成默認配置
headscale config > /etc/headscale/config.yaml
```

**編輯 `/etc/headscale/config.yaml`，關鍵配置如下**：

```yaml
# 監聽地址
server_url: https://vpn.brood.com  # ← 改成你的域名
listen_addr: 127.0.0.1:8080       # Headscale 監聽（被 Caddy 代理）
metrics_listen_addr: 127.0.0.1:9090

# TLS (讓 Caddy 處理, Headscale 不直接對外)
tls_letsencrypt_hostname: ""
tls_letsencrypt_cache_dir: ""
tls_cert_path: ""
tls_key_path: ""

# 網絡配置
ip_prefixes:
  - 100.64.0.0/10       # Tailscale 默認 CGNAT 網段
  - fd7a:115c:a1e0::/48 # IPv6 ULA

# DERP 中繼配置
derp:
  server:
    enabled: false       # Headscale 內置 DERP 不啟用(我們單獨部署)
  urls: []               # 不用公共 DERP
  paths:                 # 使用自建 DERP
    - /etc/headscale/derp.yaml
  auto_update_enabled: false
  update_frequency: 24h

# 禁用公共 DERP，強制使用自建中繼
# (Tailscale 默認 DERP 節點都在國外，中國訪問可能很慢或不可達)

# 數據庫
db_type: sqlite3
db_path: /var/lib/headscale/db.sqlite

# ACL
acl_policy_path: /etc/headscale/acl.json

# DNS
dns_config:
  override_local_dns: true
  nameservers:
    - 1.1.1.1          # 或自建 DNS
  domains: []
  magic_dns: true      # 自動為節點分配域名
  base_domain: brood.vpn

# Unix socket (給 CLI 用)
unix_socket: /var/run/headscale/headscale.sock

# 日誌
log:
  format: text
  level: info

# 過期策略
ephemeral_node_inactivity_timeout: 120h  # 臨時節點 5 天不活躍即過期
node_update_check_interval: 10s
```

### 2.4 步驟三：配置 Caddy 反向代理

```bash
# 安裝 Caddy
apt install -y caddy

# 配置 Caddy
cat > /etc/caddy/Caddyfile << 'EOF'
vpn.brood.com {
    # Headscale Web/API
    reverse_proxy localhost:8080
    
    # gRPC (Tailscale 客戶端協議)
    # Tailscale 客戶端會連到 :443 做 gRPC
    @grpc {
        protocol grpc
    }
    reverse_proxy @grpc localhost:50443
    
    # TLS 自動
    tls admin@brood.com
}
EOF

systemctl restart caddy
```

### 2.5 步驟四：部署自建 DERP 中繼

這一步**對中國場景至關重要**。Tailscale 默認的 DERP 節點都在歐美，從中國過去延遲極高。必須自建。

```bash
# 安裝最新的 Tailscale 客戶端（內含 derper）
curl -fsSL https://tailscale.com/install.sh | sh

# 方法一：用 Tailscale 內置的 derper
# 創建 systemd service
cat > /etc/systemd/system/derper.service << 'EOF'
[Unit]
Description=Tailscale DERP Server
After=network.target

[Service]
ExecStart=/usr/sbin/derper \
  -c /var/lib/derper/derper.key \
  -certmode=manual \
  -certdir=/etc/letsencrypt/live/vpn.brood.com \
  -hostname=derp.brood.com \
  -a :3443 \
  -http-port 80 \
  -stun-port 3478 \
  -verify-clients
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 注意：DERP 和 Headscale 用不同的端口
# DERP: :3443 (HTTPS), :3478 (STUN)
# Headscale: :443 (被 Caddy 代理到 :8080)

systemctl daemon-reload
systemctl enable --now derper
```

**創建 DERP 配置文件** (`/etc/headscale/derp.yaml`)：

```yaml
regions:
  900:                         # 自定義 region ID
    regionid: 900
    regioncode: "hk"
    regionname: "Hong Kong Relay"
    nodes:
      - name: "hk1"
        regionid: 900
        hostname: "derp.brood.com"
        ipv4: "<VPS 公網 IP>"
        stunport: 3478
        derpport: 3443
        stunonly: false
```

### 2.6 步驟五：啟動 Headscale

```bash
# 啟用並啟動
systemctl enable --now headscale

# 檢查狀態
systemctl status headscale
# Active: active (running)

# 檢查日誌
journalctl -u headscale -f
```

### 2.7 步驟六：用戶和節點管理

#### 創建用戶（帳號體系）

```bash
# Headscale 的用戶就是 "namespaces"，每個用戶一個 namespace

# 創建管理員用戶
headscale users create admin

# 為團隊創建開發者用戶
headscale users create dev-alice
headscale users create dev-bob
headscale users create dev-charlie

# 查看所有用戶
headscale users list
```

#### 生成註冊密鑰（PreAuth Key）

```bash
# 為 dev-alice 生成一個一次性註冊密鑰（24 小時過期）
headscale preauthkeys create \
  --user dev-alice \
  --expiration 24h \
  --tags "tag:developer"

# 為團隊生成一個可重用的註冊密鑰（180 天過期）
headscale preauthkeys create \
  --user dev-alice \
  --expiration 4320h \
  --reusable \
  --tags "tag:developer,tag:thailand-access"

# 輸出類似: 57f3c8e42a814c2b8...
```

#### 節點註冊流程

客戶端執行 `tailscale up --login-server https://vpn.brood.com` 後：

```bash
# 查看待批准節點
headscale nodes list
# ID | Name              | User    | IP            | Status
# 1  | thailand-server    | (pending) | -             | pending
# 2  | alice-macbook      | (pending) | -             | pending

# 批准節點（手動批准，安全）
headscale nodes register --user dev-alice alice-macbook
headscale nodes register --user admin thailand-server

# 如果用 PreAuth Key 則自動批准
# 客戶端: tailscale up --authkey 57f3c8e42a...

# 查看已批准節點
headscale nodes list
# ID | Name              | User    | IP            | Status
# 1  | thailand-server    | admin   | 100.64.0.1   | online
# 2  | alice-macbook      | dev-alice | 100.64.0.2 | online
```

#### 撤銷用戶/節點（防濫用）

```bash
# 撤銷特定節點
headscale nodes delete --identifier alice-macbook

# 刪除用戶（同時移除其所有節點）
headscale users destroy dev-alice

# 使 PreAuth Key 失效
headscale preauthkeys expire --key 57f3c8e42a...

# 手動斷開某個節點
headscale nodes expire --identifier alice-macbook
```

### 2.8 步驟七：客戶端連接

#### 泰國服務器 (Linux)

```bash
# 安裝 Tailscale 客戶端
curl -fsSL https://tailscale.com/install.sh | sh

# 連接到你的 Headscale 服務器
tailscale up \
  --login-server https://vpn.brood.com \
  --hostname thailand-server \
  --advertise-tags tag:thailand-server

# 如果使用 PreAuth Key（跳過 Web 審批）
tailscale up \
  --login-server https://vpn.brood.com \
  --authkey 57f3c8e42a... \
  --hostname thailand-server
```

#### 中國開發者 A (macOS)

```bash
# 安裝 Tailscale macOS App
# https://tailscale.com/download/macos

# 或命令行
brew install tailscale

# 連接到自建 Headscale
tailscale up --login-server https://vpn.brood.com

# 瀏覽器會打開 Headscale Web UI
# 登錄 → 輸入 PreAuth Key → Done

# 或直接命令行：
tailscale up \
  --login-server https://vpn.brood.com \
  --authkey <alice-key>
```

#### 中國開發者 B (Windows)

```powershell
# 下載 Tailscale Windows 客戶端
# https://tailscale.com/download/windows

# 安裝後，右鍵托盤圖標 → Preferences
# → 勾選 "Use a custom coordination server"
# → 輸入: https://vpn.brood.com
```

#### iOS / Android

```
iOS:
  1. 安裝 Tailscale App
  2. Settings → Account → Custom Server
  3. 輸入: https://vpn.brood.com
  4. 回到主頁點 Sign In → 瀏覽器打開 → 登錄

Android:
  1. 安裝 Tailscale App
  2. Settings → 勾選 "Use custom coordination server"
  3. 輸入: https://vpn.brood.com
  4. 同樣 Sign In
```

### 2.9 步驟八：驗證

```bash
# 在中國開發者電腦上
# 查看節點狀態
tailscale status

# 應該看到:
# 100.64.0.1  thailand-server  admin    linux    active; direct <VPS-IP>:41641
# 100.64.0.2  alice-macbook    dev-alice macOS    active; direct

# Ping 泰國服務器（用 MagicDNS 域名）
ping thailand-server
# 或
ping 100.64.0.1

# SSH 到泰國服務器
ssh user@thailand-server
# 或
ssh user@100.64.0.1

# 訪問服務
curl http://thailand-server:8080
git clone ssh://git@thailand-server:/repo.git
```

---

## 三、配置 ACL（防止濫用）

### 3.1 ACL JSON 配置 (`/etc/headscale/acl.json`)

```jsonc
{
  // 定義用戶組
  "groups": {
    "group:admin": ["admin@brood.com"],
    "group:developers": [
      "dev-alice@brood.com",
      "dev-bob@brood.com"
    ],
    "group:thailand-servers": ["tag:thailand-server"]
  },

  // 定義主機別名
  "hosts": {
    "thailand-git": "100.64.0.1",
    "thailand-ci": "100.64.0.1",
    "thailand-dev-env": "100.64.0.1"
  },

  // ACL 規則
  "acls": [
    // 開發者可以 SSH 到泰國服務器
    {
      "action": "accept",
      "src":    ["group:developers"],
      "dst":    ["thailand-dev-env:22"],
      "proto":  "tcp"
    },
    // 開發者可以訪問 Git (SSH)
    {
      "action": "accept",
      "src":    ["group:developers"],
      "dst":    ["thailand-git:9418"],
      "proto":  "tcp"
    },
    // 開發者可以訪問 CI (HTTP/HTTPS)
    {
      "action": "accept",
      "src":    ["group:developers"],
      "dst":    ["thailand-ci:8080", "thailand-ci:8443"],
      "proto":  "tcp"
    },
    // 管理員可以訪問一切
    {
      "action": "accept",
      "src":    ["group:admin"],
      "dst":    ["*:*"],
      "proto":  "tcp"
    }
  ],

  // 自動分組（帶 tag 的節點歸類）
  "tagOwners": {
    "tag:thailand-server": ["group:admin"]
  },

  // 自動批准特定 tag 的節點（不需要手動審批）
  "autoApprovers": {
    "routes": {
      "10.0.0.0/8": ["group:admin"],
      "192.168.0.0/16": ["group:admin"]
    },
    "exitNode": ["group:admin"]
  }
}
```

### 3.2 子網路由（訪問泰國內網）

```bash
# 泰國服務器上：宣告內網路由
tailscale up \
  --login-server https://vpn.brood.com \
  --advertise-routes 192.168.1.0/24

# Headscale 上：批准路由
headscale routes list
headscale routes enable --route 1
```

---

## 四、安全最佳實踐

### 4.1 節點批准策略

```yaml
# config.yaml 中：
# 默認手動批准（最安全）
# 每個新節點需要管理員在 CLI 或 Web UI 中批准才能加入網絡
```

### 4.2 強制使用自建 DERP

```yaml
# derp.yaml 中只放自建節點
# config.yaml 中:
derp:
  urls: []        # 不使用官方 DERP 列表
  paths:
    - /etc/headscale/derp.yaml
```

這樣所有流量都不會經過 Tailscale 官方基礎設施。

### 4.3 定期清理

```bash
# 查看過期節點
headscale nodes list --expired

# 清理長時間不活躍的節點
headscale nodes delete --identifier <old-node>

# 旋轉 PreAuth Key
headscale preauthkeys expire --key <old-key>
headscale preauthkeys create --user ... --reusable --expiration 720h
```

### 4.4 防火牆

```bash
sudo ufw default deny incoming
sudo ufw allow 22
sudo ufw allow 443       # Headscale via Caddy
sudo ufw allow 3443      # DERP HTTPS
sudo ufw allow 3478/udp  # STUN
```

---

## 五、日常運維

### 5.1 監控

```bash
# 查看所有節點
headscale nodes list

# 查看 API 日誌
journalctl -u headscale -f

# Headscale 內置 Metrics (Prometheus)
# http://localhost:9090/metrics
```

### 5.2 備份

```bash
# 備份數據庫
cp /var/lib/headscale/db.sqlite /backup/headscale-$(date +%Y%m%d).db

# 備份配置
tar czf /backup/headscale-config-$(date +%Y%m%d).tar.gz \
  /etc/headscale/config.yaml \
  /etc/headscale/acl.json \
  /etc/headscale/derp.yaml
```

### 5.3 升級

```bash
# 1. 備份
cp /var/lib/headscale/db.sqlite /tmp/backup.db

# 2. 下載新版本
wget https://github.com/juanfont/headscale/releases/download/v0.29.0/headscale_0.29.0_linux_amd64.deb

# 3. 安裝
dpkg -i headscale_0.29.0_linux_amd64.deb

# 4. 運行數據庫遷移
headscale db migrate

# 5. 重啟
systemctl restart headscale
```

---

## 六、Headscale 的局限性（針對你的場景）

### 6.1 僅支持 WireGuard 協議

這是最主要的問題。中國運營商對 UDP 流量的 QoS 可能導致：
- WireGuard 流量被識別並限速
- 某些時候完全無法建立直連
- 只能走 DERP 中繼（增加延遲）

### 6.2 與 EasyTier 對比

| 跨境場景 | Headscale | EasyTier |
|:---|:---|:---|
| 協議 | 只有 WireGuard (UDP) | UDP/TCP/WSS/QUIC/WireGuard 五種 |
| UDP 被 QoS 時 | 只能走中繼 | 自動切 WSS 偽裝 HTTPS |
| DPI 檢測風險 | 中等 (WireGuard 握手有特徵) | 低 (WSS 就是標準 HTTPS) |
| 中繼後延遲 | VPS 位置決定 | 同樣，但多協議可選 |
| 解決方案 | 疊加 udp2raw 或 Hysteria2 | 內置 |

### 6.3 改進方案（疊加 udp2raw）

如果堅持用 Headscale/Tailscale + WireGuard，可以疊加一層 TCP 偽裝：

```bash
# 中國端
udp2raw -c -l 0.0.0.0:44444 -r <VPS-IP>:55555 \
  --raw-mode faketcp \
  --cipher-mode xor \
  --auth-mode simple \
  -k "passwd"

# 泰國端 (在 VPS 上或泰國服務器上)
udp2raw -s -l 0.0.0.0:55555 -r 127.0.0.1:41641 \
  --raw-mode faketcp \
  --cipher-mode xor \
  --auth-mode simple \
  -k "passwd"

# 然後 Tailscale/NetBird 的 UDP 流量被封裝在 TCP 中
```

但這就失去了 WireGuard 的簡潔性，增加了複雜度。**這也是為什麼 EasyTier 做為一體化解決方案更有優勢。**

---

## 七、總結

### Headscale 適合你的場景如果：

- ✅ 團隊已經在用或想用 Tailscale（生態成熟，客戶端體驗好）
- ✅ 需要 iOS/Android 最好的移動端體驗
- ✅ 團隊有 Go 運維能力
- ✅ 跨境 UDP 質量尚可（或願意疊加 udp2raw）

### Headscale 不適合如果：

- ❌ 中國 UDP QoS 嚴重，需要多協議切換（→ EasyTier）
- ❌ 不想維護這麼多組件（Headscale + Caddy + DERP + 可選的 udp2raw）
- ❌ 需要完善的 Web 管理界面（→ NetBird）
- ❌ 需要內置的 SSO 用戶管理（→ NetBird）

### 對比 NetBird

| 維度 | Headscale | NetBird |
|:---|:---|:---|
| 用戶管理 | CLI-only (基礎) | Web UI + SSO (完善) |
| Web 儀表板 | 無 (需第三方) | 內置，功能完善 |
| 客戶端 | Tailscale 官方 (閉源部分) | NetBird 完全開源 |
| 生態 | 40k stars, 最成熟 | 13k stars, 快速成長 |
| ACL | JSON 配置 | Web UI 可視化配置 |
| 部署 | 配置文件驅動 | Docker Compose 一鍵 |
