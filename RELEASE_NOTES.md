# Nova Server v1.45.0

## Important if you sell by device count: the device limit could be bypassed

The strongest reason to update. A customer sending a crafted device identifier
with their subscription request was treated as an already-known device, so they
were let through without the limit being checked, and the device was never
recorded. One such customer could connect from any number of devices,
indefinitely, whatever their device limit said.

This needs no panel access and no account beyond a normal subscription link, and
it leaves no trace: the extra devices never appear in the panel's device list,
so there is nothing to notice. Any node still on an older version has it.

There is nothing for you to do beyond updating, and no customer needs a new
link. If you sell by device count, it is worth checking your busiest accounts
afterwards, because the limit will now actually apply to them.

## A customer with an unusual account id could have had no data limit at all

Found while building the above, and older than it. A handful of reserved words,
`__proto__` most of all, are treated specially when used as an account id, and a
customer whose id was one of them accrued no traffic that anyone could see and
never reached their data limit, on any protocol, with nothing in the panel to
say so. Account ids can be set through the API and by resellers, so this was not
purely hypothetical.

The same ids also escaped the device (IP) limit, which now applies to them
normally. Their traffic is counted normally too. If you have such a customer, their
counter starts from whatever it currently reads, not from what they have
actually used, so reset them if you want the limit to bite from zero.
## Every customer now gets their own Telegram proxy link

This is the change you asked for, and it replaces the program behind the proxy
rather than adjusting it. The old one had a single secret for everybody and
counted nothing, so a per-customer proxy was not possible with it at all.

- Turn the Telegram proxy on for a customer on their own page, exactly as you
  grant mieru. Their link appears on their own subscription page.
- Their Telegram traffic counts against their data limit, and their expiry
  applies to it. Blocking or expiring a customer cuts their Telegram access
  immediately, including connections already open.
- A shared link for everybody still exists, but it is a **new** link: the one you
  handed out before this release is not it. Its traffic is counted against
  nobody, because any number of people may be holding it, so hand it out only if
  you mean to.

**Read this before updating.** Telegram links you handed out before this release
stop working, and there is no way around that: the change is what makes
per-customer links possible. Send customers their new link from their
subscription page after updating.

One thing to know for later: the domain the proxy pretends to be is stored
inside every secret, so changing that domain re-mints every customer's link at
once. That was already true of the single shared link; it is louder now.

## AmneziaWG traffic now counts against the customer's data limit

1.44.0 made AmneziaWG something you can sell to one customer and not another.
This release makes it something you can sell with a data limit, which is what an
operator asked for straight afterwards.

Until now AmneziaWG was the one thing this node serves that nobody was charged
for. It is a kernel tunnel rather than an Xray inbound, so none of the panel's
traffic accounting could see a byte of it: a customer sold nothing but the
tunnel had, in practice, no limit at all, and a customer who also had an ordinary
inbound only reached their cap on that other traffic.

AmneziaWG bytes are now read straight off the interface every half minute and
added to the same total as everything else, so the data limit, the usage shown
in the panel, the figure the customer's own app displays, the backup and the
usage a parent panel pulls from a node all include the tunnel with nothing for
you to switch on.

Four things worth knowing:

- **Counting starts when you update.** Traffic your node carried before this
  release is not charged retrospectively. Those counters run for the life of the
  interface, so importing them would push customers past a limit for gigabytes
  that were never billed, with no way for you to reconcile it.
- **Restarting the tunnel costs at most half a minute of accounting.** Saving
  the AmneziaWG card restarts the interface and zeroes its counters. The panel
  treats that as a restart rather than as a negative number, and resumes.
- **Expiry and the data limit already withdrew the tunnel** and still do, keeping
  the customer's keys, so renewing restores the configuration they already hold.
  What is new is that the tunnel's own traffic can now be what trips the limit.
- **mieru is still not counted**, and cannot be: its server reports traffic for
  the whole node and never per person. The health check already says so.

## mieru traffic now counts against the data limit

