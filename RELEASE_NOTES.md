# Nova Server v1.20.0

One switch to survive an IP block.

## Added

- **Resilience mode.** A single toggle on the Nodes page that spreads every config
  across all of your infrastructure at once. When on, every standalone protocol runs
  on the main server AND every node, and each user's subscription lists each config
  once per server and once per Iran bridge. The client url-tests and fails over
  automatically, so a single blocked IP never takes a user offline, with no per-inbound
  placement or per-user node setup. Give each protocol a unique port.

## Notes

- Opt-in and default off; existing setups are unchanged until you turn it on.
- Every node then holds all protocols' keys and served users' credentials, so only
  enable it across nodes you trust at the same level as the main server.
- Existing nodes pick this up through the panel's version-gated update. Nova Server
  ships as an obfuscated build by design; the installer and verified tools stay open.
