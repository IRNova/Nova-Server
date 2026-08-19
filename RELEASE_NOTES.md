# Nova Server 1.68.2

Choosing Tor or Psiphon as an exit installs it for you, and Psiphon is verified
before it is allowed to run.

## The exit you chose is a service, and nothing installed it

Tor and Psiphon exits hand traffic to a service running on the node itself.
Nova installed neither, so an operator could pick one, be told the setting was
saved, and get silence. The thing that would have fixed it, a one-click install,
lived on a different page with no reason to visit it.

Choosing one of those exits now installs it. If it is already there but stopped,
it is started. Either way it happens in the background, so the choice itself is
never left waiting on a package manager, and a node that already has the service
does nothing at all.

WARP needs none of this. The node registers its own account.

## The health check has the button it was missing

A service that is not installed, or installed and not running, can now be fixed
from the row that reports it. That matters for the nodes that were already stuck
in that state, and for an inbound routed through one of those exits, which never
passes the AmneziaWG card at all.

## Psiphon is checked before it runs

It was downloaded from a location that could change at any time, with nothing
verifying what arrived, and then run as a service with full privileges. It is
now fixed to one known version, checked against a known fingerprint, and refused
if it does not match. Its configuration file travels inside the update rather
than being fetched separately.

An interrupted download is also no longer mistaken for a finished one. The old
behaviour left a half-written file that counted as installed, so nothing ever
tried again.

## Psiphon on ARM servers says so

There is no ARM build of Psiphon. Nova asked for one anyway, saved the error
page the server returned, marked it executable and enabled a service that could
never start, while reporting the install as successful. On an ARM machine it now
declines and says why. Tor is unaffected and works on both.

## Upgrading

Update and restart. Nothing changes for a node that does not use these exits. If
you had chosen Tor or Psiphon and it never worked, choose it again after
updating and the install starts by itself.
