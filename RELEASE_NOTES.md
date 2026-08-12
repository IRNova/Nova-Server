# Nova Server 1.57.0

## Tunnel verification

Exit tunnels now verify on nodes that use a secret panel path, which every new
install gets by default. The check runs from the exit, out through the Iran
bridge and back, and confirms the build answering at the other end.

A tunnel that has been showing "unverified" will show verified after this
update. Nothing to configure.

When the build still cannot be confirmed, the panel reports the HTTP status that
came back and where to forward `/install/status` if another program holds port
443 on the exit. It no longer names a cause it did not test.

## Usage rate

The usage rate has its own card in Settings, above Account security. It covers
every xray inbound plus Hysteria2 and TUIC, and the card states that scope.

AmneziaWG, mieru and the Telegram proxy keep separate rates on their own cards
on the Inbounds page. Both are reachable from panel search.

## Panel search

A result that names a setting now scrolls to that setting and highlights it,
instead of opening the page it sits on. Scrolling yourself cancels it.

## AmneziaWG

The note on the AmneziaWG card is reworded to describe how per-customer access
works and what the `.conf` file carries. It appears only when AmneziaWG is
installed and available.

## Upgrading

No action required. No setting changes meaning, no configuration is rewritten,
and no customer link changes. Subscription output is identical to 1.56.0.
