# 本地測試環境搭建指南

> 在你的 Mac 上先跑通整套 NetBird，驗證可行後再部署到辦公室服務器

---

## 測試架構

```
┌──────────────────────────────────────────────────────────┐
│                    你的 Mac (localhost)                    │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Docker Compose                                    │   │
│  │                                                  │   │
│  │  netbird-management  ← gRPC API                  │   │
│  │  netbird-signal      ← WebSocket 信令             │   │
│  │  netbird-dashboard   ← Web 管理界面               │   │
│  │  netbird-coturn      ← TURN 中繼 (可選)           │   │
│  │  caddy               ← 反向代理 + 自簽名 TLS       │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────────┐    ┌──────────────────┐          │
│  │ 節點 A (模擬泰國)  │    │ 節點 B (模擬中國)  │          │
│  │ netbird client    │    │ netbird client    │          │
│  │ 用 setup-key-a    │    │ 用 setup-key-b    │          │
│  └──────────────────┘    └──────────────────┘          │
│           ↕                      ↕                       │
│     都連到同一台 Management Server                        │
└──────────────────────────────────────────────────────────┘
```

> 預期效果：節點 A ping 通節點 B，互相可以 SSH 訪問對方的虛擬 IP

---

## 步驟 1：前置環境準備

```bash
# 確保 Docker Desktop 已安裝並運行
docker version
# 應該看到 Client 和 Server 版本信息

# 如果沒裝：
# brew install --cask docker
# 然後手動啟動 Docker Desktop
```

---

## 步驟 2：部署 NetBird 本地測試環境

### 2.1 創建測試目錄

```bash
mkdir -p ~/netbird-test
cd ~/netbird-test
```

### 2.2 創建 docker-compose.yml

```yaml
# ~/netbird-test/docker-compose.yml
version: "3.8"

services:
  # --- Caddy 反向代理 ---
  caddy:
    image: caddy:latest
    container_name: netbird-caddy
    restart: unless-stopped
    ports:
      - "443:443"
      - "80:80"
      - "10000:10000"   # Signal WebSocket
      - "3478:3478/udp" # STUN
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data

  # --- NetBird Management ---
  management:
    image: netbirdio/management:latest
    container_name: netbird-management
    restart: unless-stopped
    depends_on:
      caddy:
        condition: service_started
    volumes:
      - netbird_data:/var/lib/netbird
      - ./management.json:/etc/netbird/management.json:ro
    command: ["--config", "/etc/netbird/management.json"]

  # --- NetBird Signal ---
  signal:
    image: netbirdio/signal:latest
    container_name: netbird-signal
    restart: unless-stopped

  # --- NetBird Dashboard ---
  dashboard:
    image: netbirdio/dashboard:latest
    container_name: netbird-dashboard
    restart: unless-stopped
    environment:
      NETBIRD_MGMT_API_ENDPOINT: https://localhost:33073
      NETBIRD_MGMT_GRPC_API_ENDPOINT: https://localhost:33073

  # --- Coturn (TURN/STUN 中繼) ---
  coturn:
    image: coturn/coturn:latest
    container_name: netbird-coturn
    restart: unless-stopped
    network_mode: host  # TURN 需要知道真實 IP（測試用 localhost 可以）
    command:
      - "-n"
      - "--log-file=stdout"
      - "--listening-port=3478"
      - "--external-ip=127.0.0.1"
      - "--realm=localhost"
      - "--no-auth"
      - "--no-multicast-peers"

volumes:
  caddy_data:
  netbird_data:
```

### 2.3 創建 Caddyfile

```bash
cat > ~/netbird-test/Caddyfile << 'EOF'
# 用 localhost 測試，自簽名證書
localhost, 127.0.0.1 {
    # 自簽名 TLS
    tls internal

    # Dashboard → localhost:80 (dashboard)
    reverse_proxy /api/* dashboard:80
    reverse_proxy /management/* management:80
    reverse_proxy / netbird-dashboard:80

    # Signal WebSocket
    @signal {
        path /signalexchange/*
    }
    reverse_proxy @signal signal:10000
}

# Management gRPC
localhost:33073 {
    tls internal
    reverse_proxy management:80 {
        transport http {
            versions h2c
        }
    }
}
EOF
```

### 2.4 創建 management.json

