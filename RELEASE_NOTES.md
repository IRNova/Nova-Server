# Nova Server 1.79.0

The dashboard stopped getting slower as your server got older, and a reseller's
dashboard now shows their own traffic instead of the whole server's.

## The dashboard was doing too much work

To draw the traffic chart, the dashboard read every day of every customer's
history and added it up. The panel refreshes that chart every few seconds.

On a small or new server nobody noticed. On a server with a few hundred
customers that had been running for a year, one refresh meant reading hundreds
of thousands of records, which took seconds of solid work and a large part of
the memory Nova is allowed. The panel became unresponsive, and on the largest
servers it could use enough memory to restart the agent, which made the
dashboard unusable rather than merely slow.

The shape of that is backwards: the servers with the most to show were the ones
least able to show it.

Nova now keeps a running daily total for the server as a whole, updated as
traffic is counted. Drawing the chart reads fourteen small numbers instead of
the entire history, so opening the dashboard costs the same on a year-old server
as on one set up this morning.

Your existing history is not lost. The first time each past day is shown, Nova
works it out from the records it already has and stores the result, so the chart
fills in as you use it and does the work only once. The day you update is the
one exception: it counts from the update onwards, and corrects itself the next
day.

## A reseller was shown the whole server's traffic

The reseller dashboard scoped the customer count correctly and left the traffic
figures beside it unscoped. A reseller saw the server's total, today's total,
and a fortnight of daily figures, all of it covering the owner's own customers
and every other reseller's.

It now shows their own customers only, matching the count that was already
right.

If you run resellers on a node, they have been able to see this. Nothing else
about their access changes.

## Upgrading

Panel: Settings, then Update. Or run the installer again over SSH:

    bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