You were right that this was possible, and our own documentation was wrong. It
said the mieru server reports traffic only for the whole node. It does not: it
reports per customer, under exactly the name Nova already gives each one. The
check behind the old claim was run on a server that had never carried any mieru
traffic, where those counters do not exist yet, and their absence was read as
the feature being missing.

So a customer sold nothing but mieru now reaches their data limit like anybody
else, and the health warning that said their cap could not hold is gone. As with
AmneziaWG, counting starts when you update; traffic carried before that is not
charged retrospectively.

## A Tor country exit could look perfectly healthy and carry nothing

Tor has no exit servers at all in some countries, and the panel offered them
anyway. If you picked Ireland, Slovenia or Slovakia, everything looked right:
the service showed as running, the card was green, and customers you gave it to
received a configuration. It could never carry a single byte, because the exit
is set to use that country only and there is nothing there to use.

The health check now says so plainly, and it no longer treats a dead exit as
though it were access, which was hiding the problem: a customer whose only
access was such an exit was being reported as perfectly fine.

Countries where Tor has only one to three exit servers, Turkey among them, now
get a warning rather than a failure. They do work, but they are slow and drop
often, so they are a poor thing to sell. The Netherlands, Germany and the United
States have hundreds each and are the safe choices.

The Test button on those exits was also too impatient: fifteen seconds is not
long enough to build a route through a country with three servers, so it
reported working exits as broken. It now waits longer, and it checks that what
answered really is Tor.

## Four things you reported about 1.44.0

**AmneziaWG could not actually be sold, and this is the big one.** If you turned
AmneziaWG on from the card on the Inbounds page, which is the normal way, then
ticking AmneziaWG for a customer did nothing at all: no tunnel was created for
them, and their subscription page showed nothing. It only worked on a node that
had the per-user WireGuard protocol switched on, which is a different control.
The per-customer switch is now what decides, everywhere: their own page, the
Connect box, on restart, and the moment you turn the card on. Customers you
already ticked get their tunnel on the next update with no action from you.

**The Hiddify and Karing links are now on the customer's own page**, and they go
to every customer. Before, they lived only in your panel, and only for a
customer who had mieru. That was backwards: a customer whose access is
NaiveProxy needs them most, because the ordinary subscription is a plain list of
links and a raw NaiveProxy link is read by v2rayN and almost nothing else, while
both of those apps read the full document where NaiveProxy works properly.

**The NaiveProxy link was incomplete.** It now carries the same parameters
v2rayN writes when it exports that link itself. One deliberate difference from
the example you sent: whether the client is told to accept the certificate
follows your node. Yours has a real certificate so you will see `0`, exactly as
in your example, but a self-signed node needs `1` and hardcoding `0` would have
handed those customers a link that cannot connect.

**One tap import was a wall of identical tiles.** Hiddify and Karing now sit at
the top as two large recommended cards, and every other app is a small chip.
When the Nova client is ready it takes that slot.

## A stale tunnel could have been charged to the wrong person

Found by replaying this panel's own settings through the new accounting rather
than by a test. A node that has AmneziaWG switched off never reconciles its
tunnel list, so peers belonging to customers deleted long ago can sit there
indefinitely. Their traffic is now charged to nobody. Without that, a customer
created later under a reused name would have inherited a deleted customer's
usage and could have been cut off by a limit they had never used.

## Two corrections to the manual

Both found while writing the above, and both were wrong in all three languages.

- The manual said that turning a customer's AmneziaWG access off and on again
  deletes their peer and invalidates the `.conf` they hold. That stopped being
  true in 1.44.0: withdrawing access stops the traffic and keeps the keys, and
  granting it back restores the very file they already have. What does
  destroy their keys is deleting the customer, and so does granting AmneziaWG to
  a new customer on a node whose 253 addresses are all taken, which reclaims the
  oldest withdrawn customer's address and their keys with it. Choosing a
  different obfuscation strength keeps every key but rewrites the junk
  parameters carried in every configuration, so those files stop working and
  have to be sent out again.
- The manual said AmneziaWG traffic is not counted. It now is.


---

**Updating:** Settings, then Check for updates. No inbound, user account,
password or client configuration is changed by this release, and no customer
needs a new link.
