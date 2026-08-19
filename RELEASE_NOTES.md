# Nova Server 1.68.1

Sending AmneziaWG out through WARP, Tor or Psiphon works now. It never has.

## The exit selector never worked, on any node

Choosing where the tunnel leaves from is done by one firewall rule that hands
its traffic to the proxy engine. That rule was written in a form the firewall
refuses outright, so it was never installed on any server, from the day the
feature shipped.

What you saw depended on which version you were on, and neither was the truth.
On 1.67.0 the traffic simply left from this server's own address, which is the
exact thing choosing an exit is meant to prevent, and nothing said so. On
1.67.1, which made that failure refuse traffic rather than leak it, the tunnel
went quiet the moment an exit was chosen: connected, and nothing loading.

An operator reported both halves. It is fixed, and this time it was checked by
running it rather than by reading it: a tunnel in a container, a real client,
and traffic confirmed leaving through WARP on a different address from the
server's own.

## Tor and Psiphon need their service on the node

Those two exits hand traffic to a Tor or Psiphon service running on the machine.
Nova does not install either, so if it is not there the exit has nothing to give
the traffic to and nothing will load. The health check reports this.

WARP is different: the node registers its own account and needs nothing
installed.

## What's new was in a place you could not find it

It was added to a menu group that starts collapsed, so the page you go looking
for after an update was the one page you had to already know how to reach. It is
in the main menu now.

## The help panels were walls of text

Several had grown to cover four or five unrelated subjects in a single
paragraph, one of them over three thousand characters. They are broken into
paragraphs, in all three languages, with no wording changed. A build check now
refuses any paragraph over 650 characters.

## Upgrading

Update and restart. A node with an exit already chosen installs the corrected
rule on that first start. If you had chosen Tor or Psiphon and it never worked,
check the health check before choosing again: it will tell you whether the
service is installed.