```bash
cat > ~/netbird-test/management.json << 'EOF'
{
  "HttpConfig": {
    "Address": "0.0.0.0:80",
    "CertFile": "",
    "CertKey": ""
  },
  "StoreConfig": {
    "Engine": "sqlite"
  },
  "TURNConfig": {
    "Turns": [
      {
        "Proto": "udp",
        "Host": "127.0.0.1",
        "Port": 3478,
        "Username": "netbird",
        "Password": "netbird"
      }
    ],
    "Secret": "turn-secret-for-testing-change-in-production",
    "TimeBasedCredentials": false
  },
  "Signal": {
    "Proto": "https",
    "Uri": "localhost:10000"
  },
  "Datadir": "/var/lib/netbird/",
  "DataStoreEncryptionKey": "test-encryption-key-change-me-in-production",
  "GetAccessTokenAudience": "netbird-test-audience",
  "IdPMgmtConfig": {
    "ManagerType": "none"
  },
  "DeviceAuthorizationFlow": {
    "Provider": "hosted",
    "ProviderConfig": {
      "ClientID": "netbird-client",
      "Audience": "netbird-test-audience"
    }
  }
}
EOF
```

### 2.5 啟動

```bash
cd ~/netbird-test
docker compose up -d

# 查看啟動狀態
docker compose ps
# 應該看到 4-5 個容器 running

# 查看日誌（確認沒有錯誤）
docker compose logs management
```

---

## 步驟 3：創建測試帳號

```bash
# 生成管理員 Setup Key
docker compose exec management \
  netbird management setup-key create \
  --name "admin-test" \
  --type reusable \
  --expires-in 87600h

# 輸出類似：
# Setup Key: A8F1B2C3-D4E5-6789-ABCD-EF0123456789
# 複製這個 Key！

# 再生成一個開發者 Setup Key
docker compose exec management \
  netbird management setup-key create \
  --name "dev-test" \
  --type reusable \
  --expires-in 87600h
```

---

## 步驟 4：在本機安裝 NetBird 客戶端並測試

```bash
# 安裝客戶端
brew install netbirdio/netbird/netbird

# 用管理員 Key 連接
netbird up \
  --management-url https://localhost:33073 \
  --admin-url https://localhost \
  --setup-key "A8F1B2C3-..." \
  --hostname "my-mac-admin"

# 檢查狀態
netbird status
# Management: Connected ✓
# Signal: Connected ✓
# IP: 100.64.0.x
# Peers: 1 (only yourself)

# 查看分配的 IP
netbird status --detail
```

---

## 步驟 5：模擬第二個節點

因為同一台機器只能跑一個 NetBird 客戶端，可以用 Docker 跑第二個節點：

```bash
# 在 Docker 中跑第二個 NetBird 客戶端（模擬中國開發者）
docker run -d \
  --name netbird-node2 \
  --cap-add NET_ADMIN \
  --device /dev/net/tun \
  -v /tmp/netbird2:/etc/netbird \
  netbirdio/netbird:latest \
  netbird up \
    --management-url https://host.docker.internal:33073 \
    --admin-url https://host.docker.internal \
    --setup-key "<dev-setup-key>" \
    --hostname "test-china-dev"
```

如果 Docker 節點不成功（因為 TUN 設備限制），**換個更簡單的方法**：

### 更簡單：用另一台設備測試

```bash
# 找一台備用手機或筆記本，連到同一個 WiFi
# 安裝 NetBird 客戶端（iOS/Android/另一台 Mac）

# 連接到你本機的 Management Server
# 注意：另一台設備不能用 localhost，要用你 Mac 的局域網 IP
# 先查看你的 Mac IP：
ifconfig en0 | grep "inet " | awk '{print $2}'
# 例如: 192.168.1.50

# 在那台設備上：
netbird up \
  --management-url https://192.168.1.50:33073 \
  --admin-url https://192.168.1.50 \
  --setup-key "<dev-setup-key>" \
  --hostname "test-other-device"
```

---

## 步驟 6：驗證 P2P 連通

```bash
# 在本機查看所有節點
netbird status

# 應該看到兩個節點：
# my-mac-admin     100.64.0.5  active  direct
# test-other-device 100.64.0.6  active  direct

# Ping 第二個節點的虛擬 IP
ping 100.64.0.6

# 如果兩個節點都在同一台 Mac 上（Docker 方式），延遲應該 < 5ms
# 如果不同設備但在同一個 WiFi，延遲應該 < 10ms
```

---

