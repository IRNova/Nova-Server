# Nova Server v1.41.0

Two reports, and the first is one you should read before updating if you run
nodes.

## Traffic served by a node was never counted

An operator made a user with a 500 MB limit, downloaded a large file with it,
and the panel still showed 0 bytes.

They were right, and it was not a display problem. A node counts the traffic it
serves in its own store, and nothing ever moved those numbers to the panel. On
the test pair, the same user read 13.3 GB on the panel and a separate 780 KB on
the node, and the two were never added together.

**The number on screen was the smaller half of the problem.** Those same counters
are what a data limit is measured against, and what your users' apps show them.
So a user whose configurations pointed at a node had, in practice, no data limit
at all: they could download without end and nothing stopped them, because the
part of Nova that enforces the cap could not see the traffic.

Usage is now the total across the panel and every node. A limit applies to the
whole fleet rather than separately to each server. The panel collects each
node's counters every half minute, and a node that is unreachable for a while
has its traffic added in full as soon as it answers again, rather than losing
it.

**Past traffic is not billed retroactively.** Each node's first reading after
this update is taken as a starting point, not as a bill. Your nodes have been
counting since the day they were installed, and importing that history would
have landed months of traffic on every user in a single moment and switched off
everyone already past their limit, for bytes you never charged them for.
Counting starts when you update. Everything from that point on is counted in
full.

You do not have to update your nodes for this to work: a node on an older build
is still counted, just without the upload/download split. Updating them adds
that detail.

## Country exits stayed on the main domain

Giving a front its own domain in 1.38.0 moved the front itself, but the
per-country exits and the per-carrier variants kept the panel's main domain,
which an operator reported after setting the domain and finding most of their
configurations unchanged.

They are the same front reached by a different path, so they now follow it. On a
panel with two fronts and five country exits, seven configurations per user move
to the front domain instead of two. Standalone inbounds are unaffected: those
have their own domain setting and always did.

If you have never set a front domain, nothing changes for you at all.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release.
