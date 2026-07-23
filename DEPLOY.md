# Deploying Nova Server

Nova runs on any Linux VPS with root. One command installs the proxy cores (xray, sing-box for Hysteria2, AmneziaWG), the admin panel, and the tunnel backends, and supports every protocol including the UDP ones.

## Install

On a fresh Ubuntu 20.04+ or Debian 11+ server (x86_64 or arm64):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Then open the panel on your server's IP or domain and set an admin password. The Setup Wizard walks you through a domain, a recommended protocol, and your first user.

### Install from your phone (no SSH)

When you create the VPS, paste this into your provider's **User data** / **Cloud-init** box:

```bash
#!/bin/bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The server installs Nova by itself on first boot (about 3 to 5 minutes), then you open `https://YOUR_SERVER_IP` and set a password.

## Update

The panel checks for new versions and updates in one click (Settings, General, self-update), or turn on automatic updates. Re-running the install command also updates an existing node. Your users, inbounds, and settings are preserved.

## Reset the admin password

```bash
nova-passwd 'YourNewPassword' --clear-2fa
```

## Uninstall

Remove Nova, xray, sing-box and all Nova data:

```bash
nova-uninstall
```

Add `--yes` to skip the confirmation prompt. If the command is not present, run it directly:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-uninstall.sh)
```
