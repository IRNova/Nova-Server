# Nova Server 1.57.0
## The tunnel check that could never pass, and a setting nobody could find

Four fixes, all of them from one operator's report. Three were ours to begin
with. Nothing here changes a setting, a config or a customer's link.

---

## The tunnel's verification could never pass on most nodes

An exit tunnel shows one of three states: down, up and verified, or up but
unverified. The third one says the tunnel carries traffic while Nova cannot
confirm what is answering at the other end.

Nova checks this by asking the exit, through the bridge, for `/install/status`
and looking for its own build in the answer. It asked for that address without
the panel's secret path. `/install/` is part of the panel, so a node with a
secret path answered its own check with the same decoy 404 it shows a scanner.
The installer gives every new node a random secret path, so this was not an edge
case: it was the normal state, and the check could never go green no matter what
the operator did.

The message it printed made this worse. It said the exit "fronts 443 with a
proxy that does not expose /install/status". Nothing in that check ever looked
for a proxy. It printed that sentence for every answer that was not the one it
wanted, including the 404 Nova had just given itself. Operators read it, believed
there was a web server in front of their exit, and edited configuration files to
fix a problem that was on our side.

The check now carries a one-time token that proves the request is this node's
own, and still asks for the plain address. Sending it under the secret path was
the obvious fix and is the wrong one: this request leaves the exit, crosses the
public internet to a rented VPS in Iran, and is made without verifying who
answers, because the node's own certificate is usually self-signed. Putting a
secret that defeats both of the node's decoys on that wire every two minutes, to
make an indicator turn green, is a bad trade. A captured token is spent and
worth nothing, and a scanner without one still gets the same 404 it always got.

The message now reports what actually came back, says a second program owning
port 443 is the usual explanation rather than a certainty, and names where to
forward the address if that is the case: the Nova agent on `127.0.0.1:8088`,
headers included, since the token travels in one.

If your tunnel has been sitting on "unverified", update and look again. On most
nodes it will simply be green, and there was never anything for you to configure.

---

## The usage rate was in a place nobody would look

1.56.0 added a rate for ordinary proxy traffic and then put the field inside the
Backup and maintenance card, under the Account security heading, at the bottom of
a page with a dozen cards above it. The first operator to go looking reported the
feature as missing, and they were right to: search took them to Settings, they
saw no such field anywhere, and there was nothing to tell them to keep scrolling.

It now has its own card with its own heading, above Account security, and it says
in plain words which traffic it covers: every xray inbound plus Hysteria2 and
TUIC. AmneziaWG, mieru and the Telegram proxy each have their own rate on their
own card, and now the search knows about those too.

Nothing about how the rate works has changed. The number you set is the number
that was already there.

---

## Search now takes you to the setting, not to the page it lives on

Searching for something used to open the right page and stop. On a short page
that is fine. On Settings it left you at the top of a very long one, which is how
a setting that exists for two lines of scrolling reads as a setting that does not
exist.

A result that points at one control now scrolls to it and rings it briefly, and
holds that aim while the rest of the page finishes loading, which on these pages
takes a moment and used to carry the thing you searched for back off the screen.
Touch the scroll yourself and it stops immediately.

---

## The AmneziaWG note read like an instruction you had missed

The note on the AmneziaWG card explains that the protocol is granted per customer
and warns that the `.conf` file carries that customer's private key. It was
phrased as a set of instructions, so on a server where AmneziaWG was already
running it read as though something had not been done yet. One operator reported
it alongside two real faults for exactly that reason.

Same facts, reworded so it reads as how it works. It is shown only when
AmneziaWG is installed and available, which it always was.

---

## For operators updating

Nothing to do. No setting changes meaning, no configuration is rewritten, and no
customer's link changes. With the default rate and existing resellers, the
subscription output is identical to 1.56.0.

One thing may change on screen without you touching anything: an exit tunnel that
has been reporting "unverified" will most likely report verified after the
update, because the check was asking the wrong address.
