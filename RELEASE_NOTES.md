# Nova Server v1.52.0
## AmneziaWG 2.0, off by default, and the panel tells you what it costs

AmneziaWG can now speak protocol 2.0 on a node you choose. It is **off**, it is
**per node**, and turning it on or off is one press with nothing to repair by
hand.

If you never open the AmneziaWG card, nothing on your node changes. Both of the
servers this release was tested against produce byte-identical subscriptions,
byte-identical Clash and sing-box documents, and byte-identical AmneziaWG files
before and after the update.

### What 2.0 actually is

Version 1.0 pads the two handshake packets. Version 2.0 pads the cookie packet
and **every data packet** as well, so a censor watching packet lengths has less
to work with.

You choose it on the AmneziaWG card, on the Inbounds page, in a new **Protocol
version** picker beside the obfuscation strength.

### Read this before you press it

**2.0 and 1.0 cannot carry traffic to each other, and the failure is silent.**
The handshake still succeeds. Your customer's app connects, shows a tunnel, and
then nothing loads, and there is no error message for them to send you.

So switching in either direction means **every customer has to be sent their
configuration file again**, from their own subscription page. The panel asks you
to confirm before it changes, and says this in the dialog.

**Nobody is re-keyed.** Every peer keeps the same keys and the same tunnel
address. What changes is the padding written into the file, not who the customer
is. That is also what makes going back real: switch to 1.0 and anybody still
holding the 1.0 file they had before you switched works again immediately.

### Which apps can use 2.0

Nova hands AmneziaWG out as a `.conf` file. The apps that import one and
understand 2.0 are:

- the official **AmneziaVPN** app, from version **4.8.12.9**,
- the standalone **AmneziaWG** app, from version **2.0**,
- **Nova's own Android app**.

Nova's iPhone, Windows, macOS and Linux apps cannot use AmneziaWG at either
version, so 2.0 takes nothing away from them. Karing, v2rayNG and the ordinary
WireGuard app have never been able to use AmneziaWG at all.

If you cannot tell which app your customers are using, 1.0 is the safer answer.

### Where it is explained

- The **manual**, under "Telegram proxy, mieru and AmneziaWG", in English,
  Persian and Russian.
- The **panel search**: type "2.0", "protocol version", or "connects but nothing
  loads".
- The **health check** carries a note while 2.0 is on, so whoever picks this
  node up later can find out why an old app stopped working. It is a note, not a
  warning: nothing is wrong.
- **Your customer's own subscription page** now says, under their AmneziaWG
  configuration, which app version it needs.

### If the panel says 2.0 and the node is serving 1.0

A settings document restored from a backup taken before this release can name
2.0 without carrying the values to write it with. Nova serves **1.0** in that
case, which keeps every customer connected, and the health check says so. Open
the AmneziaWG card and press **Re-apply** to generate them, then send your
customers their file again.

### What Nova deliberately does not write

2.0 also defines special junk packets (I1 to I5) and magic headers given as a
range. Nova writes neither. The junk-packet syntax is not the same in the Linux
kernel module your node runs and in the client library, so there is no value
that is certainly readable by both; and a magic-header range on a node whose
kernel module is too old is rejected along with the whole configuration, which
stops the interface and takes every other customer with it. What Nova writes is
what was confirmed working on a real node first.

### One more thing, if your server has an IPv6 address

Version 2.0 adds a few bytes to every data packet, and over IPv6 there is no
room left for them. If AmneziaWG hands out an IPv6 address, customers will
connect, small pages will load, and anything large will stall with no error. The
health check now says so and names the address. Publish the server's IPv4
address on the AmneziaWG card instead, or stay on 1.0.

### Upgrading

Nothing to do. The switch is off on every existing node and on every new one.
