# Nova Server v1.32.8

## A fleet node can now have its own WARP account

An inbound placed on a node and set to leave through WARP had nowhere to go. WARP needs a Cloudflare registration on the machine that actually dials out, and a node closes its admin surface, so there was no way to create one. The health check would tell you the node could not provide that egress, and there was nothing you could do about it.

Nodes now register their own account, driven from the panel. Each node gets its own identity, which is the correct arrangement: sharing one registration across the fleet would put every node behind a single WARP endpoint and undo the reason for having several.

A node that already has an account reports it instead of registering again, so a repeated click cannot orphan the identity the running configuration depends on. The account token itself is never handed back to the panel; it stays on the node that owns it.

## The response no longer dies before it arrives

Found while testing the above against a real node. Registration reloads the core so the new egress exists, but on a node the core *is* the front carrying the request, so reloading it killed the reply in flight. The registration succeeded and the caller saw a dropped connection, which reads as "the node is unreachable" for work that had completed, inviting a retry of something already done.

The reload now waits until the response has been delivered, the same way the panel's own user actions have always done.

## Verification

Exercised end to end against a live fleet node: registration on a node with no account returns the endpoint it was given and the account persists; the health of the node and its core are unchanged; and registering a second time reports the existing account rather than replacing it. The reload fix was confirmed by clearing the account and repeating the registration, which now returns its result instead of an empty reply.

## Upgrading

Nodes with automatic updates enabled will take this on their next check. To update now, use the panel's update button, or re-run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
