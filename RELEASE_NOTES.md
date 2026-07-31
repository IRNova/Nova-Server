# Nova Server v1.26.5

Nova Server 1.26.5 polishes the persistent agent build indicator and keeps it synchronized with live update checks.

## A clearer agent build indicator

- The sidebar now presents the agent build as a compact, readable version badge instead of a long overflowing string.
- The full build identifier remains available as a tooltip for diagnostics.
- Update checks refresh the visible badge immediately when a newer current version is reported.
- English, Persian, and Russian layouts keep the badge aligned without wrapping or clipping.

## Validation

- Regression coverage verifies version formatting, live update synchronization, and compact badge styling.
- The production archive remains source-free and excludes tests, Git metadata, source maps, and internal instructions.

## Upgrade

Existing servers can update normally from the panel. No database migration is required.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.

---

# Nova Server v1.26.4

Nova Server 1.26.4 fixes certificate activation feedback and subscription addresses across the panel, API, Telegram bot, installer, and recovery tools.

## Certificates that recover and explain failures

- Let's Encrypt HTTP validation can add a tracked Nova-owned UFW rule for TCP port 80 while preserving rules that already existed. If ownership tracking cannot be saved, Nova removes only the rule it just added.
- Fresh installation reports immediate certificate request failures and timeouts instead of silently falling back.
- Candidate activation uses a longer retry window for the local Xray TLS front on slower VPS instances.
- Nova captures the peer certificate as soon as the TLS response arrives, avoiding a false readiness failure after Node releases the response socket.
- English, Persian, and Russian errors now distinguish Xray configuration rejection, Xray restart failure, sing-box restart failure, and TLS-front readiness failure.
- Transactional activation still restores the previous certificate, runtime configuration, services, settings, and Nova-created Cloudflare DNS change on failure.

## Subscription links that open correctly

- IP-only nodes no longer advertise plaintext HTTP subscription URLs on an unserved port.
- Subscription secrets always use HTTPS, including self-signed nodes.
- Custom front ports are preserved in panel, REST API, Telegram, installer, enrollment, and recovery output.
- SSH recovery commands load the active front port from Nova's root-owned environment, reject malformed replacement hosts, and never reflect rejected host text into terminal output.
- IPv6 literals remain complete and are correctly bracketed in URLs.
- Unsafe Host-header authorities are rejected instead of being reflected into generated links.

## Validation

- Regression coverage includes self-signed IPv4, IPv6, custom front ports, host injection, installer certificate failures, slow Xray readiness, TLS socket lifecycle handling, and real admin and REST subscription responses.
- The production archive contains obfuscated runtime modules and excludes tests, Git metadata, source maps, and internal instructions.

## Upgrade

Existing servers can update normally from the panel. No database migration is required.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
