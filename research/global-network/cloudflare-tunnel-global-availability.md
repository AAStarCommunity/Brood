# Cloudflare Tunnel 全球可用性分析

> 研究背景：KMS/DVT 节点通过 Cloudflare Tunnel 将用户本地硬件（MX93 主板）映射至自定义域名，
> 实现外部访问。本文分析这一架构在全球各地区的可用性风险与应对方案。
>
> 更新日期：2026-07-07 | v2（补充京东云合作细节 + 中国专项方案）

---

## 一、架构回顾

```
用户/访问者
    │
    ▼
自定义域名（user.example.com）
    │  DNS 解析到 Cloudflare 边缘节点
    ▼
Cloudflare 边缘 PoP（全球 330+ 节点）
    │  通过 cloudflared 隧道回传
    ▼
用户本地机器（MX93 主板）
    └── KMS / DVT 节点进程
```

**cloudflared 的流量特征**（导致易被 DPI 识别）：
- 默认端口 7844（非标准）
- SNI 字段含 `cfargotunnel.com`（明文可见，无需解密即可过滤）
- Cloudflare IP 段完全公开（`104.16.0.0/12` 等）
- 三点组合 → 任何国家级防火墙均可**无需解密**精确识别并封锁

---

## 二、Cloudflare 与京东云合作：实际覆盖范围

### 合作概况

| 项目 | 内容 |
|------|------|
| 宣布时间 | 2020-04-28（替代早期与百度的"云加速"合作） |
| 最新动态 | 2025-12-17 宣布 AI 推理方向深度扩展 |
| 运营模式 | 京东云持有 MIIT 许可证，管理境内数据中心；Cloudflare 提供技术平台；客户使用**同一 Cloudflare 账号** |

### 在华可用服务（实际验证）

| 产品 | 状态 |
|------|------|
| CDN / DDoS / WAF | ✅ 完全可用 |
| Workers / KV / Assets | ✅ 完全可用 |
| R2 存储 | ⚠️ 境内不可创建 bucket，可通过 Global Acceleration 访问境外 |
| Zero Trust / WARP | ⚠️ 需额外订阅 Global Acceleration |
| **Cloudflare Tunnel（cloudflared）** | ❌ **不在可用产品列表** |
| Pages / Turnstile | ❌ 不可用 |

### 关键结论

**Cloudflare Tunnel 不属于京东云合作覆盖的产品。** 即使是企业用户购买了 China Network 附加订阅，也没有官方支持的 Tunnel 路径。

京东云合作解决的是"**把静态/动态内容分发给中国用户**"的问题，解决不了"**把中国境内的本地节点暴露给外网访问**"的问题。这是两个完全不同的方向。

准入门槛（供参考）：Enterprise 计划 + China Network 附加订阅 + 每个域名 ICP 备案（需中国法人实体）。

---

## 三、全球可用性地图

### 🔴 完全封锁

| 地区 | 详情 |
|------|------|
| **中国大陆（GFW）** | Cloudflare IP 黑名单；`cfargotunnel.com` DNS 污染；2024-04 GFW 开始 QUIC SNI 精确检测；HTTP/2 回退因 IP 封锁同样失效 |
| 朝鲜 / 土库曼斯坦 | 无商业互联网 |

### 🟠 严重受限

| 地区 | 详情 |
|------|------|
| **俄罗斯** | 2024-11 封锁 ECH；2025-06 起 ISP 对 Cloudflare 流量实施 16KB 截断限速（握手完成即中断） |
| **伊朗** | 2026-01 断网 53 天（史上最长）；平时部分可用 |

### 🟡 性能下降（可用但延迟高）

非洲大部（+100-200ms）、中亚（+80-150ms）、太平洋岛国（+120-300ms）、南美内陆（+60-100ms）——均因无本地 PoP 绕路导致。

---

## 四、中国大陆专项解决方案

### 方案 1：香港/新加坡中继节点（最实用，强烈推荐）

