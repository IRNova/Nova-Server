# Nova node in Docker

Run a full Nova node in a container. This is an alternative to the native
one-line installer, for people who prefer Docker (reproducible, easy to stop or
move, clean upgrades). All node data lives on named volumes, so `down` then `up`
keeps your users, settings, and certificate.

> Docker needs a real Linux host with host networking. It does not work on Docker
> Desktop for Mac or Windows (they cannot bind the host's :443 the way a node
> needs). Use the native installer there, or run Docker on a Linux VPS.

## One-line setup

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker/nova-docker.sh)
```

It installs Docker if missing, downloads and verifies the release package,
bundles the installer and agent into the image, and starts the node. Then watch
the first boot install Nova and print your panel URL:

```bash
cd /opt/nova-docker/docker && docker compose logs -f nova-node
```

Pass the same options as the native installer as environment variables:

```bash
NOVA_DOMAIN=node.example.com NOVA_ADMIN_PASS='StrongPass123' \
  bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker/nova-docker.sh)
```

## Manual setup

```bash
mkdir nova-docker && cd nova-docker
for f in Dockerfile entry.sh firstboot.sh nova-firstboot.service docker-compose.yml .dockerignore .env.example; do
  curl -fsSL "https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker/$f" -o "$f"
done
curl -fsSL "https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh" -o nova-node.sh
curl -fsSL "https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node-agent.tar.gz" -o nova-node-agent.tar.gz
curl -fsSL "https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node-agent.tar.gz.sha256" -o nova-node-agent.tar.gz.sha256
cp .env.example .env   # or create .env yourself
docker compose up -d --build
docker compose logs -f nova-node
```

`.env` keys (all optional):

| Key | Meaning |
| --- | --- |
| `NOVA_ADMIN_PASS` | Panel admin password. Blank generates a strong password that is kept across interrupted first-boot retries and printed in the install log. |
| `NOVA_DOMAIN` | A domain pointing at this host. It gets a free Let's Encrypt certificate. Blank uses the host IP with a self-signed certificate. |
| `NOVA_DOMAIN_EMAIL` | Email for certificate renewal notices (optional). |
| `NOVA_PANEL_PATH` | Secret panel subpath. Blank generates a random one; `none` keeps the panel at the root. |
| `NOVA_PANEL_PORT` | Optional extra HTTPS port for the panel. |

## Why it runs the way it does

A Nova node is a VPN appliance, not a plain web app:

- It binds **:443 (TCP and UDP)**, and, when you enable them, **:53/udp** (DNS
  tunnel) and a WireGuard/AmneziaWG UDP port. `network_mode: host` gives it the
  real ports.
- It uses **systemd** to manage xray, sing-box, and optional services (Tor and
  Psiphon exits, tunnel backends, the DNS tunnel), so the container runs systemd
  as PID 1 and installs the node on first boot with the same tested installer as
  the native path.
- The optional **AmneziaWG server** loads a kernel module from the host, which is
  why the compose file mounts `/lib/modules` read-only and runs privileged. If
  you do not need AmneziaWG, you can try replacing `privileged: true` with
  `cap_add: [NET_ADMIN, SYS_ADMIN]`.

## Common commands

```bash
cd /opt/nova-docker/docker
docker compose logs -f nova-node     # watch logs / find the panel URL
docker compose restart nova-node     # restart
docker compose down                  # stop (keeps the data volumes)
docker compose up -d --build         # start / upgrade
docker compose down -v               # stop AND delete all node data
```

Forgot the panel path? Print it from inside the container:

```bash
docker compose exec nova-node nova-passwd 'NewPassword'
```
