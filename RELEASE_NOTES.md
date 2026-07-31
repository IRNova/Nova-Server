# Nova Server v1.26.2

Nova Server 1.26.2 makes every primary, additional-server, and Iran-bridge certificate change transactional, so a failed domain attempt cannot take working configurations offline.

## Safe certificate activation

- Nova snapshots the working certificate, private key, renewal hook, Xray config, and sing-box config before starting a domain change.
- Certificate jobs and runtime configuration writes are serialized, so overlapping changes cannot restore stale state over a newer successful change.
- Xray and sing-box restart failures are now observable during certificate activation instead of being treated as success.
- The candidate domain must serve Nova's local build marker through the TLS front and present a certificate that covers its exact SNI before settings are published.
- A failed activation restores the previous certificate and runtime files, reapplies the previous settings, restarts the services, and verifies the restored front.
- Reissuing an already-active additional or bridge domain keeps the previous working address active if the replacement fails.
- Failed automatic Cloudflare activation also restores the previous DNS record or removes the record Nova created.
- Cloudflare credentials, the root renewal hook, and proxy configs now use atomic replacement with exact secret-safe permissions, and their ownership state is included in rollback.
- If rollback itself cannot be verified, the panel gives a distinct trilingual recovery action and warns the operator not to retry until Xray is healthy.

## Upgrade

Existing servers can update normally from the panel. No database migration is required.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
