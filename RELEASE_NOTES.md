# Nova Server v1.28.0

Nova Server 1.28.0 fixes three ways a config could be handed out that did not work, and makes the node's certificate, rather than a saved setting, decide which domains it claims to answer for.

## Configs that pointed at the wrong server

- An inbound running on a fleet node was listed at the panel's address in the Clash and sing-box subscriptions, so that entry dialled a port the panel does not listen on and could never connect. It now uses the node's own address, matching the plain subscription.
- Resilience mode spreads an inbound across every node. The Clash and sing-box subscriptions only ever carried the local copy, so the redundancy was missing from the formats most desktop clients import.
- Per-country exits reached the plain subscription only. A user who had opted into them received none in Clash or sing-box.

Both subscription builders now share one function for deciding where an inbound lives, so they cannot drift apart again.

## The Telegram bot hands out the same configs as the subscription link

- Configs sent by the bot were missing the Iran bridge routing, the spread across nodes, and the extra-domain fallbacks. A user who took their configs from the bot quietly received a weaker set than one who imported the subscription link.
- A user with many inbounds got an error and no configs at all, because the whole list was sent as one message and Telegram rejects anything over its size limit. The list is now split across messages, always between configs, never through one.

## The certificate decides what the node claims

- The wildcard setting records what was requested when a certificate was ordered, not what was issued. A node could hold the setting without holding a matching certificate, and then every subdomain looked valid while no client could verify it.
- Nova now reads the certificate itself and trusts what it actually covers. Where no certificate can be read, the previous behaviour is kept, so nothing changes for a node that was already correct.

## Configs current clients would not load at all

- Recent sing-box versions removed the routing fields Nova was still using, and the Nova client itself ships one of those versions. Any server with ad blocking, Iranian direct routing, or QUIC blocking turned on was producing a config that sing-box refused to open. Those settings now use the current form and load again.
- A user whose name matched one the client reserves for itself (for example "DIRECT") made the client throw away the entire subscription, not just that one entry. Names are now made unique before they are sent.

## Validation

- 446 automated tests pass, including regression coverage for fleet placement, resilience, per-country exits, message splitting, client-reserved names, the current sing-box routing form, certificate pinning, and certificate reading verified against real certificates.
- The production archive remains source-free and excludes tests, Git metadata, source maps, and internal instructions.

## Upgrade

Existing servers can update normally from the panel. No database migration is required.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.

---

# Nova Server v1.27.0

Nova Server 1.27.0 lets the QUIC protocols answer for a node's extra domains, replaces the free-text public address with a picker, and adds configuration health checks that catch a node handing out configs that cannot connect.

## Hysteria2, TUIC and NaiveProxy can choose a domain

- Each of these inbounds now presents the certificate for its own domain instead of always using the node's primary pair.
- The subscription advertises that same name, so the link and the listener always agree. Clash, sing-box and the raw list all match.
- A node with no extra domains produces exactly the configuration it did before.
- A domain the node holds no certificate for falls back to the main host rather than emitting a link that cannot connect.

## A domain picker instead of a free-text box

- The inbound editor lists only domains with a working certificate, plus a Custom option.
- Choosing one moves the connection name with it, which previously had to be remembered by hand.
- Reality inbounds keep their borrowed SNI untouched, because that name is meant to imitate an unrelated site.
- An inbound whose public address was literally the main host is normalised to blank on save. Blank means the main host and keeps the Iran bridge routing, the multi-node spread and the extra-domain fallbacks, all of which a literal value switched off.

## Configuration health checks

- Diagnostics previously inspected only services, ports, disk and certificate expiry, so a node could report perfect health while a config was undeliverable.
- New checks: a connection name with no certificate, a QUIC dial address with no certificate, an inbound no user receives, and a user whose inbound list is empty and therefore denies everything.
- Each finding offers one-click fixes, re-validated on the server before anything is written, and configuration problems now affect the headline verdict.
- Inbounds that run on another node are left to that node, and an inbound reserved to a plan is reported as a note rather than a failure.

## Validation

- 427 automated tests pass, including regression coverage for certificate selection, subscription output in every format, and each health check and its fix.
- The production archive remains source-free and excludes tests, Git metadata, source maps, and internal instructions.

## Upgrade

Existing servers can update normally from the panel. No database migration is required.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.

---

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
