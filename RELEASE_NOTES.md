# Nova Server 1.85.2

A bug the new tests found before an operator did.

## AmneziaWG ignored your default IP on "Automatic"

1.84.1 made the IP addresses you have added appear in the AmneziaWG address
list. Picking one from that list worked. Leaving it on **Automatic** did not:
AmneziaWG still published whichever address the operating system reported first,
which on a server with a reserved or floating IP is usually not the one you
want.

mieru and the Telegram proxy already handled this correctly. The wiring is one
line per protocol, two of the three had it, and the release that was
specifically about this gap shipped without closing it.

If you set a default IP and left AmneziaWG on Automatic, its configurations were
naming the wrong address. Update, and re-issue any AmneziaWG configuration you
handed out since then.

## How it was found

A new test walks every surface a configuration can reach a customer through, in
one place, and covers both publishing rules at once:

- which **domain** a configuration may name (the panel domain setting, and the
  per-domain settings)
- which of this server's **addresses** it leads with

It drives the real subscription route with every format and every client
User-Agent, then the three protocol pickers, then each renderer. Reintroducing
the last four shipped bugs of this kind all fail it.

## Upgrading

Update from the panel, or run the installer again.
