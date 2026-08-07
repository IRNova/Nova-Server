# Nova Server v1.43.0

## Reality now looks different for each of your users

An operator pointed out that every client on a Reality inbound presented the
same SNI and the same short ID, so they all looked alike on the wire. They were
right, and it was worse than it looked: Xray supports a list of each, but Nova
minted exactly one short ID and every subscription used the first entry. Even if
you added ten by hand, every customer still showed the same one.

New Reality inbounds now get a pool of six short IDs, and each user is given one
of them. The choice is fixed per user, so a customer's config does not change
when they refresh their subscription, and no single value identifies your whole
node. The borrowed-SNI field takes a comma separated list, and its suggestion
chips now add to what is there instead of replacing it.

**Nothing is ever removed.** A client config carries the short ID it was issued
with, and Reality rejects a connection whose short ID the server no longer
lists, so removing one would kill configs already in your customers' hands.
Values are only ever added, including values Nova would not generate itself.

Your existing inbounds are left exactly as they are by this update. They are not
widened automatically, because widening reloads Xray and drops every live
connection on the node. If you want an existing inbound to use a pool, the
health check offers it as a fix and you choose when to press it.

## Your own brand on the subscription page

The page your customers open can now carry your name, your logo, and none of
Nova's social links. It is in Settings, under the subscription page section.

The logo is uploaded and stored inside the page rather than linked, because that
page promises it makes no external requests of any kind, which is part of what
makes it safe to open on a censored network. A linked logo would also hand its
host the address of every customer who opens the link. PNG, JPEG, WebP and GIF
are accepted, SVG is not. If you set a name without a logo, the page shows your
initials rather than Nova's mark next to your name.

## The panel documents the two newest protocols

The manual has a section on the Telegram proxy and mieru, which it had never
mentioned, and the panel search finds them, so typing "telegram" or "mieru"
returns something instead of nothing.

Health check findings are now in Persian and Russian as well as English. They
were English sentences on every panel, on the one screen people open when they
are already stuck.

## A customer could be served the wrong page

A subscription or panel page carrying certain characters in a stored value, a
customer name containing `$'` for example, could splice part of the page into
itself. The visible result was that customer opening their subscription link and
seeing a demo account instead of their own, silently, with no error.

This is older than this release and affects every version before it. If any of
your customers has ever reported seeing an account that is not theirs on the
subscription page, this was why.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release, and no client configuration needs to be reissued.