```
中国大陆 MX93 节点
    │
    │  cloudflared / frp / rathole（出境流量，走 443/80）
    ▼
香港 VPS（延迟约 10-30ms，不受 GFW 管控）
    │
    ├── 对外暴露：用户通过香港域名访问节点面板
    │
    └── 对上连接：香港 → 其余全球 DVT 节点（Cloudflare / 直连）
```

**为什么是香港而不是其他地方：**
- GFW 不管香港，出境流量畅通
- 延迟极低（广州→香港约 8ms，上海→香港约 30ms）
- 香港 VPS 有大量成熟选择：Vultr HK、Hetzner Singapore（备选）、DigitalOcean Singapore

**节点软件推荐：frp（稳定成熟）或 rathole（Rust 高性能）**

```toml
# frp server 配置（香港 VPS，frps.toml）
bindPort = 7000
vhostHTTPSPort = 443               # frps 独占 :443 对外（type="https" vhost）；不要再叠 nginx
auth.token = "your-secret-token"   # v0.52+ 必须放 [auth] 段；顶层 token= 会被静默忽略

# 管理面板：默认 admin/admin，绝不能裸暴露公网
[webServer]
addr = "127.0.0.1"          # 仅本机；如需远程访问请走 SSH 隧道，勿改 0.0.0.0
port = 7500
user = "admin"
password = "改成强随机口令"   # 未设口令 = 公网可被扫库接管

# frp client 配置（中国境内 MX93，frpc.toml）
serverAddr = "hk-vps-ip"
serverPort = 7000
auth.token = "your-secret-token"   # 与 frps 的 auth.token 一致

[[proxies]]
name = "kms-node"
type = "https"
localIP = "127.0.0.1"
localPort = 3000
customDomains = ["cn-node.your-domain.com"]
```

DNS：`cn-node.your-domain.com` → 指向香港 VPS IP（不走 Cloudflare）

**TLS 终结**：上面的 `type="https"` 是 SNI 透传骨架；vhost HTTPS 的证书要在 **frpc 端 `https2http` 插件**（`crtPath`/`keyPath`）终结——frps 不做服务端 vhost TLS 终结。完整步骤见 `china-kms-tunnel-setup.md` Step 5。

**鉴权**：KMS 默认 fail-closed，外部调 `/Sign`、`/CreateKey` 等受保护路由必须带 `-H "x-api-key: <key>"`（`api-key generate` 生成）；暴露公网前务必 provision key，切勿开 `KMS_ALLOW_OPEN_MODE=1`（否则成开放签名预言机）。详见 setup 指南 Step 6。

**注意**：frp 的连接流量本身用 TCP，出境到 443 端口可伪装为 HTTPS，被封概率低。如需更高抗检测性，在 frp 外层套 wstunnel（WebSocket over TLS）。

---

### 方案 2：P2P 直连（libp2p circuit relay）

**适合场景**：DVT 节点之间的共识通信，不需要公开 HTTP 访问。

DVT 本身已原生使用 libp2p（与以太坊共识层相同），libp2p 内置了 NAT 穿透和中继机制：

```
中国节点 A ←──── libp2p circuit relay ────→ 境外节点 B
                        │
               可用香港/新加坡的 relay 节点
               （SSZ 协议，不依赖 Cloudflare）
```

- libp2p 的 **circuit relay v2** 协议：A 和 B 都能通过中间 relay 节点建立连接，无需双方有公网 IP
- **噪声协议（Noise Protocol）** 加密，抗中间人
- GFW 对 libp2p 流量没有特别针对（流量特征像普通 HTTPS）

**这是 DVT 节点间通信的最佳方案，不需要 Cloudflare Tunnel。**

问题在于：KMS 节点的**管理界面**（Web UI）不是 libp2p，仍然需要 HTTP(S) 隧道，回到方案 1。

---

### 方案 3：WireGuard + wstunnel（中等复杂度）

WireGuard UDP 在中国被大规模封锁，但可以包裹在 WebSocket over TLS 里绕过：

```
MX93（本地）
  └── wstunnel client（UDP → WebSocket over TLS）
        └── 香港 VPS
              └── wstunnel server（WebSocket → UDP）
                    └── WireGuard server
```

