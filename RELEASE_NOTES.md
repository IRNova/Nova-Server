# Nova Server 1.71.0

Five things, four of them reported by operators and one by a customer of one.
Three are failures with the same symptom and three different causes, which is
why they are described separately rather than as one fix.

## Nodes that had quietly stopped receiving their configuration

The panel sends its whole user set to each node in a single POST. A node capped
every request body at one megabyte, and the cap did not simply refuse: it
rejected with a 413 and then destroyed the request, so the answer the route had
just written went into a socket that no longer existed. What came back to the
panel was a transport error, and for a body a little over the cap Node words
that error `socket hang up`.

Past roughly five thousand customers, therefore, every push to every node
failed. The nodes kept serving whatever configuration they last received, the
Nodes page and the health check both said `socket hang up`, and that phrase is
wrong about the cause in the way that matters most, because nothing was
unreachable. Reproduced against a real node before anything was touched: 4,800
customers pushed fine, 5,200 said `socket hang up`.

Three changes. A node now accepts a body sized for a real fleet push, chosen
against its own heap rather than picked round: the unit runs Node with
`--max-old-space-size=192`, and eight megabytes costs about a third of that
between the buffer, the string and the parsed object. The reader stops
collecting at the cap but keeps draining, so the 413 is delivered the ordinary
way, and only drops the connection for a body nobody could have sent by
accident. And a panel talking to a node too old for either now says which node
to update and why, instead of repeating a phrase that names nothing.

## "Socket hang up" after updating a node, which was a different problem

The same words, a different cause, and it is the one an operator will have seen
first: press Update, then find that every attempt afterwards failed while Test,
a moment later, said the node was perfectly reachable.

Every request this panel made to a node went through Node's global HTTP agent,
which has kept connections alive by default since Node 19. One TCP connection
therefore carried every call to that node. It was fine right up until the node
dropped it, and the Update button is what makes a node do exactly that: it
answers, updates, and restarts, which closes the connection. The next call was
written into a socket that was already gone and came back as a reset, and
nothing retried it. Test, opening a fresh connection, was telling the truth.

A fleet control channel makes a handful of calls a minute, so the shared pool
bought nothing measurable and cost this. Each call gets its own connection now.

## Renewing an expired customer

A customer is sold a number of days, and that number does nothing until their
first byte arrives: enforcement then stamps a real date on them, once, and from
that moment the date is the only thing deciding whether they are active. The
rule that reads the day count is gated on there being no date yet, so it can
never fire again.

Both user editors offered the day count and nothing else. So after a customer
expired there was no control anywhere in the panel that could bring them back.
Typing a bigger number rewrote a field nothing reads. Turning the switch back on
set a flag the calendar overrules. An operator reported it in exactly those two
halves, and the server was right throughout: the one path that did work, the
bulk Days action, is the one nobody reaches from a customer's own page.

Once a customer's clock has started, both editors now show the date instead, and
an expired customer's record says why the switch alone will not do it. Before
the clock starts they still show the day count, which is the right control then:
it is what the customer bought, and it should not begin running because somebody
opened their record.

## Finding one customer among thousands

The customer list drew every customer at once with no way to look anybody up.
That is fine at fifty and unusable at five thousand: an operator taking a
support call had the browser's own Ctrl+F and a page that took seconds to lay
out, and a reseller scrolling for one name had nothing at all.

There is a search box, matching on name, email, ID and note, in any order and
across fields, so "ali gmail" finds the right Ali. It folds the ways the same
Persian name gets typed, since Arabic ي and ى against Persian ی, ك against ک,
and Persian digits against ASCII ones are the same name to the person searching
and different strings to a string match. Page size is 10, 25, 50, 100 or all,
remembered between sessions; the search is not, deliberately, because a stale
filter hiding customers at the next login is the worst thing this feature could
do. Select-all now means the rows on screen, which is the only safe answer once
a filter can hide four thousand of them.

## XHTTP and AmneziaWG in the Nova app's subscription

XHTTP servers were left out of every structured subscription because no sing-box
implements that transport. True of every client except this one: Nova's app
ships the combined sing-box and Xray core and routes VLESS-over-XHTTP nodes to
the second core, each behind its own local socks inbound, measured and pinned
like anything else. So `?target=nova` carries them now, along with HTTPUpgrade,
which needs no second core at all. Every other document is unchanged, because
sing-box, Hiddify and Karing all refuse a whole configuration over a transport
they do not know.

Two limits, both the app's own rather than invented here: XHTTP translates for
VLESS only, and an XHTTP node on a self-signed certificate stays out, because
Xray 26.3.27 removed `allowInsecure` and there is no certificate pin to offer in
its place. Reality is the exception and the intended answer on a no-domain node,
since it authenticates with its own key and asks no CA anything.

AmneziaWG arrives the same way. sing-box 1.11 moved WireGuard into its own
`endpoints` array and the app's importer follows it there, so a customer's
tunnel now imports with their subscription, sits in the server list, updates
itself and is measured like any other server, instead of being a file to find on
a web page and add by hand. Tunnels on fleet nodes come through as well, each
named after its node. A panel whose only address is behind a CDN offers no
tunnel rather than its origin, which is what its customer page already does.

Tunnels ride the customer's own subscription and not the whole-panel `?token=`
one, which is a narrower rule than everything else in that document follows. It
is not about who can read it, since that link is owner-only and already carries
every uuid and every password. It is about what cannot be undone: a leaked
subscription token is rotated in one press, and an AmneziaWG keypair is not,
because minting a new pair kills the file the customer is already holding.

## Upgrading

Update and restart. Update your fleet nodes too: a node keeps the old body cap
until it is updated, and that is the half of the sync fix that lives on the node.
Nothing changes for a customer who is connected.
