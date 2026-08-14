# Nova Server 1.60.1

The health check no longer calls a customer broken for holding something other
than an inbound.

## What changed

1.60.0 made an empty inbound list mean empty, so a reseller can sell access that
is only AmneziaWG, only the Telegram proxy, only a country exit or only mieru.
The health check had not caught up: it reported every one of those customers as
having "no configurations", and the repair offered beside the report would have
granted them every inbound on the node, which is the opposite of what was
chosen when the list was emptied.

A customer holding any of those four, on a node that runs it, is no longer
reported. They receive exactly what they were sold.

The check still fires where it should. A customer with an empty list and
nothing else really does receive nothing, and so does one granted a protocol
the node is not running: a grant for something switched off is worth knowing
about, not hiding behind a checkbox.

## Upgrading

No action required. The findings clear on the next health check.
