# 方案二：NetBird — 自託管零信任 Mesh VPN

> 推薦指數：⭐⭐⭐⭐ (團隊管理首選)
> 官網：https://netbird.io
> GitHub：https://github.com/netbirdio/netbird
> 最新版本：v0.71.4 (2026-05) | Stars: 13,000+

---

## 一、項目背景與原理

### 1.1 是什麼

NetBird 是一個基於 WireGuard 的開源零信任 Mesh VPN 平台。它是最接近 Tailscale 體驗的完全自託管替代方案 — 整個控制平面都是開源的，你可以完全控制所有組件。

### 1.2 與 Tailscale 的關係

```
Tailscale 的閉源部分：
├── 協調服務器 (控制面) ← Headscale 或 NetBird 替代
├── DERP 中繼服務器      ← 可以自建
└── 客戶端               ← 閉源（但 Headscale 兼容官方客戶端）

NetBird 的做法：
├── Management Server ← 完全開源
├── Signal Server     ← 完全開源 (WebSocket 信令)
├── Coturn (TURN)     ← 用開源 Coturn
└── Client            ← 完全開源
```

### 1.3 架構原理

#### 三層分離架構

```
┌─────────────────────────────────────────────────────────┐
│                    控制面 (Control Plane)                 │
│                                                         │
│  ┌──────────────────┐    ┌──────────────────┐          │
│  │ Management API    │    │  Signal Service   │          │
│  │ (gRPC + HTTP)    │    │  (WebSocket)      │          │
│  │                  │    │                   │          │
│  │ • 用戶/設備管理   │    │ • 節點發現        │          │
│  │ • ACL 策略分發    │    │ • NAT 信息交換    │          │
│  │ • 密鑰管理       │    │ • 連接協調        │          │
│  └──────────────────┘    └──────────────────┘          │
│                                                         │
│  存儲: SQLite (默認) 或 PostgreSQL (生產)               │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    數據面 (Data Plane)                    │
│                                                         │
│  節點 A ←───────── WireGuard P2P ──────────→ 節點 B    │
│                        │                                │
│                   (NAT 穿透失敗時)                        │
│                        ↓                                │
│              ┌──────────────────┐                       │
│              │  Coturn TURN     │                       │
│              │  (中繼轉發)       │                       │
│              └──────────────────┘                       │
└─────────────────────────────────────────────────────────┘
```

#### 連接建立流程

```
Step 1: 客戶端註冊
  Agent → Management API: "我是 user@team.com, 這是我的公鑰, 分配個 IP 吧"
  Management → Agent: "你的 IP 是 100.64.0.5, 這是網絡裡其他節點的信息"

Step 2: 信令交換
  Agent A → Signal: "我想連 Agent B, 這是我的候選地址列表"
  Signal → Agent B: "Agent A 想連你, 這是 A 的候選地址"
  Agent B → Signal: "好的, 這是我的候選地址"

Step 3: WebRTC 風格的連線建立
  Agent A ↔ Agent B: STUN 檢查 → UDP 打洞 → WireGuard 握手 → 加密隧道

Step 4: 降級
  如果 P2P 失敗 → Coturn TURN 中繼轉發
```

### 1.4 為什麼 NetBird 更適合團隊

| 能力 | 說明 |
|:---|:---|
| **用戶管理** | 內置用戶系統，支持邀請、角色 |
| **SSO 集成** | OIDC/SAML — Google, Azure, Keycloak, Authentik 等 |
| **ACL 策略** | 基於組的訪問控制，聲明式規則 |
| **活動日誌** | 誰在何時連接了什麼 |
| **姿態檢查** | 連接前檢查設備安全狀態（OS 版本、防火牆狀態等） |
| **Web 儀表板** | 可視化網絡拓撲、節點狀態、流量統計 |

---

## 二、完整搭建步驟

### 2.1 環境準備

#### 架構規劃

```
┌───────────────────────────────────────────────────────┐
│              雲端 VPS (香港/新加坡推薦)                   │
│              Ubuntu 22.04, 2C2G 即可                    │
│              Public IP: <vps-public-ip>                │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ Docker Compose Stack                            │ │
│  │                                                 │ │
│  │  netbird-management  (port 443, 33073 gRPC)     │ │
│  │  netbird-signal      (port 10000)               │ │
│  │  netbird-dashboard   (port 80 → 443)            │ │
│  │  coturn              (port 3478, 5349, 49152-)  │ │
│  │  zitadel             (optional, for SSO)        │ │
│  │  caddy               (reverse proxy + auto TLS) │ │
│  └─────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────┘
         │                          │
    ┌────┴────┐               ┌────┴────┐
    │ 泰國服務器│               │ 中國開發者│
    │ Agent   │               │ Agent   │
    └─────────┘               └─────────┘
```

