# Nova Server v1.32.4

1.32.3 made node certificates safe to change but left them reachable only over the API. This release adds the panel screen, and stops the panel from sending an unsafe request to a node that has not updated yet.

## Node certificates now have a screen

Each node in the Fleet list has a **Certificate** button. It shows the node's primary domain, the names on its current certificate, and any additional domains with their status, then offers the two operations 1.32.3 separated:

- **Add a domain**, which leaves the node's existing certificate serving and publishes the new one alongside it. This is what an inbound that needs its own name should use.
- **Change primary**, which is presented as the destructive action it is, since every link already issued on the old name stops working and the node's address in the panel changes.

Before this, neither these nor the certificate endpoint added in 1.31.0 had any control in the panel at all.

## The panel no longer sends "add a domain" to a node that cannot do it

A node older than 1.32.3 does not know the field that distinguishes the two operations, and an unknown field is ignored rather than rejected. So "add a domain" aimed at an older node fell straight through to the old behaviour and replaced its certificate: the exact outage 1.32.3 exists to prevent, performed by the button meant to avoid it.

The panel now asks the node what it supports before sending anything, and refuses with an explanation if the node is too old. It reads the answer from the node's own certificate response rather than comparing version strings, so it cannot be fooled by a node that reports a version it does not behave like.

If you run fleet nodes, update the nodes as well as the panel. Until a node takes 1.32.3 or later, adding a domain to it stays unavailable, which is the point.

## Verification

The panel screen was driven in a browser against a live agent: the certificate view, both dialogs, and the unreachable-node path. Interface text is present in English, Persian and Russian; the English screens were checked visually.

## Upgrading

Nodes with automatic updates enabled will take this on their next check. To update now, use the panel's update button, or re-run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
