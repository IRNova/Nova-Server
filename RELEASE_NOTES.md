# Nova Server v1.26.1

Nova Server 1.26.1 fixes Cloudflare account-owned API token support and makes failed automatic certificates clear and recoverable.

## Cloudflare token compatibility

- Both user API tokens and account-owned API tokens are accepted.
- Nova discovers the accessible account from the token's zones and verifies account-owned tokens through the correct Cloudflare account endpoint.
- Connecting Cloudflare now confirms that the token can list at least one active zone, so a missing Zone Read permission is reported before domain setup begins.
- Use a scoped token with Zone DNS Edit and Zone Read for the domains Nova should manage.

## Domain and certificate recovery

- Automatic Cloudflare setup creates the DNS record and uses DNS validation, so inbound TCP port 80 is not required.
- Automatic Let's Encrypt now clearly explains that the domain must already point directly to the server and TCP port 80 must be reachable.
- Certificate errors distinguish DNS resolution, port 80 reachability, and Cloudflare permission problems in English, Persian, and Russian.
- Raw commands, API errors, tokens, internal paths, and process details are no longer exposed in the panel.

## Upgrade

Existing servers can update normally from the panel. No database migration is required. If a valid account-owned Cloudflare token was previously rejected, reconnect the same token after updating.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
