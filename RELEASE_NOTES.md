# Nova Server 1.84.1

A fix for something 1.84.0 got half right.

## The AmneziaWG address list did not offer your new default IP

If you added a second IP on the Network page and marked it as the default,
mieru and the Telegram proxy started using it, and the AmneziaWG address list
did not offer it at all.

The AmneziaWG card builds its own dropdown of this server's addresses, and that
one was still reading only the first address the operating system reports. The
other two pickers had already moved to the shared list, so 1.84.0 shipped with
two of the three correct, which is the most confusing shape this could have
taken: the feature clearly worked, just not where you needed it.

All three now read the same list. Every address you have added appears in each
of them, with your default first.

Nothing else changes, and no configuration you have already issued is affected.

## Upgrading

Update from the panel, or run the installer again.
