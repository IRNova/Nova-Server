# Security and verification

Nova Server runs on a VPS that you own and control. This document explains what
you can inspect, how downloads are verified, and how to report a problem.

## What you can inspect

- The installer and setup scripts in this repository (`nova-node.sh`,
  `nova-bridge.sh`, `nova-uninstall.sh`) are **plain shell**. Read them before you
  run them, they are the code that touches your server.
- The node runs entirely on **your own machine**, under your control. You can
  inspect its processes, files, open ports, and network traffic at any time.
- The proxy cores it installs (xray-core, sing-box) come from their own published
  releases over HTTPS.

## The agent is a closed, obfuscated build (on purpose)

The node agent and panel are distributed as an **obfuscated build**
(`nova-node-agent.tar.gz`); their source is not public. This is deliberate: the
agent and panel are the product, and keeping them closed limits cloning and abuse
of the network. We are not claiming the agent is open source, and you should not
treat it as auditable line by line.

What we make verifiable instead is **integrity** and **containment**:

- **Integrity** — the build you install is exactly the one we published (see
  below), not something swapped in transit.
- **Containment** — the node runs entirely on your own machine, so you can watch
  what it actually does: its processes, files, open ports, and outbound traffic.

If line-by-line source review matters to you, Nova Proxy (the Cloudflare Worker)
is fully open and unminified in [`IRNova/Nova-Proxy`](https://github.com/IRNova/Nova-Proxy);
the node agent is not.

## Verifying the agent download

The agent ships with a published [`SHA256SUMS`](SHA256SUMS) next to the tarball.
The installer verifies the downloaded agent against that checksum **before
extracting** and aborts on a mismatch (fail-closed). You can check any copy
yourself:

```bash
curl -fsSLO https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node-agent.tar.gz
curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/SHA256SUMS | sha256sum -c
```

A self-hosted node only ever runs the build you installed; it does not fetch or
execute remote code at runtime beyond the updates you trigger.

## Reporting a vulnerability

Please report security issues privately first, so users are not exposed before a
fix ships:

- Telegram: **[@irnova_proxy](https://t.me/irnova_proxy)**
- Or open a **private security advisory** on this repository (Security tab).

We aim to acknowledge reports quickly and to credit reporters who want it. We do
not condone harassment of anyone who reports an issue in good faith.
