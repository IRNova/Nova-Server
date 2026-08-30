# Nova Server 1.76.0

A brand-new server could finish installing with a dead panel. Hysteria2 gets
its first engine update since it was added.

## The install that looked like it worked

On a server created a few minutes earlier, the installer could print

    ==> Installing Node.js 24
    OK  node v18.19.1

and carry on to report a successful install. The panel was then unreachable,
and behind the scenes the Nova service was starting and dying every two
seconds.

It was not your server, your domain or your connection. A freshly created VPS
runs its own package updates on first boot, and those hold a lock that the
installer needs. When the installer arrived during that window, it could not
refresh the package list, so it installed the version of Node your distribution
already knew about instead of the one Nova asked for. Nova needs Node 24; the
older one is missing a component the whole settings database is built on, so
the service could never start.

The installer reported success because it only checked that Node was present,
not which Node.

## What changed

It waits for the server's own startup updates to finish before installing
anything, and says so while it waits, so a pause does not look like a freeze.
The wait gives up after five minutes rather than hanging forever.

It then checks the version it actually installed. On anything too old it stops
with a plain explanation and the command to run again, instead of continuing
and leaving you with a panel that never comes up.

If you hit this, running the installer again was already the fix, and your
server is fine.

## Hysteria2 engine updates

Until now the Hysteria2 engine was installed once and never replaced. Every
improvement to it reached brand-new servers only, and never the servers already
running, which are the ones that had been up long enough to need them.

Existing servers now pick up the current engine the next time you run the
installer. This version clears several connection leaks and a stall that could
accumulate on a server left running for a long time, so Hysteria2 stays healthy
over weeks rather than slowly degrading.

The download is verified before it replaces anything. A server that already has
the current version downloads nothing at all, and a failed update leaves the
working engine in place rather than a broken one.

## Hysteria2 settings that cannot work now say so

A Hysteria2 configuration the engine refuses used to leave Hysteria2 quietly
switched off. That looked identical to simply not having turned it on. Nova now
checks the configuration before applying it and tells you when it will not
start.

## Upgrading

Panel: Settings, then Update. Or run the installer again over SSH:

    bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)

Re-running the installer is what picks up the new Hysteria2 engine. The panel
updater alone does not replace it.
