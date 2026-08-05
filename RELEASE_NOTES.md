# Nova Server v1.34.1

A patch on 1.34.0. The Update button now tells you what happened, and you get
proper control over which of your domains appear in your users' configurations.

## The Update button was hiding its own failures

If you pressed **Update** and nothing seemed to happen, this is why. The update
ran in the background with its output thrown away, so every possible failure was
invisible: no network, a refused checksum, a disk with no space left, a release
file that had not finished publishing. The panel had already said "update
started", the version simply never changed, and nothing anywhere told you why.

Several operators concluded the button did not work and updated by hand from
GitHub instead. That was a reasonable conclusion and the button was at fault.

Now the panel watches the update and tells you how it ended: **"Updated to
1.34.1"**, or a plain reason such as *"the downloaded file did not match its
checksum, so it was refused"* or *"the update downloaded but could not be
unpacked (is the disk full or read-only?)"*.

The update itself was never broken. It was only silent. Fixing it turned up two
things worth naming: checksum verification was skipped entirely on systems
without `sha256sum`, which some minimal images lack, and it was also skipped when
a release had published its archive but not yet its checksum file. In both cases
the update installed unverified rather than refusing. Nova now falls back to
`shasum`, and refuses outright when no checksum is available.

## Choose which of your domains your users' configurations use

1.34.0 let a second domain carry your configurations **instead of** your panel
address. This adds the third option, so you now have full control per domain:

- **As an extra address.** Published alongside your main one, so a client can
  fall back if one is blocked. Unchanged, and still the default.
- **Instead of the panel address.** This domain carries the configurations and
  your main one is left out of them entirely.
- **Never in configurations.** This domain keeps working for the panel and keeps
  its certificate, but no configuration ever names it.

The last one is for a domain that points straight at your server. Anyone holding
a configuration that names it can look it up and find your address.

## Nova now tells you when your address is exposed

If you have put one domain behind Cloudflare to hide your server's address, but
your configurations still carry another domain that points straight at the
server, the health check now says so. The proxied domain protects nothing while
the two are published together: one configuration is enough to find the server.

This only appears when you actually have a proxied domain. On a node with no CDN
in front, every name points at the server, that is simply how it works, and there
is nothing to warn about.

An operator worked this out for themselves and asked why the panel had not told
them. It should have.

---

**Updating:** Settings, then Check for updates. Nothing in this release changes
your users' configurations.
