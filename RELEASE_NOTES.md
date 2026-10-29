# Nova Server 1.94.3

Smart DNS now says why a registration failed. On the customer's page, a failed
register or remove used to show one message for every cause, which made a
real failure hard to diagnose (one took five rounds). The page now names the
agent's own reason: Smart DNS switched off, a link that is not valid on this
server, a plan without Smart DNS, the rate limit, an address that cannot be
used (private, IPv6, a VPN exit, or already held by another customer), or a
server error with its HTTP code. When something in front of the server,
such as a CDN, answers instead of Nova, the page says the server did not
answer as expected and shows the code. The register and remove buttons always
come back after an answer, whatever the server sent.

Also in this release:

- While Smart DNS is stopped (it is by design whenever nobody is served), the
  agent checks systemd first and skips the usage query, so the journal no
  longer fills with connection-refused lines. Traffic between the last poll
  and a stop stays uncounted, as before.
- The game copy in the panel, the manual and the customer's page matches
  1.94.2's behaviour: PlayStation, Xbox and Steam names stay direct, and EA is
  relayed in VIP (in list mode only if the owner adds it). Smart DNS still
  does not guarantee a NAT type or multiplayer.

# Nova Server 1.94.2

EA games sign in again with Smart DNS. In 1.94.1 `ea.com` was in
`SDNS_PASSTHROUGH`, so a console on Smart DNS reached EA from its real Iranian
address and EA refused it: Battlefield stopped at launch with "Service
limitations apply", then 0:66003S (the same failure as with no Smart DNS at
all). EA is out of the passthrough list, so its names are relayed again in VIP;
in list mode they are relayed only if the owner adds them. The Sony, Xbox and
Steam names stay direct; in 1.94.1 that took one tested PS5 from a failed
network test to NAT type 2. That is one measurement, not a promise: Smart DNS
does not guarantee a NAT type or multiplayer. Checked on xray 26.3.27 and 26.10.21 in a container:
`accounts.ea.com`, `gateway.ea.com`, `battlefield.com` and `origin.com` get the
relay address; PlayStation, Xbox and Steam names get their real addresses.
Ceiling, named in the code: Activision, Blizzard, Riot and Epic are still
passed through and may refuse Iran the same way; nobody has measured them.
If a game keeps failing after the update, clear its cache once.

Also in this release, from the independent review of 1.94.1 (no High, no
Medium):

- Smart DNS matches names in any letter case. Xray 26.3.27 compares DNS rules
  case-sensitively, so a console asking for `PlayStation.NET`, or a resolver
  that randomizes letter case, got the relay instead of its real address in
  VIP. Every DNS name rule is now a case-insensitive pattern that keeps the
  label boundary and accepts a trailing dot. Checked against real Xray 26.3.27
  and 26.10.21.
- The customer page, the manual and the games category no longer promise that
  games always get their real answer. Sign-in and network-test names on the
  passthrough list (PlayStation, Xbox, Steam and several other publishers) do;
  EA is the exception, relayed in VIP and in list mode only if the owner adds
  it; with VIP a game whose servers use a generic cloud name can still be
  relayed, and Smart DNS does nothing for UDP or
  fixed-address game traffic.
- A test that a custom suffix like `a.com` is never treated as covering
  `ea.com`.

# Nova Server 1.94.1

Smart DNS no longer breaks online games. Reported from a live test: with Smart
DNS as the console's DNS, Battlefield stopped with EA errors 0:85011S and
0:85008S and the PS5 network test said "NAT type: Failed"; with 1.1.1.1 both
worked and the NAT type was 2. The relay carries TCP 443 (by SNI) and 80 (by
Host) and nothing else, so steering a game or console name to it breaks UDP,
the NAT test and play.

`SDNS_PASSTHROUGH` (`src/smart-dns.mjs`) lists the sign-in, play and
network-test suffixes of PlayStation, Xbox, EA, Steam, Epic, Riot, Blizzard,
Nintendo, Activision, Ubisoft and Rockstar. In list mode `smartDnsDomains` drops
any built-in or custom entry equal to or above one of them; a download host
BELOW one (`dl.playstation.net`) can still be relayed. In the VIP view they are
added to the first real-answer server. The `games` category now holds download
hosts only and is labelled "Game downloads". The VIP DNS also sets
`disableFallbackIfMatch`, so a non-existent `.ir`, Nova-own or passthrough name
returns an empty answer instead of falling through to the relay address
(measured before the fix).

Ceiling, named in the code: in VIP a whole passthrough suffix resolves direct,
download hosts under it included, and game backends on generic cloud names are
still relayed. Verified on xray 26.10.21 in a container: both configs pass
`run -test`; PlayStation, EA and Xbox names get real addresses in both modes;
chatgpt.com and docker.com get the relay; non-existent names come back empty.
Not verified: a real console on a live node. Panel card, manual, search and the
customer page say online gaming is not helped, in EN, FA and RU.

# Nova Server 1.94.0

Smart DNS privacy. The owner's Smart DNS card and `/admin/smart-dns` now carry
each customer's name and a count of registered connections, never the
addresses. The owner can clear one customer's whole list (confirmed, logged
with the name and count only); the per-address remove is gone. Customers see
their own registrations on their subscription page and remove each one there,
authenticated by their subscription link, including after their grant has
lapsed. xray and journal text that reaches the panel or logs has registered
addresses scrubbed. This is not encryption: root on the server, and anyone
holding a customer's link, can still see that customer's addresses.

