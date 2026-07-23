# Nova Server v1.1.6

Extends per-operator subscription configs to all client formats.

## Change
- The **Per-operator configs in subscription** option now also applies to the Clash-Meta and sing-box subscription formats, not just the plain link list. Each carrier variant carries the right uTLS fingerprint natively (`client-fingerprint` for Clash, `utls.fingerprint` for sing-box), and the fingerprint is normalized per client so mihomo gets a value it accepts. Off by default, no effect when off.

## Install
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```
