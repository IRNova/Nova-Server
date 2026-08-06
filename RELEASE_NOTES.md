# Nova Server v1.41.1

A setting you already had, which the panel was not showing you.

## "How to use this address" now says so on every domain

Add a second domain and you can decide, per domain, whether it is published
alongside your panel address or instead of it. The list showed that choice only
when it was set to one of the less common options. On the default it showed
nothing at all.

So an operator who added a domain for their fronts, saw every configuration
appear twice, once on the new domain and once on the panel domain, had no way to
tell there was a switch for it. They reported the duplication as a missing
feature. It was not missing; it was invisible.

Every domain in the list now states how it is used, including the default. If
you want a second domain to carry the configurations **instead of** your panel
address rather than in addition to it, open it and set that: the duplicates go
away, and your panel address stops travelling inside what your users hold.

Nothing changed about how any of the three options behave. If your list looks
right today, it is unchanged.

## The manual now covers the CDN case

An operator worked out an arrangement worth passing on, so the Domains guide
describes it: put a second name behind Cloudflare and let it carry the WebSocket
configurations, then take your main domain out from behind the CDN. Your users
keep two things that do not depend on Cloudflare at all, the ability to refresh
their subscription and Hysteria2, which goes direct and never could pass through
a CDN anyway.

The guide is honest about the costs, since none of them are obvious: a domain
that is not behind the CDN publishes this server's address to anyone who looks it
up, a CDN outage takes every WebSocket configuration with it and leaves Hysteria2
as the fallback, and the subscription host has to stay on the main domain or the
outage can stop your users updating after all. It also warns about the order to
do it in, which the health check already catches: take the main domain off the
CDN while the second name is still an extra address and every configuration
carries both names, so the CDN hides nothing.

One detail decides whether the arrangement works or quietly defeats itself, so
the guide spells it out: set the CDN name to **WebSocket front only**. Hysteria2
and TUIC are UDP and cannot pass through Cloudflare at all. On All compatible
protocols, if your certificate also covers that second name, "instead of the
panel address" moves those two onto the CDN name too, where they cannot connect,
and the fallback you were relying on is the thing that breaks.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release.
