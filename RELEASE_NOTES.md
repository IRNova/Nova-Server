# Nova Server v1.14.2

Documentation: how to remove a node from the terminal.

## Changed

- The in-panel Nodes guide (English, Persian, Russian) now notes that an offline
  node can be wiped over SSH with `nova-uninstall` and then cleared from the panel.
- DEPLOY.md splits "remove a node" into the panel path and the terminal path, so the
  full lifecycle (detach, wipe, or unmanage) is documented in one place.

## Notes

- No behavior change: node removal already worked from the Nodes page and via
  `nova-uninstall`. This release only documents the terminal workflow.
- Nova Server ships as an obfuscated build by design; Nova Proxy and the verified
  tools stay open.
