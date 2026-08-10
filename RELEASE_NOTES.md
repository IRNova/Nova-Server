# Nova Server v1.54.0
## Any port you like, a one-tap import that works, and a long list of things that were quietly telling you the wrong thing

This release has one new control and a lot of corrections. Most of the
corrections are cases where the panel said something confident and wrong, which
is worse than saying nothing: a health page you learn to ignore is a health page
that cannot warn you when it matters.

Both live servers produce byte-identical health findings and byte-identical
subscription output before and after this update, checked against their real
settings documents.

### Put a CDN transport on any port

XHTTP and HTTPUpgrade used to offer a fixed list of ports, because Cloudflare
forwards only a set of HTTPS ports and anything else produces a listener the
edge never reaches. Operators kept asking for the rest, and they were right to:
**the server never restricted the port at all.** The list was a recommendation
living in a dropdown.

The dropdown now ends in **Custom port**, which opens a box for anything from 1
to 65535. Use it where traffic reaches your server directly rather than through
Cloudflare: a grey-cloud domain, a bare address, or another CDN. A port another
Nova service already holds is refused when you save, and the box tells you as
you type it.

An inbound already sitting on a port outside the list now opens on **Custom
port** with its number filled in, so opening the editor never moves it.

### One-tap import into v2rayNG

The import button on a customer's page answered **"1 skipped"** while copying
the same link and pasting it worked. The page was handing v2rayNG its
*config-import* entry point with a *subscription* URL in it, so the app parsed
one item, matched no config scheme, and skipped it. That counter was v2rayNG's
own, which is why the symptom was so specific.

All three places that build that link now use the subscription entry point, and
the imported subscription arrives with your brand name on it instead of blank.

### AmneziaWG on a node that does not have it installed

If you switched AmneziaWG on for a node and the health page told you the node
needed a kernel module "which a container install does not have", and your node
was not a container, that message was wrong.

"Cannot run it" has two causes and the node has always reported which. A
container genuinely cannot, and now says so on its own. Far more often the
AmneziaWG packages simply are not installed: **the node installer adds them on a
best-effort basis and carries on when it cannot**, which happens on Debian (the
packages come from an Ubuntu repository) and on any server with no kernel
headers for the kernel it is running. That case now says so, gives you the exact
command, and puts a **Push configuration to this node now** button on the row so
you can clear it the moment you have run it.

### Health findings that were telling you the wrong thing

- **Your server address in customer configurations** was invisible in the
  commonest setup there is. The check looked for a proxied *additional domain*
  and never for a proxied *primary*, which is the only state Nova's own domain
  setup produces. So the operator most likely to be leaking their origin was the
  one least likely to be told. Worse, it punished following this page's own
  advice: it tells you to add a grey-cloud domain, that domain is published to
  every customer, and nothing here noticed.
- **An IPv6 address is not a domain.** The panel-visibility check treated
  `2a01:4f8:...` as a domain name because it contains letters, accused the
  operator, offered a fix, and cleared the red row while a scan of the bare
  address still got the sign-in page. The decoy site had the same bug, in the
  same direction: it hid the panel from your real names and kept serving it to
  scanners. Both now share one rule, and a node whose primary is an address but
  which has additional domains is handled properly in both.
- **"Move the inbound to the main server"** was the advice given, in resilience
  mode, about an inbound that was already on the main server, with no button to
  press. Resilience mode copies every standalone inbound to every node, so the
  main copy works and only the node copies drop traffic. It now says that, and
  offers **Send this inbound out directly**, which is the one remedy that always
  works.
- **The AmneziaWG address ceiling** produced one identical red row per node for a
  single fleet-wide number, and advised moving customers to another node, which
  cannot help when every node carries every granted customer. One row now, and
  it names the only lever that exists.
- **Empty sing-box, Hiddify, Karing and Clash documents went unreported** for
  customers holding only mieru, or only NaiveProxy on a self-signed node. The
  check carried its own copy of the renderers' rule and the copy had gone stale.
  It asks the renderers now.
- **The Reality button** was offered on WebSocket, gRPC and XHTTP inbounds, where
  the conversion refuses, so the button existed to explain why it did not apply.
  It is no longer offered there and the text tells you to change the transport
  first.

### Fixes you will not see, which is the point

- **A node could be locked out of its own settings.** Granting one customer
  AmneziaWG without placing an inbound on that node made every settings save and
  every backup restore on that node fail, with an error mentioning nothing about
  AmneziaWG. Its host, protocols, domain and wsPath became unchangeable.
- **A customer with no id could have their full credentials pushed to a rented
  node**, bypassing the redaction that exists to stop exactly that.
- **A node that already had its own AmneziaWG could be silently re-keyed on
  enrolment**, dropping every client it already served. The guard read Nova's own
  records and never the machine; it now asks the machine.
- **The AmneziaWG server key file** is written atomically and its permissions are
  enforced rather than requested. On a node where that file predated Nova, the
  private key could sit world-readable.
- **A one-shot "replace this node's AmneziaWG" press behaved as a standing
  permission**, surviving indefinitely and invisibly until it destroyed that
  node's own customers' files much later.
- The mieru, MTProto and AmneziaWG address pickers offered names Nova knew were
  behind a CDN, producing links that connect to nothing.
- Three Persian strings rendered with their numbers and units reversed.

### For operators upgrading

Nothing to do. No setting changes meaning, no configuration is rewritten, and no
customer's link changes. If you have never switched AmneziaWG on for a node,
most of the above was never reachable for you.

**Still owed and stated plainly:** the v2rayNG deep link was verified against the
app's published source, not driven on a physical Android handset. The Streisand
and NekoBox links were not driven either and are deliberately unchanged.
