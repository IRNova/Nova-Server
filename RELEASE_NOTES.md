# Nova Server v1.32.7

## The health check no longer calls an empty subscription healthy

Sing-box and Clash cannot implement XHTTP or httpupgrade, so since 1.29.0 Nova skips those entries rather than emitting configurations those clients cannot use. The health check never modelled that skip: it counted any inbound a user was granted, whatever transport it ran on.

So a user granted only XHTTP inbounds had a working v2rayNG list and a completely empty subscription in sing-box, Hiddify, Karing and Clash, and the health check reported them as fine. The operator had no way to see it short of loading that user's subscription in one of those clients.

Now a user whose every reachable inbound is one the structured formats skip is reported as a failure, naming the clients that get nothing and what to change.

Hysteria2 is deliberately not counted, even when it carries an unusual transport label. Those protocols take free-form labels, so treating them as skipped would report working configurations as broken.

## Upgrading

Nodes with automatic updates enabled will take this on their next check. To update now, use the panel's update button, or re-run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
