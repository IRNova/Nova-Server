# Nova Server v1.31.2

Completes the 1.31.1 hotfix. **If you took 1.31.1, take this one too**, and note that both ends need it: the guard that stops the disconnect lives on the node, so a panel on 1.31.2 talking to a node on 1.31.1 will still see reloads.

## The disconnect fix did not reach every panel

1.31.1 stopped a configuration push from reloading the node's proxy core when nothing had changed. That was correct, but incomplete.

A node works out some things for itself from its own traffic: when a "N days from first use" plan actually starts, and when a traffic cycle resets. Your panel never sees node traffic, so its copy of the customer has neither. The push overwrote the node's values with the panel's blanks, which made every reconcile look like a change, which kept forcing the reload.

So if your plans expire a set number of days after first use, 1.31.1 did not stop your disconnects. This does. The node keeps what it worked out, and anything the panel actually sets still wins, so changing an expiry on the panel still takes effect.

## A failed reload was never retried

Configuration is saved before the core is reloaded. If that reload failed, the next push saw no difference, skipped the reload, and the node kept serving the old configuration indefinitely while the panel showed the sync as successful. An outstanding reload is now remembered and retried.

## Verification

Emitted configurations were checked against real client binaries: xray-core 26.3.27, mihomo 1.19.29, and sing-box 1.11.15, 1.12.16, 1.13.15 and 1.14.0-beta.4. The subscription and certificate paths were exercised end to end against live servers, including an Android emulator running Hiddify 4.1.1.

Two areas remain **untested** and are called out deliberately: certificate issuance through Cloudflare DNS-01, and per-inbound certificates for individual domains. Both need DNS write access that was not available. If you use either, treat this release as unproven for that path.

## Upgrading

Nodes with automatic updates enabled will take this on their next check. To update now, use the panel's update button, or re-run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
