# Nova Server 1.87.0

Soar, Lantern's DNS tunnel, as a third engine, per customer if you want.

## What it is

Soar is a DNS tunnel from the Lantern team, built against the two engines
Nova already ships: it uses every resolver at once with in-country discovery,
recovers from loss quickly, and connects in seconds rather than tens of
seconds. It carries TCP only, to ports 80 and 443 unless you widen that.

Upstream's server has no notion of a customer: anyone holding its public key
can use it. Nova runs it through soar-nova, a small wrapper of our own that
keeps upstream unmodified and serves one Soar instance per account, each with
its own key and its own byte counters. That is what makes the second mode
possible.

## Two modes

Shared: one account, one link, handed to whoever you choose. The same shape
as MasterDnsVPN and CottenDns, with no per-customer accounting.

Per customer: a switch in each customer's form, like mieru's. Every granted
customer gets a key and link of their own, their Soar traffic lands in the
same usage ledger as everything else, so data caps, expiry and the usual
alerts apply, and revoking closes that one customer. Resellers can be allowed
to grant it; plans and bulk actions carry it.

The link is WhiteDNS's profile format, because the WhiteDNS app for Android
(1.6.8 or newer) is today the only client that imports a third-party Soar
server. It appears on the customer's subscription page and in the panel's
per-customer links. The health page reports customers who were granted Soar
while the tunnel is off, on another engine, or in shared mode.

## Caveats

Soar is nine days old upstream and changed four times last week. Its wire
format may still move; Nova pins the exact version it was built against and
will update it the same way it updates the other engines. Nobody has measured
it from inside Iran yet, including WhiteDNS. Treat it as a field test: enable
it on one server, give it to a few customers, and tell us what you see.

Android only for now. No iOS or desktop client exists. If the engine proves
itself, the Soar client can be built into the Nova app, which is a separate
piece of work.

## Upgrading

Update from the panel, or run the installer again. The soar-nova engine is
installed on demand the first time you enable Soar, checksum-verified from
Nova's own release, the same way mieru's server is.

# Nova Server 1.86.2

The health page now shows what the last two releases do on their own.

1.86.0 and 1.86.1 added three things that happen without a click: the
Hysteria2 engine replaces itself on the daily check, mita updates itself when
mieru is switched off and on, and a clean IP that does not answer is put on a
strike and removed the next day. Each had a failure the panel showed only in
the activity log or on a card an operator may not open. The health page now
reports a refused engine update with its reason, a mita behind this release's
version (as information, since it fixes itself) or whose update failed (as a
warning, with the error), and a clean IP on its first strike. A fresh, healthy
server sees none of these rows, and the setup assistant still produces a
server the health page has nothing to say about.

Everything below is 1.86.1 and 1.86.0, released the same day.

# Nova Server 1.86.1

A clean IP that does not answer is no longer published, and turning mieru off
and on now brings mita up to date.

## The dead clean IP

An operator reported a Cloudflare address in the clean-IP list, 172.67.18.6,
that accepted no connection at all. Every config that drew it was dead. It was
measured while this was written: the address is inside Cloudflare's published
ranges, one of the sources still answers with it, and TCP 443 to it does not
open from anywhere, while every other address the same source returned
completed a TLS handshake in about 40 milliseconds.

Nova checked the one thing the sources could not lie about, that an address is
Cloudflare's, and never the thing they did not promise, that it serves. The
daily refresh now dials every candidate and every address already in the
list with a verified TLS handshake, using your own proxied domain as the name
so the certificate has to be the one for your zone. A new address that does
not answer is not admitted. An address already in your list is removed only
after failing on two consecutive days, so a momentary blip at this server
cannot delete something you chose, and an address that is dead from here but
alive from Iran gets a second look. If most or all addresses fail in one
round, that is this server's network rather than thirty dead addresses, and
nothing is removed; when your own domain cannot be verified on any edge but
Cloudflare's own can, the log says the name is the problem rather than the
network. What was removed, and what is on its first strike, is written to the
activity log by address.

This does not judge reachability from inside Iran, which only a client can
measure; it removes the addresses that are dead for everyone, which is what
the report was.

## mieru


