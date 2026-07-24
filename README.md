<div align="center">

<img src="https://raw.githubusercontent.com/iiviirv/irnova-site/main/brand/nova-logo-badge-round.png" width="70" alt="Nova">

<div align="right">
  <a href="README.fa.md"><img src="https://raw.githubusercontent.com/IRNova/Nova-Proxy/main/flag-iran.svg" height="16" alt="Iran (Lion and Sun)" /> فارسی</a>
</div>

# Nova Server

**Your own censorship-resistant proxy server and full admin panel on any VPS.**

VLESS, VMess, Trojan, Shadowsocks, Reality, Hysteria2 and WireGuard, with a modern
trilingual (English, فارسی, Русский) panel, per-user accounts, multi-node fleet, Iran
bridge tunnels, one-click SSL, a Telegram bot with a Mini App, and two-factor auth.

[![License](https://img.shields.io/badge/license-Proprietary-8b5cf6?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.1.6-blueviolet?style=for-the-badge)](https://github.com/IRNova/Nova-Server/releases)
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
- 🧩 **Every protocol that matters**: VLESS, VMess, Trojan, Shadowsocks, Reality, Hysteria2, and native WireGuard
- 🇮🇷 **Iran bridge tunnels**: front a foreign exit with a clean-IP server inside Iran (Backhaul, BackPack, rathole, wstunnel). The Iran side installs with **one lightweight command** the panel generates for you, no full stack needed there
- 🔐 **One-click SSL**: Let's Encrypt or full-auto Cloudflare (auto-DNS + wildcard), no manual port 80
- 👥 **Per-user everything**: quota, expiry, device limit, data reset, and per-user protocol access
- 🛰️ **Multi-node fleet**: manage many servers from one panel; add a new node by running one panel-generated command on a fresh VPS
- 🔒 **Hidden panel**: fresh installs put the panel behind a random secret path (with an optional dedicated port); every other path returns a plain 404, so scanners see nothing
- 🤖 **Telegram bot + Mini App**: run the whole panel inside Telegram
- 🛡️ **Anti-censorship egress**: WARP (with your own WARP+ license), Tor, and Psiphon, built in
- ⚙️ **Automated**: backups, health alerts, auto-update, clean-IP refresh, and a first-run setup wizard
- 🌍 **Trilingual panel**: English, Persian (RTL), and Russian, with a built-in manual

---

## ⚡ Quick Install

On a fresh Ubuntu 20.04+ or Debian 11+ server (x86_64 or arm64), run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The installer asks a few quick questions first:

- **Domain**: have one? It gets a free Let's Encrypt certificate automatically.
- **Secret panel path**: press Enter to auto-generate one, type your own, or answer `none` to keep the panel at the root.
- **Extra panel port**: optionally give the panel its own HTTPS port (for example 2053). The firewall port is opened automatically.

It then sets up the proxy cores, the panel, and the tunnel backends, and prints your panel URL (including the secret path, so save it). Open it, set an admin password, and use the **Setup Wizard** to add a domain, a recommended protocol, and your first user.

For scripted (non-interactive) installs, set everything with environment variables instead: `NOVA_DOMAIN`, `NOVA_DOMAIN_EMAIL`, `NOVA_PANEL_PATH` (or `none`), `NOVA_PANEL_PORT`, `NOVA_ADMIN_PASS`, and `NOVA_NO_PROMPT=1` to skip all questions.

Forgot your password, or the secret panel path? Reset the password from the server; the same command also prints the current panel URL:

```bash
nova-passwd 'YourNewPassword' --clear-2fa
```

### 🔒 Panel behind a secret path

The panel used to answer at the bare root (`https://server/`). Now a fresh install hides it behind a random secret subpath such as `https://server/p-a1b2c3/`, and every other path returns a plain 404 decoy, so scanners that probe your bare IP or domain see nothing (the same idea as the web base path in 3x-ui and Marzban). You can change the path, clear it back to root, or give the panel its own extra HTTPS port any time in **Settings > General > Panel access**; the firewall port is opened for you.

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

## 🛰️ Add nodes with one command

You no longer need a full panel on every server. Install the panel once on your main server, then grow your fleet from there:

1. In the main panel, open the **Nodes** page and click **Add a node with one command**.
2. Copy the single line it gives you and run it on a fresh VPS:

```bash
NOVA_JOIN_URL='https://your-panel' NOVA_JOIN_TOKEN='njt_...' bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The new server installs in **managed node** mode: it has no panel of its own (just a stub page, no sign-in), it registers itself with your main panel automatically, and from then on you control it entirely from the main panel (users, traffic, everything) over the node API. The join token is one-time and expires in 24 hours.

---

## 🌉 Iran bridge (lightweight)

Want a clean Iran IP fronting your foreign exit, without installing the whole stack on the Iran box? You don't have to.

1. On your **foreign (exit)** node's panel, open **Tunnels**, configure the tunnel, and click **Generate the Iran bridge command**.
2. Copy the one-line command and run it on your **Iran VPS**. It installs only the tunnel backend (Backhaul, BackPack, rathole, or wstunnel) and starts it, no xray, no sing-box, no panel.

Your users then connect to the clean Iran IP and the traffic tunnels to your foreign exit. The command carries the shared tunnel secret, so keep it private.

---

## 📶 Per-operator configs (optional)

Turn on **Per-operator configs in subscription** in Settings, and each user's subscription gains one extra config per Iranian carrier (Irancell, MCI, Rightel, Shatel, MobinNet), each tuned with that carrier's TLS fingerprint and labeled by carrier. Users on normal clients (v2rayNG, sing-box, Clash) just pick the one matching their SIM, no custom app needed. Off by default, and it applies to the plain, Clash, and sing-box subscription formats.

---

## 🧹 Uninstall

To completely remove Nova, xray, sing-box and all Nova data from the server, run:

```bash
nova-uninstall
```

It asks you to confirm first. To skip the prompt (for scripts), use `nova-uninstall --yes`. If the `nova-uninstall` command is not available, run it directly:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-uninstall.sh)
```

---

## 🧩 Features

| Area | What you get |
|------|--------------|
| **Protocols** | VLESS, VMess, Trojan, Shadowsocks-2022, VLESS-Reality (XTLS-Vision), Hysteria2, native WireGuard, AmneziaWG, all managed on one Inbounds page |
| **Transports** | TCP, WebSocket, gRPC, XHTTP, HTTPUpgrade, over TLS or Reality |
| **Deploy** | One-line VPS installer with quick setup questions (domain with free SSL, secret panel path, extra panel port), or fully scripted via env vars; `nova-uninstall` to remove it all |
| **Users** | Data quota (total or up/down split), expiry (fixed or first-use), device/IP limit, daily/weekly/monthly reset, per-user protocol and inbound access |
| **Subscriptions** | One auto-updating link per user, live usage page + native usage/expiry header, QR codes, Clash/Mihomo and sing-box formats, multi-profile inbounds (one inbound, many CDN domains), optional per-operator configs (one tuned config per Iranian carrier, works in normal clients) |
| **Per-country exits** | Let users pick their exit country in their app; per-country Tor/Psiphon instances, one config per country in the subscription |
| **Routing** | Point-and-click geosite/geoip/CIDR/domain/protocol rules, Direct-Iran and domestic bypass, ad/porn/BitTorrent/QUIC blocking, secure and anti-sanction DNS |
| **Egress** | Direct, block, WARP (with WARP+ license), Tor, Psiphon, custom SOCKS/HTTP outbounds, and per-inbound egress assignment |
| **Diagnostics** | Config/port health check (is each config actually listening and reachable), firewall and reserved-ports view, one-click fixes |
| **Iran tunnels** | Bridge-to-exit with Backhaul, BackPack, rathole, or wstunnel; carries TCP and UDP so Hysteria2 keeps working. The Iran bridge sets up from one panel-generated command (slim installer, no full stack on the Iran box) |
| **Domain and SSL** | One-click Let's Encrypt, full-auto Cloudflare (auto-DNS + wildcard), or a pasted Origin cert, all auto-renewing |
| **Panel access** | Random secret panel path with a plain 404 decoy on every other path, plus an optional dedicated panel HTTPS port; both editable under Settings > General; `nova-passwd` prints the current panel URL |
| **Fleet** | Register and manage multiple Nova nodes from one panel, aggregate users and usage, provision remotely; join a fresh VPS as a managed node with one panel-generated command (one-time token, no local panel) |
| **API and bot** | Token-authed REST API (`/api/v1`) and a full Telegram bot with a Mini App that opens the whole panel in Telegram |
| **Resellers** | Owner, managers, and resellers with custom per-capability permissions; resellers see only their own users and build them on your inbounds; two-factor auth per admin; server-side password reset |
| **Automation** | Nightly backups (disk and Telegram), proactive alerts, opt-in auto-update, clean-IP refresh, health check |
| **Panel** | English, Persian (RTL), Russian; global search, setup wizard, per-section guides, and a full in-panel manual; light and dark |

---

## 🆚 How it compares

| | Nova Server | 3x-ui | Marzban |
|---|:--:|:--:|:--:|
| Xray + sing-box (Hysteria2) | ✅ | Xray only | Xray only |
| Native WireGuard inbound | ✅ | plain |  ✗ |
| Reality | ✅ | ✅ | ✅ |
| Iran bridge tunnels (built in) | ✅ |  ✗ |  ✗ |
| WARP / Tor / Psiphon egress | ✅ all three | WARP | raw config |
| One-click Cloudflare auto-DNS + SSL | ✅ |  ✗ |  ✗ |
| Per-user protocol/inbound access | ✅ |  ✗ |  ✗ |
| REST API | ✅ | ✅ | ✅ |
| Full Telegram bot + Mini App | ✅ | control bot | control bot |
| Multi-admin + resellers | ✅ |  ✗ | WIP |
| Multi-node fleet | ✅ |  ✗ | ✅ |
| 2FA | ✅ |  ✗ |  ✗ |
| Trilingual panel + in-panel manual | ✅ EN/FA/RU | 13 langs | multi |

---

## 🏗️ Architecture

```
                         :443 (TCP/UDP)
  clients  ───────────────────────────────►  Nova node
                                              ├─ Xray-core   VLESS / VMess / Trojan / Reality / SS
                                              ├─ sing-box    Hysteria2 (UDP)
                                              ├─ AmneziaWG   obfuscated WireGuard
                                              └─ Nova agent  panel, REST API, Telegram, automations
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
