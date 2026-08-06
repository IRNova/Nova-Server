# Nova Server v1.41.2

## A front can now be pointed at the domain you added for fronts

Open a front inbound and its **Public address** list offers your main panel
domain, your other domains, or a custom one. It left out exactly one kind: a
domain whose scope is WebSocket front only, which is the kind you add *for*
fronts.

So an operator who added a domain for their fronts opened the front inbound to
point it there, did not find it in the list, and asked for a new feature to do
what this list is already for. The domain is now offered, labelled with its
scope so the choice is not a guess.

That is the difference between a front published on both your panel domain and
the new one, and a front published only on the new one. If duplicate
configurations were your reason for asking, this is the per-inbound way to stop
them: set the front's public address to that domain. The per-domain **How to use
this address** setting is still there for doing it to every front at once.

Direct inbounds are unchanged and deliberately so. An inbound clients dial
straight at this server is still never offered a fronted domain: a CDN carries
neither QUIC nor Reality, and answering for that name from this server's own
address ties the fronted domain back to this machine for anyone scanning. That
reasoning was always about inbounds dialled here directly. A front is served on
the very shared port the CDN sits in front of, so for a front the fronted name
is the right answer, and it was the only one missing.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release.
