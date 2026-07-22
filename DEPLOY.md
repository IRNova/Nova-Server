# Deploying Nova Server

Nova runs three ways. Pick the one your host supports.

| Option | Where | Protocols | UDP (Hysteria2 / WireGuard) |
|---|---|---|---|
| VPS installer | A Linux server with root | All | Yes |
| Docker | Any Docker host | VLESS / VMess / Trojan over WebSocket | No |
| PaaS (runflare, etc.) | Container platforms, port 22 closed | VLESS / VMess / Trojan over WebSocket | No |

## 1. VPS (recommended, full features)

A Linux server with root. Installs xray, sing-box and AmneziaWG natively and supports every protocol, including the UDP ones (Hysteria2, WireGuard) and the Iran bridge tunnels.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Then open the panel on your server's IP or domain and set an admin password.

## 2. Docker (self-host, one-click)

Any Docker host. WebSocket-only (VLESS / VMess / Trojan over WS). Put a TLS edge in front (Cloudflare, or a reverse proxy like Caddy / nginx / Traefik) that forwards HTTPS to the container's port 3000.

```bash
curl -fsSL -O https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker-compose.yml
curl -fsSL -O https://raw.githubusercontent.com/IRNova/Nova-Server/main/Dockerfile
NOVA_PUBLIC_HOST=your.domain docker compose up -d
```

The image pulls Nova's obfuscated release automatically. Data lives on a named volume, so it survives restarts.

## 3. PaaS / provider (runflare and similar), one-click

For Iranian and other container platforms where port 22 is closed to the outside and only HTTP/WebSocket is exposed. WebSocket-only, and the platform provides TLS.

**runflare** (https://runflare.com):

1. Create a project, then a service. Runtime: **Docker**. Expose Port: **3000**.
2. Deploy this repo (it contains the Dockerfile) via the runflare CLI, GitHub, or upload:
   ```bash
   runflare deploy
   ```
3. Add an environment variable `NOVA_PUBLIC_HOST` = your service domain (for example `name.runflare.run`) so subscription links point at it.
4. Attach a disk mounted at `/data` so the user database persists across redeploys.
5. Open the service domain and set your admin password.

Any other Docker or Kubernetes PaaS works the same way: build the Dockerfile, route the platform's HTTPS to the container's port 3000, mount a volume at `/data`, and set `NOVA_PUBLIC_HOST`.

## What is different on PaaS / Docker

No UDP, so no Hysteria2 and no WireGuard there (those need a VPS). Normal browsing, VLESS / VMess / Trojan over WebSocket, and VoIP calls (tunneled over the WebSocket connection) all work. If you need the UDP protocols, use a VPS.
