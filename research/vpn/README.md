# 跨國團隊內部 VPN 方案技術調研

> 調研日期：2026-06-23
> 場景：泰國 ↔ 中國兩地團隊遠程協作開發
> 需求：開源自建內部專用通道，連接泰國開發服務器做 git pull/build，支持遠程開發

---

## 一、問題場景

```
┌──────────────────────────────────────────────────────────────────┐
│                         現實問題                                  │
│                                                                  │
│  泰國團隊 ←────────── 網絡隔離 ──────────→ 中國團隊               │
│  (開發服務器)      運營商 NAT / GFW        (開發者機器)           │
│                    UDP 限速 / DPI                             │
│                    商業 VPN 收費 + 不穩定                         │
│                                                                  │
│  需要：開源自建、穩定、低延遲、加密、專用的內部網絡通道            │
└──────────────────────────────────────────────────────────────────┘
```

### 核心需求

1. **穩定性** — 跨境鏈路本身就不穩定，方案必須有抗丟包、協議切換能力
2. **低成本** — 非商業用途，最好零成本或僅需一台便宜 VPS
3. **易維護** — 團隊自己可控，不依賴第三方服務
4. **安全性** — 源碼拉取和開發流量需要端到端加密
5. **穿透能力** — 兩邊可能都沒有公網 IP，需要 NAT 穿透

---

## 二、技術路線總覽

### Mesh VPN 的工作原理

傳統 VPN（如 OpenVPN、IPsec）是 **Hub-Spoke 模式**：所有流量經過中心服務器。

```
傳統 VPN:      A → Server → B    (中心瓶頸, 延遲翻倍)
Mesh VPN:     A ←──P2P──→ B     (直連, 延遲最低)
```

Mesh VPN 的核心流程：

```
1. 節點發現   — 新節點如何找到網絡中的其他節點
2. NAT 穿透   — 雙方都在路由器後面如何建立直連
3. 密鑰交換   — 如何安全地協商加密密鑰
4. 路由同步   — 每個節點如何知道數據包該發給誰
5. 數據加密   — WireGuard / TLS / Noise 協議加密傳輸
```

### 協議棧分層

```
┌──────────────────────────────────┐
│  應用層   │ Git / SSH / HTTP     │
├───────────┼──────────────────────┤
│  傳輸層   │ TCP / UDP            │
├───────────┼──────────────────────┤
│  隧道層   │ WireGuard / QUIC     │  ← Mesh VPN 的核心
├───────────┼──────────────────────┤
│  加密層   │ Noise / TLS 1.3      │
├───────────┼──────────────────────┤
│  NAT 穿透  │ STUN / TURN / DERP   │
├───────────┼──────────────────────┤
│  物理層   │ 實際的互聯網鏈路       │
└──────────────────────────────────┘
```

---

## 三、域名訪問 + 帳號管理需求分析

### 3.1 域名代替 IP

三個方案都支持域名：

| 方案 | 域名支持方式 |
|:---|:---|
| **EasyTier** | `--peers tcp://vpn.brood.com:11010`，DNS 解析後連接 |
| **NetBird** | 域名是必需的（TLS 證書），`--management-url https://vpn.brood.com` |
| **Headscale** | 域名是必需的（TLS 證書），`--login-server https://vpn.brood.com` |

### 3.2 帳號管理（防止濫用）— 這是關鍵差異！

| 能力 | EasyTier | NetBird | Headscale |
|:---|:---|:---|:---|
| **個體帳號** | ❌ 所有人共用一個 network-secret | ✅ 獨立帳號 + 邀請制 | ✅ 獨立帳號 (namespace) |
| **SSO 集成** | ❌ | ✅ OIDC/SAML (Google, Keycloak...) | ⚠️ 實驗性 OIDC |
| **Setup Key 過期** | ❌ | ✅ 單次/限時/可重用 | ✅ 單次/限時/可重用 |
| **單用戶撤銷** | ❌ 改密鑰影響所有人 | ✅ 一鍵撤銷 | ✅ CLI 撤銷 |
| **ACL 訪問控制** | ❌ | ✅ 精細端口級 | ✅ JSON 規則 |
| **審計日誌** | ❌ | ✅ 誰何時訪問了什麼 | ⚠️ 基礎日誌 |
| **Web 管理界面** | ⚠️ 自帶監控面板 | ✅ 完善儀表板 | ❌ 需第三方 |

### 3.3 綜合選型更新

