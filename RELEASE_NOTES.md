# Nova Server 1.61.0

The certificate a node without a domain depends on, and a word about simple mode.

## Nodes without a domain

That certificate is not cosmetic. The subscription link is fetched over it, so a
bad one means apps refuse to import the link and several protocols will not
connect. Operators reported both ways it goes wrong: an error during install,
and, worse, no error at all.

The silent case had a cause. A certificate carrying only a common name is
rejected by every current app, and Nova could produce exactly that: the
installer asked for a SubjectAltName and, if that attempt failed for any reason,
quietly fell back to one without it. The node then served a certificate nothing
would accept while looking perfectly healthy from the inside. The panel's own
"remove domain" path had the same gap, so a node that dropped its domain got the
same unusable certificate.

Both now always carry a SubjectAltName, and the installer says so if one still
lands without.

**The Domain page now tells you the truth about it.** A node with no domain sees
whether its certificate is valid, and if it is not, why: missing, damaged,
expired, issued for the wrong address, or naming no address at all. Beside that
is a button to issue a new one.

The button verifies before it reports success, because writing a certificate
and not checking it is the bug this exists to fix. If it still cannot produce a
usable one, it says so and explains how to issue one by hand and where to put
it. It will not touch a node that has a real certificate.

## Simple mode says what it is hiding

A panel in simple mode hides whole pages: routing, outbounds, clean IPs, tunnel,
fleet and the Xray settings. Nothing said so, so an operator looking for a
setting could not tell "this panel does not have it" from "this panel is not
showing it to me", and the switch that reveals them is itself on one of those
pages.

The dashboard now says which pages are hidden, with a button to show everything
and one to dismiss it.

## Upgrading

No action required. If your node already serves a good certificate, nothing
changes. If it does not, the Domain page will now tell you, and one button
fixes it.
