# Nova Server 1.58.2

SOCKS and HTTP access now tells the customer how to connect.

## What changed

A SOCKS or HTTP inbound could be created, assigned to a customer, and enforced
by the server, while the username and password it required were written down
nowhere: not in the panel, not on the customer's own page. The access worked and
nobody could use it, because nobody could be told what it was.

These protocols have no share link, so no subscription carries them and no app
imports them. They are typed in by hand, which means the details have to be
readable somewhere, and now they are.

The customer's subscription page lists every SOCKS and HTTP proxy they hold,
with the address, the port, the username and the password, each with its own
copy button, since these get entered one box at a time into a browser's proxy
settings or a phone's network options.

The details come from the same place the server's own configuration does, so
what a customer is shown is what the node accepts. A proxy that carries no UDP
is marked, because a client expecting it fails in a way the customer cannot
diagnose.

## Notes

The address shown is the one the customer can actually reach: the node's
address, or a per-inbound public address when the operator has set one.

Nothing else changes. Existing inbounds, users and subscriptions are untouched,
and the credentials were always these; they were simply never displayed.
