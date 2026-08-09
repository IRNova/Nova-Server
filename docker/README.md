# Nova node in Docker or Podman

Run a full Nova node in a container. This is an alternative to the native
one-line installer, for people who prefer containers (reproducible, easy to stop
or move, clean upgrades). All node data lives on named volumes, so `down` then
`up` keeps your users, settings, and certificate.

> A container node needs a real Linux host with host networking. It does not work
> on Docker Desktop for Mac or Windows (they cannot bind the host's :443 the way a
> node needs), and it does not work under rootless Podman for the same reason.
> The setup script checks both and refuses rather than leaving you with a
> container that starts and serves nothing. Use the native installer there, or run
> on a Linux VPS.

## One-line setup

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker/nova-docker.sh)
```

It installs Docker if you have neither runtime, downloads and verifies the
release package, bundles the installer and agent into the image, starts the node,
and then **follows the first boot to its end and prints your panel URL and admin
password**. Do not close the terminal until it does.

Pass the same options as the native installer as environment variables:

```bash
NOVA_DOMAIN=node.example.com NOVA_ADMIN_PASS='StrongPass123' \
  bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker/nova-docker.sh)
```

## Podman

Podman is picked up automatically when it is the only runtime installed. On a
host that has both, force it:

```bash
NOVA_CONTAINER_RUNTIME=podman bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker/nova-docker.sh)
```

Run it with `sudo`, so Podman runs rootful. Rootless Podman cannot bind the
host's `:443` and cannot reach the host's kernel modules, so a node started that
way would look healthy and serve nothing.

One Podman-specific detail is handled for you. `podman-compose` silently drops
the compose file's request for the host cgroup namespace, which leaves systemd
inside the container with a cgroup tree it does not own; systemd then exits
instantly with no output at all. The image's entrypoint detects that and gives
systemd a correct cgroup2 mount before handing over.

## Manual setup

```bash
mkdir nova-docker && cd nova-docker
for f in Dockerfile entry.sh logstream.sh firstboot.sh nova-firstboot.service docker-compose.yml .dockerignore .env.example; do
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

Leaving all of them blank is fine and is what most people do. They arrive in the
container as empty variables, which the installer reads as "use the defaults":
a generated password and a random secret panel path, both printed at the end of
the install log.

Three things to know about the password. A password you set stays in `.env` and
in the container's configuration, so anyone who can run `docker inspect
nova-node` can read it; a generated one is kept nowhere once the install
finishes. Either one is printed once into the container log, which is where you
read it from. And **a password you set here cannot contain `$`, `` ` ``, `\`,
`'` or `"`**: Compose rewrites those before the container ever sees them, so
`Str0ng$Pass-1!` would quietly become `Str0ng-1!`. The setup script refuses them
with that reason rather than installing a node whose password is not the one you
chose. If you want one of those characters, leave the password blank and set it
in the panel after the install.

## Where the install log is

The container runs systemd as PID 1. systemd sends service output to its own
journal, so nothing a service prints reaches `docker logs` on its own. The image
therefore starts a small relay (`logstream.sh`) before handing off to systemd,
which mirrors the first boot to the container's stdout. That is why these all
show the same thing:

```bash
docker compose logs -f nova-node                                   # live, and after the fact
docker compose exec nova-node cat /var/log/nova-firstboot.log      # this boot's copy
docker compose exec nova-node journalctl -u nova-firstboot         # full history, all boots
```

`/var/log/nova-firstboot.log` is root-only and is recreated on every container
start, so a restart never streams an old install into the container log again.

That is not the same as the password going away. **The first boot's output stays
readable in two places until the container is recreated**: the container log
(`docker compose logs`, kept by the host, capped by this compose file at 30 MB)
and the container's own journal (`journalctl -u nova-firstboot`). Both are
root-only, and neither is readable by xray or by anything else the node runs.
But if other people can read your host's container logs, treat the password as
seen and set a new one with `nova-passwd`.

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

## What a container node cannot do

- **The AmneziaWG server needs a kernel module.** A container cannot build or
  install one for the host, so unless the host kernel already provides
  `amneziawg`, first boot says so and the node comes up without it. Every other
  protocol works: VLESS, VMess, Trojan, Reality, Shadowsocks, Hysteria2, TUIC,
  the Telegram MTProto proxy, mieru, and the tunnel backends.
- **One node per host.** Host networking means two container nodes, or a
  container node next to a native install, fight over `:443` and the agent's
  local port. The second one restarts forever with `address already in use`.

## Common commands

```bash
cd /opt/nova-docker/docker
docker compose logs -f nova-node     # watch logs / find the panel URL
docker compose restart nova-node     # restart
docker compose down                  # stop (keeps the data volumes)
docker compose up -d --build         # start / upgrade
docker compose down -v               # stop AND delete all node data
```

Forgot the panel path? Print it from inside the container. `nova-access` only
reads, it changes nothing:

```bash
docker compose exec nova-node nova-access
```

Lost the admin password? It cannot be read back, so set a new one:

```bash
docker compose exec nova-node nova-passwd 'NewPassword'
```

With Podman, use `podman-compose` (or `podman compose`) in place of
`docker compose` in every command above.
