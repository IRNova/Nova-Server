# Nova Server 1.65.0

WARP on your nodes, and a correction to what 1.64.0 left the panel saying about
them.

## A node can provide WARP now, and says so

1.64.0 made a server register the free WARP account its own configuration
implies, which fixed an inbound routed through WARP carrying nothing. That
applies to a node as well: an inbound you place on a node arrives there carrying
its egress, so the node registers its own account and the inbound works.

The panel had not caught up. It still said a node could not provide WARP at all,
and the button it offered was **Send this inbound out directly**. That takes an
inbound you deliberately routed through WARP and publishes the node's own
address instead, which is the address your customer was hiding. On a node that
now works, pressing it would have undone something healthy.

Three changes:

- **The node reports.** Every fleet push comes back with whether that node needs
  WARP and whether it holds an account, the same way it already reports whether
  it can run AmneziaWG.
- **The panel is quiet only when a node has confirmed one.** With resilience
  mode on, an inbound is copied to every node, so it counts as settled only when
  every node has confirmed. Not hearing from a node is not the same as a node
  being fine, so that still shows.
- **The remedy is to register, not to expose.** The button now asks that node to
  register a free account. It works on any node you have, cannot expose anyone,
  and on a node that already has an account it simply confirms it. With
  resilience mode on it asks every node that still needs one, since that is the
  only thing that can clear the row.

Each node registers its own identity rather than sharing one. A single WARP
account across a fleet would put every node behind the same endpoint, which is
both worse for your customers and a quota they would all share.

## Upgrading

Update the panel and the nodes. A node reports its WARP state on its next sync
once it is updated; until then its inbound still shows a row in the health
check, and pressing the button there resolves it immediately on any node,
including one that has not been updated yet.