Lapsed customers. An address whose customer is no longer served (expired, over
the cap, grant withdrawn, or Smart DNS switched off) is stamped when the lapse
is first seen and deleted 30 days later. Being served again clears the stamp.
The sweep runs when the agent starts and from the automation loop at most every
6 hours (`SDNS_PRUNE_EVERY_MS`), and also on any Smart DNS sync, so a quiet
node with no traffic and no operator still deletes them. Ceiling: an entry can
outlive its 30 days by up to about 6 hours plus one poll while the agent runs;
a stopped agent sweeps nothing until it starts again, and then sweeps at boot.
A sweep with nothing stored writes nothing, and a sweep that changes nothing
writes nothing, so it does not restart the Smart DNS unit.
While their access is gone the customer's page shows a list-only card: they can
see and remove their addresses but cannot register new ones.

MasterDnsVPN update. Nova now pins upstream build `v2026.10.26.100415-5f83ee9`
by SHA-256 per architecture, and the DNS tunnel card offers an update when the
installed build is older. The update backs up the install directory and the
unit, installs and verifies the pinned build, keeps `encrypt_key.txt` and file
modes, and, if the service was running, restarts it, checks that the running
executable is the new one and that it answers a DNS query on its listen
address. Any failure restores the previous files, unit, version marker and the
previous enabled and running state. A refusal before the backup changes
nothing. The update refuses to replace a build newer than the pin (no downgrade
is offered for one), checks that the new binary is really in place before
trusting the install step, and while it runs the route answers 409 and enable
and stop refuse instead of racing it.

Bind scope. MasterDNS now listens on an IP address this server holds (the same
helper Soar uses). The 5f83ee9 build refuses a domain name there and exits, and
older Nova wrote the panel domain into `UDP_HOST` on domain nodes, which the old
build quietly turned into every address. An empty value, used only when no
address is known, still means every address.

Client config. The MasterDNS client file Nova hands out wrote
`LISTEN = "127.0.0.1:1080"`, a key neither the 7de2476 nor the 5f83ee9 client
reads, so both opened their local SOCKS proxy on their built-in 18000 and an app
pointed at 1080 reached nothing. It now writes `LISTEN_IP = "127.0.0.1"` and
`LISTEN_PORT`, with 1080 as the default and an operator-chosen port carried
through (anything outside 1 to 65535 falls back to the default). CottenDns
keeps its 18000 default. Customers holding an old file should be given a new
one.

Interop, measured in an isolated container harness with the official upstream
binaries rather than on a customer's device: the 7de2476 and 5f83ee9 clients
both connect to the 5f83ee9 server, bind the port the new file names (1080 and
a custom 2080 tried), and carry a 2 MB download through the tunnel byte for
byte. Pausing the server makes the same download fail, so the traffic is going
through the tunnel. Not verified on the phone apps customers use.

Smart DNS next to the DNS tunnel. Measured on a real systemd harness: a
customer registered for Smart DNS who queries this server directly reaches
Smart DNS, not the tunnel; through a recursive resolver such as 1.1.1.1 the
tunnel works. The DNS tunnel card, the manual and search say so in English,
Persian and Russian. Only one tunnel engine (MasterDNS, CottenDns or Soar)
holds port 53 at a time. This is documented, not solved: a per-source DNS
demultiplexer is a separate piece of work.

VIP Smart DNS. A per-customer grant that only the owner can give, on the user
form and in plans. A VIP customer's DNS answers send every foreign site through
this server, not only the sanctioned list. `.ir` names, names that resolve to an
Iranian address, and this server's own names get their real answer, so Iranian
sites still go direct and a registered device's own VPN keeps working. It runs
as a second service (`nova-smartdns-vip`, port 20554) next to Smart DNS.

It does not get past Iran's filtering: a site blocked inside Iran stays
blocked. Apps that use QUIC or a fixed address may not work, IPv6 answers come
back empty, and all of a VIP customer's foreign traffic uses this server's
bandwidth and counts against their quota.

Because VIP relays any name, it depends on a firewall guard: rules on this
server's outgoing traffic that keep the relay away from this machine, private
networks and cloud metadata addresses, in IPv4 and IPv6. If the guard is not in
place for both, VIP customers get ordinary Smart DNS instead, and owner-added
names are left out until it is. Neither Smart DNS service starts on its own at
boot; Nova starts them once the guard is back, and stops them if the guard
disappears. Only the owner can grant or withdraw VIP. A manager editing a
customer leaves it as it was, and a reseller's customers never get it, whatever
their plan says. The Smart DNS card counts VIP customers,
and the health check warns when VIP customers are registered but the VIP
service is not running.

The uninstaller also removes the MasterDNS upgrade backup, any interrupted
staging directory, and the VIP Smart DNS service.

# Nova Server 1.93.0

Smart DNS. Some sites refuse every Iranian address: Docker Hub, Google developer
pages, AI services, game stores. A device that cannot run a VPN app, such as a
PlayStation, Xbox, smart TV or router, now gets them through this node by
changing one setting, its DNS server. It fixes sanctions, not filtering: a site
that is filtered inside Iran stays filtered, because the request still carries
the real site name in the clear.

How it works. A separate xray process (`nova-smartdns`) answers DNS for the
listed sites with this node's address and relays those connections by name.
Nothing new listens on 53, 443 or 80: only registered customer addresses are
redirected to it, so everyone else still reaches the normal front and the DNS
tunnel on the same address. Changing the lists or a registration restarts only
this process, never the customer-facing core.

Who gets it. A per-customer grant, like mieru and AmneziaWG, on the user form or
in a plan. A reseller can grant it only when the owner allows it in that
reseller's settings, and taking the permission away removes it from their
customers. Expiry, the data cap and a revoked grant remove a customer at once.
Its traffic counts against the customer's allowance.

What the customer does. On their subscription page they open Smart DNS, press
the button that registers their current connection (up to 3 addresses), and
set their device's DNS server to the address shown. Only registered addresses
are answered, so the node is never an open resolver or an open relay. An
address already registered by another customer (two homes behind one carrier
NAT) is refused without touching either account. IPv4 only.

