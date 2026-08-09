# Nova Server v1.48.0

## Nova now knows which of your domains is actually behind Cloudflare

An operator reported a health finding that was simply wrong. Their panel domain
sits behind Cloudflare with the orange cloud on, but they got its certificate
from Let's Encrypt rather than through Nova's Cloudflare integration, so Nova had
never written anything down about it. The health page then told them that domain
was pointing straight at their server and exposing it beside a proxied one. It
was not. A false alarm on that page is worse than no alarm, because it teaches
people to ignore the real one.

Nova only ever knew about domains it had set up through Cloudflare itself. Now it
resolves each of your domains and checks whether the addresses belong to
Cloudflare, whose published ranges are already compiled into the agent. A domain
that resolves into Cloudflare **is** behind Cloudflare; that is a fact, not a
guess.

The lookup is encrypted and goes to resolvers named by address, not through
whatever resolver your server's network hands it. That matters because this
answer decides what your customers receive: a network that filters your server
can stop Nova finding out, which leaves the domain at "not established" and
changes nothing, but it cannot tell Nova something untrue.

**Each domain row on the Domains and addresses page now says one of three
things**, and the third one is the important one:

- **Behind Cloudflare**
- **Points straight here**
- **Not established**

"Not established" is a real answer and not a polite no. DNS from a server in or
near Iran is exactly what gets blocked or poisoned, and a lookup that fails must
never be read as "points straight here". When Nova cannot establish a name, it
says so and acts on nothing at all: no accusation on the health page, and no
change to any address a customer dials. That is the same behaviour you had
before this release.

**You have the last word.** Each row has a dropdown: work it out automatically,
it is behind Cloudflare, or it points straight at this server. Your answer beats
anything Nova worked out, everywhere it is used: the health page, the clean-IP
feature, and the address the Telegram proxy, mieru and AmneziaWG publish. Use it
when you can see your DNS panel and this server cannot. **Check again** re-runs
every lookup immediately rather than waiting for the next scheduled one, which
happens every six hours.

Two things follow from this that are worth knowing:

- **The clean-IP feature now works for you even if Nova did not set up your
  domain.** It used to require a domain Nova had provisioned through Cloudflare,
  which shut out every operator who arranged their own.
- **A domain you put behind Cloudflare yourself will now stop being published as
  the endpoint for the Telegram proxy, mieru or AmneziaWG.** None of those three
  can pass through a CDN, so a configuration naming a proxied domain cannot
  connect at all. If that removes an address you were relying on, the health page
  explains why and the per-domain dropdown lets you overrule it.

## Clean IPs: findable, and you choose what customers receive

**The Clean IPs page is in the menu.** It had a page and a search entry and no
navigation entry at all, so the only way in was to already know it existed. There
is also a shortcut to it directly under the daily refresh switch in Settings,
which is where the operator who reported this was looking.

**You can now choose what customers receive.** Both the domain entry and a
clean-address copy, which stays the default, or only the clean-address copy.
"Only" stands down to "both" for as long as nothing has corroborated the pool,
which covers both a seeded list and a collection that only one source
contributed to, because withdrawing your customer's working domain entry in
favour of nothing but untested addresses is a trap rather than a trade; your
choice is remembered and takes effect the moment a corroborated collection
lands, or the moment you paste your own list.
Both is the safer one: if a clean address stops working, the customer loses one
configuration instead of all of them. Choose only when you want your domain out
of what clients hold, and the panel states plainly what you are giving up, which
is that there is no fallback left. Reality, Hysteria2, TUIC, NaiveProxy, mieru
and Shadowsocks are never affected either way, because a clean address cannot
carry any of them.

**An empty pool is seeded.** If the published sources cannot be reached, Nova
resolves well-known Cloudflare sites such as chatgpt.com, over the same
encrypted lookup, and keeps the addresses that pass the same check every other
candidate passes. The page labels these as
seeds, and the label matters: they are genuine Cloudflare addresses that nobody
has tested from inside Iran, so some may already be blocked. A real collection
replaces them as soon as one succeeds, and seeds never touch a pool that already
has something in it.

## Testing a Tor or Psiphon country exit tells you something useful

**A working Psiphon exit was reported as broken.** The Test button asked
check.torproject.org whatever the service was and required it to answer
`"IsTor":true`, so a Psiphon exit came back as "something answered on this port
but it is not a Tor exit". That was true and useless: Psiphon is not Tor and
never claimed to be. Psiphon is now asked whether traffic gets through and what
address it leaves from, and nothing about Tor is asserted of it. Tor keeps its
own check, because that is the only thing that proves the port in front of you
really is a Tor exit rather than something else that took it.

**A failed test now says which of three things happened**: nothing is listening
on the exit's local port, so its instance is not running; the port is open but no
circuit came back; or Tor's own check service could not be reached from this
server. That last one used to make every country on an affected node look broken,
because the whole test depended on reaching one host. There is a second check
now: if traffic gets through while Tor's service is unreachable, the exit is
reported as working, with the honest note that Nova could not confirm it left
through Tor.

## Where client-side fragment actually lands

Operators tested v2rayN, Shadowrocket, Streisand and Happ and found no
client-side fragment. That is correct and it cannot be fixed: a `vless://` share
link has no fragment parameter at all, so there is nowhere in it for one to go
and no setting can put one there.

Nova does emit a real client-side fragment, in the **Xray JSON** subscription and
in Karing. The Xray JSON link is now offered on the Distribution page beside
Clash and sing-box: give it to a v2rayN or v2rayNG user, who imports it as a
custom config, and the fragment arrives. The card on the Domains and addresses
page and the manual both say this plainly now. The same is true of multiplexing.

## New inbound choices, and one that would have taken your node down

- **Reality over XHTTP**, and **Reality over gRPC**, as first-class choices in
  the inbound editor.
- **HTTPUpgrade over TLS** as a first-class inbound. Xray marks HTTPUpgrade
  deprecated in favour of XHTTP; it still works, the editor says so, and XHTTP is
  the better choice for something new.
- **The XHTTP port is choosable.** It was pinned at 2087 with no control at all,
  which is a dead end on a node already using that port. XHTTP and HTTPUpgrade
  now offer the HTTPS ports Cloudflare actually forwards (443, 2053, 2083, 2087,
  2096 and 8443), and a port something else on this server binds is shown greyed
  out with the reason rather than hidden.

Every combination offered was checked against the real Xray binary before it
shipped, which is how one was found that Nova would previously have accepted:
**Reality over HTTPUpgrade**. Xray refuses it outright, and a configuration Xray
refuses does not break one inbound, it stops the whole node reloading and takes
every other inbound with it. It is refused at save time now.

## Editing a Hysteria2 inbound opened the wrong editor

Pressing Edit on a Hysteria2 inbound opened the **Reality** editor: server name,
borrow destination and short IDs, on a UDP listener that has none of them.
Saving from there would have rewritten a working Hysteria2 listener as a Reality
inbound and taken away every customer's configuration for it. Its card also
carried a REALITY badge over a "tcp" transport.

Hysteria2, TUIC and NaiveProxy have no Xray transport at all, and their stored
records carry Nova's standalone defaults in fields nothing reads. The panel was
reading those defaults as though they meant something. Fixed for all three;
nothing you have saved needs changing.

## Upgrading

Nothing here changes what your customers hold unless you change a setting. If
you have a domain you put behind Cloudflare yourself, open Domains and addresses
after updating and check what each row now says, because the health page and the
standalone protocols act on it.
