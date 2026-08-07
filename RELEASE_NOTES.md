# Nova Server v1.42.0

## A Telegram proxy

Telegram is the one app almost everybody in Iran needs, and an MTProto proxy
with a FakeTLS secret is still hard to filter. Nova can now run one.

It is not part of anyone's subscription, and that is deliberate rather than a
limitation: a Telegram proxy has one secret for everybody, no per-user
credential and no per-user accounting, and no subscription format can carry a
`tg://` link. So what it produces is a single link you share. Anyone who opens
it uses your server for Telegram and nothing else.

Turn it on under Inbounds, pick a free port, and pick the site the proxy
pretends to be. That last choice matters more than it looks: the name has to be
reachable both from your server and from Iran, because a censor who sees an SNI
they block will cut the connection whatever is inside it. Nova offers a few that
hold up and accepts any other.

The front domain lives **inside** the secret, so changing it makes a new secret
and the old link stops working. That is not a quirk to work around: keeping the
old secret would hand out a link whose embedded name no longer matches what your
server presents, and every client would fail the handshake while the panel
showed the new domain.

The link never names a Cloudflare-proxied address. MTProto is not HTTP, so the
orange cloud would answer the handshake itself and nothing would reach your
node. If your panel domain is proxied, Nova picks a direct one by itself.

Anyone holding the link can use it, so treat it like a password. There is a
"New secret" button for when it spreads further than you meant.

## mieru, and exactly how far it reaches

mieru is a low-overhead protocol with very little padding, so calls and games
feel better on it than on the heavier ones. Nova can now run its server, and
each user you give it to gets their own credential.

**Only some apps can use it, and we would rather say so than let you find out
from a customer.** Hiddify can, and mieru's own command-line client can. The
ordinary sing-box apps, Clash, v2rayNG and Nova's own app cannot, and there is
no share link for it at all.

So mieru is **never** put in the normal subscription. If it were, every user on
one of those clients would lose their entire configuration, not just mieru: a
core that meets an outbound type it does not know refuses the whole document. A
user you enable it for instead gets a second, Hiddify-specific link and a config
file on their page, and their normal subscription is untouched.

Our advice is to give it to people you know are on Hiddify, and leave everyone
else on what they already have.

Two things worth knowing before you sell it:

- **mieru traffic is not counted.** Its server reports traffic for the whole
  node rather than per user, so a customer whose *only* access is mieru has a
  data cap that cannot be measured and will not stop them. If they also have an
  ordinary inbound, their cap still fills on that traffic and mieru is withdrawn
  along with everything else. The health check tells you when this applies to
  somebody.
- **Expiry works normally**, and so does disabling a user. Both withdraw mieru.

Plans can include mieru, so resellers can sell it.

## Where the two binaries come from

Neither protocol can be served by a core Nova already runs, so each needs its
own program: `mtg` for Telegram, `mita` for mieru.

Both are pinned to an exact version and an exact SHA-256, and both are served
from Nova's own release rather than pulled from upstream's latest. A node runs
these as a service, so whoever controls the bytes controls the node; fetching
whatever is newest would let an upstream account compromise reach every Nova
node with no release of ours in between. The mirrored files are byte-identical
copies of upstream's, so the checksums are upstream's own and anyone can verify
the mirror is unmodified.

If a download is corrupt or the checksum does not match, nothing is installed.
The feature stays unavailable rather than running something unverified.

Neither service runs as root.

Both are off until you turn them on, and installing this release changes nothing
about what your users receive.

## Also in this release

- Both protocols refuse a port something else on your server already uses,
  instead of starting, failing to bind, and restarting for ever while the panel
  shows them as on. The reverse is guarded too: an inbound cannot be placed on
  top of either one.
- The health check watches both ports, and knows that a UDP listener never
  appears in a TCP listing.
- The support bundle scrubs the Telegram secret and mieru's key material.
