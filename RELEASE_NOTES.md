# Nova Server v1.25.0

Nova Server 1.25.0 adds an all-in-one Setup Assistant and completes the remaining security and lifecycle hardening.

## Setup Assistant

- Opens automatically on the first authenticated panel visit and stays available for later adjustments.
- Asks simple questions about personal, family, or business use, network restrictions, safer browsing, and users.
- Explains and plans a single server, an Iran bridge, an additional Nova node, or both.
- Guides primary domains, bridge domains, trusted certificates, and Cloudflare DNS.
- Explains that Cloudflare orange-cloud proxying supports WebSocket traffic, while Reality and Hysteria2 remain direct.
- Shows every active protocol, transport, security method, obfuscation choice, and port before applying changes.
- Preserves manually created users and inbounds and links into the existing domain, bridge, and pinned node tools.
- Includes complete English, Persian, and Russian guidance.

## Security and reliability

- Self-signed parent and node enrollment now pins the exact certificate before any owner token is sent.
- Fresh installation requires a root-only, one-time claim token and uses a 128-bit secret panel path.
- Host values and join URLs are validated against shell injection and remote cleartext downgrade.
- Docker images run only the installer and checksum-pinned package bundled into the signed image.
- Interrupted Docker setup can resume safely, and recreated containers restore missing runtime files without replacing persistent configuration.
- Docker completion markers are written only after both the local API and HTTPS proxy front are healthy.
- Webhook delivery pins validated public DNS answers, rejects internal and mixed targets, and revalidates redirects.
- Certificate storage is created with restrictive ownership and rejects unsafe symlink paths.
- Active bridge domains create subscription alternatives without starting duplicate tunnel control connections.
- Uninstall removes Nova-owned runtime, firewall, tunnel, and helper artifacts while preserving host tools and rules Nova did not create.
- The public archive now fails closed if tests, Git metadata, source maps, or repository-only development instructions enter the package.

## Upgrade notes

- Existing standalone servers can use the normal in-panel update.
- Existing self-signed fleet nodes must be removed and enrolled again after the parent is updated. This stores the new certificate pin and rotates the owner token.
- The public repository contains the obfuscated runtime package, installers, documentation, checksums, and Docker release context. The unobfuscated server source remains private.
