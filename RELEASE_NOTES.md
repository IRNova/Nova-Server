# Nova Server v1.38.0

Five things operators reported. Three of them were the panel telling you
something that was not true.

## An inbound on one of your nodes was reported as dead

If the health check showed a red "Nothing is listening on <port>" for an inbound
that runs on one of your nodes, and pressing **Reload service** ran for a few
seconds and changed nothing however many times you tried, nothing was ever wrong
with it.

That inbound listens on its node, not on your panel's server. The check was
looking at the wrong machine, so it could never pass, and the repair it offered
reloads the panel's own service, which cannot make another server's port appear.
Your configuration was working the whole time.

The check now only looks at ports this machine is actually meant to be listening
on. On our own panel that removed eight permanent failures.

## Users who had one of the default fronts were reported as having nothing

Give someone one of the shared 443 protocols and nothing else, and the health
check called them out in red as receiving no configurations at all, while their
client was connected and working perfectly.

It was worse than a wrong colour, because the fix it offered would have rewritten
that user's inbound list and given them access they were never meant to have.
Both are fixed. Users who genuinely receive nothing are still reported.

## AmneziaWG can be pointed at the right address

AmneziaWG is WireGuard, which is UDP, and a CDN does not carry UDP. If your main
domain sits behind one, which is what we recommend for everything else, the
configurations it produced could not connect at all, and the address had to be
edited by hand before handing each one out.

There is now an **Address clients dial** setting on the AmneziaWG panel: your
panel domain, any of your other domains, or the server's IP. When Nova can tell
your main domain is behind a CDN it picks a direct address by itself, and the
health check explains the problem if the one you picked cannot work.

## A front can be published on its own domain

Front protocols (VLESS, VMess and Trojan on the shared 443) now have the same
domain picker every other inbound has, and it now does something: previously the
setting could be entered and was quietly ignored. Both the address and the
certificate name move together, so the handshake still matches.

## Hysteria2 can be turned off

Hysteria2 could be running, appearing in everyone's configurations and ticked for
every new user, with no switch anywhere to turn it off. The only thing you could
do was untick it for each user by hand.

Settings now has a proper on/off switch for it, above the port. Turning it off
asks first, because it removes a configuration people may currently be using.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release.
