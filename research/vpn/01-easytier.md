# 方案一：EasyTier — 去中心化 Mesh VPN

> 推薦指數：⭐⭐⭐⭐⭐ (首選方案)
> 官網：https://easytier.cn
> GitHub：https://github.com/EasyTier/EasyTier
> 最新版本：v2.6.4 (2026-05-12) | Stars: 12,100+

---

## 一、項目背景與原理

### 1.1 是什麼

EasyTier 是一個基於 **Rust + Tokio 異步運行時** 構建的去中心化 Mesh VPN。由中國開發者主導，專為複雜 NAT 環境（特別是中國運營商網絡）設計。

### 1.2 為什麼選 Rust

```
Rust 的優勢在網絡基礎設施中：
├── 零成本抽象 → 接近 C 的性能
├── 所有權系統 → 無 GC 停頓，無數據競爭
├── 內存安全 → 無緩衝區溢出、use-after-free
└── Tokio 異步 → 百萬級並發連接
```

EasyTier 號稱「全鏈路零拷貝」，數據從網卡到應用層不需要拷貝，理論吞吐接近線速。

### 1.3 核心原理

#### 去中心化架構

```
傳統 VPN (Hub-Spoke):           EasyTier (Mesh):
                                
   ┌─────┐                      ┌─────┐
   │ Hub │                      │  A  │◄────P2P────►│  B  │
   └──┬──┘                      └──┬──┘              └──┬──┘
     ┌─┴─┐                        │                    │
   ┌─┴─┐ ┌─┴─┐                   └─────────┬──────────┘
   │ A │ │ B │                             │
   └───┘ └───┘                    ┌────────┴────────┐
   流量必經中心                     Optional 公共中繼
   中心 = 瓶頸 + 單點               僅穿透失敗時使用
```

#### 協議自動降級機制（最核心的能力）

```
優先級 1: UDP 直連         ← 延遲最低，適合 FullCone NAT
   ↓ 失敗
優先級 2: WireGuard 直連   ← 內核級加密隧道
   ↓ 失敗
優先級 3: QUIC 直連        ← 基於 UDP，但有多路復用和抗丟包
   ↓ 失敗
優先級 4: WSS (WebSocket over TLS)
                           ← 偽裝成 HTTPS 流量，端口 443
   ↓ 失敗                   幾乎無法被 DPI 識別/阻斷
優先級 5: FakeTCP          ← 模擬 TCP 行為，兜底方案
   ↓ 全部失敗
最後手段: 中繼轉發          ← 通過公共中繼節點轉發
```

這個自動降級是 EasyTier 相比 NetBird/Headscale 最大的優勢。對於中國↔泰國這種跨境鏈路，UDP 很可能被運營商 QoS 限速甚至丟棄，WSS 偽裝成 HTTPS 幾乎是必須的。

#### NAT 穿透原理

```
NAT 穿透 (UDP Hole Punching) 過程：

Step 1: 註冊
  Node A ──→ 公共中繼: "我在這裡, 地址是 1.2.3.4:12345"
  Node B ──→ 公共中繼: "我在這裡, 地址是 5.6.7.8:54321"

Step 2: 交換信息
  公共中繼 ──→ Node A: "Node B 的地址是 5.6.7.8:54321"
  公共中繼 ──→ Node B: "Node A 的地址是 1.2.3.4:12345"

Step 3: 同時打洞
  Node A ──→ 5.6.7.8:54321 (偽造來源端口, 在 NAT 上開個洞)
  Node B ──→ 1.2.3.4:12345 (同樣操作)
  
Step 4: 直連建立
  Node A ←══P2P══→ Node B (數據不經中繼)

關鍵：EasyTier 同時支持 UDP 打洞 + TCP 打洞，
     比僅支持 UDP 打洞的方案的穿透成功率高得多（98%+）
```

---

## 二、完整搭建步驟

### 2.1 環境準備

#### 場景假設

```
泰國端：
  - 開發服務器：Ubuntu 22.04, 有公網 IP (203.0.113.10)
  - 需要暴露：Git server (22), CI/CD (8080), 開發環境 (22)

中國端：
  - 開發者 A：macOS, 家裡寬帶 (無公網 IP)
  - 開發者 B：Windows 11, 公司網絡 (無公網 IP)
  - 開發者 C：Ubuntu 筆記本, 移動熱點 (無公網 IP)
```