## 步驟 7：模擬跨境場景（在本地測試多協議）

用 Network Link Conditioner（Mac 自帶）模擬高延遲和丟包：

```bash
# 1. 安裝 Network Link Conditioner (如果沒有)
#    系統設置 → 開發者 → Network Link Conditioner

# 2. 添加一個配置文件：
#    延遲: 80ms, 丟包: 5%, 帶寬: 50Mbps
#    模擬中國→泰國的網絡環境

# 3. 開啟後再次 ping 和測試連接
#    觀察是否仍然穩定，延遲是否符合預期
```

---

## 步驟 8：對接到 crm.aastar.io + Cloudflare Tunnel

本地測試通過後，部署到實際環境：

### 8.1 架構

```
crm.aastar.io (DNS → Cloudflare)
       │
       ▼
Cloudflare Tunnel (cloudflared)
       │
       ▼
辦公室服務器 localhost:443 (Caddy → NetBird)
```

### 8.2 部署步驟

```bash
# === 在辦公室服務器上 ===

# 1. 把 ~/netbird-test 目錄複製過去
scp -r ~/netbird-test user@office-server:~/netbird-prod

# 2. 修改 Caddyfile，把 localhost 改為 crm.aastar.io
```

**在辦公室服務器上修改 Caddyfile**：

```bash
cat > ~/netbird-prod/Caddyfile << 'EOF'
# 對外服務域名
crm.aastar.io {
    tls internal  # 先用內部證書，Cloudflare Tunnel 處理對外 TLS

    # Dashboard
    reverse_proxy /api/* dashboard:80
    reverse_proxy /management/* management:80
    reverse_proxy / netbird-dashboard:80

    # Signal WebSocket
    @signal {
        path /signalexchange/*
    }
    reverse_proxy @signal signal:10000
}

# Management gRPC
crm.aastar.io:33073 {
    tls internal
    reverse_proxy management:80 {
        transport http {
            versions h2c
        }
    }
}
EOF
```

**配置 Cloudflare Tunnel**：

```bash
# 1. 安裝 cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# 2. 登錄 Cloudflare（打開瀏覽器授權 crm.aastar.io 所屬的 CF 帳號）
cloudflared tunnel login

# 3. 創建 Tunnel
cloudflared tunnel create brood-vpn
# 輸出: Created tunnel brood-vpn with id xxxxxxxx-xxxx

# 4. 配置 Tunnel
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
credentials-file: /root/.cloudflared/xxxxxxxx.json

ingress:
  # NetBird 全部流量走這個
  - hostname: crm.aastar.io
    service: https://localhost:443
    originRequest:
      originServerName: crm.aastar.io
      noTLSVerify: true
  
  # 默認拒絕
  - service: http_status:404
EOF

# 5. DNS 路由
cloudflared tunnel route dns brood-vpn crm.aastar.io

# 6. 啟動
cloudflared tunnel run brood-vpn

# 7. 設為開機自啟
cloudflared service install
systemctl enable --now cloudflared
```

### 8.3 最終效果

```
中國開發者 → crm.aastar.io:33073 → CF Edge → Tunnel → 辦公室 NetBird
中國開發者 → crm.aastar.io:443   → CF Edge → Tunnel → 辦公室 Dashboard
```

---

## 測試清單

| 測試項 | 命令 | 預期結果 |
|:---|:---|:---|
| Docker 啟動 | `docker compose ps` | 4-5 個容器 running |
| Management 可達 | `curl -k https://localhost:33073` | 有響應 |
| Dashboard 可達 | `curl -k https://localhost` | HTML 頁面 |
| 客戶端連接 | `netbird up ...` | Connected |
| 多節點互 ping | `ping <另一個虛擬IP>` | 有響應 |
| 模擬跨境延遲 | 開啟 Network Link Conditioner | 仍可連接，延遲符合預期 |

---

## 本地測試完成後的生產部署路徑

```
Phase 1: 本地測試 (本機 Docker)           ← 你現在在這裡
    ↓ 驗證通過
Phase 2: 部署到辦公室服務器 (內網 IP)
    ↓ 驗證通過
Phase 3: 對接 crm.aastar.io + CF Tunnel   ← 中國團隊可從外部訪問
    ↓ 驗證通過
Phase 4: 添加真實團隊成員，配置 ACL
    ↓ 穩定運行
Phase 5: 可選 → 在 VPS 上部署備份 Management（高可用）
```
