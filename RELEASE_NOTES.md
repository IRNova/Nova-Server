# Nova Server 1.71.3

Five things, all reported from the field.

## XHTTP servers were dialling the wrong path

An XHTTP server delivered to the Nova app connected and then carried nothing:
the app shows Connected and sits on Verifying for ever. The same server from the
ordinary link list worked. Everything about the config matched except one field,
and the path was being replaced with `/`.

Only WebSocket ever copied the path and the host onto a config object. That was
invisible for as long as it was true of nothing that mattered: the link list is
built from the inbound itself, so it was always right, and no other format
rendered XHTTP at all. 1.71.0 taught `?target=nova` to carry XHTTP, and it
inherited the gap.

The Xray-config link (`?target=json`, "custom config" in v2rayNG) had the same
fault, and for much longer, since it has emitted XHTTP settings all along. Its
XHTTP mode was being ignored too, always sent as `auto` whatever the inbound
said. Fixed on the config object rather than in each renderer, so the next
reader cannot inherit it again, and checked by comparing the same server across
all three outputs.

## A tunnel you could not switch off

Every control on the Tunnel page lived inside the code that ran only when the
live status loaded. So an operator whose tunnel was misconfigured, which is the
one operator who needs that page, got a spinner, then "could not load tunnel
settings", and no controls at all: they could not correct the address, could not
try a different Iran server, and could not turn the tunnel off. The
configuration that broke it was already saved, so every reload reproduced it.

The settings now render whatever happens to the status, from what the panel
already knows. A rendering error is also no longer reported as a failure to
load: one catch covered both, so a display bug looked like a broken tunnel.

And a tunnel that fails to start is left switched OFF rather than recorded as
running. Everything typed is kept, so the form comes back filled in and one
field away from correct, instead of the node insisting it has a tunnel that was
never started.

## Domains you had already added were frozen

"Use in configurations" and "How to use this address" could be chosen when a
domain was added and never again: the list showed both as plain text. Changing
either meant removing the domain and adding it back, which discards a working
certificate and takes the name out of every customer's configurations until a
new one is issued.

Both are dropdowns on the domain's own row now. Neither touches the certificate,
so the name keeps serving while you change it.

## New from plan created a customer the plan did not describe

It filled in the data cap, the upload and download caps, the expiry, the device
limits and the reset schedule, and stopped there. The five fields that decide
what a customer can actually reach kept the form's defaults: every inbound
ticked, and the country exits, mieru, AmneziaWG and the Telegram proxy all off.

So a plan restricted to a single inbound produced a customer who could use all of
them, and a plan whose purpose is selling the tunnel produced a customer without
it. The form starts as the plan now, for every field it can express, and
everything is still editable before saving.

A plan naming inbounds that no longer exist falls back to no restriction rather
than to a customer served by nothing, and a plan naming every inbound that
exists today stores that list, which is what applying the same plan to an
existing customer already did.

## The Telegram proxy travels with the subscription

No subscription format can carry a `tg://` link, so a customer's own page was the
only place theirs could be delivered: they had to find that page and copy a link
out of it by hand. The Nova app's document now carries it under a namespaced key
of its own, so the app can offer it directly. Until the app does, nothing
changes for anyone.

It rides the customer's own subscription only. The secret is derived for them,
so it has no meaning in the whole-panel link and does not appear there.

## Upgrading

Update and restart. No customer that already exists is changed. Two things worth
checking afterwards: customers created from a restricted plan before this
release were created with access to everything, and if an XHTTP server has been
sitting on "Verifying" in the Nova app, it should connect once the subscription
refreshes.
