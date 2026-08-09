# Nova Server v1.47.0

## Clean Cloudflare IPs are now used, instead of being collected and thrown away

If your domain sits behind Cloudflare's orange cloud, your customers never
connect to your server. They connect to whichever Cloudflare edge address your
domain currently resolves to, and Cloudflare passes the traffic on. Filtering in
Iran works on those edge addresses, so a customer's configuration can stop
working while your server, your domain and your certificate are all completely
fine.

The standard answer is to dial a different Cloudflare address while still
presenting your own domain, and Nova can do that for you now. Turn on
**Publish clean IPs in configs** on the Clean IPs page, and every one of your
Cloudflare-fronted configurations gains a second copy that connects to a clean
Cloudflare address while the SNI and the WebSocket Host stay your own domain. The
certificate still validates, because the name in the handshake never moved.

**Nothing is replaced.** The original entry stays exactly where it was, so your
customer's app simply has two ways in and uses whichever answers. A clean address
that goes stale costs one dead entry among several, not a customer's whole
subscription.

Four things about it are worth knowing:

- **It only applies where a CDN can carry the traffic.** Reality, Hysteria2,
  TUIC, NaiveProxy, mieru, the Telegram proxy and AmneziaWG are untouched. None
  of them can pass through Cloudflare, so giving one of them a Cloudflare address
  would hand out a configuration that cannot connect.
- **Only when Nova knows a Cloudflare-proxied name is in front of your server.**
  That means a primary domain Nova set up through Cloudflare with proxying on, or
  an additional domain marked as proxied. A domain Nova did not set up counts as
  not proxied, because publishing a Cloudflare address in front of a name that
  points straight at your server produces a configuration that reaches Cloudflare
  and stops there.
- **Every address is checked against Cloudflare's own published ranges** before
  it can reach anybody, and that check cannot be widened by anything fetched over
  the network. A list that is wrong, out of date or has been tampered with makes
  the pool smaller. It cannot send your customers somewhere else.
- **No single source can fill the pool on its own**, and a day's refresh never
  takes more than half of what you already have. A network that answers Nova
  dishonestly can only ever be part of the answer, not all of it.
- **Each customer keeps the same address between subscription refreshes**, the
  same way their Reality short ID does, so their configuration does not change
  under them.

The daily **Auto clean-IP refresh** switch on the Settings page fills the list.
It now collects from the published sources and stores only addresses it has
proved are Cloudflare's. If it cannot reach a source, or nothing in what it
receives passes the check, it leaves your existing list exactly as it was and
says so in the activity log rather than emptying a working pool.

**A correction worth stating plainly: that switch has never actually collected
anything, on any node.** It fetched a URL that is a directory rather than a file,
so GitHub answered 404 every time and the automation stopped there without a
word. Anything in your Clean IPs list today is something you typed yourself. That
is fixed.

**Nothing changes unless you turn it on.** Both of our own servers produce
byte-identical subscriptions on this release, in all six formats.

## Fragment and multiplexing inside your customers' configurations

An operator reported that the anti-censorship card "does not apply to configs".
It is not broken, and nothing about it was fixed: that card is a **server-side**
setting and its own description says so. It splits the handshake of connections
**this server** makes outward, to the sites your customers visit. It has never
been part of what customers receive.

What they were asking for is a different thing, and it is now a card of its own,
directly underneath: a fragment and a multiplexing setting written into the
configurations you hand out, so the customer's own app applies them when it dials
your node. That is the direction censorship happens in.

You set the piece size, the pause between pieces, which packets to split, the
multiplexing protocol and how many connections share a tunnel. What actually
carries it is not the same for every client, and the card says so rather than
leaving you to find out:

- **Xray JSON** gets both.
- **Karing** gets the fragment, in its own fork's field, plus multiplexing.
- **Hiddify and plain sing-box** get multiplexing only. The fragment option does
  exist in newer builds of each, but both refuse an entire subscription over one
  field they do not recognise, and there is no way to know which build a customer
  is running. Giving fragmentation to some customers by taking every
  configuration away from others is not a trade worth making.
- **Multiplexing itself** is added only to VLESS, VMess, Trojan and Shadowsocks.
  Hysteria2, TUIC and NaiveProxy have no such option at all, and adding one to
  them would have the same effect as the fragment: the client refuses the whole
  document. Those three are left exactly as they were.
- **Clash and plain share links** carry neither. No such option exists for them,
  and Nova will not invent a parameter that a client ignores or refuses.

Both switches are off by default.

## Three smaller things operators asked for

**The AmneziaWG `.conf` no longer arrives as `.conf.txt` on Android.** Chrome for
Android renames a download the panel labelled as plain text, and the Amnezia app
then refuses the file. Every configuration download in both the panel and the
customer's own subscription page now keeps the name it was given. If a customer
had a file that would not import, ask them to download it again.

**A button that opens a customer's subscription page.** On each row in Users,
beside the copy-link control, it opens that customer's own page in a new tab,
exactly as they see it: their usage, their expiry, every configuration they hold,
and their AmneziaWG or mieru file. It is the quickest way to see what somebody is
actually receiving before answering a support message. It follows the same rule
about whose customers you may see, so a reseller opens their own customers' pages
and nobody else's.

**CPU and memory on the dashboard are live.** They refresh every five seconds
while the dashboard is on screen, so you can watch a load spike as it happens
instead of reloading. They stop when you go to another page and pause when the
browser tab is in the background, so a panel left open does not keep asking your
node for numbers nobody is reading.

## Upgrading

Nothing to do beyond updating, and nothing changes for any existing customer.
Both new features are off until you switch them on, and both of our own servers
produce byte-for-byte identical subscriptions on this release in the raw, Clash,
sing-box, Hiddify, Karing and Xray JSON formats.
