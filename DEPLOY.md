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

## Verify your download

The installer and setup scripts in this repo are plain shell you can read before running. The node agent ships as `nova-node-agent.tar.gz` with a published `SHA256SUMS` next to it; the installer verifies the agent against that checksum automatically and aborts on a mismatch. To check a copy by hand:

```bash
curl -fsSLO https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node-agent.tar.gz
curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/SHA256SUMS | sha256sum -c
```

## Update

The panel checks for new versions and updates in one click (Settings, General, self-update), or turn on automatic updates. Re-running the install command also updates an existing node. Your users, inbounds, and settings are preserved.

## Iran bridge (lightweight, no full install)

To front your foreign exit with a clean Iran IP, you do not install the full node on the Iran box:

1. On the foreign (exit) node's panel, open **Tunnels**, configure the tunnel, and click **Generate the Iran bridge command**.
2. Run that one command on the Iran VPS. It installs only the tunnel backend (Backhaul, BackPack, rathole, or wstunnel) and starts it as a service (`nova-tunnel`).

Remove the bridge later with `systemctl disable --now nova-tunnel`. The command contains the shared tunnel secret, so keep it private.

## Reset the admin password

```bash
nova-passwd 'YourNewPassword' --clear-2fa
```

## Managed nodes: remove or reclaim

A node added to a fleet with the one-command install runs in managed mode (no panel of its own). It self-registers automatically whether it has a domain or runs on a bare IP with a self-signed certificate. To manage its lifecycle:

- **Enrollment is secure.** The node sends its access token to the panel over a verified TLS connection; when the panel is self-signed the node also pins the panel's key, so the token can't be intercepted in transit. If you rotate or change the panel's certificate (or front it with a different certificate), generate a fresh "Add a node" command, an old one would fail the pin (safely).
- **Enrollment that can't complete shows up, it isn't lost.** If the main panel can't reach the new node back (usually because port 443 isn't open to the internet on it yet), the node appears on the **Nodes** page as **Pending** with the reason, and the attempt is logged. Open 443 on that server and press **Test**, or add the node by hand.
- **Users and protocols are central; nodes just serve.** Create users on the **Users** page and protocols on the **Inbounds** page. When adding a protocol, pick **Run on** (this server, a node, or all nodes); the panel pushes it and its assigned users to that node, and each user's subscription config uses the node's IP. On the **Users** page you choose which nodes each user gets: tick specific nodes under **Nodes for this user**, or turn on **Access all nodes** to include every node in their subscription. A node has no users or inbounds of its own to manage.
- **Remove a node from the panel.** On the main panel's **Nodes** page, click **Remove**. Tick **also uninstall Nova from that server** to have the node tear itself down completely (xray, sing-box, the agent, and all data); leave it off to only detach the node from the fleet while it keeps serving on its own. An offline node is still removed from the fleet, so no dead row is left behind.
- **Remove a node from the terminal.** When the node is unreachable from the panel, or you are already on the box, wipe it over SSH with `nova-uninstall` (the same teardown the "also uninstall" checkbox triggers). See [Uninstall](#uninstall) below for the exact commands. Then, back in the panel, open **Nodes** and click **Remove** on the now-unreachable row (leave the uninstall box off, since it is already gone) to clear the last reference to it. If you only want to unmanage the node without wiping it, skip `nova-uninstall` and just **Remove** it from the panel with the box off; the server keeps running as a standalone Nova install.
- **Reclaim a managed node** as a normal standalone panel (for example if its main panel is gone, or it never finished registering). On that server, over SSH:

  ```bash
  nova-unlock 'YourNewPassword'
  ```

  This turns managed mode off and sets a new owner password. Users and traffic are untouched. A node that fails to register during install is never locked, so it stays a standalone panel you can sign into.

## Uninstall

Remove Nova, xray, sing-box and all Nova data:

```bash
nova-uninstall
```

Add `--yes` to skip the confirmation prompt. If the command is not present, run it directly:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-uninstall.sh)
```
