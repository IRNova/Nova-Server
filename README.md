<div align="center">

<div align="right">
  <a href="README.fa.md"><img src="https://raw.githubusercontent.com/IRNova/Nova-Proxy/main/flag-iran.svg" height="16" alt="Iran (Lion and Sun)" /> فارسی</a>
</div>

<img src="./assets/readme/hero-en.svg" width="100%" alt="Nova Server: your own censorship-resistant proxy server and full admin panel on any VPS. Clients connect over port 443 to a node running Xray-core, sing-box and AmneziaWG.">

**Your own censorship-resistant proxy server and full admin panel on any VPS.**

VLESS, VMess, Trojan, Shadowsocks, Reality, Hysteria2, TUIC, NaiveProxy and WireGuard, with a modern
trilingual (English, فارسی, Русский) panel, per-user accounts, multi-node fleet, Iran
bridge tunnels, one-click SSL, a Telegram bot with a Mini App, and two-factor auth.

[![License](https://img.shields.io/badge/license-Proprietary-8b5cf6?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.7.0-blueviolet?style=for-the-badge)](https://github.com/IRNova/Nova-Server/releases)
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

<a id="-what-is-nova-server"></a>

<img src="./assets/readme/section-overview.svg" width="100%" alt="What is Nova Server?">


Nova Server turns a plain Linux VPS into your own private, censorship-resistant proxy node with a **full admin panel**. It runs `Xray-core`, `sing-box` (Hysteria2), and `AmneziaWG` behind a single port, all driven by one self-hosted agent. Where Nova Proxy runs on Cloudflare's free tier, Nova Server is the **self-hosted big brother**: a real proxy core with everything a serious node operator needs.

**What makes Nova Server different:**
- 🧩 **Every protocol that matters**: VLESS, VMess, Trojan, Shadowsocks, Reality, Hysteria2, TUIC, NaiveProxy, and native WireGuard
- 🇮🇷 **Iran bridge tunnels**: front a foreign exit with a clean-IP server inside Iran (Backhaul, BackPack, rathole, wstunnel). The Iran side installs with **one lightweight command** the panel generates for you, no full stack needed there
- 🔐 **One-click SSL**: Let's Encrypt or full-auto Cloudflare (auto-DNS + wildcard), no manual port 80
- 👥 **Per-user everything**: quota, expiry, device limit, data reset, and per-user protocol access
- 🛰️ **Multi-node fleet**: manage many servers from one panel; add a new node by running one panel-generated command on a fresh VPS
- 🔒 **Hidden panel**: fresh installs put the panel behind a random secret path (with an optional dedicated port); every other path returns a plain 404, so scanners see nothing
- 🛡️ **Login guard**: a fail2ban-style shield that blocks an IP after too many failed sign-ins, on by default, with a live view of active bans you can lift any time
- 🔔 **Webhooks**: get a signed POST to your own URL when a user is created, expires, or hits quota, when a node joins, or when an IP is banned
- 📊 **Per-inbound traffic**: a daily traffic chart per inbound on the Inbounds page, so you can see which entry points carry the load
- 🤖 **Telegram bot + Mini App**: run the whole panel inside Telegram
- 🛡️ **Anti-censorship egress**: WARP (with your own WARP+ license), Tor, and Psiphon, built in
- ⚙️ **Automated**: backups, health alerts, auto-update, clean-IP refresh, and a first-run setup wizard
- 🌍 **Trilingual panel**: English, Persian (RTL), and Russian, with a built-in manual

---

<a id="-quick-install"></a>

<img src="./assets/readme/section-install.svg" width="100%" alt="Get started: Quick Install">


On a fresh Ubuntu 20.04+ or Debian 11+ server (x86_64 or arm64), run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The installer asks a few quick questions first:

- **Domain**: have one? It gets a free Let's Encrypt certificate automatically. No domain is fine too: the node runs on its IP with a self-signed certificate, and the Nova app connects to it either way.
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

## 🧭 New here? A step-by-step walkthrough

Never set up a server before? This is the whole journey in plain steps. Every technical word is explained the first time it appears.

1. **Get a VPS.** A VPS is a small computer you rent on the internet that stays on all the time, so people can connect to it day and night. Any provider works; a basic Ubuntu 20.04+ or Debian 11+ box (about 4 to 6 dollars a month) is plenty. You do **not** need a domain name to start.

2. **Install Nova (pick one way).**
   - **One command:** open your server's terminal (most providers have a **Console** button in your browser if you have never used SSH, which is just a way to type commands on your server), paste the [Quick Install](#-quick-install) command, and press Enter. It asks a couple of easy questions; pressing Enter to accept the defaults is fine.
   - **No computer:** paste the same command into your provider's **cloud-init** or **user data** box when you create the server. See [Install from your phone](#-no-computer-install-from-your-phone).
   - **Telegram:** the installer bot can do the whole thing for you.

3. **Open your panel and set a password.** The installer prints your panel address, including a secret path (so scanners cannot find it), so save that link. Open it and set an admin password. Lost the link later? Run `nova-passwd` on the server and it prints the current address.

4. **(Optional) Add a domain and free HTTPS.** A domain (a web address like `vpn.example.com`) and an SSL certificate (the padlock that makes a connection trusted) are optional. Without one, your node runs on its IP and the Nova app still connects. With one, the panel gets a free certificate for you. You can skip this and add it later.

5. **Create your first user and connect.** In **Users**, add a user and copy their **subscription link** (one link that carries all their connection settings and keeps itself updated). Open it in the Nova app, scan the QR code on a phone, or paste it into a normal client like v2rayNG, sing-box, or Clash. You are online.

6. **Go further when you need to.** Add more users and set data or time limits, add more entry points on the Inbounds page, stay online under heavy blocking with the [Iran bridge](#-iran-bridge-lightweight) or the [DNS tunnel](#-dns-tunnel-last-resort), and grow to [more servers](#-add-nodes-with-one-command) from one panel.

The panel itself has an even more detailed **Step-by-step setup** guide built in (at the top of the in-panel manual), in English, Persian, and Russian.

---

## 🐳 Install with Docker

Prefer containers? Nova ships a Docker option as an alternative to the native one-line installer. It's reproducible, easy to stop, move, or upgrade, and your data lives on named volumes so it survives a rebuild.

Run this on a real Linux VPS as root. It installs Docker if it's missing, builds the image, and starts the node:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker/nova-docker.sh)
```

You get the same options as the native installer, passed as environment variables: `NOVA_ADMIN_PASS`, `NOVA_DOMAIN`, `NOVA_PANEL_PATH`, and `NOVA_PANEL_PORT`.

After it starts, watch the first-boot install and find your panel URL with:

```bash
cd /opt/nova-docker && docker compose logs -f nova-node
```

**Important:** this needs a real Linux host with host networking. It does **not** work on Docker Desktop for Mac or Windows, which can't bind the host's `:443` the way a node needs. The container runs systemd and uses host networking plus privileged mode because a Nova node is a VPN appliance: it binds `:443` (TCP and UDP), optionally `:53/udp` and a WireGuard UDP port, and manages systemd services. Full details are in `docker/README.md`.

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

<a id="-add-nodes-with-one-command"></a>

<img src="./assets/readme/section-fleet.svg" width="100%" alt="Scale out: Add nodes with one command">


You no longer need a full panel on every server. Install the panel once on your main server, then grow your fleet from there:

1. In the main panel, open the **Nodes** page and click **Add a node with one command**.
2. Copy the single line it gives you and run it on a fresh VPS:

```bash
NOVA_JOIN_URL='https://your-panel' NOVA_JOIN_TOKEN='njt_...' bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The new server installs in **managed node** mode: it has no panel of its own (just a stub page, no sign-in), it registers itself with your main panel automatically, and from then on you control it entirely from the main panel (users, traffic, everything) over the node API. The join token is one-time and expires in 24 hours.

---

<a id="-iran-bridge-lightweight"></a>

<img src="./assets/readme/section-bridge.svg" width="100%" alt="Stay online: Iran bridge">


Want a clean Iran IP fronting your foreign exit, without installing the whole stack on the Iran box? You don't have to.

1. On your **foreign (exit)** node's panel, open **Tunnels**, configure the tunnel, and click **Generate the Iran bridge command**.
2. Copy the one-line command and run it on your **Iran VPS**. It installs only the tunnel backend (Backhaul, BackPack, rathole, or wstunnel) and starts it, no xray, no sing-box, no panel.

Your users then connect to the clean Iran IP and the traffic tunnels to your foreign exit. The command carries the shared tunnel secret, so keep it private.

---

## 📶 Per-operator configs (optional)

Turn on **Per-operator configs in subscription** in Settings, and each user's subscription gains one extra config per Iranian carrier (Irancell, MCI, Rightel, Shatel, MobinNet), each tuned with that carrier's TLS fingerprint and labeled by carrier. Users on normal clients (v2rayNG, sing-box, Clash) just pick the one matching their SIM, no custom app needed. Off by default, and it applies to the plain, Clash, and sing-box subscription formats. The per-operator subscription toggle and the per-ISP client optimization now sit together in Settings.

---

## 🛡️ Login guard and webhooks

Two operator tools live under **Settings > Security**.

**Login guard** is a fail2ban-style shield for the panel sign-in. After too many failed attempts from one IP within a window, that IP is blocked for a set time, so password guessing gets nowhere. It is on by default; you can tune the attempt count, the window, and the ban length, and the same page lists every active ban with a one-click **Unban** (and a **Clear all**).

**Webhooks** send a small signed JSON POST to your own URL when something happens on the node: a user is created, updated, deleted, expires, or hits quota; a node enrolls; or an IP is banned. Add as many endpoints as you like, pick which events each one wants (or leave it on all), and set an optional secret. When a secret is set, Nova signs the body with HMAC-SHA256 and sends it in the `X-Nova-Signature: sha256=...` header, so your receiver can confirm the call really came from your node. A **Test** button fires a sample delivery so you can check the wiring. The payload is `{ event, timestamp, node, data }`.

---

## 🕳️ DNS Tunnel (last resort)

Nova has an optional built-in DNS tunnel that carries traffic inside DNS queries. Because it rides on DNS, it keeps working when everything else is blocked but DNS still resolves, so it's the last-resort transport when nothing else gets through.

You pick the engine in the DNS Tunnel card:

- **MasterDnsVPN** is the simple default.
- **CottenDns** is the more capable engine, built for very lossy or heavily probed networks: it adds DNS-over-TLS and DNS-over-HTTPS resolver transport, balances across several resolvers, and recovers from packet loss. It never binds :443, so it coexists with the panel.

Both bind port 53, so only one runs at a time; switching engines takes the port from the other. Turn it on in the panel under **Settings**. It needs a subdomain delegated to your node with an NS record. If your domain is on Cloudflare, the panel can create the delegation for you automatically; otherwise the in-panel guide walks you through the manual A and NS records.

It's a separate protocol: users connect with the engine's own client ([MasterDnsVPN](https://github.com/masterking32/MasterDnsVPN) or [CottenDns](https://github.com/TaJirax/CottenDns)), not the Nova app. The panel generates and exports the client config for them.

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

<a id="-features"></a>

<img src="./assets/readme/section-features.svg" width="100%" alt="Capabilities: Features">


| Area | What you get |
|------|--------------|
| **Protocols** | VLESS, VMess, Trojan, Shadowsocks-2022, VLESS-Reality (XTLS-Vision), Hysteria2, TUIC v5, NaiveProxy, native WireGuard, AmneziaWG, all managed on one Inbounds page |
| **Transports** | TCP, WebSocket, gRPC, XHTTP, HTTPUpgrade, over TLS or Reality |
| **Deploy** | One-line VPS installer with quick setup questions (domain with free SSL, secret panel path, extra panel port), or fully scripted via env vars; a Docker install too (host networking, data on named volumes); `nova-uninstall` to remove it all |
| **Users** | Data quota (total or up/down split), expiry (fixed or first-use), device/IP limit, daily/weekly/monthly reset, per-user protocol and inbound access; saved plans (reusable limit sets applied to one user or many), bulk actions (enable, disable, extend, reset, apply a plan, or delete across selected users), and CSV import/export (idempotent upsert by name) |
| **Subscriptions** | One auto-updating link per user, live usage page + native usage/expiry header, QR codes, Clash/Mihomo and sing-box formats, multi-profile inbounds (one inbound, many CDN domains), optional per-operator configs (one tuned config per Iranian carrier, works in normal clients) |
| **Per-country exits** | Let users pick their exit country in their app; per-country Tor/Psiphon instances, one config per country in the subscription |
| **Routing** | Point-and-click geosite/geoip/CIDR/domain/protocol rules, Direct-Iran and domestic bypass, ad/porn/BitTorrent/QUIC blocking, secure and anti-sanction DNS |
| **Egress** | Direct, block, WARP (with WARP+ license), Tor, Psiphon, custom SOCKS/HTTP outbounds, and per-inbound egress assignment |
| **Monitoring** | Dashboard traffic charts, plus a per-inbound daily traffic chart on the Inbounds page so you can see which entry points carry the load |
| **Diagnostics** | Config/port health check (is each config actually listening and reachable), firewall and reserved-ports view, one-click fixes |
| **Iran tunnels** | Bridge-to-exit with Backhaul, BackPack, rathole, or wstunnel; carries TCP and UDP so Hysteria2 keeps working. The Iran bridge sets up from one panel-generated command (slim installer, no full stack on the Iran box) |
| **DNS tunnel** | Optional built-in DNS tunnel that carries traffic inside DNS queries, the last-resort transport for when only DNS still resolves, with a choice of engine: MasterDnsVPN (simple default) or CottenDns (DoT/DoH resolvers, multi-resolver balancing, loss recovery, for very hostile networks); auto NS delegation on Cloudflare or a guided manual setup, with the client config exported from the panel |
| **Domain and SSL** | One-click Let's Encrypt, full-auto Cloudflare (auto-DNS + wildcard), or a pasted Origin cert, all auto-renewing |
| **Panel access** | Random secret panel path with a plain 404 decoy on every other path, plus an optional dedicated panel HTTPS port; both editable under Settings > General; `nova-passwd` prints the current panel URL |
| **Fleet** | Register and manage multiple Nova nodes from one panel, aggregate users and usage, provision remotely; join a fresh VPS as a managed node with one panel-generated command (one-time token, no local panel) |
| **API and bot** | Token-authed REST API (`/api/v1`) and a full Telegram bot with a Mini App that opens the whole panel in Telegram |
| **Webhooks** | Outbound webhooks to your own URL on user create/update/delete, expiry, quota, node enroll, and login-ban events; each call is optionally HMAC-signed (`X-Nova-Signature`) so your endpoint can verify it |
| **Login guard** | Fail2ban-style per-IP lockout after repeated failed sign-ins (thresholds and ban length configurable), a live list of active bans, and one-click unban; on by default |
| **Resellers** | Owner, managers, and resellers with custom per-capability permissions; resellers see only their own users and build them on your inbounds; two-factor auth per admin; server-side password reset |
| **Automation** | Nightly backups (disk and Telegram), proactive alerts, opt-in auto-update, clean-IP refresh, health check |
| **Panel** | English, Persian (RTL), Russian; global search, setup wizard, per-section guides, and a full in-panel manual; light and dark |

---

<a id="-how-it-compares"></a>

<img src="./assets/readme/section-compare.svg" width="100%" alt="Comparison: How it compares">


| | Nova Server | 3x-ui | Marzban |
|---|:--:|:--:|:--:|
| Xray + sing-box (Hysteria2, TUIC, NaiveProxy) | ✅ | Xray only | Xray only |
| Native WireGuard inbound | ✅ | plain |  ✗ |
| Reality | ✅ | ✅ | ✅ |
| Login IP ban (fail2ban-style) | ✅ |  ✗ |  ✗ |
| Outbound webhooks | ✅ |  ✗ |  ✗ |
| Per-inbound traffic charts | ✅ | ✅ |  ✗ |
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

<a id="-architecture"></a>

<img src="./assets/readme/section-architecture.svg" width="100%" alt="Under the hood: Architecture">


<img src="./assets/readme/architecture.svg" width="100%" alt="Clients connect over a single port 443 (TCP and UDP) to one Nova node. Inside the node, one self-hosted agent drives four lanes: Xray-core (VLESS, VMess, Trojan, Reality, Shadowsocks), sing-box (Hysteria2, TUIC, NaiveProxy), AmneziaWG (obfuscated WireGuard), and the Nova agent (panel, REST API, Telegram bot, automations).">

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

<br>

<a href="https://github.com/oil-oil/beautify-github-readme"><img src="./assets/readme/made-with-beautify.svg" width="260" alt="README made with beautify-github-readme"></a>

</div>
