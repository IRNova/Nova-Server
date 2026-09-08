# Nova Server 1.85.0

Your panel domain can now be kept out of client configurations.

## What was missing

The extra domains have always had a **Never in configurations** setting. Your
main domain did not.

So the only way to keep the panel domain out of what customers hold was to mark
an extra domain as "Instead of the panel address". That setting replaces the
main domain only where the extra one can actually carry the configuration, which
is the right rule for a substitution and the wrong one for an absence. Add a
WebSocket-front domain, point your 443 VLESS at it, and the main domain still
appeared beside it in the subscription. That is the reported case, and nobody
was doing anything wrong.

## What changed

The main domain row on the Network page has the same **How to use this address**
control the extra domains have, with two choices:

- **In configurations, as normal.** The default, and what every node does today.
- **Never in configurations.** No configuration names your panel domain.

The reason to want this: a configuration that names your panel is a
configuration that gets your panel blocked along with it.

## The part to read before you switch it on

"Never in configurations" is strict. Anything no other domain can carry is left
out **entirely** rather than quietly falling back to your panel domain.

On a node whose only extra domain is WebSocket-front-only, that means the
Reality and other direct configurations disappear from subscriptions. They do
not silently move back to the panel domain, because that is exactly the
behaviour this setting exists to stop.

Before switching it on, make sure the other addresses you have listed cover the
protocols you actually sell. If they do not, add a domain that can carry them,
or leave this on the default.

## Upgrading

Update from the panel, or run the installer again. The default is unchanged, so
a node where you do not touch this setting behaves exactly as it does now.
