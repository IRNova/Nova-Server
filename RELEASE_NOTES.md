# Nova Server v1.43.1

## The manual and the panel search now cover what 1.43.0 added

1.43.0 shipped two features and documented neither in the place operators
actually look. The panel's manual said nothing about Reality short IDs varying
per user, and nothing about branding the subscription page. Searching the panel
for "brand", "logo" or "short id" returned nothing at all, so both features were
reachable only by already knowing where they lived.

Both now have manual entries, in English, Persian and Russian:

- **Inbounds** explains that a Reality inbound holds a set of short IDs rather
  than one, that each user is given one of them, that saving only ever adds to
  the set because a configuration a customer already holds carries the ID it was
  issued with, and that existing inbounds stay as they are until you widen them
  through the health check, because widening reloads the proxy core and briefly
  interrupts live connections.
- **Settings** explains the subscription page branding: your name, your logo,
  and dropping the Nova social links, plus why the logo is embedded rather than
  linked and why SVG is not accepted.

The panel search has a row for each, so "short id", "sni", "brand", "logo" and
"white label" now find them, in all three languages.

Nothing else changed. No code path, no setting, no user, no inbound, and no
client configuration is affected by this release. If you are on 1.43.0 and do
not use the manual or the search, there is nothing here you need.

---

**Updating:** Settings, then Check for updates.
