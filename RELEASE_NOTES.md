# Nova Server 1.69.0

Three things that were decided for you and are now yours to set.

## Move WARP off an address that is blocked for you

Each node picks one clean Cloudflare address and keeps it. That is deliberate:
it used to be redrawn every time the configuration was written, so saving an
unrelated setting could move a working node onto a blocked address, which is
what "sometimes it works" looked like from the outside.

Holding one address took the accidental escape with it. A node whose address
happened to be blocked stayed blocked, and the only way out was knowing to type
an endpoint by hand.

Try another address, on the WARP card, moves the node to a different address in
the pool and holds that one just as firmly. It appears only when it can do
something: with clean addresses switched on and no endpoint set by hand.

## Set the tunnel's packet size

The AmneziaWG card has a packet size box. Leave it blank unless you know the
whole path to your customers carries full-size packets. 1280 is the safe value
and the one that fixed tunnels that connect and then load nothing, which is what
home and mobile connections do to a larger number.

Raising it can add throughput on a clean network, and breaks large downloads on
a narrow one. Blank means the default, so a later release can move that default
without leaving your node pinned to today's.

## A blocked route says so

When a routing rule points at an exit this node does not have, the traffic is
blocked rather than sent out of this server's own address. That is the right
answer, and it is a change in what your customers can reach, so it now appears
in the activity log. It used to happen with no trace anywhere.

## Upgrading

Update and restart. Nothing changes unless you use one of these.
