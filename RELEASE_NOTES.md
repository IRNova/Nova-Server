# Nova Server 1.78.0

Updating Nova now updates the Hysteria2 engine too.

## The gap this closes

Hysteria2 is not served by Nova itself. It is served by a separate program on
your server, and until now that program was installed once, when the server was
first set up, and never replaced.

The practical effect was backwards. Improvements to that engine reached only
servers built after them. A server set up last week got the current engine; a
server that had been running for a year kept the one it was born with. Almost
every release of that engine fixes a slow leak or a stall that builds up over
weeks of uptime, so the servers that stood to gain the most were precisely the
ones that could never receive it.

The Update button did not help either. It replaced Nova and nothing else, which
is not what "update" reads like to anyone pressing it.

## What changed

Updating Nova now updates the engine in the same click, and automatic updates do
it too. Nothing new to turn on and no new button.

It is careful about it:

- The download is checked against its published fingerprint before anything is
  replaced. If there is no fingerprint to check against, the update is refused
  rather than installed unverified.
- The new engine is asked to read your current Hysteria2 settings before it is
  allowed to replace the working one. If it cannot, the update is refused and
  your existing engine keeps running. This matters because a broken engine does
  not announce itself: Hysteria2 simply stops, which looks exactly like having
  switched it off.
- A server already running the current engine downloads nothing.
- If an engine update is refused, the update card says so. Previously the only
  symptom would have been a version that quietly never changed.

Your users, inbounds and settings are untouched, as with any update.

## Seeing when a customer was last connected

The user list now shows when each customer last actually used their connection:
"seen today", "seen 5d ago", or the date once it is further back than a week.

It reads the traffic Nova already records, so there is nothing to turn on and it
works from today rather than only for traffic from here on. A customer who has
never transferred anything says "no traffic yet" rather than showing a blank,
because never having connected is a real answer and a different one from "we do
not know".

Asked for in issue #2.

## Installing on a server that cannot reach GitHub

Installing xray needed two GitHub hosts that are routinely unreachable from the
places Nova is used: one for the install script, one for the version number. When
they were blocked, the installer stopped with an SSL timeout and nothing else to
go on, and there was nothing wrong with the server.

Nova now keeps its own copy of xray on its release page and falls back to it when
GitHub cannot be reached. That copy is checked against a fingerprint before it is
unpacked, and GitHub stays the first choice, so a server with normal access keeps
getting whatever xray publishes today.

mieru, the Telegram proxy and the Hysteria2 engine have been kept this way for a
long time. xray was the last piece still fetched directly.

Reported in issue #21.

## The REST API is in the guide now

Nova has had a REST API at `/api/v1` the whole time, including a page that lists
every route it accepts, but nothing in the guide mentioned it, which is why
people asked. The Updating the node section now explains where it is and how to
create a token for it.

Raised in issue #8.

## Upgrading

Panel: Settings, then Update. Or turn on Automatic updates and it happens on its
own. Re-running the installer over SSH still works and does the same thing.
