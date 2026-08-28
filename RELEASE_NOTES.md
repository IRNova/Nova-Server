# Nova Server 1.74.1

Updating a node looked like it did nothing.

## What was wrong

Pressing Update on a node left the row exactly as it had been: the old version,
still offering the update, with nothing to say anything was happening.

The update was running the whole time. A node downloads the published release,
checks it against its checksum, extracts it and restarts, then reports its new
version on its next sync. For the minute or two that takes, the row had nothing
to show, so the only signal was a toast, which disappears, and the row is what
you keep looking at.

That was reported as an update that does not work, on a node that had finished
updating about a minute after the screenshot was taken.

## What it does now

The row says "Updating" in place of the update-available badge, from the press
until the node comes back with its new version.

It clears in exactly two ways and deliberately not a third. The version changing
ends it, which is the real signal. Six minutes ends it, which covers an update
that failed, a node that never came back, and a stamp restored from a backup. A
state that only something remembers to clear is how a row starts lying, which is
the problem this fixes.

The state is stored on the node's record rather than in your browser, so it
survives a reload and another admin looking at the same fleet sees it too.

## Worth knowing

Auto-update covers this panel only, never its nodes. A node is always a manual
press, so if you have been waiting for nodes to follow the panel on their own,
they will not.

## Upgrading

Update and restart. Nothing about how any node serves traffic changes.
