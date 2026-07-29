# Nova Server v1.14.9

A manual "Reapply core" control.

## Added

- A **Reapply core** button in the dashboard System row. It rebuilds xray's config
  from your current settings and reloads the proxy core, so it clears a stuck core or
  a stale config left by a change that no save happened to touch. The panel briefly
  reconnects while xray reloads, and a confirm tells you so before it runs.

## Notes

- Normal saves already reload xray automatically when an xray-relevant setting
  changes; this is the manual safety valve for the cases that do not trigger that.
- Existing nodes pick this up through the panel's version-gated update. Nova Server
  ships as an obfuscated build by design; the installer and verified tools stay open.
