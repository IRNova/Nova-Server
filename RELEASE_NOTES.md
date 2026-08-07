# Nova Server v1.42.1

Three things the panel was showing you that were not true. All reported within
hours of 1.42.0, thank you.

## The Reload button on a Telegram proxy or mieru port did nothing

If either of the new protocols showed a red "nothing is listening", the panel
offered a **Reload service** button. That button restarted Xray, which has
nothing to do with either of them, so pressing it changed nothing however many
times you tried.

It now restarts the service that actually owns the port. For mieru it also
starts the proxy afterwards, because mieru's service being up is not the same as
mieru serving traffic: it comes up idle, so a restart that stopped at the service
would have told you it worked while the port stayed shut.

## The Persian health page read backwards

The health check writes its explanations in English, and in a right-to-left page
their punctuation was being moved to the wrong end of the line. Sentences came
out looking like ".which ,TUIC and NaiveProxy run over QUIC ,Hysteria2 is UDP"
on the one page you open when something is already wrong.

Fixed. The text now lays itself out in its own direction, and it will still be
right when those explanations are eventually translated.

## You can now choose which address goes in the proxy link

If your panel domain is behind Cloudflare, the Telegram proxy link named an
address nobody could connect to, and mieru had the same problem with no way to
change it.

Both now have an address picker. It lists only the domains that can actually
carry these protocols, and a Cloudflare-proxied domain is deliberately not among
them: neither protocol is HTTP, so the CDN answers the handshake itself and
nothing reaches your server. If you have no direct domain, leave it on
**Automatic** and Nova uses the server's own address.

Nothing else changes, and nothing your users hold is affected.
