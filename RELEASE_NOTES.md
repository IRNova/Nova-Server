# Nova Server v1.31.1

A hotfix for two fleet-sync faults reported from production. **If you run fleet nodes on 1.30.0 or 1.31.0, take this one.**

## Your users were being disconnected every ten minutes

Pushing configuration to a node forced the node's proxy core to reload, which drops every live connection on it. That was harmless while a push only happened when you changed something. 1.30.0 added a ten-minute reconciler so that a node left alone would still receive its configuration, and the two combined into "disconnect every user on every node, once per interval".

A push now compares what it is sending against what the node already has, and reloads only on a real difference. Introduced in 1.30.0; earlier releases are unaffected.

## Inbounds using a custom outbound dropped all traffic

If you defined your own outbound in the panel, a SOCKS5 proxy for example, and set a node inbound to leave through it, the node received the routing rule naming that outbound but never the outbound itself. Its proxy core then routed traffic to a tag it had no definition for, and every connection through that inbound dropped, with nothing in the panel to indicate why.

Nodes now receive the outbounds their inbounds actually use. Only those: a node is never sent credentials for an egress it does not use, and a push that omits them leaves a node's existing egresses alone.

## Verification

Emitted configurations were checked against real client binaries: xray-core 26.3.27, mihomo 1.19.29, and sing-box 1.11.15, 1.12.16, 1.13.15 and 1.14.0-beta.4. The subscription and certificate paths were exercised end to end against live servers, including an Android emulator running Hiddify 4.1.1.

Two areas remain **untested** and are called out deliberately: certificate issuance through Cloudflare DNS-01, and per-inbound certificates for individual domains. Both need DNS write access that was not available. If you use either, treat this release as unproven for that path.

## Upgrading

Nodes with automatic updates enabled will take this on their next check. To update now, use the panel's update button, or re-run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
