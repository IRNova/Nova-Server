# Nova Server v1.3.0

A big feature release: easier user management, a last-resort transport, and a Docker install option.

## New

- **User plans, bulk actions, and CSV.** Save reusable **plans** (limit sets like "30 days, 50 GB, 3 devices") and apply them to one user or many. Select multiple users to **enable, disable, extend, reset traffic, apply a plan, or delete** them in one step. **Import and export users as CSV** (re-importing a name updates it instead of duplicating). All reseller-scoped.

- **DNS Tunnel (last resort).** An optional built-in MasterDnsVPN server that carries traffic inside DNS queries, so it keeps working when everything else is blocked but DNS still resolves. Enable it in Settings; it needs a subdomain delegated to the node (an NS record). If your domain is on Cloudflare, the panel creates the delegation for you automatically; otherwise the in-panel guide walks you through the manual records. Users connect with the separate MasterDnsVPN client (the panel exports the config), not the Nova app. Off by default.

- **Install with Docker.** A container-based alternative to the native installer, for people who prefer Docker. One line on a Linux VPS installs Docker if needed, builds the image, and starts the node; your data lives on named volumes. See the "Install with Docker" section in the README (and `docker/README.md`).

## Improved

- The per-operator subscription toggle now sits next to the per-ISP client optimization card in Settings, since both tune the connection per carrier.

## Fixes

- The user list no longer shows an empty green pill on every row (a hidden "online" badge was being shown by a CSS rule).

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Or with Docker:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker/nova-docker.sh)
```

Existing nodes update themselves from Settings > Updates.