#### 安裝 EasyTier

**Linux (泰國服務器 + 中國開發者 C)**：

```bash
# 方法一：一鍵安裝腳本
curl -sSL https://easytier.cn/install.sh | bash

# 方法二：手動下載
wget https://github.com/EasyTier/EasyTier/releases/download/v2.6.4/easytier-core-linux-x86_64.tar.gz
tar -xzf easytier-core-linux-x86_64.tar.gz
sudo mv easytier-core /usr/local/bin/
sudo chmod +x /usr/local/bin/easytier-core
```

**macOS (開發者 A)**：

```bash
# Homebrew
brew install easytier

# 或手動下載
curl -L -o easytier-core https://github.com/EasyTier/EasyTier/releases/download/v2.6.4/easytier-core-darwin-arm64
chmod +x easytier-core
sudo mv easytier-core /usr/local/bin/
```

**Windows (開發者 B)**：

```powershell
# 下載 GUI 版本（推薦）
# https://github.com/EasyTier/EasyTier/releases/download/v2.6.4/easytier-gui-windows-x86_64.exe

# 或命令行版本
# https://github.com/EasyTier/EasyTier/releases/download/v2.6.4/easytier-core-windows-x86_64.exe
```

#### 防火牆準備

**泰國服務器**（如果有防火牆）：

```bash
# 開放 EasyTier 端口
sudo ufw allow 11010/tcp
sudo ufw allow 11010/udp
sudo ufw allow 11011/tcp    # WebSocket
sudo ufw allow 11012/tcp    # WebSocket SSL
sudo ufw allow 11013/udp    # WireGuard

# 如果在雲端（如阿里雲/Vultr），記得在安全組中開放這些端口
```

### 2.2 場景一：泰國有公網 IP（最簡單）

#### 架構圖

```
┌─────────────────────────────┐       ┌─────────────────────────────┐
│      泰國服務器               │       │      中國開發者機器            │
│     203.0.113.10             │       │      (各自內網, 無公網 IP)     │
│                              │       │                              │
│  easytier-core \            │  P2P  │  easytier-core \            │
│    --ip 10.144.144.1        │◄─────►│    --ip 10.144.144.x        │
│    --network-name brood     │       │    --peers tcp://203.0...    │
│    --network-secret <key>   │       │                              │
│    --listener tcp://0.0.0.0 │       │                              │
└─────────────────────────────┘       └─────────────────────────────┘
```

#### 步驟

**Step 1：泰國服務器配置**

```bash
# 生成網絡密鑰（所有人共用）
easytier-core --gen-network-secret
# 輸出類似: TTgGk3qVn4R7wY2xL5mJ9pB8dF1hA6cE3iK0oN4sU7vW2yZ

# 啟動 EasyTier (listener 模式，因為有公網 IP)
easytier-core \
  --ip 10.144.144.1 \
  --network-name brood-team \
  --network-secret "TTgGk3qVn4R7wY2xL5mJ9pB8dF1hA6cE3iK0oN4sU7vW2yZ" \
  --listener tcp://0.0.0.0:11010 \
  --listener udp://0.0.0.0:11010 \
  --listener wss://0.0.0.0:11012 \
  --listener wireguard://0.0.0.0:11013
```

**Step 2：中國開發者 A (macOS) 連接**

```bash
easytier-core \
  --ip 10.144.144.10 \
  --network-name brood-team \
  --network-secret "TTgGk3qVn4R7wY2xL5mJ9pB8dF1hA6cE3iK0oN4sU7vW2yZ" \
  --peers tcp://203.0.113.10:11010
```

**Step 3：驗證連接**

```bash
# 在開發者電腦上 ping 泰國服務器虛擬 IP
ping 10.144.144.1

# 應該看到:
# 64 bytes from 10.144.144.1: icmp_seq=0 ttl=64 time=45.2 ms
```

**Step 4：測試開發工作流**

```bash
# SSH 到泰國服務器（通過虛擬 IP）
ssh user@10.144.144.1

# Git clone（通過虛擬網絡）
git clone ssh://git@10.144.144.1:/home/git/repos/myproject.git

# 如果泰國服務器上有 CI，訪問
curl http://10.144.144.1:8080
```

### 2.3 場景二：兩邊都沒公網 IP（需要中繼）