```
你的需求                        →  推薦方案
─────────────────────────────────────────────
快速試用，不在意帳號管理           →  EasyTier
需要域名 + 帳號管理 + 防濫用     →  NetBird ← 現在更推薦
需要 Tailscale 生態 + 基礎管理   →  Headscale
需要最強跨國內網穿透             →  EasyTier (疊加手動管理)
```

> **更新後的建議**：考慮到你需要域名訪問和帳號管理來防止濫用，**NetBird 是最佳平衡點** — 完善的用戶管理 + SSO + ACL + Web 儀表板。EasyTier 雖然網絡穿透最強，但缺乏帳號體系。如果你能接受手動管理（通過 network-secret 輪換來控制訪問），EasyTier 也可以。

---

## 四、三方案對比總覽

| 維度 | EasyTier | NetBird | Headscale |
|:---|:---|:---|:---|
| **GitHub Stars** | ⭐ 12,100+ | ⭐ 13,000+ | ⭐ 40,000+ |
| **語言** | Rust | Go | Go |
| **License** | LGPL-3.0 | BSD-3-Clause | BSD-3-Clause |
| **最新版本** | v2.6.4 (2026-05) | v0.71.4 (2026-05) | v0.28.0 (2026-02) |
| **架構** | 完全去中心化 P2P | Hub-Spoke (自建控制面) | Hub-Spoke (兼容 Tailscale) |
| **中心服務器** | 不需要 | 需要（自建） | 需要（自建） |
| **數據面協議** | WireGuard / QUIC / TCP / WSS | WireGuard (UDP) | WireGuard (UDP) |
| **NAT 穿透** | 98%+ (UDP+TCP 雙打洞) | STUN + Coturn TURN | DERP 中繼 |
| **協議切換** | ✅ 自動降級（UDP→WSS→TCP） | ❌ 僅 UDP | ❌ 僅 UDP |
| **Web 管理界面** | ✅ 內置 | ✅ 完善 | 需第三方 |
| **SSO/用戶管理** | ❌ 無 | ✅ OIDC/SAML | 有限 |
| **移動端** | Android/iOS (WG 接入) | Android/iOS | 用 Tailscale 客戶端 |
| **跨平台** | Win/Mac/Linux/FreeBSD | Win/Mac/Linux | Win/Mac/Linux/iOS/Android |
| **中文支持** | ✅ 中英雙語 | ❌ 英文 | ❌ 英文 |
| **部署難度** | ⭐ 極簡 (3 命令) | ⭐⭐ 中等 (Docker) | ⭐⭐ 中等 |
| **適合團隊規模** | 1-20 人 | 5-100 人 | 5-100 人 |

### 選型建議

```
你的情況                              →  推薦方案
─────────────────────────────────────────────────
想先試試，快速跑通                      →  EasyTier
團隊 5-10 人，需要管理界面              →  NetBird
已有 Tailscale 經驗，追求生態成熟       →  Headscale
需要最強的抗干擾能力（中國網絡環境）     →  EasyTier
需要精細的訪問控制策略                  →  NetBird
不想維護任何服務器                      →  EasyTier
```

---

## 五、架構對比

### EasyTier — 完全去中心化

```
     ┌──────────┐         ┌──────────┐
     │  Node A  │◄═══════►│  Node B  │   所有節點對等
     │ (泰國)   │  P2P     │ (中國)   │   無中心服務器
     └────┬─────┘ direct  └────┬─────┘
          │                    │
          └────────┬───────────┘
                   │
            ┌──────┴──────┐
            │  Optional    │   可選共用中繼（無公網 IP 時）
            │  Relay Node  │
            └─────────────┘
```

### NetBird / Headscale — 中心化管理

```
     ┌──────────────────────────┐
     │   Management Server      │   控制面：管理節點、分發密鑰
     │   (自建 VPS)             │
     │   + Signal (WebSocket)   │   信號面：幫助節點發現彼此
     │   + TURN/DERP Relay      │   中繼面：NAT 穿透失敗時轉發流量
     └────┬──────────┬──────────┘
          │          │
    ┌─────┴──┐  ┌───┴──────┐
    │ Node A │  │  Node B  │       數據面：P2P WireGuard 直連
    │ (泰國)  │  │  (中國)   │       (穿透成功時不經服務器)
    └────────┘  └──────────┘
```

