# Nova Server 1.64.0

Two things that were dead and said nothing about it: an inbound routed through
WARP, and the per-country exits.

## An inbound routed through WARP carried nothing

Pick WARP as an inbound's egress, save, hand out the link, and every connection
opens and then sits there. Not refused, no error, just nothing back. It looks
like a broken server, a bad certificate, or a problem with the app.

Which traffic goes to WARP is decided by a routing rule written from the
inbound's own setting. The WARP connection behind that rule was only built if a
WARP account already existed on the server, and an account only ever existed if
somebody had pressed Register on the WARP card. So choosing WARP anywhere else
produced a rule pointing at something the proxy core does not have, and
everything matching it was dropped.

The account is free and takes one request to Cloudflare, which is what that
button always did. **Now the server gets one by itself** whenever the
configuration asks for WARP: when you pick it on an inbound, when you save a
routing rule that uses it, and on the next restart for a server that is already
in this state. So existing servers repair themselves.

If the server cannot reach Cloudflare, the health check now says so in plain
terms, names the inbound that is affected, and carries a button that tries
again. It used to say only "WARP: enabled but no account registered", in a list
you had to go and open, with nothing connecting it to the inbound that was dead.

## Country exits could not start, on every country at once

Every per-country Tor exit showed Stopped, all of them together, with "nothing
is listening on this exit's local port", while Tor itself was installed and
running fine. The natural conclusion is that the country has no exit relays.
That was wrong.

Nova wrote each country's configuration into a folder Tor is not allowed to
open. Tor runs as its own user, that folder belongs to the certificate
directory, and the certificate directory is deliberately closed to everyone but
the proxy. So Tor could not read its own configuration and quit in a fraction of
a second, on every country, from the day the feature shipped. The panel could
only report the symptom.

The configuration now lives in its own folder, owned by root and readable by
Tor, and deliberately not inside the folder Tor itself owns. **1.63.1 announced
this fix and did not deliver it**: the folder it moved to is closed on any server
where Tor was installed from the panel, which is most of them.

Three more things around it:

- **The repair now tells the truth.** "Repair all exits" reported success as
  long as it could write the files, so it could report five countries repaired
  while all five were still dead. Failures to enable or start a country are
  reported now, per country, and a country whose files could not be written is
  no longer started on top of that.
- **Adding a country no longer restarts the others.** Every reconcile restarted
  every exit, so adding a sixth country dropped every customer on the five that
  were working, and Tor then needed minutes to rebuild circuits. Only exits that
  actually changed, or are not running, are restarted.
- **The health check covers them.** Each enabled country exit is checked, and
  when one is down it says why where it can: never installed, failed so often
  systemd gave up, or starts and dies immediately. A button on the health check
  reinstalls and restarts them all.

## Also

- The health check no longer spends four commands per stopped country exit. On a
  server with many of them, and especially on one where systemd is itself
  unwell, that was a slow page at the worst moment.
- Registering a free WARP account no longer warns you that customer
  configurations will change and everyone needs to resubscribe. Nothing about
  your customers changes.

## Upgrading

Update and restart. A server whose configuration routes traffic through WARP
registers an account on that first start, and the activity log says so. Country
exits are rewritten and restarted on the same boot, and any that still cannot
start are named in the log rather than passed over.
