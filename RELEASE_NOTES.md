# Nova Server 1.71.2

A QR code beside each recommended app on the customer's subscription page.

## What it is for

Tapping an app's row on that page hands the subscription straight to the app.
That is the right thing for the customer reading the page on their phone, and it
is nothing at all for the customer reading it on a computer with their phone in
their hand. That customer's only option was the big QR at the top of the page,
which encodes the plain subscription URL: scanning it into the Nova app gives
that app the raw link list rather than the sing-box document built for it, and
the same is true for Hiddify and Karing.

So each of those three rows now has a QR button beside it, and the code behind it
encodes that app's own subscription. Requested by an operator for the Nova app;
the other two are there because the condition is the reason rather than a
shortlist. A client with its own document has a URL the page shows nowhere else,
and a client without one uses the URL the top of the page already shows a QR for,
where a second identical code would be a duplicate.

Each one stays folded away until it is asked for. This page has been careful for
several releases about not becoming a wall of QR codes, and three more codes on
by default is exactly that.

## Details

The button sits at the trailing edge of the row, so it is on the left in Farsi
without a second rule. It states its own pressed state and what it will do next,
because it has to sit beside the row rather than above the panel it opens, which
is what `details` and `summary` would have given for free. The recommended tier
now wraps to two rows and then one as the card narrows, since three app rows plus
their buttons no longer fit across; the alternative was squeezing "Hiddify" down
to "Hidd..." to make room for an icon.

## Upgrading

Update and restart. Nothing else changes, and nothing a customer already holds is
affected.
