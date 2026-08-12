# Nova Server 1.57.1

## Panels showed notices that should have been hidden

Several notices, hints and controls appeared on every node regardless of state,
because the rule that hides them was outranked by the styling that lays them
out. Six places were affected:

- **mieru and the Telegram proxy** showed "the server is not on this node yet"
  even when the service was installed and running, under a green Running light.
  Reported by an operator, and the reason this release exists.
- **The bulk actions bar** on the Users page stayed on screen with no users
  selected.
- **The Reality hint** on the Censorship resistance card showed on nodes that
  already have a domain, which is the opposite of the advice it exists to give.
- **The routing granularity note** showed when it did not apply.
- **The Cloudflare proxy toggle** in the add-a-domain dialog showed for domains
  where it does not apply.
- **The built-in manual's contents list** did not filter when you searched it,
  so every entry stayed on screen while the sections below were filtered.

None of this affected traffic, users or configuration. The wrong state was on
screen only. Nodes serving mieru or the Telegram proxy are the ones most likely
to have noticed, since the message contradicted the status light directly above
it.

## Upgrading

No action required.
