# Nova Server v1.34.0

Five problems reported from real servers, a way to keep your panel address out of
your users' configurations, and one button that checks the whole node and repairs
what it safely can.

**If your server's disk has been filling up, this is the release that fixes it.**
Update and it reclaims the space on the next start.

## Your disk was filling up, and nothing was rotating the log

Xray's access log at `/var/log/nova/access.log` had no rotation of any kind. Not
in the installer, not in `logrotate.d`, not in the agent. It simply grew until the
disk was full. One operator watched a server go from 50% to 80% in a morning.

It cannot just be turned off, because Nova reads it to work out who is online. So
it is now rotated: a logrotate policy at 50 MB keeping three compressed copies,
plus a hard ceiling the agent enforces itself for machines that have no logrotate
installed. Both trim the file **in place**, which matters more than it sounds:
Xray keeps the file open and does not reopen it when a file is renamed, so an
ordinary rotation would leave it writing to a file nobody can see, filling the
disk anyway while the online-user list silently stopped updating.

This is installed every time the agent starts, not only on a fresh install, so a
server that is already full gets fixed by updating and trims itself immediately.

## AmneziaWG stopped turning itself off

If you turned AmneziaWG on and then added, edited or deleted a user, AmneziaWG
switched off. Every time.

Two different features shared one switch: the per-user WireGuard protocol, which
Nova manages for you, and the standalone AmneziaWG server you turn on yourself.
Turning it on yourself does not enable the per-user protocol, so the routine that
keeps per-user WireGuard in step saw the protocol was off and shut the interface
down, taking your hand-built server with it.

Nova now records which of the two created an interface and only ever takes down
its own. A server you enabled yourself is left alone. Existing servers are
protected the moment you update, without you doing anything.

## Users disconnected by an update, with no warning

Xray removed support for the mKCP transport, so Nova deletes mKCP inbounds when it
starts, because one of them stops the whole configuration from loading. That part
is unavoidable. What was wrong is that it happened in complete silence.

If a user had only been given mKCP inbounds, their subscription became empty.
Their app shows every field as `-1` and they cannot connect, and nothing anywhere
told you it had happened.

Nova now names the affected users in the activity log and sends you a Telegram
alert. It deliberately does **not** hand those users other inbounds by itself:
quietly giving somebody access their plan never included is a worse surprise than
the disconnection. The health check offers to restore them, as a choice you make.

## Keep your panel address out of your users' configurations

When you add a second domain, Nova has always published your configurations on
both that domain and your main one. That is deliberate, so a client can fall back
if one is blocked, and it stays the default.

But it meant your panel's address travelled inside every configuration you handed
out, and a configuration that names your panel is a configuration that gets your
panel blocked along with it.

A second domain can now be set to **"Instead of the panel address"**. Your
configurations use that domain and your main one is left out of them entirely.
Anything the second domain cannot carry stays on the main address rather than
being dropped, because an empty subscription would be worse than a visible name.

Existing domains are unchanged and keep publishing on both.

## AmneziaWG in one press

Turning AmneziaWG on used to leave you with a running server and no clients, so
there was still nothing to give anybody. **Set up with defaults** now picks
sensible settings and creates your first client, ready to hand out. The manual
route with its own strength and port is still there.

## One button to check the whole server and fix what it can

The health check now ends by sorting everything it found into three groups.

**What it can fix for you.** One press repairs all of them and runs the check
again so you see the result rather than a promise. It lists every change before
you press, and it will never make a change that gives a user access they did not
have: anything like that is left as a separate decision, with its own button.

**What needs you.** Choices only you can make, like which domain an inbound should
present, or whether to charge resellers for renewals.

**What cannot be fixed from here.** When something is left that nothing in the
panel can repair, the problem is usually in Nova rather than in your setup. Nova
offers to make a support report instead of leaving you pressing a button that
cannot help.

## A support report you can read before you send it

**Logs & Xray** has a new **Support bundle**. It gathers your Nova version, your
operating system, which services are running, your ports and protocols, which
checks failed, and the last few hundred log lines into one file.

Before you see it, every private value is replaced: your address and domain, your
users and their names and IDs, every key and password, your bot token, and any
address that appears in a log line. The same value always becomes the same
placeholder inside one file, so whoever helps you can follow one person through a
run of log lines and see what happened to them without ever learning who they are.
Those placeholders mean nothing in any other file.

Xray's access log is deliberately never collected. It is a record of which sites
each of your users visited, and no amount of scrambling makes that safe to pass
around.

The whole file is shown to you in the panel first. Copy it or download it and send
it however you like. Your server never sends it anywhere on its own and holds no
credential that would let it.

## Also

- The health check's port section was reading field names that did not exist, so
  it came back blank on a real server. It now shows what it always should have.

---

**Updating:** Settings, then Check for updates. Nothing in this release changes
your users' configurations: the subscriptions they already hold stay exactly as
they are, which was verified against a copy of a live server before release.
