# Nova Server v1.55.0
## Every node has been counting as the same node, and the obvious repair was worse

Nova tells novaproxy.online once that a node exists, so the project can say how
many are running. It has been getting that wrong since the day it shipped.

The report identified a node by hashing its address, and it took that address
from the request that set the admin password. That request never comes from your
browser. The installer sets the password itself, over `http://127.0.0.1:8088`,
and the container installer does the same. So every node on earth reported the
hash of `127.0.0.1`, the site treated the second one and every one after it as a
repeat of the first, and dropped it.

The public counter holds exactly two entries from this channel: the hash of
`127.0.0.1` from 2026-07-20, when the feature landed, and the hash of `localhost`
from 2026-07-30, when the container path first ran. No node has counted since.

### Why it is not simply hashing your real address instead

That was the first fix, and it was the wrong one. A hash of a public IPv4 is a
32-bit input under an unsalted SHA-256, which is a lookup table, not a one-way
function, and a counter that deduplicates will tell anyone who asks whether it
has seen a given id before. Together those turn an install total into a way to
test whether any address you name is running Nova. For this product that is not
a trade worth making for a statistic.

A node now identifies itself with a random number it makes up for itself on
first contact and keeps. It stands for nothing, it matches no address, and it
cannot be guessed from anything about your server. As a side effect the count
also got more accurate: two nodes behind one NAT or one PaaS egress pool used to
collapse into a single install, and no longer do.

### Nodes that are already running will count too

A node set up before this release used up its one report long ago, and a managed
fleet node never sets a local password at all, so that moment does not exist for
it. Neither would ever have counted. Both now report once on their first start
after this update, and then never again. A node that cannot reach the site tries
again on later starts and gives up after five, rather than opening a connection
on every boot for the rest of its life.

### What is actually sent

A single HTTPS request, once per machine, and nothing after it. Like any website,
novaproxy.online sees your server's IP address when a request arrives from it.
Inside the request there is the word `install` and that random number. Not your
users, traffic, keys, domains or settings.

Set `STATS_OPTOUT=1` in `/etc/nova/agent.env` and nothing is sent at all, now or
later. The installer now carries that line across when it rewrites the file, so
repairing or updating a node no longer silently undoes it, and it is listed in
`agent.env.example`. The panel explains all of this in the manual in all three
languages, and the panel search finds it under the words people actually type,
including "telemetry" and "tracking".

### For operators upgrading

Nothing to do. No setting changes meaning, no configuration is rewritten, and no
customer's link changes.