#### 服務器要求

| 資源 | 最低 | 推薦 |
|:---|:---|:---|
| CPU | 1 核 | 2 核 |
| 內存 | 1 GB | 2 GB |
| 磁盤 | 10 GB | 20 GB |
| 帶寬 | 10 Mbps | 30 Mbps+ |
| 域名 | 需要一個 | `vpn.yourdomain.com` |

> 域名是必需的 — NetBird 的 Management API 需要 TLS 證書。如果沒有域名，可以用 `nip.io` 或 `sslip.io` 這類免費服務。

### 2.2 步驟一：在 VPS 上部署 NetBird 控制面

#### 官方快速部署（推薦）

```bash
# SSH 到 VPS
ssh root@<vps-ip>

# 安裝 Docker (如果還沒有)
curl -fsSL https://get.docker.com | bash

# 下載 NetBird 快速部署腳本
export NETBIRD_DOMAIN=vpn.yourdomain.com
curl -fsSL https://raw.githubusercontent.com/netbirdio/netbird/main/infrastructure_files/quickstart.sh | bash

# 腳本會自動：
# 1. 生成 TLS 證書 (Let's Encrypt)
# 2. 啟動所有容器
# 3. 創建初始管理員帳號
# 4. 輸出 setup key
```

#### 如果沒有域名，用 nip.io

```bash
# nip.io 會把你的 IP 解析為域名
# 例如 VPS IP 是 123.45.67.89
# 則 vpn.123.45.67.89.nip.io 自動解析到 123.45.67.89

export NETBIRD_DOMAIN=vpn.123.45.67.89.nip.io
# 但這種方式無法獲取 Let's Encrypt 證書, 需要自簽名
```

#### 手動 Docker Compose 部署（完全控制）

```bash
# 克隆倉庫
git clone https://github.com/netbirdio/netbird.git
cd netbird/infrastructure_files

# 配置環境變量
cat > .env << 'EOF'
NETBIRD_DOMAIN=vpn.yourdomain.com
NETBIRD_LETSENCRYPT_EMAIL=admin@yourdomain.com
NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT=
# 如果不配置 OIDC，使用內置用戶系統
EOF

# 啟動
docker compose up -d

# 檢查狀態
docker compose ps
# 應該看到 5-6 個容器都在 running
```

### 2.3 步驟二：配置管理界面

```bash
# 訪問管理儀表板
# https://vpn.yourdomain.com

# 首次登錄：
# 1. 用 quickstart 輸出的 admin 帳號
# 2. 或運行以下命令創建用戶：
docker compose exec management \
  netbird management user create \
  --email admin@brood.com \
  --name "Brood Admin" \
  --role admin

# 獲取 setup key（用於客戶端註冊）
docker compose exec management \
  netbird management setup-key create \
  --name "brood-team" \
  --type reusable \
  --expires-in 87600h  # 10 years

# 保存輸出: Setup Key: B8F1A2C3-....
```

### 2.4 步驟三：安裝客戶端 Agent

#### 泰國服務器 (Linux)

```bash
# 安裝 NetBird Agent
curl -fsSL https://pkgs.netbird.io/install.sh | bash

# 註冊到你的 NetBird 服務器
netbird up \
  --management-url https://vpn.yourdomain.com:33073 \
  --admin-url https://vpn.yourdomain.com:443 \
  --setup-key "B8F1A2C3-..." \
  --hostname "thailand-dev-server"

# 檢查狀態
netbird status
# Peers: 1 (just itself for now)
# Management: Connected
# Signal: Connected
```

#### 中國開發者 A (macOS)

```bash
# Homebrew 安裝
brew install netbirdio/netbird/netbird

# 或直接下載
# https://github.com/netbirdio/netbird/releases/latest

# 啟動並註冊
netbird up \
  --management-url https://vpn.yourdomain.com:33073 \
  --admin-url https://vpn.yourdomain.com:443 \
  --setup-key "B8F1A2C3-..."

# 如果使用 GUI：
# 下載 macOS 客戶端 → 設置 Management URL → 輸入 Setup Key
```

