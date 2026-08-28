# Nova Server 1.74.0

AmneziaWG 3.0 can be set on a node, not only on this panel.

## What was wrong

The AmneziaWG card for a node offered 1.0 and 2.0 and nothing else. A node
updated alongside its panel still could not be put on the newest protocol, and
nothing said why, because there was nothing to say: three separate places
refused version 3 for a node, and the picker simply never listed it.

## Why it was not a one-line change

Before letting an operator choose 3.0 for this panel's own interface, Nova
checks the AmneziaWG packages on this machine. It cannot run that check on a
node, which it only reaches over HTTP.

That check is not a nicety. Writing a 3.0 configuration to older packages does
not fall back to something workable: `awg setconf` refuses the whole document
and the interface stops, taking every peer on that node down with it, and the
error names no field.

So the node reports which generation its own packages are, in the check-in it
already makes, and this panel gates the option on that answer. A node whose
packages are positively identified as the older line is refused, with a message
saying to update them, and one that cannot be identified is allowed, because an
unreadable version string is far more often a packaging variant than an old box.

There is a second question, and it is the one that matters on the day this
ships. A node running an older Nova does not refuse a 3.0 configuration: it
keeps the version field only when it says 2, so a 3.0 push is stored as nothing
and that node serves 1.0 while this panel hands its customers 3.0 files. They
connect and carry nothing, with no error on either end, and the node reports
success. So 3.0 is offered for a node only once that node is itself on 1.74.0 or
newer. Unlike the package question, a node that has never reported a version is
refused rather than allowed: it cannot report one because it is too old, which
is the answer.

## What it costs, unchanged

Switching a node to 3.0 is the same flag day switching this panel is. The header
key is shared by the whole interface, so every configuration that node has
handed out stops working the moment you press it, and each of its customers
needs their file again. The same confirmation appears, with the same warning.

## Upgrading

Update and restart. Nothing changes for anyone until you choose it: every node
stays on the version it is on. The 3.0 option appears on a node's card once that
node has checked in after updating, which is the first poll after its own
update.

If a node shows the option and refuses it on save, that node's packages are the
older line and the message says so; update AmneziaWG on that machine and try
again.
