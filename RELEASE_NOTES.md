# Nova Server v1.22.0

Faster connections on lossy links.

## Added

- **TCP BBR congestion control (default on).** Nova now enables BBR + the fq qdisc on the node, which measurably improves throughput for TCP-based protocols (VLESS/Reality, Trojan, VMess) on lossy, high-latency links, exactly the conditions on Iran's international routes. It is applied at install and re-applied by the agent on boot, so existing nodes get it through the update. A toggle with a live status line lives in Xray Settings > Network tuning. Hysteria2 has its own congestion control and is unaffected.

## Notes

- On by default; the downside is negligible. Turn it off in the panel if you prefer the kernel default (cubic).
- Existing nodes pick this up through the version-gated update. Nova Server ships as an obfuscated build by design; the installer and verified tools stay open.