Lists. Developer sites are on by default. Game stores are off by default,
because game downloads cost you bandwidth and use up a customer's allowance in
an evening. You can add up to 200 of your own names; each covers its
subdomains and nothing else.

If your domain is behind Cloudflare or an Iran bridge, the server's own
address is hidden and Nova will not publish it by itself. The card asks you to
type the IPv4 address you are willing to show customers. Registered addresses
are not included in backups; customers press the button again after a move.

Security, on every node, whether or not Smart DNS is on: a customer's
connection could reach services listening on the server's own loopback
address, including the core's management interface. Both cores now refuse
loopback and the name `localhost` for customer traffic. Update soon.

Expiry and the data cap now reach the DNS tunnel (Soar) straight away. Before,
an expired or over-cap customer kept their Soar tunnel until some unrelated
change happened to refresh it.

A factory reset and the uninstaller now remove Smart DNS completely: the
service, its firewall chains and every registered address.

Nothing changes on a node until the owner switches it on. Not yet verified from
inside Iran: whether an ISP intercepts port 53 to a foreign resolver, which
would stop it working for that customer.

# Nova Server 1.92.4

Security fix. A reseller or manager account could read every customer's
subscription on the node, including other resellers' customers, through
`/admin/sub-content`. That route builds one subscription for the whole node
and was not limited to the owner. It is owner-only now, like the other routes
that expose the whole node. The owner and the built-in admin keep access, and
API tokens never reached it.

Every build up to 1.92.3 has this. If you have resellers or managers, update,
and consider rotating customer credentials you do not want those accounts to
hold.

# Nova Server 1.92.3

Irancell clients now split TLS records instead of TCP segments. The built-in
carrier profile served at `/isp-profile` sets Irancell to `tlsFragment: false`
and adds `recordFragment: true`, which Nova Client turns into sing-box
`record_fragment`. Two NetDiag runs on Irancell from inside Iran (sing-box
1.14.1, one tester, one night, two different links) had the TCP split fail 0/3
in both, while TLS record splitting passed 3/3 in both. A plain connection got
0/3 and 2/3 in the same runs. Other carriers are unchanged because nothing was
measured on them.

Older Nova clients ignore the new key and connect on Irancell without a split.
A custom ISP profile saved in the panel is kept as it is and does not get this
change.

Saving the per-ISP settings in the panel no longer drops `recordFragment` from
a carrier rule. The panel's built-in copy of the profile, used when it cannot
load `/isp-profile` and on Reset, now has the same Irancell setting.

Saving an ISP profile with a wrong value in a known setting is now refused
instead of stored and served to clients: `tlsFragment`, `recordFragment` and
`mux` must be true or false, `fingerprint` must be one the panel offers, and
`mtu` must be a whole number from 576 to 1500. Other keys are kept. A profile
already saved keeps working; the check runs on the next save.

# Nova Server 1.92.2

