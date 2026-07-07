---
id: doc-8
title: 🌐 中国社区 KMS 节点隧道部署指南
status: active
created_date: "2026-07-07"
updated_date: "2026-07-07"
labels:
  - infrastructure
  - china
  - kms
  - tunnel
---

# 中国社区 KMS 节点隧道部署指南

> **背景**：AirAccount KMS 默认使用 Cloudflare Tunnel 将 NXP FRDM-IMX93 主板上的 KMS 服务暴露到公网。
> 但 Cloudflare Tunnel 在中国大陆被 GFW 完全封锁（IP 黑名单 + SNI 检测），中国社区成员无法直接使用。
> 本指南提供替代方案：通过香港 VPS 中继实现等效的隧道访问。
>
> 适用硬件：NXP FRDM-IMX93（家庭部署，无公网 IP，NAT 后面）
> 更新日期：2026-07-07

---

## 一、为什么 Cloudflare Tunnel 在国内不行

| 问题 | 原因 |
|------|------|
| Cloudflare IP 段被封 | `104.16.0.0/12` 等 CF IP 在 GFW 黑名单 |
| cloudflared SNI 被识别 | SNI 字段含 `cfargotunnel.com`，DPI 直接过滤 |
| QUIC 端口被封 | 2024-04 GFW 开始精确检测 QUIC SNI |
| 京东云合作不覆盖 Tunnel | CF × 京东云合作只含 CDN/Workers，不含 Tunnel 产品 |

**GFW 只封锁入站连接，不封锁出站连接。** 解决思路：让 IMX93 主动出站连到香港 VPS，外部请求通过香港 VPS 中转进来。

---

## 二、整体架构

```
外部调用方（全球任意位置）
        │
        ▼
your-kms.your-domain.com
（CNAME → relay.aastar.io 或 A → 香港 VPS IP）
        │
        ▼
香港 VPS（frp server，统一中继入口）
        │
        │ ← IMX93 主动出站建立的持久隧道
        │   （出站不受 GFW 限制）
        ▼
家里的 NXP FRDM-IMX93
  └── KMS 服务（:3000）
      ├── POST /kms/Sign
      ├── POST /kms/CreateKey
      └── GET  /health
```

---

## 三、两种部署模式

### 模式 A：使用 AAstar 提供的共享中继（推荐，适合大多数社区）

AAstar 运营一套共享香港中继基础设施，社区只需：
1. 在 IMX93 上安装 frp client
2. 把自己的域名 CNAME 到共享中继
3. 向 AAstar 申请接入 token

