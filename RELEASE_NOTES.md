# Nova Server v1.9.2

Documentation only, no behavior change.

## Docs

- The README, DEPLOY guide, and the in-panel **Nodes** guide now explain that node
  enrollment sends the node's access token to the panel over a verified,
  key-pinned connection (so it can't be intercepted), and note to generate a fresh
  "Add a node" command if you rotate or change the panel's certificate.

Everything else is unchanged from v1.9.1.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Existing nodes update themselves from Settings > Updates.
