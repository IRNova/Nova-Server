# Nova Server v1.46.0

## mieru, the Telegram proxy and AmneziaWG on a server with no domain

Reported by an operator, and they were right. All three of these run on a plain
IP address perfectly well, and they always did whenever the panel's address
field held one. What did not work was the state where nothing at all was
stored: the Telegram card produced an empty link, mieru handed out no client
configuration, and nothing anywhere said why. AmneziaWG was the only one of the
three that fell back to the server's own address.

Now all three follow one rule, and it ends with the server's own address:

1. Whatever you typed into the address field on that card.
2. Your server's main address, if it has one.
3. A domain you added that points straight at this server.
4. The address Nova reads off the machine itself.

So a node with no domain and an empty address field hands out working links
again. Nothing changes on a node that already has an address: on both of our
own servers this release resolves to exactly the same address as before, for all
three, with no new warnings.

The operators who hit this are the ones who cleared a domain, or whose address
detection failed when the server was installed, which is why it looked like it
only happened sometimes.

There is nothing to do beyond updating. Customers who already had working links
keep them; customers who were being handed nothing start receiving a
configuration on the next refresh of their subscription.

## The health check now says when there is no address to hand out

The reason this took an operator to report is that it failed silently. New
health-check findings say what is wrong, in English, Persian and Russian, one
per card so you can see which one is affected:

- **No address at all.** No domain, and no IP address Nova can read off the
  machine. Type the server's address into the field on the card, or add a
  domain that points straight at it.
- **Only a private address.** The machine knows itself as something like
  `10.0.0.4`, which is what a server behind NAT looks like. Nobody outside that
  network can connect to it, so the address customers actually reach the server
  on has to be typed in by hand.
- **Behind a CDN, with nothing else.** See below.
- **A proxied address, chosen on purpose.** If you type a Cloudflare-proxied
  domain into one of these cards, the configurations cannot connect. Until now
  only AmneziaWG told you that; mieru and the Telegram proxy said nothing at
  all, although the rule was never about AmneziaWG. Your choice is still
  honoured rather than overruled, and now you are told why it will not work.

None offers a one-click fix, deliberately: which address to publish is your
decision, and the wrong one hands out configurations that cannot connect.

## If every domain in front of your server is behind Cloudflare

Unchanged, and worth stating plainly because the health check now explains it
instead of leaving you to work it out. None of these three protocols passes
through a CDN: the orange cloud answers the handshake itself and nothing reaches
your server. Nova will not put your server's real address into a customer's
configuration while a CDN is hiding it either, because anybody holding a
subscription link could then find the server directly. That applies whether the
proxied name is your main domain or one of your extra domains.

So on such a node, customers are given nothing for these three rather than a
link that cannot connect. Your own AmneziaWG configurations in the panel still
use the real address and still work. Adding one domain that points straight at
the server (DNS only, grey cloud) turns all three back on for customers.

One related fix while we were in there: removing your main domain now also
clears Nova's record that it was behind Cloudflare. Until now that record stayed
behind, so a server whose proxied domain had been removed kept behaving as
though a CDN were still in front of it, which is exactly the state some of the
operators who reported this were in.

If you decide to publish your server's own address anyway, which is the only way
to run these three on such a node, that now works and the health check adds a
note saying what it costs: anyone holding a customer's link can read your
server's real address. It is a trade worth making knowingly rather than finding
out about later.

**One thing to know if you use resellers or managers.** The per-user page never
carried your server's real address to a reseller before this release and still
does not, and the same now applies to managers. On a server whose domain is
behind a CDN, only the owner sees an AmneziaWG configuration on that page, and
only the owner can take one from the AmneziaWG card, which is owner-only. On
every other server nothing changes for anybody. The AmneziaWG card also now says
which customer each peer belongs to, so a peer can be matched to a person.

## The setup assistant writes the address down

The assistant's review has always said "no domain, using this address", and then
nothing ever wrote that address anywhere. On a server with no address stored,
and where you are not about to add a domain, it now saves the detected address.
Only a public one: your stored address is what every subscription link is built
from, so a server behind NAT is left alone and told what is missing instead of
being given a guess that would break links that currently work.

## The manual and the search cover it

The manual section "Telegram proxy, mieru and AmneziaWG" now has a paragraph, in
all three languages, saying that none of the three needs a domain, exactly which
address each one uses and in what order, and what happens behind a CDN. Typing
"no domain", "ip" or "address" into the panel search now finds all three cards.