**联系方式**：[Brood Issues](https://github.com/AAStarCommunity/Brood/issues) 申请接入

---

### 模式 B：社区自建香港 VPS 中继（完全独立）

适合有一定技术能力、希望数据主权完全独立的社区。

---

## 四、模式 B 详细部署步骤

### Step 1：购买香港 VPS

| 推荐服务商 | 规格 | 月费 | 备注 |
|-----------|------|------|------|
| Vultr（Hong Kong） | 1C/1G/25G | $6 | BGP 优化，三网可用 |
| DigitalOcean（Singapore） | 1C/1G/25G | $6 | 备选，新加坡延迟略高 |
| Hetzner（Singapore） | 2C/2G/40G | $5 | 性价比高 |

**要求**：有固定公网 IP，支持开放自定义端口。

---

### Step 2：香港 VPS 安装 frp server

```bash
# 下载 frp（选择最新版本）
wget https://github.com/fatedier/frp/releases/download/v0.61.1/frp_0.61.1_linux_amd64.tar.gz
tar -zxvf frp_0.61.1_linux_amd64.tar.gz
cd frp_0.61.1_linux_amd64

# 创建配置文件
cat > frps.toml << 'EOF'
bindPort = 7000
vhostHTTPSPort = 443
auth.token = "your-strong-secret-token"   # 改成自己的密钥

# 日志
log.to = "/var/log/frps.log"
log.level = "info"
EOF

# 启动（生产环境用 systemd）
./frps -c frps.toml
```

**systemd 服务（开机自启）**：

```ini
# /etc/systemd/system/frps.service
[Unit]
Description=frp server
After=network.target

[Service]
ExecStart=/opt/frp/frps -c /opt/frp/frps.toml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
systemctl enable frps && systemctl start frps
```

**开放防火墙端口**：
```bash
ufw allow 7000/tcp   # frp 控制端口（内部，可限制 IP）
ufw allow 443/tcp    # HTTPS 对外
ufw allow 80/tcp     # HTTP（可选，重定向到 443）
```

---

### Step 3：IMX93 上安装 frp client

```bash
# IMX93 是 aarch64，下载对应版本
wget https://github.com/fatedier/frp/releases/download/v0.61.1/frp_0.61.1_linux_arm64.tar.gz
tar -zxvf frp_0.61.1_linux_arm64.tar.gz
cd frp_0.61.1_linux_arm64

# 创建配置文件
cat > frpc.toml << 'EOF'
serverAddr = "1.2.3.4"      # 替换为你的香港 VPS IP
serverPort = 7000
auth.token = "your-strong-secret-token"   # 与 frps 一致

[[proxies]]
name = "kms-https"
type = "https"
localIP = "127.0.0.1"
localPort = 3000            # KMS 服务监听端口
customDomains = ["your-kms.your-domain.com"]   # 你的域名
EOF

# 测试启动
./frpc -c frpc.toml
```

**systemd 服务**（IMX93 上）：

```ini
# /etc/systemd/system/frpc.service
[Unit]
Description=frp client
After=network.target kms.service

[Service]
ExecStart=/opt/frp/frpc -c /opt/frp/frpc.toml
Restart=always
RestartSec=10
# frp 断线会自动重连，RestartSec 是本地进程崩溃重启间隔

[Install]
WantedBy=multi-user.target
```

```bash
systemctl enable frpc && systemctl start frpc
```

---

### Step 4：DNS 配置

在你的域名服务商处添加：

```
your-kms.your-domain.com    A    1.2.3.4    TTL 300
```

**不要开 Cloudflare 橙色云朵（代理）**，直接 A 记录指向香港 VPS。

---

### Step 5：TLS 证书（香港 VPS 上）

frp 的 vhost HTTPS 模式需要在香港 VPS 上配置 TLS 证书：

```bash
# 安装 certbot
apt install certbot

# 申请证书
certbot certonly --standalone -d your-kms.your-domain.com

# 证书路径
# /etc/letsencrypt/live/your-kms.your-domain.com/fullchain.pem
# /etc/letsencrypt/live/your-kms.your-domain.com/privkey.pem
```

在 frps.toml 中指定证书：

```toml
# 追加到 frps.toml
[[httpPlugins]]
# 或者直接在 vhost 层配置证书
# frp v0.50+ 支持 wildcardDomain + TLS
```

> **简化方案**：如果 TLS 配置复杂，可以先用 HTTP（80端口）验证通路，再加证书。KMS 客户端通常可配置 skipVerify 用于测试。

---

### Step 6：验证连通性

```bash
# 在任意外部机器（非中国大陆）测试
curl -X GET https://your-kms.your-domain.com/health
# 期望返回：{"status":"ok","version":"0.27.3",...}

# 测试签名接口（参考 AirAccount kms/test-full-api.sh）
curl -X POST https://your-kms.your-domain.com/kms/CreateKey \
  -H "x-amz-target: TrentService.CreateKey" \
  -H "Content-Type: application/json" \
  -d '{"KeySpec":"ECC_NIST_P256","KeyUsage":"SIGN_VERIFY","Description":"test",...}'
```

---

## 五、与 Cloudflare Tunnel 的对比

| 特性 | Cloudflare Tunnel | 香港 VPS + frp |
|------|-------------------|---------------|
| 中国大陆可用 | ❌ 被封 | ✅ 可用 |
| 配置复杂度 | 低（一条命令） | 中（需要 VPS） |
| 费用 | 免费 | ~$6/月 |
| 延迟（国内访问） | N/A（不可用） | +20-50ms |
| 延迟（海外访问） | 正常 CF 延迟 | 经 HK 略增加 |
| 稳定性 | CF 基础设施级 | 取决于 VPS 质量 |
| 维护负担 | 零 | 低（frp 极稳定） |

**建议**：全球其他地区节点继续用 Cloudflare Tunnel，中国大陆节点用本方案，两套并行。

---

## 六、可靠性加固（可选）

### 双中继热备

IMX93 同时连接两个 relay，主 HK 故障时自动切换：

```toml
# frpc.toml 主备配置（frp v0.51+ 支持多 server）
serverAddr = "hk-vps.your-domain.com"    # 主
# 备用：修改 serverAddr 后重启，或用 DNS 故障切换
```

DNS 层面：主 A 记录 → HK VPS，TTL 设 60 秒，故障时快速切换到新加坡备用 VPS。

### 监控

```bash
# 简单的健康检查脚本（在 HK VPS 上跑）
curl -sf https://your-kms.your-domain.com/health || \
  curl -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d "chat_id=<CHAT_ID>&text=KMS 节点离线告警"
```

---

## 七、常见问题

**Q：frp 连接会被 GFW 封锁吗？**  
A：frp 出站流量（IMX93 → HK VPS:7000）走 TCP，看起来像普通的 TCP 应用流量，被封概率很低。如果被干扰，在 frp 外层套 wstunnel 伪装成 WebSocket over TLS（443端口），几乎不可能被识别。

**Q：家用宽带 IP 变化怎么办？**  
A：IMX93 的 IP 不需要固定，frp client 是主动出站连接，只要能出网就能维持隧道。域名指向的是香港 VPS 的固定 IP，不受 IMX93 本地 IP 变化影响。

**Q：多个社区能共用一台香港 VPS 吗？**  
A：可以。frp 的 vhost 模式按域名路由，一台 VPS 可以同时服务 50+ 个社区的 IMX93，按需要扩容。

**Q：KMS 私钥安全性会受影响吗？**  
A：不会。私钥分片始终在 IMX93 的 TEE（TrustZone）内，香港 VPS 只做流量中转，看不到任何密钥内容。流量加密由 TLS 保证，frp 只是 TCP 透传。

---

## 八、相关链接

- AirAccount KMS 接口文档：`kms/` 目录，`test-full-api.sh`
- frp 项目：https://github.com/fatedier/frp
- 全球可用性分析：`research/global-network/cloudflare-tunnel-global-availability.md`
- 申请共享中继接入：https://github.com/AAStarCommunity/Brood/issues
