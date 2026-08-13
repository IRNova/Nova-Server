# Nova Server 1.58.1

The reseller allowance now stops traffic, not just sales.

## What changed

In 1.58.0 a volume reseller could sell past their allowance and was told to buy
more, which is what operators asked for: nobody should be stopped part-way
through serving a customer who has already paid. But nothing stopped the traffic
either, so a reseller with a 100 GB allowance could sell 130 GB and keep
delivering all of it. The owner was carrying the difference.

Selling past the allowance is still allowed, and still only a warning. The
allowance is now where that debt comes due:

- A reseller with 100 GB can still create 130 GB of customers. Everyone keeps
  working, and the reseller is told they have sold 30 GB more than they bought.
- Once their customers have used 100 GB **between them**, every customer of that
  reseller stops sending and receiving until the owner sells them more volume.
- Buying more volume brings all of them back immediately.

The reseller sees which of the two states they are in, because they are very
different situations: one is a bill, the other is an outage they will get calls
about. The owner sees the same thing on the resellers list, as used-of-bought
with a Suspended badge, since the owner is the only person who can lift it.

Traffic already charged for deleted or reset customers counts toward the stop,
so deleting a customer does not reset the meter.

## Notes

Nothing is written to the customers themselves. The suspension is recalculated
from live usage, which is why a top-up restores service at once, and why a
customer the reseller switched off by hand stays off afterwards.

A reseller with no allowance set is unlimited and never stops. Plan resellers are
unaffected: they hold a credit balance, not a volume allowance.

You are alerted once per reseller when this happens, not once per customer, and
the activity log records both the suspension and the top-up that lifts it.

## Upgrading

No action required. If a reseller has already delivered more than they bought,
their customers stop on the first run after the update, which is the point. Top
them up and everyone resumes.
