# Nova Server 1.60.0

Four things operators reported about resellers.

## Selling a customer without any xray inbound

Unticking every inbound gave the customer every inbound. The list was read as
"no opinion" and quietly replaced with the reseller's whole allowlist, so a
reseller selling access that is only AmneziaWG, or only a country exit, saved
the form and got all of them back.

An empty list now means empty. A request that never mentions inbounds at all,
applying a plan, renaming a customer, still gets the reseller's allowlist as
before.

## Taking an inbound back now reaches the customers already sold

Withdrawing an inbound from a reseller only affected the next customer they
created. Every customer they already had kept it in their subscription until
somebody opened and saved each account by hand, so on a reseller with a hundred
customers the withdrawal had effectively not happened.

It now applies the moment you save, to all of that reseller's customers, and
the running core is reloaded with them. It only ever removes: widening a
reseller's allowlist never silently grants their existing customers more.

## A reseller can carry their own brand

Grant "Manage own branding" and the reseller gets a My brand page with the same
name and logo form you use, applied to the subscription pages their own
customers open. Nobody else's customers see it.

They set only what they want to change: a reseller who sets a name but no logo
keeps yours. Withdrawing the capability puts all their customers back on your
brand at once, and their setting is kept in case you grant it again.

## The reseller mode is chosen once

Switching an existing reseller between plan and volume looked like it worked
and did not. The two are backed by different fields, and a reseller's
customers, plans and ledger are all keyed to the mode they were sold under, so
a flipped record showed figures that measured nothing.

The mode is now chosen when the reseller is created and shown as a fact
afterwards. Existing resellers keep the mode they have.

## Upgrading

No action required. Nothing changes for existing resellers except that a
withdrawn inbound now takes effect immediately, which is what it was always
meant to do.
