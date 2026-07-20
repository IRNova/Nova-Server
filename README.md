<div align="center">

<img src="https://raw.githubusercontent.com/iiviirv/irnova-site/main/brand/nova-logo-gradient.svg" width="70" alt="Nova">

<div align="right">
  <a href="README.fa.md"><img src="https://raw.githubusercontent.com/IRNova/Nova-Proxy/main/flag-iran.svg" height="16" alt="Iran (Lion and Sun)" /> فارسی</a>
</div>

# Nova Server

**The full Nova panel on your own VPS.**

xray-core plus the Nova node agent behind one public port (443), managed from the same
Nova app, browser, or Telegram bot you already use. Multi-protocol (VLESS, Trojan,
Shadowsocks, Hysteria2), per-ISP client optimization, and add-a-domain TLS. Everything
runs on **your** server, and nothing about your traffic is sent out.

[![License](https://img.shields.io/badge/license-MIT-purple?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Debian%20%2F%20Ubuntu-0ea5e9?style=for-the-badge&logo=linux&logoColor=white)](https://github.com/IRNova/Nova-Server)
[![Stars](https://img.shields.io/github/stars/IRNova/Nova-Server?style=for-the-badge&color=8957e5)](https://github.com/IRNova/Nova-Server)

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

Nova Server is the VPS side of Nova. One command installs **xray-core** plus the **Nova node agent** on your own Debian or Ubuntu server and wires them together so a single public port (443) serves both the admin panel and the tunnel. You manage it from the same Nova app, a browser at `https://your-vps`, or the built-in Telegram bot.

Where the Cloudflare Worker cannot run native TCP or handle UDP, a Nova Server can. That means full **VLESS**, real **UDP for voice and video calls**, and **Hysteria2** for low-latency gaming, all on infrastructure you control.

**What makes it different:**
- 🔒 **Your server, your traffic.** Nothing is logged, nothing is sent out.
- ⚡ **One-line install.** Xray and the whole Nova panel, wired up in minutes.
- 🧩 **Multi-protocol.** VLESS, Trojan, Shadowsocks, and Hysteria2 with a configurable UDP port for port-hopping.
- 🌍 **Per-ISP optimization.** Fingerprint and fragmentation auto-tuned for each carrier.
- 🔐 **Add-a-domain TLS.** Point a domain at the server for a real certificate (Let's Encrypt or Cloudflare Origin), or run on the public IP with a self-signed cert.
- 📱 **Managed anywhere.** From the Nova app, a browser, or Telegram.

---

## ⚡ Quick Install

Run on your own VPS (Debian or Ubuntu, as root):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Optional environment variables:

- `NOVA_ADMIN_PASS=...` sets the panel admin password (a random one is generated if unset).
- `NOVA_DOMAIN=...` a domain that points at this server. Without one, the node uses the public IP with a self-signed certificate.

When it finishes, open `https://your-vps` in a browser or add the node straight from the Nova app.

---

## 📋 Requirements

- A **VPS with root SSH access** (Debian or Ubuntu).
- Optional: a **domain** pointing at the server, for a trusted TLS certificate.

---

## 🛠 How it works

Xray terminates TLS on port 443 and dispatches by path: the tunnel path routes to the VLESS, VMess, Trojan and Hysteria2 inbounds on loopback, and everything else goes to the agent's HTTP panel and browser dashboard. The agent is managed from the Nova app, a browser, or the built-in Telegram bot, and it all runs entirely on your server.

---

## 💜 Support

If Nova Server helps you, please **⭐ star the repo**. It keeps the project alive and free for everyone.

<div align="center">

### ⭐ [Star Nova Server on GitHub](https://github.com/IRNova/Nova-Server) ⭐

| Coin | Address |
|------|---------|
| **TON** | `UQD51lGC35rP_SbVYgbFA7CEEii4GVMFgqj4N8fiGi6m425w` |

</div>

---

## 🙏 Credits

Built with ❤️ for a free and open internet.

- [@iiviirv](https://github.com/iiviirv) — contributor
- [Xray-core](https://github.com/XTLS/xray-core)
- [Nova Proxy](https://github.com/IRNova/Nova-Proxy) — the Cloudflare Worker side of Nova

---

## License

MIT, see the [LICENSE](LICENSE) file.

---

<div align="center">

Made for Iran <img src="https://raw.githubusercontent.com/IRNova/Nova-Proxy/main/flag-iran.svg" height="16" alt="Iran (Lion and Sun)" /> and anyone who needs a free, open internet.
**Nothing about your traffic is logged. The server is yours.**

📖 [Persian version](README.fa.md)

</div>
