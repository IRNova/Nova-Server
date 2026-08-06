# Nova Server v1.40.0

Four things operators reported, and one access problem found while checking
them. Please read the first section before updating.

## Please read: some users may lose a configuration

Nova decides which protocols a user may have. That decision was applied to the
plain subscription but **not** to the Clash, sing-box, Hiddify and Karing one, so
a user could be denied a protocol, see it correctly missing from one client, and
still receive a working configuration for it in another.

The Hysteria2 front is the case that mattered: the server accepts any enabled
user, so that configuration genuinely worked. Anyone you restricted could open
the same subscription link in Hiddify and have access you had not given them.

That is now fixed, and the two agree. **If someone was relying on access they
were never granted, their client will lose that configuration when it next
updates.** On one of our own nodes exactly one user was in that position.

If you want them to keep it, grant it deliberately: open the user and tick the
protocol, or put it in their plan. Users whose inbound list you never restricted
are unaffected, because that has always meant "everything".

## Backups now keep everyone's usage

Taking a backup and restoring it on a new server reset every user's traffic to
zero. Their limits, expiry and settings came across; how much they had actually
used did not.

That is not cosmetic. Quotas are measured against those numbers, so everybody
quietly got a full allowance again and there was no way to tell who had used
what. Backups now carry the usage and restore it with everything else.

Backups you took before this release still restore exactly as they did.

## Users who only have the country exits are no longer reported as broken

If you give someone only the per-country exits (Tor, Psiphon), so their real
address never reaches a domestic service, the health check called them out in red
as receiving no configurations at all while their client was connected and
working.

Worse, the repair it offered would have rewritten that user's inbound list and
given them access you never granted. Both are fixed. Users who genuinely receive
nothing are still reported, including the case worth catching: someone set up for
the country exits on a node where they are all switched off.

## Plans can include the country exits

The country exits were a per-user switch, so a reseller could not sell them and
you had to set them by hand on every customer. They are now part of what a plan
grants, like the protocol list, which means you can build a plan that routes only
through Psiphon and Tor.

Turning them off in a plan takes them away on an upgrade or downgrade, so a plan
change does what it looks like it does.

## The panel's memory use

A report that the panel's RAM kept climbing turned out to be mostly something
else, and the measurement is worth sharing.

On a node running five country exits, Nova used about 1230 MB in total. The
panel agent was 363 MB of it and was not growing. **About 740 MB was Tor: each
country exit runs its own instance costing roughly 120 MB.** Five countries cost
more memory than everything else Nova runs put together. If your server is short
on RAM, that is the number to look at first.

The agent is now capped regardless: it will not grow into whatever memory the
machine happens to have, and it has a ceiling so that if it ever does leak it
restarts instead of taking the node down with it. Your proxy keeps serving while
that happens.

This applies to nodes that already exist, not just new installs.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release.