#### 中國開發者 B (Windows)

```powershell
# PowerShell (管理員)
Invoke-WebRequest -Uri https://pkgs.netbird.io/install.ps1 | Invoke-Expression

netbird up `
  --management-url https://vpn.yourdomain.com:33073 `
  --admin-url https://vpn.yourdomain.com:443 `
  --setup-key "B8F1A2C3-..."
```

### 2.5 步驟四：驗證和配置路由

#### 驗證連接

```bash
# 在管理儀表板查看所有節點
# https://vpn.yourdomain.com/peers

# 在中國開發者電腦上
ping 100.64.0.5   # 泰國服務器的 NetBird IP

# SSH 到泰國服務器
ssh user@100.64.0.5
```

#### 配置子網路由（可選但推薦）

如果泰國服務器所在的內網有其他設備需要訪問：

```bash
# 在管理儀表板 → Routes → Add Route
# Network: 192.168.1.0/24
# Peer: thailand-dev-server
# Description: 泰國辦公室內網

# 這樣所有 NetBird 節點都可以訪問 192.168.1.x
```

### 2.6 步驟五：配置 ACL（訪問控制）

在管理儀表板 → Access Control：

```json
{
  "Rules": [
    {
      "name": "開發者可以 SSH 到泰國服務器",
      "description": "允許所有開發者 SSH",
      "disabled": false,
      "sources": ["group:developers"],
      "destinations": ["thailand-dev-server"],
      "ports": ["22"],
      "protocol": "tcp"
    },
    {
      "name": "開發者可以訪問 Git",
      "description": "Git over SSH",
      "disabled": false,
      "sources": ["group:developers"],
      "destinations": ["thailand-dev-server"],
      "ports": ["9418"],
      "protocol": "tcp"
    },
    {
      "name": "開發者可以訪問 CI/CD",
      "disabled": false,
      "sources": ["group:developers"],
      "destinations": ["thailand-dev-server"],
      "ports": ["8080", "8443"],
      "protocol": "tcp"
    },
    {
      "name": "默認拒絕其他一切",
      "description": "Zero Trust — 默認不信任",
      "disabled": false,
      "sources": ["group:developers"],
      "destinations": ["thailand-dev-server"],
      "ports": [],
      "protocol": "all",
      "action": "drop"
    }
  ]
}
```

---

## 三、可選：集成 SSO (Keycloak 為例)

### 3.1 為什麼要 SSO

- 不用記額外的帳號密碼
- 離職員工的權限自動失效
- 統一審計日誌

### 3.2 部署 Keycloak（與 NetBird 同一台 VPS）

```yaml
# 添加到 docker-compose.yml
  keycloak:
    image: quay.io/keycloak/keycloak:latest
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: <strong-password>
    command: start-dev
    ports:
      - "8080:8080"
```

### 3.3 配置 NetBird 使用 Keycloak OIDC

```bash
# 在 .env 中添加
NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT=https://keycloak.yourdomain.com/realms/brood/.well-known/openid-configuration
NETBIRD_AUTH_OIDC_CLIENT_ID=netbird
NETBIRD_AUTH_OIDC_CLIENT_SECRET=<client-secret>
NETBIRD_AUTH_SUPPORTED_SCOPES="openid profile email"
NETBIRD_AUTH_TOKEN_ENDPOINT=https://keycloak.yourdomain.com/realms/brood/protocol/openid-connect/token

# 重啟
docker compose restart management
```

---

## 四、NAT 穿透配置（跨境場景關鍵）

### 4.1 Coturn TURN 服務器配置

中國的運營商 NAT 特別嚴格，P2P 穿透成功率不穩定。配置好 TURN 中繼是關鍵。

```bash
# coturn 配置 (turnserver.conf)
listening-port=3478
tls-listening-port=5349
relay-ip=<vps-public-ip>
external-ip=<vps-public-ip>
realm=vpn.yourdomain.com
server-name=vpn.yourdomain.com

# 認證
user=netbird:<turn-secret>
lt-cred-mech

# 端口範圍（防火牆需要開放）
min-port=49152
max-port=65535

# 性能
total-quota=100
max-bps=10000000  # 10 Mbps per session

