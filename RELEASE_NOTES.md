# Nova Server v1.26.0

Nova Server 1.26.0 adds one safe place to manage primary, additional-server, Iran-bridge, and managed-node domains, and improves the Setup Assistant for multi-server planning.

## Multiple domains and certificates

- Keep one primary panel domain and add up to 20 additional domains or subdomains for the same server.
- Choose automatic Let's Encrypt, automatic Cloudflare DNS, or a validated pasted certificate for each address.
- Nova verifies the certificate and a candidate Xray reload before publishing a new address in subscriptions.
- Failed and pending domains stay private and never appear in user configurations.
- Cloudflare orange-cloud addresses are automatically limited to the shared WebSocket front because direct TLS, Reality, and UDP cannot pass through that proxy.
- Hysteria2, TUIC, and NaiveProxy aliases are published only when the primary Cloudflare wildcard certificate covers the subdomain.

## Bridges, nodes, and guided setup

- The panel clearly separates ordinary server aliases, Iran bridge domains, and managed-node domains so an address cannot be attached to the wrong traffic path.
- A new managed node can receive its trusted domain and certificate email in the generated one-command enrollment flow.
- Setup Assistant users can select an Iran bridge and an additional node independently, including both together.
- The assistant remains available after installation for later changes and explains the protocols, transports, security methods, and ports before applying a plan.
- Domain and certificate storage is created automatically with restrictive permissions. No manual `chmod 777` workaround is required.
- Cookie-authenticated admin changes now reject cross-origin requests and simple-form content types, closing a same-site sibling-subdomain CSRF path.

## Upgrade

Existing standalone servers can update normally from the panel. No database migration or manual domain change is required.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