```bash
# 香港 VPS 上
wstunnel server --log-lvl INFO wss://0.0.0.0:8080

# MX93 本地
wstunnel client -L 'udp://51820:127.0.0.1:51820' wss://hk-vps:8080
# 然后正常连接 WireGuard
wg-quick up wg0
```

适合需要全流量 VPN overlay 的场景（节点运营者远程管理整台机器）。

---

### 方案 4：VLESS+Reality（最强 GFW 穿透，运维成本高）

专门为穿透 GFW 设计，伪装成正常 TLS 流量，理论上无法被识别：

- Reality 协议：借用真实网站（如 google.com）的 TLS 指纹，GFW 无法区分
- 适合**有技术能力的节点运营者自己配置**，不适合作为产品推给普通用户

---

### 方案对比（中国大陆场景）

| 方案 | 穿透 GFW | 延迟 | 运维复杂度 | 适合场景 |
|------|---------|------|-----------|---------|
| **香港 VPS + frp** | ✅ | 低（10-50ms） | 低 | 节点管理 UI 公开访问 |
| **libp2p circuit relay** | ✅ | 低-中 | 极低（已内置） | DVT 节点间共识 |
| WireGuard + wstunnel | ✅ | 低 | 中 | 运营者远程管理整机 |
| VLESS+Reality | ✅ | 低 | 高 | 极高抗检测需求 |
| Cloudflare Tunnel（直连） | ❌ | — | — | 不适用 |
| CF China Network | ❌ | — | — | Tunnel 不在产品列表 |

---

## 五、整体架构建议

### 推荐的三层架构

```
┌─────────────────────────────────────────────────────────┐
│  第一层：Cloudflare Tunnel（默认，覆盖全球 80%+）          │
│  EU / US / APAC / 大部分发展中国家                        │
└─────────────────────────────────────────────────────────┘
                          │ 降级
┌─────────────────────────────────────────────────────────┐
│  第二层：香港/新加坡 VPS + frp（受限地区）                  │
│  中国大陆（经香港中继）、俄罗斯、中亚                        │
│  同一域名，DNS 智能解析到对应出口                           │
└─────────────────────────────────────────────────────────┘
                          │ 节点间通信
┌─────────────────────────────────────────────────────────┐
│  第三层：libp2p circuit relay（DVT 共识层，全球通用）        │
│  不依赖 Cloudflare，自带抗 NAT 穿透                        │
└─────────────────────────────────────────────────────────┘
```

### DVT 节点地区设计原则

利用 DVT 的门限容错特性（如 3-of-5）：
- 将中国大陆节点设为少数派（minority nodes）
- 香港/新加坡节点作为「中国友好」的多数派代表
- 即使中国节点断连，门限满足，验证器仍正常出块

这比解决网络问题更根本。

---

## 六、待跟进问题

- [ ] 当前中国大陆是否已有 MX93 节点部署？数量？
- [ ] DVT 分组是否已考虑地区多样性（geo-diversity）？
- [ ] 香港 VPS 中继方案：谁来运维？费用分担？
- [ ] frp 出境流量如需更高隐蔽性，是否引入 wstunnel？
- [ ] libp2p relay 节点是否可以部署在香港服务器上，降低中国节点连接延迟？

---

## 七、参考资料

- [Cloudflare × JD Cloud AI 扩展公告 2025-12](https://blog.cloudflare.com/cloudflare-jd-cloud-partner/)
- [Cloudflare China Network 产品页](https://www.cloudflare.com/network/china/)
- [GFW QUIC SNI 检测 — USENIX Security 2025](https://gfw.report/publications/usenixsecurity25/en/)
- [俄罗斯 16KB 截断 — Cloudflare Blog 2025-06](https://blog.cloudflare.com/russian-internet-users-are-unable-to-access-the-open-internet/)
- [libp2p circuit relay v2 规范](https://github.com/libp2p/specs/blob/master/relay/circuit-v2.md)
- [awesome-tunneling 工具汇总](https://github.com/anderspitman/awesome-tunneling)
- [frp 文档](https://github.com/fatedier/frp)
- [wstunnel — WireGuard over WebSocket](https://github.com/erebe/wstunnel)