WARP setup no longer depends on one API name. Registering a WARP account,
applying a WARP+ key and checking the plan now try `api.devices.cloudflare.com`
(the name Cloudflare's own client calls since 2026.6.0) first, then
`api.cloudflareclient.com`, then the new name on the Cloudflare edges
104.24.4.6 and 104.18.0.6 directly. The next route is tried only when there is
no answer or the answer is not Cloudflare's own (a block page). The route that
answered goes first for later calls. The edge route still checks the
certificate against the API name. The route order comes from Aether 2.4.0.

All routes reach one backend, checked live: a device registered through the new
name was read through the old name and an edge, then deleted. Existing WARP
accounts keep working and nothing needs to be re-registered. The API version
and client headers are unchanged.

A reply without a real account (an empty page that answers 200, for example)
is no longer stored as a WARP account; the next route is tried instead. A
parent panel now waits long enough for a node to try every route before it
reports the registration as failed.

# Nova Server 1.92.1

Keep ECH enabled. This corrects 1.92.0's ECH guidance: repair the legacy lookup
instead of offering to disable ECH. Only the exact old default
`https://dns.alidns.com/dns-query` migrates automatically to
`cloudflare-ech.com+udp://1.1.1.1`. ECH state and stored keypairs are preserved.
Custom resolvers remain unchanged; Health offers an explicit lookup fix for
AliDNS and unverified DoH choices. Iran setup selects the verified default
without changing ECH state or replacing a custom resolver.

Optional decoy parameters now reach customer raw VLESS/Trojan links, the
subscription page and Telegram through the shared helper. Off by default,
with no built-in names. Reality and ECH links never receive decoy parameters.
Desktop packet injection still needs a future compatible Nova Client and
privileges. No Nova Client build or release was changed.

The endpoint-name report and conditional shared-hostname guidance from 1.92.0
remain. A decoy never hides the real endpoint name from stateful inspection.

# Nova Server 1.92.0

Operators can now offer decoy SNI metadata to compatible desktop Nova clients.
In Routing, enter carrier-tested hostnames and choose a method. Per-carrier
overrides are available in the ISP editor. The feature is off by default and
ships no built-in decoy names. Current clients keep their existing behavior;
desktop packet injection requires a future compatible client and privileges.
This release does not publish or modify Nova Client build 239.

Only a customer's Nova document carries the new metadata. Eligible raw TLS
VLESS and Trojan links in Nova requests carry the selected decoy; Reality and ECH links do not.
Raw parameters are limited to Nova's User-Agent or `target=nova-raw` until a
real stock-client import has been verified. Generic raw, page and bot links stay unchanged.
Other structured subscription formats are unchanged. Names are validated on
save and sanitized on output, including after alias and bridge rewrites.

A decoy is a first-packet technique. The real server name still follows.
Use an allowed custom domain or an eligible direct Reality inbound when the
endpoint name itself is filtered. No carrier success is claimed without tests.

Health now warns about ECH on Iran profiles and high-risk shared endpoint
names. The explicit disable action preserves stored ECH keys, including across
later inbound saves. ECH remains available for networks where it works.
Setup Assistant does not enable ECH or decoy names automatically.

Inspect endpoint names in the client transport card to see names emitted by
the subscription builders for up to three enabled customers. The owner-only
report includes the subscription hostname and highlights repeated panel names
and shared endpoints. It returns no credentials and is not a packet capture.

# Nova Server 1.91.1

The Soar card on the customer subscription page now recommends Nova Client on
Android or iPhone, in English, Persian and Russian.

- Install opens the Nova Client download page.
- Open in Nova Client imports the customer's own `target=nova` subscription
  through the app's registered import link.
- Copy and the 300 px QR code still carry the same Soar profile for direct
  import. Accounts, keys, permissions and traffic limits are unchanged.

For Soar delivered through a subscription, use Nova Client build 238 or newer.
Update Nova Server from the panel or run its installer again, then reload the
customer subscription page.

The real container install check also exposed an incomplete Xray permission
repair: upstream creates `/usr/local/etc/xray` as `root:xray 0750`, while Nova
runs Xray as `nobody:nogroup`. The installer and agent now give that standard
directory group `nogroup` and mode `0750`, including when the unit user was
already corrected. This restores config access without making it public.

# Nova Server 1.91.0

The Soar profile travels with the customer's subscription, and its QR code can
be scanned.

## Soar in the subscription

A customer's own subscription now carries their Soar profile, so a Nova app
that knows Soar imports it with their servers instead of sending them to find
the link on their page:

- In the Nova document (`?target=nova`) it is a `soar` outbound under the
  client's own field names: the zone, the public key, the resolvers and the
  five tuning values that differ from the Soar library's defaults. It is not
  named in the selector or the url test. A Soar node has one route and carries
  no UDP, so the client keeps it out of its pools, and a core that tried to run
  the document as written would refuse a pool naming it.
- In the base64 list, which is what the client receives when its link was
  pasted without a target, it is a `soar://` line after the configs. A client
  that does not know the scheme skips that one line and keeps the rest.
- Only the customer's own link carries it. The whole-panel `?token=` link does
  not, and neither do the sing-box, Clash, Hiddify, Karing and Xray JSON
  documents: those cores refuse a whole configuration over one unknown entry.
- The same gates as the customer page: a customer who is expired, out of data,
  switched off, or sold by a reseller without the Soar permission gets no
  profile. The page and the Users page are unchanged, and WhiteDNS users keep
  importing the link from the page.

## The Soar QR code

A tester could not scan the Soar code on the customer page on two client
builds, and the reason was size: the link was about 830 characters, which is a
97-module code, drawn in the same 150-pixel tile as a 45-module VLESS code, so
each module was about 1.5 pixels wide.

- The profile now carries only the five tuning values that differ from the
  Soar library's own defaults (discovery on, 2 resolvers wanted, 2 probed at a
  time, 1000 ms apart, 128 streams) plus the country. WhiteDNS reads an absent
  value as its own default, which is the value Nova used to send, so the app
  behaves exactly as before. The link drops to about 550 characters, and every
  subscription that carries it is shorter by the same amount.
- The customer page draws the Soar code at 300 pixels in a full-width card of
  its own, with the buttons beside it on a wide screen and under it on a phone.

## Also in this release

- A customer of a volume reseller who has delivered their whole allowance no
  longer receives the shared Soar link on their page, in their links on the
  Users page, or in their subscription. In shared mode the engine serves the
  one account whatever the user list says, so that link kept working after
  the customer's configs had stopped.
- In shared mode the one link now rides every active customer's own
  subscription, and only Rotate revokes it; the card on the DNS tunnel page
  says so.

# Nova Server 1.90.1

Personal web proxy links on servers that had the web proxy on before 1.90.0.

A server that already had the Telegram web proxy on when it updated to 1.90.0
had no per-customer salt yet (1.90.0 minted it when the card was saved), so
granting a customer the web proxy produced no link until the card on the
Inbounds page was saved again. The node now completes that record when it
starts, exactly as it completes an MTProto record that predates per-customer
secrets. The shared link, its path and its secret are left as they were.

# Nova Server 1.90.0

A personal Telegram web proxy for each customer, the Nova app on the
Distribution page, and a domain can be marked as behind a CDN that is not
Cloudflare.

## A personal Telegram web proxy per customer

1.89.0 added Telegram's web proxy, the type that keeps working through a CDN,
as one shared link per server. It is now also per customer, the way the
MTProto proxy has been since 1.42.0:

- The user form and the plan editor have a **Telegram web proxy** switch, next
  to the MTProto one. A reseller may set it under the same permission that
  lets them sell the Telegram proxy.
- A customer with it on gets a link of their own, with a secret of their own,
  on their subscription page (a new card under the MTProto one, with the same
  two buttons) and among their links on the Users page (QR code and copy).
- Secrets are derived, not stored: revoking the switch and turning it back on
  gives the same link, renaming the customer changes nothing, and nothing
  per customer is added to the settings document. Expired and capped
  customers drop out of the relay the way they drop out of everything else.
- The shared link on the Inbounds card keeps working beside the personal
  ones, and the card says how many customers are being served. **New link**
  still retires every link at once, personal ones included, because it
  changes the path they all share.
- Each personal profile is bounded on the relay (8 sessions, 512 streams and
  a session rate of its own), so one customer, or one leaked personal link,
  cannot use up the relay and lock out the shared link and the others.
- The relay is told about profile changes by a restart (it has no reload), so
  granting or revoking a customer reconnects the others for a few seconds.
  Changes are applied at most once every 20 seconds, with the last state
  winning, so a run of edits, or a reseller toggling one customer in a loop,
  costs one restart per 20 seconds rather than one per edit.