**關鍵點**：無論 NetBird 還是 Headscale，**數據流量不經過管理服務器**。管理服務器只負責協調（告訴 A 和 B 彼此的地址和公鑰），實際數據是 A↔B 直連。只有 NAT 穿透失敗時才走中繼轉發。

---

## 六、詳細文檔索引

| 文檔 | 內容 |
|:---|:---|
| [01-easytier.md](./01-easytier.md) | EasyTier 原理、架構、完整搭建步驟、故障排查 |
| [02-netbird.md](./02-netbird.md) | NetBird 原理、Docker 部署、團隊管理配置、ACL 策略 |
| [03-headscale.md](./03-headscale.md) | Headscale 原理、自建控制面、Tailscale 客戶端接入、DERP 配置 |
| [04-onboarding-guide.md](./04-onboarding-guide.md) | 新員工 VPN 接入指南（可直接發給新人，5 分鐘上手） |
| [05-local-testing.md](./05-local-testing.md) | 本地測試環境搭建（Mac Docker → Cloudflare Tunnel → 生產） |

---

## 七、跨境網絡穩定性補充

VPN 建好只是第一步，針對中國↔泰國的特殊網絡環境，還有以下補充措施：

### 6.1 協議層優化

| 問題 | 根因 | 對策 |
|:---|:---|:---|
| UDP 被 QoS 限速 | 運營商對 UDP 流量低優先級 | EasyTier 自動切 WSS/TCP；NetBird/Headscale 需額外套 udp2raw |
| WireGuard 被 DPI 識別 | 特徵明顯的握手包 | EasyTier 用 WSS 偽裝 HTTPS；或套 Hysteria2 |
| TCP 被限速 | 國際帶寬擁塞 | Hysteria2 (QUIC) 暴力抗丟包；BBR 擁塞控制 |
| DNS 污染 | GFW DNS 劫持 | 組內自建 DNS over HTTPS |

### 6.2 中繼節點選址

如果兩邊 NAT 穿透失敗需要中繼，中繼節點的位置直接決定延遲：

```
泰國 ←──→ 新加坡 VPS: ~25ms
中國 ←──→ 新加坡 VPS: ~70ms (南方) / ~150ms (北方)
泰國 ←──→ 香港 VPS:   ~40ms
中國 ←──→ 香港 VPS:   ~30ms (南方) / ~80ms (北方)

推薦中繼位置：
- 團隊在南方（廣州/深圳）→ 香港 VPS
- 團隊分散全國       → 新加坡 VPS (對稱性好)
```

### 6.3 低成本 VPS 推薦

| 服務商 | 地區 | 最低價格 | 帶寬 |
|:---|:---|:---|:---|
| 阿里雲輕量 | 香港 | ~$4/月 | 30Mbps |
| 騰訊雲輕量 | 新加坡 | ~$5/月 | 30Mbps |
| Vultr | 新加坡 | $6/月 | 1TB 流量 |
| DigitalOcean | 新加坡 | $6/月 | 1TB 流量 |
| Linode | 新加坡 | $5/月 | 1TB 流量 |

---

## 八、數據源

本調研基於以下來源（2026-06-23）：

- [EasyTier GitHub](https://github.com/EasyTier/EasyTier) — 12.1k stars
- [NetBird GitHub](https://github.com/netbirdio/netbird) — 13k stars
- [Headscale GitHub](https://github.com/juanfont/headscale) — 40k stars
- [NetBird vs Netmaker 對比](https://cybersectools.com/compare/netbird-connect-vs-netmaker)
- [Self-Hosted VPN in 2026 (dev.to)](https://dev.to/moksh/self-hosted-vpn-in-2026-wireguard-headscale-netbird-and-more-compared-5fln)
- [VPN & Mesh Networking 2026 Deep Dive](https://www.youngju.dev/blog/culture/2026-05-16-vpn-mesh-networking-2026-tailscale-wireguard-twingate-zerotier-netbird-nebula-mullvad-headscale-deep-dive.en)
- [Top Open Source Tailscale Alternatives in 2026](https://pinggy.io/blog/top_open_source_tailscale_alternatives/)
- [EasyTier 技術解析 (CSDN)](https://xuanwu.csdn.net/69fc566354b52172bc7238c9.html)
- [VNT 項目](https://github.com/vnt-dev/vnt)
- [Nebula GitHub](https://github.com/slackhq/nebula) — 17.4k stars
- [FOSDEM 2026: Headscale Talk](https://fosdem.org/2026/schedule/event/KYQ3LL-headscale-the-complementary-open-source-clone/)
