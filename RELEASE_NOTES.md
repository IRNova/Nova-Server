# Nova Server 1.67.0

AmneziaWG stops needing a person when a kernel upgrade breaks it, can leave
through WARP, Tor or Psiphon, and the page your customers actually look at has
been rebuilt. Two bugs operators reported are fixed, and the API can tell you
how busy a node is right now.

## AmneziaWG repairs itself after a kernel upgrade

AmneziaWG needs a kernel module, built for the kernel that was running when it
was installed. An ordinary unattended upgrade reboots the machine into a newer
kernel with no module for it, and the tunnel cannot start: not the config, not
the peers, not anything you did. Every customer's file stays valid and useless.

The only sign was the health check reporting that nothing was listening on the
tunnel's UDP port, which is true and impossible to act on.

Nova now rebuilds the module by itself when the node starts, and brings the
tunnel back up in the same boot. When it cannot, it says why, naming the kernel,
in the activity log and on the health check, and tries again once a day rather
than on every restart. A node not using AmneziaWG does nothing, and a container
is skipped, since no container can load a kernel module.

## The Reload button restarted the wrong thing

Pressing the fix on a dead AmneziaWG port restarted xray. AmneziaWG is not
served by xray, so it could never have helped, and it dropped every live
connection on the node each time it was pressed. The button now acts on
AmneziaWG: it brings the tunnel up, or tells you the kernel module is missing
and gives you the command.

Relatedly, Nova decided AmneziaWG was "available" by looking for its command
line tools. Both can be installed while the module is missing, which is exactly
the broken state above, so a node reported the tunnel as available and handed
customers files for something that could not exist. Availability now requires
the module.

The card stays usable while the tunnel is down, so you can still switch it off
or remove a customer from it.

## Choose where AmneziaWG traffic leaves from

An inbound has always been able to leave through WARP, Tor or Psiphon. The
tunnel could not, because it is a kernel interface and its traffic never passes
through the proxy core where the other exits live. Now it can: pick an exit on
the AmneziaWG card.

**One limit, stated plainly because it is not small.** Tor carries no UDP at all
and Psiphon carries only TCP, so when you choose an exit, UDP is refused rather
than sent out of this server's own address behind the customer's back. Browsers
fall back from QUIC to TCP and carry on. Games and calls that insist on UDP will
not work while an exit is selected. And DNS still leaves from this server's own
address: the names your customers look up are visible here even while their
traffic leaves elsewhere. Leave the setting on this server and nothing changes.

## The subscription page

The page your customers open has been rebuilt around the one thing they need.
The link and its QR code now sit together in a single panel instead of the QR
floating beside the card. There is one obvious button to copy the link, where
there used to be three that looked alike. The apps show their real logos rather
than letters. The JSON configuration, the Telegram proxy and SOCKS details moved
into drawers, so they are there when somebody needs them and quiet when nobody
does.

The AmneziaWG configuration now comes first in the config list, because it is
the only one that is a file to download rather than a link to scan, and it was
sitting last behind everything else.

## Two reports from operators

**A subscription that said "never expires".** Adding days to an account made the
customer's page report no expiry at all. Nova stores an expiry in two shapes,
a plain date from most paths and a full timestamp from the bulk "add days"
action, and the page only understood the first. The second came out as an
invalid date, which the next line read as "no expiry" and printed. Nothing was
wrong with the account: the server knew when it ended the whole time, and it
still ended then. Deleting and recreating the customer appeared to fix it
because a new account is written in the shape the page could read, which is why
the workaround worked and explained nothing. The page reads both now.

**A device limit that did nothing.** There are two limits side by side in the
user form, and neither was doing what the label suggested. The IP limit applies
to every app but does nothing until "enforce device limit" is switched on in
settings, and nothing said so. The hardware-id limit only counts devices that
identify themselves when they fetch the subscription, and the apps customers
actually use do not, so that number never applied to anyone no matter what was
switched on.

Both are now labelled for what they do, and the health check reports a limit
that is sitting there applying to nobody: an IP limit with enforcement off, with
one press to switch it on, and a hardware-id limit on a customer whose apps have
never once identified themselves.

## Live connection counts over the API

The API could say how many customers a node has and how much traffic they had
used, but not how many were connected right now. That number existed only inside
the panel, behind a browser login, so anything automated could not reach it.
`GET /api/v1/online` now returns it: connected devices per customer, plus the
node's totals. A reseller token sees its own customers and no one else's, in the
list and in the totals.

This is the number to steer on if you run several nodes behind one address and
want traffic to land on the emptiest.

## Security

Three fixes from this release's review, two of which change behaviour you can see.

**An exit that is not there now blocks, instead of leaving from this server.**
Choosing WARP as an exit when the node has not registered a WARP account
produced a rule pointing at something that did not exist, and xray sends an
unknown destination to its default, which is this server's own address. So the
customer who was put behind WARP left from exactly the address WARP was chosen
to hide, and nothing said so. This now blocks instead, which is visible
immediately and is already reported by the health check. The same guard covers
every exit, not just WARP: no rule can point at an exit the configuration does
not define. The same applies when the tunnel's firewall rule cannot be
installed at all, which on some kernels it cannot: the traffic is refused rather
than quietly sent out from here.

**Customers can no longer reach the server's cloud metadata address.** On most
providers a machine can ask 169.254.169.254 about itself and get back its own
setup details, and on some, credentials for the account it belongs to. Anyone
holding a subscription could ask for that through the server, from the server,
which is the one place that address answers. It is now blocked everywhere a
customer's traffic can leave: the proxy core, the tunnel, and Hysteria2, TUIC
and NaiveProxy, whatever else is configured. Nothing legitimate uses it. This
one predates the release and applies to every Nova node.

The last three are served by a second engine, and the rule for them is written
in an older form on purpose. The current form needs a version newer than some
nodes have, a node only downloads that engine when it is missing, and its
configuration is not checked before the service restarts. The newer form would
have taken those protocols off the air on exactly the oldest nodes, so the
older form is used, having been tested against four builds spanning the range
that is actually in the field.

**A reseller could see the whole node's live user list.** The panel's live
connection view was not filtered by reseller: any reseller could read every
other reseller's customers and how many devices each had connected at that
moment. It is filtered now, the same way traffic already was.

## The health check learned the rest of it

It now covers the AmneziaWG kernel module, the tunnel's exit, whether the
service behind that exit is even installed, the device limits above, and which
of your nodes are running an older version than this panel, with one press to
update each. The setup wizard covers the same ground for a new node.

## Upgrading

Update and restart. A node with AmneziaWG switched on checks its module on that
first start and repairs it if it can.