- Resellers: the switch is sold under the existing Telegram proxy permission,
  so a reseller who may already sell the MTProto proxy may sell this one too
  without any change on your side. Traffic through it is not metered against
  the customer's data limit; expiry and the data limit still withdraw it.
- Up to 511 personal links per server, the relay's profile limit as Nova
  configures it. Past that the card says how many customers are over the line
  and get no link until others are revoked.

## The Nova app on the Distribution page

The Distribution page now opens with Nova's own client. The recommended-apps
list leads with a Nova card that carries the download link (the GitHub release
page the website links), and the "Open in app" row has a Nova card beside
Auto, Base64 and Clash: a QR code and a one-tap button that hand the whole
node to the app through the same `nova://install-config` link the customer's
subscription page already uses. The link asks for the `nova` document, the
one that carries mieru to the app.

## A domain behind another CDN

Each domain row on the Domains card (the panel domain included) offered three
answers to "is this domain behind Cloudflare": work it out, it is, it is not.
There is a fourth now: **It is behind another CDN**, for a name fronted by
ArvanCloud, Gcore, Fastly, Akamai, bunny.net or any CDN that is not
Cloudflare.

Nova cannot work that one out for you. The only edge addresses it knows are
Cloudflare's published ranges, so a name on another CDN resolves to addresses
that look exactly like a direct server's, and the automatic answer was
"points straight at this server". Everything that read that answer then
treated the name as your origin: the health check accused it of exposing the
server, the AmneziaWG, MTProto and mieru pickers offered it as a UDP endpoint
that a CDN cannot carry, and the subscription announced the panel host on a
config that dialled the CDN.

What the new choice does:

- The name counts as fronted everywhere a CDN is a CDN. It hides your
  server, it can carry the WebSocket front and nothing else (widening it to
  all inbounds is refused, as it is for a Cloudflare name), no UDP protocol
  is published on it, and a config that dials it announces it.
- The name is NOT Cloudflare to the two features that publish Cloudflare's
  own key and addresses. ECH is not written onto its lines, even with the
  switch on, because the lookup clients are given finds Cloudflare's key and
  a client told to use it against another CDN fails the handshake rather than
  falling back. Clean Cloudflare IPs are not published for it, because a
  Cloudflare edge has no route for a name it does not front.
- The ECH card on the Distribution page names the domains it leaves alone,
  and its "nothing to apply to" note asks about Cloudflare specifically. The
  Clean IPs switch does the same. The health check's ECH warning now also
  fires on a node whose only fronted name is on another CDN, where before the
  state would have read as "not established" and kept it quiet.

## Also in this release

- A domain Nova knows a CDN fronts carries the WebSocket front only, and that
  now holds however the knowledge arrived: one you marked, one that resolves
  into Cloudflare, or one Nova provisioned. Until now only the last was
  clamped. Marking an added domain as behind Cloudflare or another CDN narrows
  it to the front in the same write, adding a domain already marked lands it
  narrowed, widening it afterwards is refused, and a row that is still wide
  from before says so and offers the one way out.
- The subscription-link chooser labels a domain as going through a CDN by the
  same effective state, so a name you marked yourself carries the warning
  that the subscription is decrypted at that edge.
- The Domains search row and the manual cover the new choice; a search row
  for the Nova app points at the Distribution page.

# Nova Server 1.89.1

Certificates on arm64 servers, and a broken Hysteria2 can no longer block a
certificate on any server.

## What was wrong

On every arm64 server (Hetzner CAX, Oracle Ampere, Scaleway and the like)
adding a domain failed, by Let's Encrypt and by Cloudflare alike, with a
message about not being able to restore the previous setup and xray being
unhealthy. xray was healthy and the certificate had been issued. Measured on a
fresh 1.89.0 install in an arm64 container: Let's Encrypt issued the
certificate in 45 seconds, then the panel reported the rollback failure.

The chain:

- Hysteria2's engine (`sing-box-nova`) was published as a single amd64
  asset, and the installer put it on arm64 servers too. The kernel answers
  every start with "Exec format error"; systemd restarted it into that every
  three seconds for the life of the node.
- The node checks the engine's configuration before restarting it by running
  the engine. Running a file the kernel will not execute falls back to
  `/bin/sh`, which prints garbage and exits non-zero, so the node concluded
  the engine rejected its configuration.
- Adding a domain is a transaction that is strict about every service. That
  verdict aborted it, the rollback hit the same verdict, and the operator was
  told that the previous setup could not be restored and to check xray.

## What changed

- One engine build per architecture on the mirror. amd64 keeps the asset
  name every earlier installer asks for; arm64 is `sing-box-nova-linux-arm64.gz`.
  The installer and the node's engine updater choose by architecture; a machine
  with no published build skips Hysteria2 with one clear line instead of
  failing three downloads.
- The installer reads the engine's header too. A build for another
  architecture has its unit stopped and is replaced through the ordinary,
  checksum-verified update path; it is never deleted, because a missing
  engine would send the next run down the fresh-install path, which installs
  without a checksum when the mirror's sidecar is unreachable.
- The node reads the engine's ELF header before asking it anything, and on a
  mismatch asks the binary itself once (a host with binfmt emulation may run
  it fine). A build that cannot run is treated as no engine at all, in strict
  transactions too; the unit is stopped and one journal line says why. The
  shell's fallback output is recognised as "could not run" by its exit code
  and signature, never by words a configuration error might also contain.
- Certificate transactions (the primary domain, additional domains, bridge
  certificates) are strict about Hysteria2 only when Hysteria2 was serving
  at the moment the new configuration is written. An engine that was already
  down cannot be made worse by a certificate and cannot be mended by rolling
  one back.
- A failed certificate transaction now writes one journal line naming the
  stage and the cause, with anything that names a credential withheld.

## Also in this release