#### 架構圖

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ 泰國服務器     │     │ 雲端中繼 VPS  │     │ 中國開發者     │
│ (NAT 後)      │     │ (香港/新加坡) │     │ (NAT 後)      │
│               │     │              │     │               │
│ easytier-core │────►│ easytier-core│◄────│ easytier-core │
│ --peers tcp:  │     │ --listener   │     │ --peers tcp:  │
│  relay:11010  │     │ tcp://0:11010│     │  relay:11010  │
└──────────────┘     └──────────────┘     └──────────────┘
        │                   │                    │
        └───────────────────┴────────────────────┘
                    嘗試 P2P 直連
                (中繼幫助交換 NAT 信息)
```

#### 步驟

**Step 1：在香港/新加坡 VPS 上部署中繼節點**

```bash
# SSH 到你的 VPS
ssh root@<vps-ip>

# 安裝 EasyTier
curl -sSL https://easytier.cn/install.sh | bash

# 啟動中繼模式 (只做 listener, 不加入虛擬 IP 網絡)
easytier-core \
  --listener tcp://0.0.0.0:11010 \
  --listener udp://0.0.0.0:11010 \
  --listener wss://0.0.0.0:11012

# 中繼節點不需要 --network-name 和 --network-secret
# 它只負責幫助相同 network-name 的節點發現彼此
```

**Step 2：泰國服務器連接中繼**

```bash
easytier-core \
  --ip 10.144.144.1 \
  --network-name brood-team \
  --network-secret "TTgGk3qVn4R7wY2xL5mJ9pB8dF1hA6cE3iK0oN4sU7vW2yZ" \
  --peers tcp://<relay-vps-ip>:11010
```

**Step 3：中國開發者連接中繼**

```bash
easytier-core \
  --ip 10.144.144.10 \
  --network-name brood-team \
  --network-secret "TTgGk3qVn4R7wY2xL5mJ9pB8dF1hA6cE3iK0oN4sU7vW2yZ" \
  --peers tcp://<relay-vps-ip>:11010
```

**流程說明**：

1. 泰國和中國節點都連到中繼
2. 中繼交換雙方的 NAT 地址
3. EasyTier 嘗試 UDP/TCP 打洞建立 P2P 直連
4. **打洞成功** → 數據直連，中繼不再轉發流量
5. **打洞失敗** → 數據通過中繼轉發（延遲略高，但可用）

### 2.4 進階配置

#### 使用 systemd 讓服務器持久運行

```bash
sudo tee /etc/systemd/system/easytier.service << 'EOF'
[Unit]
Description=EasyTier Mesh VPN
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/easytier-core \
  --ip 10.144.144.1 \
  --network-name brood-team \
  --network-secret "TTgGk3qVn4R7wY2xL5mJ9pB8dF1hA6cE3iK0oN4sU7vW2yZ" \
  --listener tcp://0.0.0.0:11010 \
  --listener udp://0.0.0.0:11010 \
  --listener wss://0.0.0.0:11012 \
  --listener wireguard://0.0.0.0:11013
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now easytier
sudo systemctl status easytier
```

#### 子網代理（讓中國開發者訪問泰國整個內網）

```bash
# 泰國服務器上：把本地子網代理到 EasyTier 網絡
easytier-core \
  --ip 10.144.144.1 \
  --network-name brood-team \
  --network-secret "..." \
  --listener tcp://0.0.0.0:11010 \
  --proxy-network 192.168.1.0/24    # ← 泰國辦公室內網

# 中國開發者不需要額外配置
# 就可以直接訪問 192.168.1.x 的所有設備
ping 192.168.1.100   # 泰國內網的 NAS
ssh 192.168.1.50     # 泰國內網的另一台服務器
```

#### Web 管理界面

```bash
# 服務器上啟動 Web 管理界面
easytier-web --port 8080 --core-api http://localhost:15888

# 訪問 http://<服務器IP>:8080
# 可以看到網絡拓撲、節點狀態、延遲等
```

#### 移動端接入（通過 WireGuard）

```bash
# 泰國服務器上導出 WireGuard 配置
easytier-cli peer export-wireguard-config

