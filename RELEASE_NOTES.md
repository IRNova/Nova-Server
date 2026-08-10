# Nova Server v1.53.0
## AmneziaWG on your nodes, and it reaches the customer's own page

Until now the AmneziaWG tunnel ran on the panel server only. It can now run on
any node in your fleet, and each customer's own subscription page carries that
node's configuration beside their other ones, the way a protocol placed on a
node already reaches them.

If you do not switch it on for a node, nothing changes. Both of the servers this
release was tested against produce byte-identical subscriptions, Clash documents,
sing-box documents and node pushes before and after the update.

### How to switch it on

Nodes page, a new card called **AmneziaWG on nodes**. Press **Turn on** for a
node, and every customer you have already granted AmneziaWG gets a tunnel there.
They see it on their own subscription page as **AmneziaWG (node name)**, with a
QR code, a copy button and a download, exactly like the one they may already
have from the panel server.

You can set the UDP port, the obfuscation strength, the protocol version and the
address customers dial. Leave the address empty to use the node's own address,
which is the one this panel already reaches it on.

### The two limits, said here rather than found later

**253 customers per node.** Each node addresses its tunnels inside a single /24,
so that is the ceiling, and the card says it. Past it, granting AmneziaWG to one
more customer takes the address of the customer whose access was withdrawn
longest ago and deletes their tunnel with it. The health check reports the node
once you are over.

**A node installed with Docker or Podman cannot run it at all.** The AmneziaWG
server needs a kernel module that is not available inside a container. Such a
node now says so instead of accepting the setting and doing nothing: the panel
shows it as not serving, the health check names the reason, and no customer is
ever offered a file for it.

### Nothing is offered for a node that is not really serving it

This is the part worth knowing. A configuration file for a tunnel that is not up
is worse than no file at all: the customer's app connects, shows a tunnel, loads
nothing, and has no error to report.

So a node's configuration reaches a customer only after that node has confirmed
it is carrying it. If the node cannot run AmneziaWG, or its interface did not
come up, or it already runs an AmneziaWG server of its own, or it has not
answered yet, the customer is offered nothing and the health check tells you
which of those it is.

### Nobody is re-keyed, and turning it off keeps everything

Existing tunnels keep their keys and their addresses. Turning a node's AmneziaWG
**off** keeps them too, so turning it back on later hands out the identical
files and nobody has to import anything again.

The one setting that does change what your customers hold is the **obfuscation
strength**: changing it regenerates the junk headers written into every file, so
every customer on that node has to be sent theirs again. The card says so.

### If a node already has an AmneziaWG of its own

Nothing is overwritten. A server that was a standalone Nova panel before you
enrolled it can already have AmneziaWG set up with configurations in your
customers' hands, and replacing it would destroy every one of them. The panel
leaves it alone and tells you why on the health page.

Switching that server off on the node does not change this, and that is
deliberate: turning AmneziaWG off keeps its keys so its own files keep working.
If you do want this panel to take it over, the node's row has a **Replace**
button. It asks first, because it destroys the keys behind every configuration
that node has already handed out and there is no way back.

### Where it is explained

- The **manual**, under Nodes, in English, Persian and Russian.
- The **panel search**: type "AmneziaWG on node", "kernel module", "253", or
  "not serving".
- The **health check**, with a row per node that is switched on and not serving,
  and one for a full subnet.
- The **support bundle** carries each node's AmneziaWG state, so a bundle you
  send is enough to see what happened without you describing it.

### Fronts on a node: still not offered, and here is why

An operator asked for the shared :443 front to be creatable on a node from this
panel. It is not, and it is deliberate rather than pending.

A front terminates TLS for a specific hostname, so it only works if the machine
running it holds a certificate covering that name. This panel cannot know
another machine's certificate state reliably: what it stores is the certificate
that node presented for this panel's own calls, which says nothing about any
other name, and a node's certificate can lapse or be removed months after the
front is created. Offering the control anyway would produce configurations that
look right on this page and cannot connect, with nothing reporting it.

The route that does work is unchanged: give the node its own domain and
certificate from the Nodes page (or when it joins), and its own front records
are kept exactly as they are.

### Upgrading

Nothing to do. Every node starts with this switched off.