- The release archive is now checked against the source tree before it is
  packaged: a file that is not tracked (an editor's backup beside a module)
  fails the build instead of shipping inside the archive.

## For arm64 servers already installed

After this update, adding a domain works. To get Hysteria2 itself, re-run the
install command once; it installs the arm64 engine and starts the service.

# Nova Server 1.89.0

Telegram's web proxy, served from this server through a CDN, and the
Distribution page back in the side menu.

## The Telegram web proxy

Telegram's newer proxy type is now a card on the Inbounds page, directly
below the MTProto proxy. It travels inside ordinary HTTPS under a secret path
on one of this server's domains, so it works through Cloudflare's orange cloud
where MTProto cannot. Needs a recent Telegram on Android or iOS.

How it is built:

- Telegram's own relay (`tproxy-server`, pinned by commit, built by Nova for
  amd64 and arm64) and a small MTProto backend (`mtprotoproxy`, pinned by
  commit and checksum) are installed on demand from the card, both verified
  against pinned SHA-256 sums, and run as an unprivileged service user on
  loopback only. Nothing new is opened to the internet.
- xray's front dispatches exactly the relay's five request paths to it, by
  exact path match, and everything else keeps going to the panel. The relay
  serves the panel's own pages for its public site, so the secret path is
  the only thing that distinguishes it.
- One secret, one path, one link per server, like the MTProto proxy's shared
  link. The link carries the host and path in one `server=` parameter and the
  marked secret the way Telegram's installer derives it; the bridge capability
  derivation is pinned against the vectors Telegram publishes. New link
  rotates path and secret together.
- The host must be one of this server's own domains with a certificate on
  disk; a bare IP is refused. Four carrier modes, WebSocket by default.
- The card shows live sessions and streams from the relay's metrics, the
  service log when a unit is down, the last install's failure, and a warning
  when the Python `cryptography` module is missing (the backend then runs
  slowly; `apt install python3-cryptography`).
- The support bundle redacts the secret, the path and the host.
- Reviewed before release. Reconciles run one at a time and restart the
  services on an applied-state stamp, since the relay reads its config once and
  has no reload; the backend's stdout is dropped (the stock script prints the
  node's own `tg://` credential on every start) and its start-up public-IP
  lookup goes nowhere; a version marker stands in for the `-version` flag the
  relay does not have, so a later relay pin reaches existing nodes; the host
  allowlist cannot fail open on a node without domains; the uninstaller removes
  the secret directory and the service user.

## Also

- The Distribution page, where ECH lives, has a side-menu entry again. It had
  dropped out of the menu and was only reachable through search.

## Upgrading

Nothing to do. The web proxy is off until you install and enable it.

# Nova Server 1.88.3

Fresh installs work again: xray is run as the user Nova writes its files for.

## What was wrong

On 2026-10-17 the upstream XTLS installer (`install-release.sh`, which a fresh
Nova install runs when GitHub is reachable) switched its systemd unit from
`User=nobody` to a dedicated `xray` user and group. Nova hands xray a config
(`root:nogroup 0640`), a certificate (`root:nogroup 0640` under a `0750`
`/etc/nova`) and an access log (`nobody:nogroup`), all written for `nobody`.
From that day every fresh install crash-looped on

```
open /usr/local/etc/xray/config.json: permission denied
```

while the summary line said `panel configured; xray failed`, :443 never came
up, and a domain could not get a certificate because the challenge rides on
xray's :443. The agent's self-heal restarted xray every two minutes to the same
end. Reported by an operator after three fresh servers and several domains;
reproduced in a container on 2026-10-19. Servers installed before 17 October
kept their `User=nobody` unit and were not affected.

## What changed

- The installer asks systemd which user the xray unit runs as and, when it is
  not `nobody`, writes `/etc/systemd/system/xray.service.d/10-nova-user.conf`
  pinning `User=nobody` and `Group=nogroup`, reloads, and restarts xray if it
  was running or failed. A drop-in outranks the unit's own `User=` and
  survives a later upstream rerun.
- The agent does the same (`ensureXrayServiceUser`) before every xray
  restart and inside the self-heal, so a node broken in the last two days
  fixes itself on the next apply or within two minutes of getting this build.
- `test/xray-service-user.mjs` executes the installer block under a fake
  `systemctl` and drives the agent helper and self-heal with a mocked exec.

## Upgrading

A server installed since 17 October that never came up: re-run the install
command from the site; it pins the user and the panel comes up on the same
address and password. Everything else: nothing to do.

# Nova Server 1.88.2

The Soar service starts on servers with a domain, and the card says why when
it does not.

## What was wrong

The Soar unit was given `-listen <panel domain>:53`. On a server whose panel
has a domain, that is a name rather than this machine's address, and when the
domain is behind Cloudflare it resolves to the edge, so the bind failed and the
service crash-looped while the card showed "? active account(s)" with nothing
else to go on. Reported by an operator on the first real enable.

## What changed

