# Nova Server v1.7.1

A user-experience fix for the Users page.

## Fixed

- **"Could not access the node" after a user action.** Enable, Disable, Extend, and Reset (and the bulk versions) succeeded, but on a multi-protocol node the panel showed a "Could not access the node" error until you refreshed. The panel is served through xray on port 443, so applying the change restarted xray and dropped the very request that triggered it before its response arrived. The node now sends the response first and restarts xray a moment later, so the action completes cleanly with no false error. Enforcement of quota and expiry from the background loop is unchanged.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Existing nodes update themselves from Settings > Updates.
