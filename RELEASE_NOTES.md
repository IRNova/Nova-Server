# Nova Server v1.11.0

One panel, many servers. Create everything on the main panel and place it on your nodes; each node just serves the traffic.

## Added

- **Central fleet, done right.** You manage everything from the main panel. Create
  users on the **Users** page and protocols on the **Inbounds** page as usual. A
  node is a full Nova server that only serves traffic, it has no users or inbounds
  of its own to manage, and no panel to sign in to.
- **Place a protocol on a node.** Adding an inbound now has a **Run on** choice:
  this main server, one node, or **all nodes**. The panel pushes that protocol and
  the users who should have it to the chosen node(s), and each user's subscription
  config uses **that node's address**, so they connect through it.
- **Choose each user's nodes.** On the **Users** page you pick which nodes a user
  gets: tick specific nodes under **Nodes for this user**, or turn on **Access all
  nodes** to include every node in their subscription (one config per location).
- **Nodes keep working on their own.** Config is pushed to each node, so a node
  keeps serving traffic even when the main panel is offline. Node management stays
  add / remove only.

## Changed

- The v1.10.0 "Manage a node" screen is retired. Users and protocols are always
  created centrally now, never on a node, which is simpler and safer.
- Docs and the in-panel **Nodes** guide (English, Farsi, Russian) are rewritten to
  the central model.

## Fixed

- A node-placed inbound whose node has been removed (or an empty fleet) no longer
  falls back to the main server's address in a subscription, it is left out.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Existing nodes update themselves from Settings > Updates.