Until now the pinned mita only ever reached fresh installs, so a server that
already had mieru stayed on whatever version it was built with, and 1.86.0
said so. An operator asked for the obvious thing instead: switching mieru off
and on should update it. Now each time mieru is enabled, or the agent
reconnects it after an update or a restart, the installed version is compared
with the pin. If it is older, the same checksum-verified download from Nova's
mirror runs and the mieru service restarts on the new binary. A mita newer
than the pin is left alone. A download that fails, or lands the wrong
version, leaves the working mita in place and is noted in the agent's log.
Re-running the installer does the same, and restarts mieru only if it was
running.

Everything below is 1.86.0, released the same day.

# Nova Server 1.86.0

A re-created customer starts clean, and the Hysteria2 engine moves to sing-box
1.14 with the pinned tools alongside it.

## The bug operators reported

Create a customer called A with a quota. Let A use it. Delete A. Create a new
customer called A. The new A arrived already over cap, carrying the old A's
traffic, last-active day and IP-limit lock.

The panel turns a name into an id, so the second A had the same id as the
first, and deleting a customer removed their record from the user list and
nothing else. Everything the server stores under that id stayed: the traffic
ledger, the per-day counters, the IP-limit lock, the Telegram flag. The
mieru and Telegram-proxy credentials are also derived from the id, so the old
A's saved configs worked again the moment the new A existed, on the new A's
quota.

Deleting a customer now clears all of that, and also their registered
devices, the last client addresses seen for them and the "already warned"
flags, through every route that deletes: the single delete, the bulk delete,
the whole-list save, removing a reseller together with their customers,
restoring a backup that does not contain them, and a managed node whose
parent stops sending them. The deleted id is remembered as retired, and a new
customer given that name gets a numbered id (a-2) rather than the old one, so
nothing of the old customer, traffic or credentials, can attach to the new
one. Restoring a backup or importing a Nova export with identities preserved
brings an id back legitimately, and clears the retired mark for it. A factory
reset clears the retired marks too. Existing customers are not touched.

One rule comes with this: a new customer id must be 1 to 64 characters of
letters, digits, underscore or hyphen, which is what the panel has always
produced. Ids of another shape that already exist keep working.

## What else changed

Hysteria2 on a Nova server is served by sing-box. The engine Nova publishes
moves from 1.13.19 to 1.14.1, the current upstream release, built exactly as
before: unmodified upstream source, the same eight build tags, pinned to the
upstream commit and checked tag by tag after the build.

Nothing changes in how it reaches you. A server with automatic updates on
fetches the engine's published checksum on its daily check, sees that it
differs from the one it installed, downloads the new engine, asks it to load
the server's current Hysteria2 settings, and only then swaps it in and restarts
Hysteria2. Any other server does the same the next time you press Update. An
engine that cannot read your settings is refused and the working one stays.

The configuration Nova writes for Hysteria2 was run through the real 1.14.1
binary before this was published. It loads without a warning, including the
older form of the link-local block that keeps loading on every engine version a
node might still have.

mieru's server, mita, is pinned at 3.37.0 for new installs and for servers that
turn mieru on from now on. 3.36 made matching a new connection to its user
faster and cut allocation churn in the cipher; 3.37 adds an optional single-IP
listen address that Nova does not use. Every behaviour the agent depends on was
re-checked against the real 3.37.0 binary: a name over 64 bytes still rejects
the whole document, applying a config still replaces the user list, an empty
user list still fails to start, and the columns of `mita get users` are
unchanged. A server that already has mieru keeps its current copy.

grpcurl, which the agent uses to read Hysteria2 per-user statistics, is fetched
at 1.9.4 instead of 1.9.1 on new installs, and it is now pinned the way the
other tools are. Until now it was the one download in the installer with no
checksum, no https-only rule and a fixed path under /tmp. The archive is now
verified against upstream's published SHA-256 before anything is installed,
fetched over https only, and staged in a private directory. A mismatch leaves
the server without metering rather than with an unverified binary.

## Upgrading

Update from the panel, or run the installer again. The Hysteria2 engine update
happens on its own; the update card shows the engine's last attempt if you want
to confirm it.
