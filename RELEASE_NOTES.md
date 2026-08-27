# Nova Server 1.73.0

AmneziaWG 3.0, a picker that could hand out configurations nobody could connect
with, and an installer that says what it is about to take.

## AmneziaWG 3.0

3.0 encrypts the packet headers themselves, which is what defeats the
statistical analysis that started catching 2.0 in mid-2026. It is on the version
picker on the AmneziaWG card, off unless you choose it.

One property decides everything about how it is offered. The header key is
shared by the whole interface, not held per peer, so a node speaks 3.0 to
everybody or to nobody. The moment you switch, every AmneziaWG configuration
this node has handed out stops working and each customer needs their file again.
A client without the key is invisible to your server rather than merely refused:
it does not appear as a failed handshake, it does not appear at all. There is no
in-between state to sit in while customers catch up, which is why the dialog
says so plainly and names the apps that can actually use it.

Nova refuses the switch outright if this server's AmneziaWG packages are too old
to serve 3.0. That is not caution: writing 3.0 settings to older packages does
not degrade to something workable, it makes the packages reject the whole
configuration, and the interface stops with every peer on it. If a version
change fails to apply for any other reason, the node is now restored to what it
was, rather than left storing a version it is not serving while the health page
points at the button that just failed.

What is written is 2.0 plus the header key. The other 3.0 parameters, the
content padding, the randomised timings and the two new switches, are
deliberately left out: none is needed to be 3.0, each widens the surface where
the two ends can disagree, and the timing ones change when a tunnel gives up
rather than what it looks like on the wire.

Two details are worth recording because the upstream announcement gets both
wrong, in the direction that costs an operator their interface. The key is
base64, not the hex the announcement describes. And the padding floor is 12, not
8: below it the configuration is rejected and the interface is deleted, with the
error naming no field. Nova's own light preset wrote 8. It writes 12 on 3.0 now,
and the 2.0 presets are untouched, since raising those would invalidate files
2.0 customers hold for a rule that does not apply to them.

Everything above was measured against a real AmneziaWG 3.0 build rather than
read: Nova's configurations carry traffic on all three strength presets, a 3.0
build still serves the 2.0 configurations Nova has always written, and a 3.0
server with a 2.0 client fails exactly as described, with no handshake recorded.

## A CDN-fronted address is no longer offered

AmneziaWG is UDP and no CDN carries UDP, so choosing a Cloudflare-fronted domain
on the AmneziaWG card produced configurations that could not connect, for every
customer, with nothing on either end reporting why.

Those entries were labelled. The label was the whole guard, and it was at the
end of the line, so a long domain pushed it out of the box: the more room a name
took, the less warning there was about it. They are shown and unselectable now.
An address already stored stays visible, because that state is reachable and
hiding it would show you something other than what your node is using.

## The installer says which ports it takes

Before it binds anything, the installer lists the ports this install will use and
where the protocol ports get decided later.

The ports Nova keeps to itself, its own agent and the xray API, both loopback,
move themselves off a collision and say so. A port your customers reach is
reported and left alone: that one is written into every link this node hands
out, so moving it would hand customers links to a port you never agreed to.

## The AmneziaWG card reads properly

Both dropdowns were cutting off their own options and the explanation under the
address picker ran to fourteen lines in a narrow column. Each control now sits
beside its explanation, and the dropdowns size themselves to their longest
option in whichever language you are reading rather than to a width picked in
English.

## Upgrading

Update and restart. Nothing changes for anyone until you choose it: AmneziaWG
stays on the version it is on, and the new address choice is unpicked.

If you are considering 3.0, the thing to check first is what your customers run.
Nova's own app carries it from v1.20.15-beta on every platform. Amnezia's
standalone Android app is still a preview at 3.0.1, their Windows client cannot,
and routers cannot. Switching disconnects everyone who is not already on
something that speaks it, all at once.
