<div align="center">

# Nova Server

**Your own proxy server on any VPS, with a full admin panel.**

Turn a plain Linux server into a private, censorship-resistant proxy node in a few minutes. Multi-protocol, multi-user, multi-node, with a modern panel in English, Persian, and Russian.

`Xray-core` + `sing-box` (Hysteria2) + `AmneziaWG` behind one port, driven by a single self-hosted agent.

</div>

---

## Install

On a fresh Ubuntu/Debian server, run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The installer sets up the proxy cores, the panel, and the tunnel backends, then prints your panel URL. Open it, set an admin password, and use the **Setup Wizard** to add a domain, a recommended protocol, and your first user.

To reset a forgotten password from the server:

```bash
nova-passwd 'YourNewPassword' --clear-2fa
```

---

## Features

### Protocols and inbounds
- **VLESS, VMess, Trojan, Shadowsocks** over TLS/WS/gRPC/XHTTP/HTTPUpgrade
- **VLESS-Reality** with XTLS-Vision (DPI-resistant, no domain needed)
- **Hysteria2** (QUIC/UDP) with Brutal congestion control and Salamander obfuscation
- **WireGuard** native inbound (per-peer keys and downloadable `.conf` + QR)
- **AmneziaWG** (obfuscated WireGuard with junk packets)
- Add standalone inbounds on any port, assign each to all users or a chosen few

### Users
- Data quota (total, or split upload/download), expiry (fixed or from first connection), device/IP limit, and daily/weekly/monthly data reset
- Per-user access control: pick exactly which protocols and inbounds each user gets
- One personal subscription link per user with a live usage page and every config as a QR
- Auto-enforcement: over-quota, expired, or over-device-limit users are cut off automatically

### Routing and egress
- Point-and-click routing: geosite/geoip/CIDR/domain/protocol matchers
- **Direct Iran** and domestic bypass (keep your real IP for .ir sites), bypass China/Russia, block ads/porn/BitTorrent/QUIC
- Extra exits built in: **WARP** (with your own WARP+ license), **Tor**, and **Psiphon**, each with install/test/status
- Custom outbounds (SOCKS/HTTP upstream, freedom, blackhole, raw) and per-inbound egress assignment
- Secure DNS (resolve on the node) and anti-sanction DNS

### Iran bridge tunnels
- Front your foreign exit with a clean-IP server inside Iran
- Selectable backends: **Backhaul** and **BackPack** (recommended), **rathole**, **wstunnel**
- Carries TCP and UDP, so Hysteria2 keeps working through the tunnel
- Step-by-step setup wizard right in the panel

### Domain and free SSL
- One-click **Let's Encrypt** (Xray steps aside automatically, no manual port 80)
- **Cloudflare full-auto**: connect a token once, then Nova creates the DNS record and issues a wildcard certificate for you
- Or paste a Cloudflare Origin certificate
- Auto-renewal, applied across all users and inbounds

### Operations
- **Multi-node fleet**: manage many Nova servers from one panel, aggregate users and usage, provision remotely
- **REST API** (`/api/v1`, token auth) and a **full Telegram bot** (button menu + a Mini App that opens the whole panel inside Telegram)
- **Multiple admins** with an owner and reseller roles
- **Two-factor auth** (Google Authenticator)
- **Automation**: nightly backups (to disk and Telegram), proactive alerts, opt-in auto-update, and clean-IP refresh
- **Health check** and one-click self-update
- Backup and restore, per-ISP client auto-tuning, and an in-panel manual in three languages

---

## Panel

- Modern, responsive UI in **English, Persian (RTL), and Russian**
- Global search (Cmd/Ctrl+K), a first-run setup wizard, and a full built-in guide for every section
- Light and dark themes

---

## Architecture

```
                         :443 (TCP/UDP)
  clients  ───────────────────────────────►  Nova node
                                              ├─ Xray-core   (VLESS/VMess/Trojan/Reality/SS)
                                              ├─ sing-box    (Hysteria2, UDP)
                                              ├─ AmneziaWG   (obfuscated WireGuard)
                                              └─ Nova agent  (panel, API, Telegram, automations)
```

The agent is a single Node.js process. Settings live in a local SQLite store. The panel, the REST API, and the Telegram bot all drive the same internal service functions.

---

## Requirements

- A VPS running Ubuntu 20.04+ or Debian 11+ (x86_64 or arm64)
- Root access
- A domain is optional (needed only for a trusted certificate and the Telegram Mini App)

---

## Updating

The panel checks for new versions and updates in one click, or turn on automatic updates. Users, inbounds, and settings are preserved.

---

## Links

- Panel client apps and more: [novaproxy.online](https://novaproxy.online)
- Telegram: [@irnova_proxy](https://t.me/irnova_proxy)

---

<div align="center">
Nova Server. All rights reserved.
</div>