- The service binds this server's own IP, read locally the way MasterDnsVPN
  does (`soarBindHost`: the panel host only when it is itself an IP, otherwise
  the node's primary address). Pinned by test.
- When the engine is installed but the service is not active, the status
  carries the last lines of the unit's journal and the card shows them with a
  Start again button, which rewrites the unit from current settings and starts
  it.
- A small layout fix on one panel page.

## Upgrading

If Soar is enabled, open the DNS Tunnel card after the update and press Start
again once; the unit is rewritten with the corrected address.

# Nova Server 1.88.1

Panel polish. A round of small refinements across the panel's newest pages:
clearer layouts, better keyboard support, a few dialogs that were missing
their confirm button, and phone-width fixes. Nothing about settings or
customer configurations changes, and nothing needs doing after the update.

# Nova Server 1.88.0

ECH on your fronted configurations, and an SSH terminal inside the panel.

## ECH

Encrypted Client Hello hides the one thing a TLS handshake still shows a
filter: the server name. A switch on the Distribution page adds the same
lookup Nova Proxy writes, `ech=cloudflare-ech.com+udp://1.1.1.1`, plus the
Chrome fingerprint, to every share link and Xray JSON entry whose name is
behind Cloudflare. The lookup text is editable and validated; plain DNS at
1.1.1.1 is the default because it is what works from inside Iran, where the
DoH form did not.

It is written only where TLS ends at Cloudflare. A client told to use ECH
against a server with no key does not fall back, it fails, so entries that
dial the node directly, Reality entries, bridge mirrors and fleet-node
entries are left as they were. Clean-IP copies inherit it from their source.
sing-box and Clash documents are not changed: they need the key bytes rather
than a lookup, and Cloudflare rotates the key. The health page reports ECH
switched on with no proxied domain to carry it, and the Telegram bot's own
subscription builder carries the option too.

## SSH terminal

Under System, owner only. A terminal to any server from inside the panel,
several at once in tabs, with a file browser (list, download, upload, new
folder, rename, delete, edit text files up to 512 KB in place) and saved
commands that run in one session or in every open session at once.

What protects it, since a shell on a server is the whole server:
- the upgrade is gated four times: session cookie, owner level, an Origin
  header naming this panel (cookies ride on cross-site WebSocket upgrades),
  and a single-use ticket minted seconds earlier;
- remembered connections are encrypted in the browser (AES-GCM) under a key
  derived from a per-admin secret only a signed-in session can fetch; the
  node stores nothing about them;
- the first connection to a server remembers its host key; a changed key is
  refused and reported, never silently accepted;
- credentials go to the SSH library and are dropped; the activity log
  records host, port and user only; sessions idle for thirty minutes close.

ssh2 1.17.0 and xterm.js 5.5.0 are vendored as pinned single files
(`src/vendor/VENDOR.md`); the agent still ships with no node_modules. An
in-process sshd built from the same bundle drives the end-to-end test.

## Upgrading

Nothing to do beyond the update. ECH is off until you switch it on. The
terminal needs the panel open on an https address for remembering
connections; on a bare http address it still works, it just cannot save them.

# Nova Server 1.87.1

The Soar engine installs again, and a failed install now says so.

## What was wrong

Enabling Soar on 1.87.0 never finished. The card said "installing" for as
long as you watched, and Install again did nothing. Reported by an operator
ten minutes in.

The agent downloads every pinned engine from Nova's own release page under
the pin's internal name, and for Soar that name (`soarNova`) is not the name
the release was published under (`soar-nova`). The download got a 404, the
install script died, and because the card had no failure state, "not
installed yet" looked like "still installing". The installer script used the
right name all along, which is why the release checks passed.

## What changed

- A pin can now name its release tag separately from its internal name, and
  `test/binary-pins.mjs` holds the agent's download address to the exact URL
  the installer uses. That test fails on 1.87.0.
- A detached install writes its output and exit status to
  `/var/lib/nova/install-<name>.log`. The DNS Tunnel card reads it back: a
  failure shows the last lines the install printed and stops polling, and an
  install that never finished (a reboot in the middle) is reported as such
  rather than as progress.

## Upgrading

Nothing to do beyond the update. If Soar is enabled, open the DNS Tunnel card
and press Install again; the engine is on the server a few seconds later and
the tunnel starts on its own.

# Nova Server 1.87.0

Soar, Lantern's DNS tunnel, as a third engine, per customer if you want.

## What it is

Soar is a DNS tunnel from the Lantern team, built against the two engines
Nova already ships: it uses every resolver at once with in-country discovery,
recovers from loss quickly, and connects in seconds rather than tens of
seconds. It carries TCP only, to ports 80 and 443 unless you widen that.

Upstream's server has no notion of a customer: anyone holding its public key
can use it. Nova runs it through soar-nova, a small wrapper of our own that
keeps upstream unmodified and serves one Soar instance per account, each with
its own key and its own byte counters. That is what makes the second mode
possible.

## Two modes

Shared: one account, one link, handed to whoever you choose. The same shape
as MasterDnsVPN and CottenDns, with no per-customer accounting.

Per customer: a switch in each customer's form, like mieru's. Every granted
customer gets a key and link of their own, their Soar traffic lands in the
same usage ledger as everything else, so data caps, expiry and the usual
alerts apply, and revoking closes that one customer. Resellers can be allowed
to grant it; plans and bulk actions carry it.

The link is WhiteDNS's profile format, because the WhiteDNS app for Android
(1.6.8 or newer) is today the only client that imports a third-party Soar
server. It appears on the customer's subscription page and in the panel's
per-customer links. The health page reports customers who were granted Soar
while the tunnel is off, on another engine, or in shared mode.

## Caveats

Soar is nine days old upstream and changed four times last week. Its wire
format may still move; Nova pins the exact version it was built against and
will update it the same way it updates the other engines. Nobody has measured
it from inside Iran yet, including WhiteDNS. Treat it as a field test: enable
it on one server, give it to a few customers, and tell us what you see.

Android only for now. No iOS or desktop client exists. If the engine proves
itself, the Soar client can be built into the Nova app, which is a separate
piece of work.

## Upgrading

Update from the panel, or run the installer again. The soar-nova engine is
installed on demand the first time you enable Soar, checksum-verified from
Nova's own release, the same way mieru's server is.

# Nova Server 1.86.2

The health page now shows what the last two releases do on their own.

1.86.0 and 1.86.1 added three things that happen without a click: the
Hysteria2 engine replaces itself on the daily check, mita updates itself when
mieru is switched off and on, and a clean IP that does not answer is put on a
strike and removed the next day. Each had a failure the panel showed only in
the activity log or on a card an operator may not open. The health page now
reports a refused engine update with its reason, a mita behind this release's
version (as information, since it fixes itself) or whose update failed (as a
warning, with the error), and a clean IP on its first strike. A fresh, healthy
server sees none of these rows, and the setup assistant still produces a
server the health page has nothing to say about.

Everything below is 1.86.1 and 1.86.0, released the same day.

# Nova Server 1.86.1

A clean IP that does not answer is no longer published, and turning mieru off
and on now brings mita up to date.

## The dead clean IP

An operator reported a Cloudflare address in the clean-IP list, 172.67.18.6,
that accepted no connection at all. Every config that drew it was dead. It was
measured while this was written: the address is inside Cloudflare's published
ranges, one of the sources still answers with it, and TCP 443 to it does not
open from anywhere, while every other address the same source returned
completed a TLS handshake in about 40 milliseconds.

Nova checked the one thing the sources could not lie about, that an address is
Cloudflare's, and never the thing they did not promise, that it serves. The
daily refresh now dials every candidate and every address already in the
list with a verified TLS handshake, using your own proxied domain as the name
so the certificate has to be the one for your zone. A new address that does
not answer is not admitted. An address already in your list is removed only
after failing on two consecutive days, so a momentary blip at this server
cannot delete something you chose, and an address that is dead from here but
alive from Iran gets a second look. If most or all addresses fail in one
round, that is this server's network rather than thirty dead addresses, and
nothing is removed; when your own domain cannot be verified on any edge but
Cloudflare's own can, the log says the name is the problem rather than the
network. What was removed, and what is on its first strike, is written to the
activity log by address.

This does not judge reachability from inside Iran, which only a client can
measure; it removes the addresses that are dead for everyone, which is what
the report was.

## mieru


Until now the pinned mita only ever reached fresh installs, so a server that
already had mieru stayed on whatever version it was built with, and 1.86.0
said so. An operator asked for the obvious thing instead: switching mieru off
and on should update it. Now each time mieru is enabled, or the agent
reconnects it after an update or a restart, the installed version is compared
with the pin. If it is older, the same checksum-verified download from Nova's
mirror runs and the mieru service restarts on the new binary. A mita newer
than the pin is left alone. A download that fails, or lands the wrong
version, leaves the working mita in place and is noted in the agent's log.
Re-running the installer does the same, and restarts mieru only if it was
running.

Everything below is 1.86.0, released the same day.

# Nova Server 1.86.0

A re-created customer starts clean, and the Hysteria2 engine moves to sing-box
1.14 with the pinned tools alongside it.

## The bug operators reported

Create a customer called A with a quota. Let A use it. Delete A. Create a new
customer called A. The new A arrived already over cap, carrying the old A's
traffic, last-active day and IP-limit lock.

The panel turns a name into an id, so the second A had the same id as the
first, and deleting a customer removed their record from the user list and
nothing else. Everything the server stores under that id stayed: the traffic
ledger, the per-day counters, the IP-limit lock, the Telegram flag. The
mieru and Telegram-proxy credentials are also derived from the id, so the old
A's saved configs worked again the moment the new A existed, on the new A's
quota.

Deleting a customer now clears all of that, and also their registered
devices, the last client addresses seen for them and the "already warned"
flags, through every route that deletes: the single delete, the bulk delete,
the whole-list save, removing a reseller together with their customers,
restoring a backup that does not contain them, and a managed node whose
parent stops sending them. The deleted id is remembered as retired, and a new
customer given that name gets a numbered id (a-2) rather than the old one, so
nothing of the old customer, traffic or credentials, can attach to the new
one. Restoring a backup or importing a Nova export with identities preserved
brings an id back legitimately, and clears the retired mark for it. A factory
reset clears the retired marks too. Existing customers are not touched.

One rule comes with this: a new customer id must be 1 to 64 characters of
letters, digits, underscore or hyphen, which is what the panel has always
produced. Ids of another shape that already exist keep working.

## What else changed

Hysteria2 on a Nova server is served by sing-box. The engine Nova publishes
moves from 1.13.19 to 1.14.1, the current upstream release, built exactly as
before: unmodified upstream source, the same eight build tags, pinned to the
upstream commit and checked tag by tag after the build.

Nothing changes in how it reaches you. A server with automatic updates on
fetches the engine's published checksum on its daily check, sees that it
differs from the one it installed, downloads the new engine, asks it to load
the server's current Hysteria2 settings, and only then swaps it in and restarts
Hysteria2. Any other server does the same the next time you press Update. An
engine that cannot read your settings is refused and the working one stays.

The configuration Nova writes for Hysteria2 was run through the real 1.14.1
binary before this was published. It loads without a warning, including the
older form of the link-local block that keeps loading on every engine version a
node might still have.

mieru's server, mita, is pinned at 3.37.0 for new installs and for servers that
turn mieru on from now on. 3.36 made matching a new connection to its user
faster and cut allocation churn in the cipher; 3.37 adds an optional single-IP
listen address that Nova does not use. Every behaviour the agent depends on was
re-checked against the real 3.37.0 binary: a name over 64 bytes still rejects
the whole document, applying a config still replaces the user list, an empty
user list still fails to start, and the columns of `mita get users` are
unchanged. A server that already has mieru keeps its current copy.

grpcurl, which the agent uses to read Hysteria2 per-user statistics, is fetched
at 1.9.4 instead of 1.9.1 on new installs, and it is now pinned the way the
other tools are. Until now it was the one download in the installer with no
checksum, no https-only rule and a fixed path under /tmp. The archive is now
verified against upstream's published SHA-256 before anything is installed,
fetched over https only, and staged in a private directory. A mismatch leaves
the server without metering rather than with an unverified binary.

## Upgrading

Update from the panel, or run the installer again. The Hysteria2 engine update
happens on its own; the update card shows the engine's last attempt if you want
to confirm it.
