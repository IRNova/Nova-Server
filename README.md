<div align="center">

<img src="https://raw.githubusercontent.com/iiviirv/irnova-site/main/brand/nova-logo-badge-round.png" width="70" alt="Nova">

<div align="right">
  <a href="README.fa.md"><img src="https://raw.githubusercontent.com/IRNova/Nova-Proxy/main/flag-iran.svg" height="16" alt="Iran (Lion and Sun)" /> فارسی</a>
</div>

# Nova Server

**Your own censorship-resistant proxy server and full admin panel on any VPS.**

VLESS · VMess · Trojan · Shadowsocks · Reality · Hysteria2 · WireGuard, with a modern
trilingual (English · فارسی · Русский) panel, per-user accounts, multi-node fleet, Iran
bridge tunnels, one-click SSL, a Telegram bot with a Mini App, and two-factor auth.

[![License](https://img.shields.io/badge/license-Proprietary-8b5cf6?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-blueviolet?style=for-the-badge)](https://github.com/IRNova/Nova-Server)
[![Stars](https://img.shields.io/github/stars/IRNova/Nova-Server?style=for-the-badge&color=0ea5e9)](https://github.com/IRNova/Nova-Server)

</div>

---

## 🌐 Links

<div align="center">

[![Website](https://img.shields.io/badge/🌐%20Website-novaproxy.online-0ea5e9?style=for-the-badge)](https://novaproxy.online/)
[![Telegram Channel](https://img.shields.io/badge/✈️%20Telegram%20Channel-@irnova__proxy-0ea5e9?style=for-the-badge&logo=telegram)](https://t.me/irnova_proxy)
[![Telegram Group](https://img.shields.io/badge/👥%20Telegram%20Group-@irnovaproxy__group-0ea5e9?style=for-the-badge&logo=telegram)](https://t.me/irnovaproxy_group)
[![YouTube](https://img.shields.io/badge/▶️%20YouTube-@novaproxyir-ff0000?style=for-the-badge&logo=youtube)](https://www.youtube.com/@novaproxyir)
[![X (Twitter)](https://img.shields.io/badge/𝕏%20X-@irNovaProxy-000000?style=for-the-badge&logo=x)](https://x.com/irNovaProxy)
[![Instagram](https://img.shields.io/badge/📸%20Instagram-@irnova__proxy-E4405F?style=for-the-badge&logo=instagram)](https://www.instagram.com/irnova_proxy)

</div>

---

## 📖 What is Nova Server?

Nova Server turns a plain Linux VPS into your own private, censorship-resistant proxy node with a **full admin panel**. It runs `Xray-core`, `sing-box` (Hysteria2), and `AmneziaWG` behind a single port, all driven by one self-hosted agent. Where Nova Proxy runs on Cloudflare's free tier, Nova Server is the **self-hosted big brother**: a real proxy core with everything a serious node operator needs.

**What makes Nova Server different:**
- 🧩 **Every protocol that matters** — VLESS, VMess, Trojan, Shadowsocks, Reality, Hysteria2, and native WireGuard
- 🇮🇷 **Iran bridge tunnels** — front a foreign exit with a clean-IP server inside Iran (Backhaul, BackPack, rathole, wstunnel)
- 🔐 **One-click SSL** — Let's Encrypt or full-auto Cloudflare (auto-DNS + wildcard), no manual port 80
- 👥 **Per-user everything** — quota, expiry, device limit, data reset, and per-user protocol access
- 🛰️ **Multi-node fleet** — manage many servers from one panel
- 🤖 **Telegram bot + Mini App** — run the whole panel inside Telegram
- 🛡️ **Anti-censorship egress** — WARP (with your own WARP+ license), Tor, and Psiphon, built in
- ⚙️ **Automated** — backups, health alerts, auto-update, clean-IP refresh, and a first-run setup wizard
- 🌍 **Trilingual panel** — English, Persian (RTL), and Russian, with a built-in manual

---

## ⚡ Quick Install

On a fresh Ubuntu 20.04+ or Debian 11+ server (x86_64 or arm64), run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The installer sets up the proxy cores, the panel, and the tunnel backends, then prints your panel URL. Open it, set an admin password, and use the **Setup Wizard** to add a domain, a recommended protocol, and your first user.

Forgot your password? Reset it from the server:

```bash
nova-passwd 'YourNewPassword' --clear-2fa
```

---

## 📱 No computer? Install from your phone

You can set up a node entirely from your phone, no terminal needed.

**Cloud-init (no SSH):** when you create your VPS on your provider's app or website, paste this into the **User data** / **Startup script** / **Cloud-init** box:

```bash
#!/bin/bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The server installs Nova by itself on first boot (about 3 to 5 minutes). Then open `https://YOUR_SERVER_IP` in your phone browser and set your admin password.

**Telegram installer bot:** a guided bot can walk you through creating the VPS and tell you when your node is online, or install it for you over SSH. Find it via our [Telegram channel](https://t.me/irnova_proxy).

---

## 🧩 Features

| Area | What you get |
|------|--------------|
| **Protocols** | VLESS, VMess, Trojan, Shadowsocks-2022, VLESS-Reality (XTLS-Vision), Hysteria2, native WireGuard, AmneziaWG |
| **Transports** | TCP, WebSocket, gRPC, XHTTP, HTTPUpgrade, mKCP, over TLS or Reality |
| **Users** | Data quota (total or up/down split), expiry (fixed or first-use), device/IP limit, daily/weekly/monthly reset, per-user protocol and inbound access |
| **Subscriptions** | One auto-updating link per user, live usage page, QR codes, Clash/Mihomo and sing-box formats |
| **Routing** | Point-and-click geosite/geoip/CIDR/domain/protocol rules, Direct-Iran and domestic bypass, ad/porn/BitTorrent/QUIC blocking, secure and anti-sanction DNS |
| **Egress** | Direct, block, WARP (with WARP+ license), Tor, Psiphon, custom SOCKS/HTTP outbounds, and per-inbound egress assignment |
| **Iran tunnels** | Bridge-to-exit with Backhaul, BackPack, rathole, or wstunnel; carries TCP and UDP so Hysteria2 keeps working |
| **Domain and SSL** | One-click Let's Encrypt, full-auto Cloudflare (auto-DNS + wildcard), or a pasted Origin cert, all auto-renewing |
| **Fleet** | Register and manage multiple Nova nodes from one panel, aggregate users and usage, provision remotely |
| **API and bot** | Token-authed REST API (`/api/v1`) and a full Telegram bot with a Mini App that opens the whole panel in Telegram |
| **Security** | Multiple admins with owner and reseller roles, two-factor auth (Google Authenticator), server-side password reset |
| **Automation** | Nightly backups (disk and Telegram), proactive alerts, opt-in auto-update, clean-IP refresh, health check |
| **Panel** | English, Persian (RTL), Russian; global search, setup wizard, per-section guides, and a full in-panel manual; light and dark |

---

## 🆚 How it compares

| | Nova Server | 3x-ui | Marzban |
|---|:--:|:--:|:--:|
| Xray + sing-box (Hysteria2) | ✅ | Xray only | Xray only |
| Native WireGuard inbound | ✅ | plain | — |
| Reality | ✅ | ✅ | ✅ |
| Iran bridge tunnels (built in) | ✅ | — | — |
| WARP / Tor / Psiphon egress | ✅ all three | WARP | raw config |
| One-click Cloudflare auto-DNS + SSL | ✅ | — | — |
| Per-user protocol/inbound access | ✅ | — | — |
| REST API | ✅ | ✅ | ✅ |
| Full Telegram bot + Mini App | ✅ | control bot | control bot |
| Multi-admin + resellers | ✅ | — | WIP |
| Multi-node fleet | ✅ | — | ✅ |
| 2FA | ✅ | — | — |
| Trilingual panel + in-panel manual | ✅ EN/FA/RU | 13 langs | multi |

---

## 🏗️ Architecture

```
                         :443 (TCP/UDP)
  clients  ───────────────────────────────►  Nova node
                                              ├─ Xray-core   VLESS / VMess / Trojan / Reality / SS
                                              ├─ sing-box    Hysteria2 (UDP)
                                              ├─ AmneziaWG   obfuscated WireGuard
                                              └─ Nova agent  panel · REST API · Telegram · automations
```

The agent is a single Node.js process backed by a local SQLite store. The panel, the REST API, and the Telegram bot all drive the same internal service functions.

---

## 📋 Prerequisites

- A VPS running **Ubuntu 20.04+** or **Debian 11+** (x86_64 or arm64)
- **Root** access
- A **domain** is optional (needed only for a trusted certificate and the Telegram Mini App)

---

## 🔄 Updating

The panel checks for new versions and updates in one click, or turn on **automatic updates**. Your users, inbounds, and settings are preserved.

---

<div align="center">

Made with care for a free and open internet.

**Nova Server. All rights reserved.**

</div>
