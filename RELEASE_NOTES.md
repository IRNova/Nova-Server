# Nova Server v1.19.0

A server-side recovery command, and per-config domains.

## Added

- **`nova-access` recovery command.** When the panel is unreachable after a domain,
  Cloudflare, or SSL change, recover it from the server over SSH without the web UI.
  Run `nova-access` to print the current panel URL and TLS mode, or `nova-access --reset`
  to revert to a self-signed no-domain node (everything falls back to the server IP).
  It can also set or clear the stealth path (`--path`), the dedicated panel port
  (`--port`), or point the panel at a new host (`--host`), then restarts the agent.
- **Per-inbound public address.** A new optional field on any inbound puts that one
  config on its own domain or subdomain: its subscription links dial that address
  instead of the panel's main host, so different configs can live on different
  subdomains. Point the DNS at the same server; the SNI stays the field above, so
  set it too when a domain needs its own certificate. It bypasses the Iran-bridge
  reroute, and it is carried across the raw, Clash, and sing-box formats.

## Fixed

- The Iran-bridge installer now always puts the bridge's public IP in the
  certificate's SubjectAltName, so a wssmux/TLS client no longer rejects it with
  "bad certificate" and the tunnel establishes on the first try.

## Notes

- Both features are opt-in and change nothing for existing setups until you use them.
- Existing nodes pick this up through the panel's version-gated update. Nova Server
  ships as an obfuscated build by design; the installer and verified tools stay open.
