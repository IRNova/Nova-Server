# Nova Server v1.44.0

## NaiveProxy was broken on every self-signed node, in every client

An operator reported that the subscription was wrong for Karing. It turned out
to be worse and older than that.

A NaiveProxy entry carried `insecure` so that a node with a self-signed
certificate could still be used. That option is not ignored by sing-box, it is
**refused**: the outbound errors with "insecure is not supported on naive
outbound". That is upstream sing-box behaviour, not a Karing quirk, so on a
self-signed node every NaiveProxy entry Nova has produced since 1.41.5 was dead
in every client that reads the sing-box format, and in some clients it took the
whole configuration down with it.

Self-signed trust is now carried the only way that outbound supports, by
including the node's own certificate in the entry. If a node has no certificate
to offer, it now emits no NaiveProxy entry at all, because an entry that cannot
connect still sits in the client's selector and slows down its tests.

If your node uses a real domain certificate, nothing changes for you. If it is
self-signed and you use NaiveProxy, your users get a working entry on their next
refresh.

## mieru now works in Karing

Karing and Hiddify do not name mieru's settings the same way, so one document
cannot serve both. mieru for Karing is its own subscription format:

    https://your-panel/sub?u=<user>&target=karing

The Hiddify link is unchanged. As before, mieru never appears in the ordinary
subscription, because a client that does not understand it refuses the entire
configuration, which would leave that customer with nothing at all.

**Both links are also now reachable in the panel.** The Hiddify link had been
unreachable since 1.42.0: it lived on a page nothing opened. Both now appear in
the Connect box on the user's card.

## AmneziaWG is now something you can sell per customer

Before this, turning WireGuard on created a tunnel for **every** user on the
node, so you could not give it to some customers and not others, and every
customer's subscription page showed a tunnel they had not bought.

AmneziaWG is now a per-user switch, exactly like mieru:

- Turn it on for a customer in their settings, or include it in a plan.
- Their subscription page carries the QR code, the configuration, and a `.conf`
  download.
- Expiry and data limits now withdraw the tunnel. Previously an expired customer
  kept a working tunnel indefinitely while the panel showed them as expired.
- Withdrawing access never deletes their keys, so renewing restores the exact
  configuration they already hold. Their existing app keeps working.

The AmneziaWG settings have also moved to the Inbounds page, directly after
mieru, which is where people were looking for them.

**Please read this before updating if you already use WireGuard.** On a node
where the WireGuard protocol is already on, every user who already has a tunnel
is given the new per-user grant automatically, once. That is deliberate: it is
what stops the update from destroying tunnels your customers are using. The
visible effect is that those customers' subscription pages now show their
tunnel configuration and QR code, which they did not before. If you do not want
that for a particular customer, turn the switch off for them after updating and
their keys are kept.

One limit worth knowing: a node addresses its tunnels in a single /24, so it
supports up to 253 customers with AmneziaWG at once. Beyond that, further
customers get no tunnel until one is freed.

---

**Updating:** Settings, then Check for updates. No inbound, user account or
password is changed by this release, and no existing client configuration stops
working.
