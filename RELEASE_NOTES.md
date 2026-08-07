# Nova Server v1.41.5

## NaiveProxy and TUIC now reach the clients that can use them

An operator reported that a NaiveProxy inbound appeared in no client at all: not
Hiddify, not Karing, not Shadowrocket. That was ours.

Those clients read the sing-box format, and Nova dropped NaiveProxy and TUIC from
it, alongside the protocols that genuinely cannot be shared (socks, http,
dokodemo-door). sing-box serves both perfectly well: checked against the same
sing-box binary Nova ships, a complete NaiveProxy outbound is accepted. So two
protocols the inbound editor offers you were reaching nobody, because the only
place they did appear was the plain link list, and `naive+https://` is not
something those clients can import.

Both are now in the sing-box subscription. Neither goes into the Clash one.
mihomo genuinely has no NaiveProxy outbound; it does have a TUIC one, so leaving
TUIC out there is a deliberate choice rather than a limitation. One wrong field
makes mihomo reject the entire document, and we can check a sing-box config
against the real binary but have no mihomo to check against, so Clash users stay
exactly where they were. If you want TUIC in Clash, say so and it can be added
once the shape is verified.

If you have a NaiveProxy or TUIC inbound, your users get it on their next
refresh in any sing-box based client. Nothing else changes.

## Hysteria2 says where it is configured

In the user editor, Hysteria2 appeared in the protocol list while the Inbounds
page showed no row for it, which reads as it being there of its own accord. The
listener is real; it is just switched on in Settings rather than created as an
inbound, so the two screens disagreed about where it lives. It now says
"Hysteria2 (Settings)", so nobody goes hunting for an inbound that does not
exist.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release.
