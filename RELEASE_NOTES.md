# Nova Server 1.80.0

The panel got faster on servers that have been running a while.

## What was slow

Nova looks things up in its own database by prefix constantly: one customer's
traffic, who has been online, which servers exist, which domains are configured.
Almost every page does several of these.

Each of those lookups was reading the entire database to find its answer, rather
than jumping to the part that could possibly match. That is fine on a new
server. It is not fine on one that has been running for a year, because the
database is mostly per-day traffic records, which are kept for a long time, and
they end up outnumbering everything else many times over.

The effect was indirect and easy to misread: a page that has nothing to do with
traffic history got slower anyway, because the lookup behind it was walking past
all of that history to reach a few hundred rows.

## What changed

Those lookups now go straight to the range of the database they need. Same
information, same results, found without reading everything else first.

On a test server with 500 customers and a year of history, twenty of those
lookups took 195ms before and 3ms after.

Nothing about your data, your settings or your customers changes. This is purely
how Nova reaches its own records.

## Upgrading

Panel: Settings, then Update. Or run the installer again over SSH:

    bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
