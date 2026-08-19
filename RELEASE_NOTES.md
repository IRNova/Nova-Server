# Nova Server 1.69.2

Two things an operator reported, both about the panel saying something untrue.

## The health check called a working tunnel broken

If AmneziaWG was set to leave through WARP, Tor or Psiphon, the health check
reported that the rule carrying its traffic was missing, in red, on nodes where
that exit was working perfectly.

The rule changed in 1.68.1, because the old one was written in a form the
firewall refuses. The check was left asking about the old one, so it failed on
the same argument error every time and could only ever answer no.

That is worse than having no check at all. A red line that is always wrong
teaches an operator to ignore red lines. It asks about the rule that is actually
installed now, and a test ties the two together so they cannot drift apart
again.

## The warning about shared customer ids says which customers

It reported that some of your customers hold ids from the old shared "user"
series, said how many, and would not say which. The thing it asks you to do,
work out whether a customer went missing, cannot be done without that list.

It names them now, with their ids, since customers can share a display name.

## Upgrading

Update and restart, then run the health check again. If it was showing the
AmneziaWG exit in red while the exit worked, it should be green now.
