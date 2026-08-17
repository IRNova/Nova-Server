# Nova Server 1.63.0

Everything an operator asked for over three rounds of feedback, and the things
those reports turned out to be hiding.

## Adding a customer no longer restarts the proxy

On a node running more than one protocol, which is the recommended setup, every
single user added or removed restarted the core. That drops every live
connection on the node, so a reseller adding a few customers at peak took
everyone else offline for a moment each time.

The reason was narrow: the in-place update only ever touched one inbound, so
with a second protocol enabled it would have left VMess and Trojan serving a
stale customer list, and a restart was the only correct answer. It now updates
every inbound the customer appears on, and restarts only when a changed inbound
genuinely cannot be updated in place.

Two node types still restart on a user change, and should: WireGuard mints or
drops a peer, and a country exit rewrites its own list, and neither can be
applied without reloading.

## Customers that disappeared, and volumes that were never applied

Saving one customer sent the **whole** customer list, built from what that
browser tab had loaded. So it did not save a customer, it replaced the list with
what the tab believed, and anyone added since the page opened, by a reseller, by
the Telegram bot, or by a second tab, was deleted. Every change to a single
customer now sends only that customer.

Volumes typed in Persian or Arabic digits were silently discarded by the browser,
leaving the field empty, and an empty volume means unlimited. Operators were
selling 100GB and provisioning customers with no ceiling. Those digits are now
converted as you type.

Customers whose names had no Latin letters all received the same internal id, so
one could overwrite another. Names now get a unique id, and the server refuses an
id that belongs to another account's customer.

## Resellers

- Their dashboard shows what they have delivered and what is left, in both
  selling modes.
- A private note on each reseller, on the create and edit forms and in your list.
- Switch a reseller off and on. It ends their sign-in, their open sessions and
  their API tokens, and cancels any unused node invitation. Their customers keep
  working.
- Their customers' subscription links are on your view of their customer list.
- Selling a second plan to a customer who has not finished the first now asks
  whether to add to what is left or replace it. Replacing was the only behaviour,
  and it threw away volume the customer had paid for.
- Enable and disable next to a customer in a reseller's or manager's list simply
  did not work, on every node, and returned an error every time.

## Backups

The full backup already covered everything; there is now a test that says so
section by section, so a new feature cannot quietly fall out of it.

The customer-only file did not do its job. It left out each customer's id, and a
subscription link is derived from that id and the node's subscription token, so
restoring onto a rebuilt node changed every link, which is the one thing the file
exists to avoid. It also dropped which reseller a customer belonged to and every
protocol grant. All of it is carried now, and the import tells you before you
commit whether the restored customers will keep the links they hold.

Resellers have their own export and restore, the same shape as the customer one.

## Nova Client

The node serves a Nova Client configuration at `?target=nova`, and Nova Client is
offered on the customer's page alongside Hiddify and Karing.

## Also in this release

A suspended customer could be given their access back and keep it. A customer
over their cap, past their expiry, or belonging to a reseller who has delivered
their whole allowance is suspended by being left out of what the proxy is given,
while their stored record still reads as enabled. Anything that handed the proxy
the stored list therefore put them straight back, and it stuck. Switching such a
customer off and on did it, a bulk enable did it forty at a time, and the node
did it to itself while healing its own configuration at startup. Every one of
those paths now works from the list the rules produce, and a node already in that
state repairs itself on the first start after this update.

## Upgrading

No action required. If you sell through resellers, the Users page has two new
health notices: customers with no data cap, and customers holding one of the
shared ids described above. Neither is changed for you, because only you know
what was meant to be sold.
