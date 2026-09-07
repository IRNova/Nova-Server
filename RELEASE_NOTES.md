# Nova Server 1.83.0

Five things operators asked for, in one release. Four of them are in the panel
and one is in what your customers receive.

## Reset one customer's traffic

Editing a customer now has a button that puts their used data back to zero on
the spot. It is for the person who has paid for a fresh month early, or for a
figure you already know is wrong.

If that customer is on a daily, weekly or monthly reset, the cycle starts again
from the moment you press it. Their next automatic reset is a full period away
rather than whatever was left of the old one, which is what an operator means by
"reset their month" and was the part that used to need a second edit.

It touches nothing else: not their allowance, not their expiry date, not whether
they are enabled. The same thing for many customers at once is where it always
was, under Bulk actions.

## Quick connect can show somebody else

The dashboard card that hands out a subscription link and QR always showed the
newest active customer. Press "Choose customer" on it and type a name, email or
id to show anybody.

Nothing is listed until you type. A node with thousands of customers cannot
usefully show them all, and it is the nodes with thousands of customers where
pinning one matters. The search is the one the Users page already uses, so the
same words find the same person and Persian and Arabic spellings normalise the
same way.

Your choice lives in your browser, not on the node. Two people sharing a panel
do not change each other's card. If that customer is later deleted, disabled or
left to expire, the card goes back to the default rather than showing a name
that no longer works.

## A customer's UUID can be edited

Open a customer and type a UUID, or press Generate.

This exists for one situation: rotating an identity you believe has leaked. It
costs the customer every configuration they are currently holding. They cannot
connect until they import the new link, so send it to them at the same time.

Nova refuses a UUID that is malformed, and refuses one that another customer on
this node already has. Two customers sharing an identity are counted as one
person for traffic and for the device limit, which is a problem you would find
weeks later while trying to work out why somebody's usage made no sense.

## The AmneziaWG client lists fold up

Every AmneziaWG client renders a card with its own QR, so a node with a dozen of
them spent more of the dashboard on that one section than on everything else put
together, and reaching anything below meant scrolling past all of it.

Above four clients, that section and the clients list in the Network tab both
arrive collapsed, with the count still on the header. Click the header to open
either one. Below four they behave as they did, because hiding three clients
behind a click costs more than the scrolling it saves.

Adding a client is unchanged and still sits below the list, not inside the fold.

## Two of a customer's configurations no longer share one clean IP

With clean IPs turned on, every configuration a customer held was landing on the
same address out of the pool. That address going bad took out everything that
customer had at once, and it made the pool narrower in practice than it was on
paper.

Each configuration now draws its own address, and refreshing a subscription
reshuffles which. Nothing to turn on, and no change to how you manage the pool.

## Upgrading

Update from the panel, or run the installer again. Nothing in this release
requires a configuration change, and no customer needs a new link because of the
update itself. The one thing that does invalidate a customer's configurations is
editing their UUID, which only happens when you do it deliberately.
