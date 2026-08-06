# Nova Server v1.39.0

## A JSON configuration link, for people who prefer one

Some people would rather import a full Xray configuration into their client than
a subscription link. v2rayNG calls it a **custom config**, other panels serve
them, and an operator asked for it.

Open a user's page and expand **Need a JSON config instead?**. There is a second
link there that serves the same subscription as complete Xray configurations.
Same servers, same limits, same user. Hand out whichever link suits the person
asking.

A few things worth knowing:

- **The normal link has not changed and is still the one to give out.** It
  already serves every client correctly: Nova looks at which app is asking and
  answers in the right format. Nothing about your existing links, or the apps
  already using them, is affected by this release.
- **Only protocols Xray itself supports can appear in a JSON config.** Hysteria2
  is not one of them, so it is left out of that link and stays in the normal one.
  This is not a limitation Nova chose: a configuration containing anything Xray
  cannot connect with is rejected in full, which would leave the person with
  nothing at all rather than with the rest of their working servers.
- **XHTTP inbounds appear here**, and only here. Xray is the only core that
  implements that transport, so until now an XHTTP inbound could only be handed
  out as a plain link. This release also stops Clash and sing-box quietly losing
  it from the shared list; they still skip it, because they cannot run it.
- **Nodes with no domain work too.** Those serve their own certificate, and the
  JSON configuration pins it, so it verifies properly rather than being told to
  skip checking.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release.
