# Nova Server v1.36.0

Two things operators asked for, both about control over your own addresses.

## Your panel address can now stay out of the subscription link

1.34.1 let you say that a second domain should carry your configurations
**instead of** your panel address. That worked, but only for the configurations
inside a subscription. The subscription link itself, the address you actually
hand to people, still named your panel.

That link is the most widely shared thing you distribute. It goes into the
client, into a QR code, and gets forwarded on. So the address you most wanted
hidden was in the one string everybody sees.

Under **Additional domains** there is now a **Subscription link uses** setting.
Pick one of your other domains and the link names that instead. Three separate
choices, so you can decide each one on its own:

- **Instead of the panel address** decides what is inside the configurations.
- **Never in configurations** keeps a domain working for the panel while no
  configuration ever mentions it.
- **Subscription link uses** decides the address in the link itself.

Links you have already handed out keep working, and so does your panel address.
If the domain you pick ever stops being usable, for instance its certificate
lapses, links quietly go back to your panel address rather than pointing
somewhere nobody can reach.

## A domain can use a certificate you already have

Until now Nova either issued the certificate itself or you pasted one in. If
your certificate comes from your own certbot, an internal authority, or you
bought it, neither fitted.

Adding a domain now offers **Use certificate files on this server**. Give it the
folder, for example `/etc/letsencrypt/live/example.com`, and Nova finds the
certificate and key, checks they really cover that name and match each other, and
takes it from there. It understands the usual layouts, so in most cases the
folder is all you need to type.

Nova keeps its own copy, so it carries on serving even if that folder later
changes or disappears. The one thing to know: renewing the files there does not
reach Nova on its own. The health check watches for exactly that and tells you to
re-add the domain, well before the certificate you are serving runs out.

Together with the per-inbound address that already existed, this means one
inbound can sit on its own subdomain using a certificate you supplied yourself.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release, and nothing needs reconfiguring.
