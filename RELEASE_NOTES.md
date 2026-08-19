# Nova Server 1.67.1

Two reliability fixes for reports that AmneziaWG and WARP are unstable. Both
turned out to be real, both were reproduced, and neither was about the tunnel
or the account.

## AmneziaWG connected, then nothing loaded

Nova never told the tunnel how large a packet it could carry, so the tunnel
worked it out from the server's own network card: 1420 bytes. That is right
only when every hop between the server and the customer also carries 1500, and
for a lot of customers it does not. Home connections over PPPoE carry 1492, and
mobile networks are commonly 1400 or less.

The result is the worst kind of failure, because the tunnel comes up. The
handshake is small, so it succeeds. A ping is small, so it works. Then anything
that fills a packet gets thrown away silently, and pages hang half-loaded. The
customer says it connects but nothing works, and the operator sees a tunnel
that looks perfectly healthy.

Measured on a test tunnel over a 1400-byte path, changing nothing but this
number: at 1420 a 3 MB download stopped after 24 kB and never recovered. At
1280 the same 3 MB arrived in a twentieth of a second.

Nova now writes 1280 into both the server and the customer's configuration.
It also tells the server to fit each connection to the path automatically,
which repairs customers whose configuration Nova did not write: an old file
they downloaded months ago, or a configuration they imported into some other
app. Those keep working without anyone re-downloading anything.

## WARP dialled the one address most likely to be blocked

WARP connects to Cloudflare through an address, and Nova used the published
default: a name that resolves into a small range that is widely blocked and
throttled on the networks this product exists for. Nova has always had the
alternative, dialling a clean Cloudflare address directly, and it was switched
off unless somebody went looking for it. So the setting most likely to work was
the one you had to know about.

It is on by default now. If you had deliberately switched it off, that is left
alone.

There was a second problem underneath. The clean address was picked at random
every time the configuration was written, which means every reload. A node that
was working could stop because you saved an unrelated setting, and a node that
was broken might fix itself for no visible reason. That is a coin toss repeated
for ever, and it is exactly what "sometimes it works" looks like from the
outside.

Each node now keeps one address of its own. Different nodes still get different
ones, so a single blocked address cannot take a whole fleet with it, but a node
that works keeps working across reloads, restarts and updates. If a node's
address is blocked, set the endpoint by hand and that still wins.

## Upgrading

Update the nodes together with the panel, or before it. A panel on this version
hands customers the corrected setting while a node still on the previous one
answers with the old one, and that combination breaks downloads specifically.

Update and restart. Nodes running AmneziaWG hand out the corrected setting from
then on; customers already connected are repaired by the server without any
action from them. Nodes using WARP move to their own clean address on the next
restart. If a node's address turns out to be blocked, set the endpoint by hand
on the WARP card; that still takes priority over everything else.