# 將生成的配置導入 iPhone/Android WireGuard App
# 手機就可以直接訪問整個 EasyTier 網絡
```

---

## 三、參數說明

| 參數 | 必需 | 說明 |
|:---|:---|:---|
| `--ip` | 是 | 本節點的虛擬 IP，需在同一個子網內 |
| `--network-name` | 是 | 網絡名稱，相同名稱的節點才能互相發現 |
| `--network-secret` | 是 | 網絡密鑰，用於加密和身份驗證 |
| `--listener` | 否 | 監聽地址，有公網 IP 時使用 |
| `--peers` | 否 | 初始連接的對等節點地址 |
| `--proxy-network` | 否 | 代理的子網 CIDR |
| `--no-p2p` | 否 | 禁用 P2P，全部走中繼（調試用） |
| `--latency-first` | 否 | 優先選擇延遲最低的路徑 |

---

## 四、故障排查

### 節點無法互相發現

```bash
# 檢查節點日誌
journalctl -u easytier -f

# 常見原因：
# 1. network-name 或 network-secret 不一致
# 2. 防火牆阻斷
# 3. --peers 地址不可達

# 測試端口可達性
nc -zv <對方IP> 11010
```

### P2P 打洞失敗（走中繼轉發）

```bash
# 查看當前連接模式
easytier-cli peer list

# 輸出示例：
# Peer: 10.144.144.10 | Protocol: WSS | Latency: 45ms | Direct: true
# Peer: 10.144.144.20 | Protocol: TCP | Latency: 120ms | Direct: false (relay)

# 如果 Direct 為 false, 檢查：
# 1. 雙方的 NAT 類型 (對稱型 NAT 最難穿透)
# 2. 運營商是否阻斷 UDP
# 3. 嘗試不同的 --peers 協議 (UDP vs TCP vs WSS)
```

### 延遲高或不穩定

```bash
# 測試各協議延遲
easytier-cli ping 10.144.144.1 --count 10

# 如果是跨境鏈路：
# - 正常延遲：中國南方↔泰國 ~60-80ms
# - 正常延遲：中國北方↔泰國 ~100-150ms
# - 如果更高：可能協議選擇不佳, 強制用 WSS 試試
#   --peers wss://<ip>:11012
```

### 協議被阻斷

```bash
# 症狀：UDP 直連失敗，但 TCP/WSS 可用
# 原因：運營商 UDP QoS

# 解決方案：
# 1. 優先使用 WSS 協議（偽裝 HTTPS）
easytier-core --peers wss://203.0.113.10:11012

# 2. 或使用 TCP 協議
easytier-core --peers tcp://203.0.113.10:11010
```

---

## 五、安全考量

### 5.1 網絡密鑰管理

```bash
# 生成強密鑰
easytier-core --gen-network-secret
# 輸出 256-bit 密鑰，足夠安全

# 密鑰分發：
# 不要通過明文聊天工具傳輸密鑰
# 使用: 加密郵件 / Signal / 當面交換
```

### 5.2 加密方式

EasyTier 支持兩種加密：

| 加密方式 | 性能 | 說明 |
|:---|:---|:---|
| AES-GCM | 高（有 AES-NI 硬件加速） | 默認，推薦 |
| WireGuard 協議 | 最高（內核態） | 需 WireGuard 內核模塊 |

### 5.3 隔離

```bash
# 不同項目可以用不同的 network-name 隔離
easytier-core --network-name brood-dev    # 開發網絡
easytier-core --network-name brood-prod   # 生產網絡
```

---

## 六、性能基準

| 模式 | 吞吐量 | 延遲 | CPU 佔用 |
|:---|:---|:---|:---|
| UDP 直連 | ~900 Mbps | +1ms | <5% |
| WireGuard | ~800 Mbps | +2ms | <5% |
| WSS | ~300 Mbps | +5ms | <10% |
| TCP 中繼 | ~200 Mbps | +中繼延遲 | <10% |

> 測試環境：i7-12700H, 1Gbps 局域網

---

## 七、總結

### EasyTier 最適合你的原因

1. **中國網絡優化最徹底**：多協議自動切換，WSS 偽裝 HTTPS 穿透 GFW
2. **部署最簡單**：三條命令，不需要額外服務器
3. **零成本**：完全去中心化，不需要中繼服務器（除非兩邊都無公網 IP）
4. **性能好**：Rust 實現，零拷貝，資源佔用低
5. **中文社區**：文檔、QQ 群都是中文

### 不適合的場景

- 需要精細的用戶管理和 ACL（→ 用 NetBird）
- 需要 SSO 集成（→ 用 NetBird）
- 超大團隊 50+ 人需要統一管理（→ 用 Headscale 或 NetBird）
