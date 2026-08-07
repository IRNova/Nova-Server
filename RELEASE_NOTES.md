# Nova Server v1.42.2

## Changing mieru's transport left the old port open

If you switched mieru between TCP and UDP, the port you switched **away from**
stayed open and accepting. The panel told you it was closed, mieru's own
configuration said it was closed, and one listener was still sitting there.

Changing the port number was always handled correctly. It was changing only the
transport that leaked, because the way mieru was being restarted releases a
listener when the port moves but not when just the protocol does. Nova now
restarts the service outright on any change to what it listens on, which is the
only thing that reliably closes every socket.

If you have ever changed mieru's transport, take this update and the stray
listener goes away. Nothing else about your setup changes, and no client
configuration is affected.

## A note on the "nothing is listening" report

Thank you to whoever reported mieru showing red on a UDP port. We could not
reproduce that symptom, and mieru on UDP is now tested end to end on a real
server: it binds, the health check sees it, and the test button passes. So if
you are still seeing it, we would genuinely like the output of these four
commands, because it is something we have not seen yet:

    ss -lnu | grep <your mieru port>
    systemctl is-active nova-mieru
    mita status
    journalctl -u nova-mieru -n 20 --no-pager

In the meantime: if mieru shows red, the **Reload service** button on that row
now actually fixes it. In 1.42.0 that button restarted Xray, which has nothing
to do with mieru, so it did nothing at all no matter how many times you pressed
it. That was fixed in 1.42.1 and is confirmed working.
