# Nova Server v1.1.7

Fixes from real-world Iran testing.

## Fixes
- **"Could not access the node" when saving is fixed.** On a node with VMess or Trojan enabled, every Save was restarting xray (which briefly drops the panel it is served through), so saving settings often failed. xray now reloads only when a change actually needs it (a config or user change), not on every Save.
- **Subscriptions now load in normal client apps on a no-domain node.** Apps like Hiddify, sing-box, Shadowrocket, HAPP, FoxRay and V2Box reject a self-signed certificate when fetching the subscription URL. A no-domain node now also serves the read-only subscription over plain HTTP, and hands out an http subscription link, so those apps can fetch it. Only the subscription is served this way; the admin panel is never exposed over HTTP. If you use a domain (trusted certificate), nothing changes.
- The panel now quietly retries a read once if a config change briefly restarts xray, so a Save that does reload no longer shows a connection error.
- Fixed the per-carrier optimization toggles (TLS fragment, Mux) overlapping their labels.
- Rewrote the Tunnel setup guide for the new lightweight Iran bridge: you no longer install the full stack on the Iran box, you run one generated command.

## Install
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```
