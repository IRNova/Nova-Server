# Nova Server v1.32.5

## Your server was telling anyone who asked that it is a VPN panel

Connect to a Nova server on 443 by its bare IP, under any name at all, and it answered with the sign-in page. Found on a live Iran bridge, which returned the panel byte for byte:

```
https://<bridge ip>/  ->  200, 1,392,610 bytes
<title>Nova Server</title>     "Admin password"     "Sign in"
```

That is the cheapest possible thing for a censor to find. No traffic analysis, no timing, no active probing of the protocol: one HTTP request and a string match identifies the server and every other one running the same software. It also put a sign-in form on the most exposed machine in the deployment.

A Nova server can now answer anything that did not arrive on its own domain with an ordinary, unremarkable page, while the panel stays exactly where its owner expects it. After turning it on, the same request returns 695 bytes titled "Welcome", with no mention of Nova, no build number, no framework fingerprint and no external requests, since a fetch to a CDN would be its own tell. The admin surface returns a plain 404 to anything arriving that way, so it does not admit to existing.

The page is deliberately generic rather than a copy of a real site. Impersonating a genuine company would be dishonest, and it is also weaker camouflage, since any mismatch against the real thing is itself a signal.

**Nothing a user holds is affected.** Subscriptions, the fleet API, tunnels and relays keep answering on whatever address the client dialled, because those URLs have already been handed out. Only the panel surface is hidden.

**You cannot lock yourself out.** Three separate guarantees, each one covered by a test:

- A server with no domain of its own, or with an IP where its domain would be, is never hidden from its own address. There, the bare address *is* the address.
- A stealth path, if you use one, always reaches the panel whatever name you used.
- A signed-in session always reaches the panel, from any address. A scanner has no session, and in a censorship context the domain is exactly what gets blocked, which is when you need the IP most.

**Existing deployments keep their current behaviour** until you turn this on, so nobody's bookmarked address stops working on an update. The health check now reports the exposure and offers the switch. New installs start with it on.

## Verification

Exercised against the live deployment that exposed it. Before: 1,392,610 bytes of admin panel on the bridge IP. After: 695 bytes titled "Welcome", zero occurrences of "Nova", "Admin password" or "Sign in", `/admin/*` returning 404, while the panel on its own domain, all three subscription formats, a subscription fetched by bare IP, and the node API were all unchanged.

## Upgrading

Nodes with automatic updates enabled will take this on their next check. To update now, use the panel's update button, or re-run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