# 啟用 TCP relay (重要！中國 UDP 可能被 QoS)
no-tcp-relay
# 上面這行是 "no tcp relay" — 取消注釋以禁用 TCP
# 我們需要 TCP relay, 所以確保這行是被註釋的或設為 tcp-relay
```

### 4.2 防火牆規則

```bash
# TURN 需要大量端口用於中繼
sudo ufw allow 3478       # STUN/TURN
sudo ufw allow 5349       # TURN over TLS
sudo ufw allow 49152:65535/udp  # TURN relay ports
```

---

## 五、日常運維

### 5.1 添加新團隊成員

```bash
# 方法一：Web 儀表板
# Users → Invite User → 輸入郵箱 → 選擇組 → 發送邀請

# 方法二：命令行生成 setup key
docker compose exec management \
  netbird management setup-key create \
  --name "new-dev-2026" \
  --type one-off \
  --expires-in 168h  # 7 天過期

# 把 setup key 發給新成員
# 他們運行 netbird up --setup-key "..." 即可
```

### 5.2 監控

```bash
# 查看所有節點狀態
netbird status --detail

# 管理儀表板概覽
# https://vpn.yourdomain.com

# 查看日誌
docker compose logs -f management
docker compose logs -f signal
```

### 5.3 備份和恢復

```bash
# 備份（主要是 SQLite 數據庫）
docker compose exec management \
  cp /var/lib/netbird/store.db /backups/store-$(date +%Y%m%d).db

# 或使用 PostgreSQL (生產推薦)
# 配置 POSTGRES_URL 環境變量，然後 pg_dump
```

### 5.4 升級

```bash
# 備份
docker compose exec management cp /var/lib/netbird/store.db /tmp/backup.db

# 拉取新鏡像
docker compose pull

# 重啟
docker compose up -d
```

---

## 六、安全最佳實踐

### 6.1 TLS 證書

```bash
# 所有對外服務都用 TLS
# Management API:  gRPC over TLS (port 33073)
# Dashboard:       HTTPS (port 443)
# Signal:          WSS (WebSocket Secure)
# TURN:            DTLS / TLS
```

### 6.2 防火牆最小化

```bash
# 僅開放必需的端口
sudo ufw default deny incoming
sudo ufw allow 22        # SSH
sudo ufw allow 443       # Dashboard
sudo ufw allow 33073     # Management gRPC
sudo ufw allow 10000     # Signal
sudo ufw allow 3478      # STUN
sudo ufw allow 5349      # TURN TLS
sudo ufw allow 49152:65535/udp  # TURN relay
```

### 6.3 定期更新

```bash
# NetBird 更新活躍，建議每月檢查
# 訂閱 GitHub Release 通知
# https://github.com/netbirdio/netbird/releases
```

---

## 七、故障排查

### 常見問題

| 問題 | 排查步驟 |
|:---|:---|
| Agent 連不上 Management | 檢查 Management URL 是否可達：`curl -k https://vpn...:33073` |
| Agent 顯示 Connected 但 ping 不通 | 檢查 ACL 規則，默認是全部拒絕的 |
| P2P 建立失敗（走 relay） | 檢查防火牆，確保 Coturn 端口開放 |
| 中國開發者延遲高 | 確保 TURN 中繼在新加坡/香港 |
| Dashboard 白屏 | 檢查瀏覽器 console，CORS 問題 |

### 診斷命令

```bash
# Agent 日誌
netbird status --detail

# 信號服務器日誌
docker compose logs signal

# 測試節點間延遲
# 在儀表板可以看到每對 peer 的延遲

# 確認是否走 relay
# Status: "Connected (relayed)" = 走中繼
# Status: "Connected (direct)"  = P2P 直連
```

---

## 八、NetBird vs EasyTier 選擇指南

| 你的情況 | 選 NetBird | 選 EasyTier |
|:---|:---|:---|
| 團隊 5 人以上 | ✅ 用戶管理必不可少 | ❌ 無用戶系統 |
| 需要訪問控制 | ✅ ACL 策略 | ❌ |
| 需要 SSO | ✅ 支持 | ❌ |
| 只想快速試試 | ❌ 需要部署服務器 | ✅ 三條命令 |
| 跨境網絡不穩定 | ⚠️ 僅 WireGuard | ✅ 多協議切換 |
| 預算極其有限 | ❌ 需要 VPS | ✅ 不需服務器 |

**最佳組合**：
- 先用 EasyTier 快速跑通，確認架構可行
- 團隊擴大到 5+ 人時遷移到 NetBird，獲得團隊管理能力
- 或者兩個並行：EasyTier 做網絡層，NetBird 做訪問控制層
