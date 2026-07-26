# Nova Server v1.10.0

Central fleet management: run your nodes' users and protocols from the main panel.

## Added

- **Manage a node from the main panel.** The **Nodes** page now has a **Manage**
  button on every reachable node. It opens that node right there, so you can:
  - **Users:** create, edit, enable/disable and delete users on the node (data
    quota, expiry, device/IP limit), and see their usage.
  - **Protocols:** list the node's inbounds, enable/disable or remove them, and add
    a new one (including VLESS-Reality, which needs no domain, the node generates
    its own keys).

  A managed node has no panel of its own, so this is how you run it: the main panel
  drives it over the node's REST API using the access token created at enrollment.
  No signing in to the node, no SSH.

The read-only fleet users list is still there for an at-a-glance view across every
node. Docs and the in-panel Nodes guide are updated.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Existing nodes update themselves from Settings > Updates.
