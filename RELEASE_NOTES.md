# Nova Server 1.75.0

Calls did not work for anyone on a Tor, Psiphon or country exit.

## What was wrong

A customer routed through Tor, Psiphon or one of the country exits had web and
apps working and no voice or video calls at all. Clubhouse, WhatsApp calls,
Telegram voice and games all need UDP, and none of those exits carry it: Tor is
TCP-only, with no UDP support at any layer, and every country exit is a dialer
to a local Tor or Psiphon.

Nothing reported it. Not to the customer, whose call simply never connected, and
not to you. It arrived here as a customer complaint, which is the only way it
could have.

## The part that makes it worse

Nova already had the fix. "Route UDP through WARP" on the WARP card exists for
exactly this, and it could not work.

Routing rules are matched in order, first match wins, and the exit rules were
emitted before it. So for anyone on an exit, the rule sending their UDP to WARP
was never reached. The one setting that would have fixed calls was being skipped
for precisely the customers who needed it, and turning it on looked like it did
nothing.

It is checked first now. Turning it on routes UDP through WARP even when that
customer's inbound is pinned to an exit.

## The trade, stated plainly

Their UDP then leaves through WARP rather than the country they chose, so a
customer on a German exit makes calls from Cloudflare's address instead. That is
why this stays a switch rather than becoming the default: a working call from
the wrong country beats a call that cannot connect, but only you can decide that
for your customers.

It is never this server's own address, so the de-anonymisation that the country
exits are careful about does not apply here.

## What a block still means

Rules are matched in order, so moving the UDP redirect up put it above the
blocks below it: the QUIC block, the ad, adult and bittorrent blocks, and any
block you wrote yourself. That would have left your filters enforced over TCP
and quietly skipped over UDP, with both switches still showing green. HTTP/3 is
UDP, so a "blocked" site would simply have loaded.

Blocks are checked first now, ahead of the UDP redirect and everything else.
Refuse what must be refused, then decide where the rest goes. One consequence
worth knowing: a content block now also applies to customers on an exit, which
was not always true before, and is the honest reading of a block being on.

A rule that ROUTES rather than blocks is still below the UDP redirect. So if you
have written something like "keep Iranian destinations direct" and you turn this
switch on, that traffic's UDP goes through WARP while its TCP stays direct.
Fixing that properly means reordering more than this release should, so it is
written down here rather than left to be discovered.

## When the switch is off

That is still a silent failure, so the health page now names it: an exit that
cannot carry UDP, with nothing else carrying it, raises a note saying what the
customer actually experiences and the one press that changes it.

The note goes quiet only when UDP genuinely has somewhere to go, which means
WARP is set up and not merely switched on. With the switch on and no WARP
account, the rule resolves to a block and every customer on the node loses UDP,
not only the ones on an exit, so falling quiet there would have hidden a worse
version of the thing it was written to report.

It also only fires when something is actually routed through such an exit.
Having Tor installed with nothing pointed at it is not that.

A note, not a failure. Routing an inbound through Tor is a deliberate choice and
everything except UDP works exactly as intended.

## Upgrading

Update and restart. Nothing changes on its own: if the switch was off it stays
off, and if it was on your customers' calls start working, which is what it
said it would do all along.
