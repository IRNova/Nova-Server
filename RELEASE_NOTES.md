# Nova Server v1.21.0

A domain and valid certificate for each Iran bridge.

## Added

- **Bridge domains with per-SNI certificates.** In the Tunnel section, give each Iran bridge its own domain with a valid certificate. Nova auto-issues and renews it over Cloudflare DNS (even though the domain points at the Iran bridge), or you can paste your own certificate, which the panel verifies covers the domain before saving. The foreign exit then serves the matching certificate by SNI, so clients dial the bridge domain directly, with no allowInsecure, and each config looks like a different site to a censor. Put the bridge domain in the failover-bridges list and each config presents its own domain as SNI.

## Notes

- Opt-in and default off; existing setups are unchanged. Certs live at /etc/nova/certs and renew hands-off.
- Existing nodes pick this up through the version-gated update. Nova Server ships as an obfuscated build by design; the installer and verified tools stay open.
