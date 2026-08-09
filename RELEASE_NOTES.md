# Nova Server v1.49.0

## Change a whole group of customers' data, or one protocol, with a preview first

Two things operators kept asking for and could not do. Applying a plan in bulk
has always been possible, but a plan rewrites everything about a customer, so
there was no way to say "give these forty people ten more gigabytes" or "take
mieru away from these twelve" without either editing them one at a time or
resetting things you did not mean to touch.

Select any customers on the Users page and the toolbar now has two more buttons.

**Change data** moves the total allowance up or down by a number of gigabytes
and touches nothing else: not the upload or download caps, not what has already
been used, and not the expiry date.

**Protocol access** gives or takes away exactly one thing across the selection:
the country exits, mieru, AmneziaWG, the Telegram proxy, or a single inbound.

**Both open with a Preview, and nothing is written until you press Apply.**
Press Preview and the server works out what would happen and tells you: how many
customers change, how many are left alone and why, and a few examples with the
before and after. A bulk change to paying customers has no undo and the wrong
click is expensive, so the summary is not the panel's guess. It comes from the
same code that will do the work, running the same pass over the same customers.
Editing the form throws the preview away, so you can never read a summary of one
change and then apply a different one.

**Two rules in Change data are worth knowing before you press it:**

- **A customer with no data limit is left alone, in both directions.** Adding to
  an unlimited allowance means nothing, and subtracting from one would have to
  invent a cap you never typed.
- **An allowance never drops below 1 GB, and a reduction never raises one.** In
  Nova a limit of 0 GB means unlimited, so arithmetic that landed on zero would
  remove somebody's cap instead of tightening it, which is the opposite of the
  button you pressed. A customer already at or below 1 GB is therefore left
  exactly as they are, and every customer that stops at that floor is counted
  separately in the preview so you can deal with those individually.

**And two in Protocol access.** Taking an inbound away from a customer who has
no inbound list of their own writes one down for them, matching exactly what
they receive today. Nothing they have changes, but from then on a new inbound no
longer reaches them on its own. The preview counts those separately so it is
never a surprise.

The second is not new to this button but is worth knowing before you use it on a
group: the shared front protocols (the VLESS, VMess and Trojan on port 443, and
Hysteria2) are withdrawn from what a customer RECEIVES, so the configuration
leaves their subscription and their client stops offering it, while the listener
still accepts a config they had already saved. Every other inbound is withdrawn
at the listener too and stops working at once. When you need the connection
itself to stop, disable the customer.

**Resellers can take access away and never add it.** Both buttons work on a
reseller's own customers for a withdrawal, exactly as a bulk disable already
does. Adding data or granting a protocol is provisioning, and a reseller
provisions by applying a plan, which is what charges their balance. Trying it
returns a plain refusal rather than doing it quietly.

## The health check no longer accuses an inbound that runs on a node

An operator added a node, created a NaiveProxy inbound and an XHTTP inbound on
it using a domain that belongs to that node, and the health page reported that
this panel had no certificate for it. It was right that this panel does not have
one. The node does, and this panel cannot see it.

The certificate checks ask "does this machine hold a certificate for the name
this inbound presents", so they only apply where a customer is actually handed
this machine's address for that inbound. That is now what they check, using the
same function the subscription builders use to decide where an inbound is
published, rather than a second copy of the rule. In practice it changes one
case: with resilience mode on, an inbound pinned to a node **and** published on
its own address is served only from that node, and this panel no longer reports
a missing certificate for a name it never answers for. Everything that was
genuinely broken is still reported, including an inbound on this server, a front
published on a name with no certificate, and every inbound on a managed node,
which really does serve all of them.

Where this panel cannot know, it now says nothing rather than guessing. That is
deliberate: a false alarm on the health page teaches people to ignore the real
one.

## A domain that points at a node gets its certificate from that node

The same operator then could not obtain a certificate for the node's domain from
this panel, and that is correct behaviour rather than a bug: the check is
answered by the machine the name points at, so a name pointing at a node can
only be certified by that node. Nothing said so, and the failure looks like an
ordinary DNS or port 80 error.

It says so now, where the failure happens. When you have nodes and a certificate
request fails that way, the panel adds what to do instead:

- **Before you install a node**, put the domain in the node domain field on the
  one-command form. Point the name at the new server first, and the node obtains
  and renews a Let's Encrypt certificate for it as it joins.
- **For a node already in your fleet**, press **Certificate** on its row, then
  **Add a domain** to serve a second name alongside the one it has, or **Change
  primary** to move the node onto a new one. Changing the primary stops every
  link already issued on the old name.

The manual has this under Nodes, and the panel search finds it, in English,
Persian and Russian.

## Upgrading

Nothing changes on its own. The two new bulk operations are buttons you have to
press, and the health-check change only ever removes a report this panel could
not stand behind. No customer's configuration, subscription or allowance is
altered by taking this release.
