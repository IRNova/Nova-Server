# Nova Server v1.35.0

Everything reported since 1.34.1, worked through in order. One of these had been
quietly breaking Telegram users on every node that runs without a domain.

## Links from the Telegram bot did not work in v2rayNG or v2box

If you created a user, sent them their link from the bot, and it would not
connect no matter what they tried, that was not their client and not their fault.

Nodes running without a domain use a self-signed certificate. Recent versions of
xray-core removed the old `allowInsecure` option and now treat it as a hard
error, so Nova moved those nodes to a pinned certificate hash instead. The panel
was already doing this correctly. The bot was not: the links it handed out still
carried the old form, which current clients refuse outright. The configuration
would import and look perfectly normal, then fail on every connection attempt.

Links from the bot and links from the panel are now identical. If your users took
their link from the bot, have them fetch it again.

## AmneziaWG port and obfuscation level can be changed

Change the port or the obfuscation level, press enable, and the old values came
straight back. What you typed was read and then ignored: the code only ever
filled in values that were missing, so anything already set was left alone.

Both now apply. Changing the obfuscation level also regenerates the junk packet
parameters that make the traffic look different, which is the reason to change it
in the first place. Setting one up for the first time behaves exactly as before,
and no existing server has its keys regenerated.

## Inbounds attached to a deleted node are now caught

If a node is removed while an inbound is still pointed at it, that inbound stops
being placed anywhere. It keeps sitting in the panel looking completely healthy,
and it serves nobody. Nothing on screen suggests anything is wrong.

The health check now finds these and offers to move the inbound to a node you
pick. It will not do it for you as part of "fix everything", because which node
your traffic runs on is your decision, not a detail to be tidied away silently.

## The health check is on the dashboard

It has a row of its own near the top, and it reports what it found even when
everything passes. A check you only ever hear from when something is broken is a
check nobody comes to trust. There is a new guide section covering what it looks
at, and what it will and will not change on its own.

## The fragment setting was described wrongly

Several people turned fragment on, opened their client, saw fragment switched
off, and reported it as broken. The setting was working. The description was
wrong: it configures fragmenting on the server's own outgoing connections, not in
your users' clients. The wording now says that plainly, in all three languages.

## The Farsi manual now reads in the right order

Latin words sitting inside Farsi text, protocol names, domains, file paths and
commands, were rendering with the punctuation around them in the wrong place.
More than 260 of them across the manual, in the one document you open precisely
when you are already stuck. They are all fixed, and anything added to the manual
later is handled automatically.

## A security fix worth updating for

A user's name is written into the AmneziaWG server configuration as a comment,
and it was not being checked for characters that end that comment early. Anyone
who can create or rename a user, which includes your resellers, could put content
into that file that does not belong there. On a node with per-user WireGuard
enabled, that is enough to take the tunnel down for everyone on it, and
potentially worse.

The name is now stripped of anything that could break out of the comment, at the
point it is written and at both places it is set. This affects every version
before this one, so if you have resellers and AmneziaWG turned on, update sooner
rather than later.

## Also in this release

The log viewer no longer reads entire log dumps aloud to screen readers each time
it refreshes.

The health check's headline was leaving port results out of its own count, so a
server whose 443 was unreachable could still be told everything was working. The
dashboard row and the health screen now report the same total, and it includes
the port checks.

Two smaller repairs to the health check itself: it no longer reports every
inbound as broken on a managed node or in resilience mode, where the thing it was
checking does not apply.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release.
