# Nova Server 1.72.0

Four things an operator asked for, and two corrections to the health check.

## XHTTP on an added domain behaved differently from the main one

An XHTTP inbound pinned to one of the node's added Cloudflare domains was
reported as erratic: one ping test answered, the next did not, with no pattern
to it, while the same inbound on the node's own (equally proxied) domain was
steady.

The two cases differed in one way. A per-inbound address replaces the address
the client dials, and the SNI and Host went on naming the panel. For a bridge
that is correct, because the panel's certificate is the one that answers there.
For a Cloudflare name it is not: the edge routes on the name it is GIVEN, so
that config asked whichever edge answered for a name it might hold no route for.
Which edge answered is the "no pattern".

A config pinned to a name Nova has established is behind a CDN now announces
that name throughout. A bridge IP, and a direct domain Nova holds no certificate
for, keep the split they were built for.

The panel's built-in Telegram bot builds these configs on its own path, and a
security pass on this release caught that it had not been told which domains are
fronted. A customer taking their links from the bot would have kept the old
behaviour while the same customer importing their subscription URL was fixed,
with nothing to tell the two apart. The bot is now on the same list, and a test
fails if any future subscription builder is left off it.

## mieru and AmneziaWG can be pointed at this server's address

Neither protocol survives a CDN, so both have an address picker that offers only
names a CDN is not in front of. On a node whose every domain is behind
Cloudflare that list was empty, and on a node with a direct domain there was no
way to say "use the IP instead", even though the chooser has always honoured a
literal address once something managed to set one.

The picker now ends with this server's own address, marked as such, on the
AmneziaWG card and the mieru and Telegram-proxy pickers alike. It is the origin
whenever anything in front of the node is proxied, which is why it is offered on
the owner-only settings cards and labelled rather than slipped in.

## A switch for the Nova app's SNI-block bypass

The Nova app carries a bypass for networks that block the domain rather than the
server, and turns it on by itself once nothing on a subscription is getting
through. That is the right default and it costs the customer one failed session
to reach.

"In your customers' configs" now has a switch that starts the app with it
already on, for a network an operator already knows is doing this. It rides the
`?target=nova` document under the `nova` key, absent rather than false when it
is off, so every client in the field reads it as off and nothing else even sees
it.

## The Telegram proxy said which kind of link, not which one to use

Both forms of a customer's proxy travelled under names describing their scheme
(`tg`, `tme`). A client shipped the `t.me` one, which lands the customer in a
browser looking at a proxy they cannot add. They are `url` and `webUrl` now. No
operator-visible change, and the customer page is unaffected.

## It was telling you to undo a working setup

A customer whose only inbounds are XHTTP or HTTPUpgrade was reported as a
failure, with the advice to grant them another transport or move one of these to
WebSocket or gRPC.

That was right for as long as it was true. The Nova app now carries both: XHTTP
on the second core it ships for exactly that, and HTTPUpgrade on its first. So
such a customer has two working paths, the raw link list and the Nova app, and
the advice would have undone a setup that works. XHTTP is also what an operator
reaches for when a domain is being filtered, which makes it the worst thing to
be steered away from.

It is a warning now rather than a failure, and it says which client carries
them, so an operator handing out a Hiddify or Clash link still learns that those
four will be empty. It stays a failure when nothing structured can carry the
customer at all, which is mieru and a NaiveProxy inbound on a self-signed node.

## A tunnel that could not start said nothing

1.71.3 changed what happens when a tunnel is saved and fails to start: what you
typed is kept and the tunnel is left switched off, so the form comes back filled
in and you can correct it. That is the honest state, and it was silent. Nothing
on the health page read a disabled tunnel, and the Tunnel card is a click away
rather than in front of you, so a bridge you believed was carrying traffic could
sit like that until somebody happened to look.

The health check now reports it, names the address it was configured for, and
points at the page where what you entered is still waiting.

## Upgrading

Update and restart. Existing configurations keep working: the XHTTP fix changes
what a config pinned to an added Cloudflare domain announces, so hand those
customers their subscription again (or let the app refresh it) and they will
pick it up. The new switch and the new address choice are both off and unpicked
until you set them.

If a customer of yours has been showing as a health failure for being on XHTTP,
that row will turn amber and explain itself.
