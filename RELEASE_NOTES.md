# Nova Server v1.56.0
## The install count, a bridge button that explains itself, resellers who sell by volume, and a price on a gigabyte

Four things, three of them asked for by operators and one of them a number that
has been wrong since the day it shipped.

---

## Every node has been counting as the same node

Nova tells novaproxy.online once that a node exists, so the project can say how
many are running. It identified a node by hashing its address, and it took that
address from the request that sets the admin password. That request never comes
from your browser: the installer sets the password itself over
`http://127.0.0.1:8088`, and the container installer does the same. So every node
on earth reported the hash of `127.0.0.1`, the site treated all but the first as a
repeat, and dropped them. Two entries in three weeks.

Hashing the real address instead would have been worse. A public IPv4 is a
32-bit input under an unsalted SHA-256, and a counter that deduplicates answers
"have I seen this before", so the install total would have become a way to test
whether any address you name runs Nova. A node now identifies itself with a
random number it mints and keeps. Nothing about the node is resolved or sent, the
public-IP lookup at startup is gone, and two nodes behind one NAT no longer
collapse into one install.

Nodes already running, and managed fleet nodes, never had a moment to report.
Both now count once on their first start after this update, capped at five
attempts, and a node cloned from a snapshot notices its machine-id changed and
counts separately.

**What is sent:** one HTTPS request per machine and nothing after it. Like any
website, novaproxy.online sees your server's IP when a request arrives from it.
Inside the request is the word `install` and that random number. Not your users,
traffic, keys, domains or settings. `STATS_OPTOUT=1` in `/etc/nova/agent.env`
stops it entirely, the installer no longer discards that line when it rewrites
the file, and `NOVA_STATS_OPTOUT` works for containers, which previously had no
way to decline before first boot.

---

## The bridge button now tells you what it did

"Point all client links at the bridge" reported success and nothing else. An
operator whose configs still dialled the exit was told it worked and given
nothing to act on.

Three rules keep an inbound off the bridge, all deliberate, none of them visible:
its port is not one the tunnel forwards (the default set is `443` and
`8443/udp`, so Reality on `8443/tcp` or a second Hysteria2 is normal), it has its
own public address, which takes priority over the bridge by design, or it runs on
a fleet node and carries that node's address.

The button now lists every inbound, whether it moved, and for the ones that did
not, the reason and what to do about it.

**On the "unverified" tunnel state**, which is not an error: when your exit fronts
port 443 with a proxy that does not expose `/install/status`, Nova cannot read the
exit's build but the data path is confirmed. Links can be pointed at the bridge in
that state and always could. Route `/install/status` to the Nova agent on your
front proxy to turn the check green.

---

## Resellers can sell from an allowance instead of your plans

A reseller has always sold one way: from plans you mark sellable, against a
prepaid credit balance. That stays, unchanged, and is still the default.

The second way gives them a pool of data and a cap on how many customers, and
inside that they build the customer themselves rather than picking a plan. The
pool counts the quota they have **assigned**, not the traffic used, so they
cannot promise more than they hold and find out only once it flows. A reseller
with an allowance cannot sell an uncapped customer at all, which is unbounded
rather than merely large. Raise either limit whenever you like.

You also choose, per reseller, which inbounds they may sell and whether they may
hand out AmneziaWG, the Telegram proxy or mieru. That applies on top of the plan
in plan mode too, so tightening one reseller no longer means editing every plan
they sell.

**mieru is withheld from resellers by default.** It reaches only Hiddify, Karing
and mieru's own client, so a reseller selling it generates support questions that
arrive at you. Tick it per reseller if you want them to have it.

Every reseller that exists today keeps plan mode and every setting it had.

---

## A gigabyte does not have to cost a gigabyte

Each way in can now charge a different share of a customer's allowance: a
percentage from 10 to 1000, where 100 is what everything does today. 150 charges
one and a half times, 50 charges half. Set it for ordinary proxy traffic in
Settings, and separately on the AmneziaWG, mieru and Telegram proxy cards.

It applies from the next reading forward. Nothing already spent is recalculated,
because a customer's remaining balance should not move because you edited a
field.

**Not per inbound, and the reason is worth knowing:** xray reports a user's
traffic summed across every inbound they belong to, so there is nothing to split
per inbound without changing what every stored usage counter means. The three
standalone daemons each run their own service and report per user for that
service alone, which is why they get a rate of their own.

---

## For operators upgrading

Nothing to do. No setting changes meaning, no configuration is rewritten, and no
customer's link changes. Subscription output and health findings are
byte-identical to 1.54.1 with every rate at its default and every reseller on
plans, which is what a node looks like the moment it updates.
