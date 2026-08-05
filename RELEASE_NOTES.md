# Nova Server v1.37.0

## Sending a support bundle now works

The support bundle has had two buttons since it arrived: **Copy** and
**Download**. There is now a third, **Send to Nova support**, because there is
finally somewhere for it to go.

Nothing about the bundle itself has changed. It is still built on your server,
still has every private value taken out before you see it, and you still read it
before deciding anything. Sending is a separate, explicit choice you make after
reading, and the confirmation tells you exactly what is about to happen.

Two details worth knowing, because they are the reason this took a while:

- **The upload comes from your browser, not from your server.** Your node never
  connects to us. It has no reason to, and on a censored network it may not be
  able to anyway. Download still works when we are unreachable.
- **Your panel address is not sent.** A normal upload would attach the address of
  the page it came from, which is the one value the bundle spends its whole
  length keeping out. The upload is deliberately made in a way that sends no
  address at all, and the receiving end refuses any request that carries one.

You get back a short code such as `NV-A1B2C3`. Quote it when you ask for help.
The code on its own does not let anyone read the file, and everything is deleted
after 30 days.

If you would rather not send anything, nothing has changed. Copy and Download
are still there, and the bundle is yours to hand over however you prefer.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release.
