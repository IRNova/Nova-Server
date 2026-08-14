# Nova Server 1.59.0

The tunnel can now carry one inbound instead of all of them.

## Choosing which inbounds use the tunnel

"Point all client links at the bridge" moves everything at once: every inbound
on a forwarded port starts advertising the Iran bridge. That is the right
default and it was the only option, so an operator who wanted one inbound
through the tunnel and the rest direct had no way to say it.

Two changes make that possible.

**The bridge is now a public address you can choose.** When an exit tunnel is
enabled, the inbound editor offers the bridge alongside your domains: its domain
if it has one, otherwise its IP. Pick it for a single inbound and only that
inbound hands out configurations pointing at the bridge. Everything else keeps
connecting to this server directly.

**"Take all links off the bridge"** sits beside the original button and undoes
it. Every inbound goes back to advertising this server, except any whose own
public address is the bridge, which is how you end up with exactly the set you
chose. It tells you how many of those there are, so nothing disappears quietly.

Turning it off runs no probe and no health check, unlike turning it on. Pointing
users at the tunnel needs the path proven first; bringing them back to the
server they are already talking to does not, and refusing to undo because the
tunnel is unhealthy would be the worst possible moment to refuse.

## Notes

Choosing the bridge as an inbound's address never moves its SNI. The
certificate presented at the far end is this server's, so the handshake still
asks for your domain; only the address the client dials changes. That is the
same split the tunnel uses everywhere else.

Nothing changes for existing setups. If you have pointed all links at the
bridge, they stay there until you press the new button.
