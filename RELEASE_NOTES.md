# Nova Server 1.66.0

Update your nodes from the panel, and see what each one is running.

## Nodes can be updated from here now

A node has no panel of its own. This one could already push a node's
configuration, issue its certificates, register its WARP account and uninstall
it entirely, but not move it off an old version. That needed a shell on the
node, which is an odd thing to require of someone who added the machine with a
single command, and it was worst exactly when it mattered: the node carrying a
bug is the node you cannot reach through the thing that is broken.

Each node now reports its version on every sync, so the Nodes page shows what
every machine is running, marks the ones behind this panel, and offers an
Update button.

Pressing it asks that node to update **itself**, with the same
checksum-verified routine this panel uses on itself. This panel sends no
address, no version and no file: it can only ask the node to do what its own
daily update would do. That is deliberate. It means someone who took over a
panel could make its nodes reinstall the official release, and nothing else.

The node restarts when it succeeds, so connections on it drop once. If the
download or the checksum check fails, the node keeps the version it has and
says why, and the panel shows you that reason rather than leaving you with
"started" and a version that never changes.

**One node has to be updated by hand first.** The button calls something that
only exists from this release onward, so a node running anything older cannot
answer it. Update each node once over SSH, or let its own daily update reach
this version, and after that the button works. The panel says exactly this if
you press it on a node that is too old, rather than reporting a bare failure.

## Also

- A node whose version this panel has never heard is shown as such, rather than
  looking current. The Update button is still offered for it, because a node too
  old to report a version is exactly the node that needs updating.
- Pressing Update twice no longer starts two updates over the same files. The
  second press says the node is already updating.
- A node that syncs successfully but reports no version clears the version the
  panel was showing, instead of displaying one that machine is no longer
  running.

## Upgrading

Update this panel first, then each node once by whatever means it has today.
From then on the Nodes page keeps them current.
