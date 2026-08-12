# Nova Server 1.58.0

Resellers, rebuilt around what operators actually asked for.

## Volume resellers can sell

A volume reseller could not create a single customer. The panel sent it to the
plan form, which posts a plan id and no data cap, so the server read that as "no
limit" and refused. It now gets the full customer editor, bounded by its
allowance and by what the owner granted it.

The editor shows only what that reseller can actually hand out. AmneziaWG, mieru
and the Telegram proxy appear when the owner has granted them, the inbound list
is the reseller's own allowlist, and the country exits appear only if granted.

## The allowance is a soft cap

A reseller may now sell past its allowance rather than being stopped part-way
through serving a customer who has already paid. It sees how far over it is and
is asked to buy more; the customers keep working.

Two things stay hard. The customer count, which limits records rather than
volume. And selling a customer with no data cap at all, because that is not a
large number, it is an unbounded one.

## Setting a reseller up takes one step

Mode, allowance, customer cap, inbound allowlist, protocol grants and the
starting figure are all on the create form. Previously every reseller was born
in plan mode with nothing to sell against and had to be reopened and edited.

Topping up a volume reseller now adds volume and customer headroom rather than
moving a credit balance it does not use. Buying more volume is also where you
set how long that reseller's customers last, which defaults to 90 days and is a
ceiling they cannot exceed.

The allowance chip shows what has been sold of the total, which is the direction
you think in when deciding whether to sell more.

## Your customer list is yours

Customers created by resellers no longer appear in the owner's Users list. Each
reseller row has a Customers action that opens that seller's book, with usage,
expiry and the same editing you always had.

## Volume resellers keep their own plans

They compose each customer by hand, so they can now save their own shapes. Those
plans are private to them: they never appear in the owner's plan manager or
another reseller's, cannot be priced, and cannot be marked sellable.

## Country exits are sellable

Psiphon and Tor country exits can be granted per reseller, so an operator can
sell access that never routes a customer's real address to a domestic service.

## A level 1 admin

A second person with the owner's powers, for someone you trust to run the node
with you. It reaches everything you reach, including settings and this node
itself. The existing manager role is now called level 2.

Two limits, and they are deliberate. **Only you can appoint, promote or remove a
level 1 admin**, so an appointment can always be undone by the person who made
it. And **it takes your password**, not just your open session.

This is not a small appointment. A level 1 admin can reset the node. The panel
says so before it asks for your password.

Removing them removes what they left behind: the tokens, nodes, invitations and
webhooks they created all go with the appointment. It does not review what they
changed on rows you created. Appoint people you would trust with the server's
root password, and after withdrawing an appointment, read your Webhooks and
Nodes pages and confirm every address on them is still yours.

Two things they cannot do, because both would take the node away from you rather
than help you run it. They cannot change what this panel answers on, which means
its address, its port, its stealth path and its domain: any of those, set by
someone else, locks you out of your own panel with no way back except a shell on
the server. And they cannot issue an API token with your powers, because that
credential outranks anything the panel would let them do directly and nothing
about it says who created it. The tokens page now shows who made each one.

## Fixes

- A customer created by a reseller kept the name they typed. It was being
  replaced by a random id, and only came back if you edited them afterwards.
- Granting a reseller AmneziaWG showed them a server card that failed to load,
  because that card is owner-only. Granted protocols now work through the
  customer editor, where they belong.
- Three capabilities offered for resellers did nothing at all: managing
  sub-admins, API tokens, and editing inbounds. Each opened a page that refused.
  They are no longer offered, and existing resellers stop seeing them.
- The Inbounds page no longer offers a reseller an Add button, row actions, or a
  traffic chart it is not allowed to read.

## Upgrading

No action required. Existing resellers keep their mode, balance, plans and
customers. A reseller with no mode set is a plan reseller, exactly as before.

One thing changes by itself. If a sub-admin ever created an API token carrying
your powers, this release scopes it down to their own customers on first start.
Tokens you created yourself are untouched. If that token was feeding an
integration, reissue it from your own account.
