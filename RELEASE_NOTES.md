# Nova Server v1.41.3

## Country exits were doubled for users who have only the exits

If you moved your fronts onto their own domain and then gave someone the
per-country exits **without** giving them the front itself, they received two
configurations for every country: one on your panel domain and one on the front
domain. A user who also held the front received one, correctly, on the front
domain.

The exits are the front reached by a different path, and Nova works out which
front domain to use from the front that serves that user. Someone sold only the
exits is on no front, so there was nothing to read the domain from and it fell
back to the panel domain, then published that copy on the other domain as well.

They now follow the front domain like everyone else, and get one configuration
per country. Nothing changes for a user who already had the front, and nothing
changes at all if you have not put your fronts on their own domain.

Where two fronts sit on different domains, a user who belongs to neither is
still left on the panel domain rather than guessed onto one of them. Publishing
someone on another customer's domain is worse than an extra entry in the list.

## Three more, found while checking the one above

**A restricted front's domain could reach a user who was denied it.** Where one
front belongs to a single customer, the fix above could borrow that customer's
private domain for another user's country exits, as the address and as the
server name. Only a front published to everyone is borrowed now. If you share
one front through an explicit user list rather than "all users", exits-only
customers keep the extra entry rather than being put on a domain that is not
theirs.

**A user denied every protocol still received a working front in Clash and
sing-box.** Only on panels that predate the front records, and only with the
per-carrier variants switched on: those variants were emitted without checking
the user's protocol list, so someone sold a restricted plan could open the same
subscription in Clash and connect. The plain list denied them correctly, which
is what made it hard to see. Both now agree.

**An IPv6 public address produced an unusable link.** An inbound or front given
a bare IPv6 address emitted a link no client could parse, because the address
was not bracketed and its colons ran into the port. Affects only operators
publishing on a literal IPv6 address.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release.
