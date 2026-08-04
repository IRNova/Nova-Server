# Nova Server v1.31.0

This release covers 1.30.0 and 1.31.0 together, since 1.30.0 was never published separately. Every item below was found by running Nova against real servers and real client cores, not by reading code, and most of them are faults that had been live for some time.

If you run Nova with fleet nodes, or on a server without a domain, this is an important release to take.

## A fleet node could sit unconfigured, and nothing said so

`syncFleet` only ever ran when someone saved an inbound or a user. There was no timer and no manual "sync now". So a node that was enrolled and then left alone **never received its configuration at all**. It kept whatever it had at enrollment.

That state was invisible. The sync result was discarded, every error was swallowed, and the panel's `lastSeen` is written by enrollment and the Test button but never by sync, so a node that had never synced looked exactly like a healthy one.

On the deployment where this was found, the node held zero user credentials for a day. Every config in every subscription that pointed at it completed a TCP handshake and then failed authentication, which reads to a user as "low ping but no data".

Now: per-node results are recorded, reconciliation runs every ten minutes, the Nodes API gained a `sync` action, and the health check reports a node that has never synced as a failure. The fan-out is concurrent rather than serial, because a serial pass with a fifteen-second per-node timeout could stall traffic accounting, quota enforcement and the xray self-heal for minutes on a larger fleet.

## A server without a domain could never obtain a certificate

The agent binds port 80 itself on a no-domain server, to serve the subscription over plain HTTP, because clients refuse to *fetch* a subscription from a self-signed HTTPS URL. Let's Encrypt needs that same port for the HTTP-01 challenge, and a shell hook cannot free a listener that lives inside the agent process.

So the workaround for having no certificate was the thing preventing the server from ever getting one. The port is now released for the challenge and restored afterwards.

The restore is a reconcile against current state, not a plain restart, and that detail matters: issuance completes before the server is marked as having a domain, so a naive resume rebound port 80 and held it forever. The unattended renewal sixty days later would then fail to bind and the certificate would quietly expire at day ninety.

## A managed node could never obtain one either

A managed node closes its admin surface, and the node API had no certificate route, so there was no path to issuance at all. A node enrolled on its IP kept the self-signed certificate from enrollment while the panel advertised a domain for its inbounds, and every client that verifies certificates refused the handshake.

The node API now has `POST /api/v1/cert` and `GET /api/v1/cert`, owner-token only, using the same job machinery the panel uses on itself.

## Clash Global mode sent everything outside the tunnel

Covered in 1.29.0 for the empty-subscription case, but the same fault applied to every populated subscription. mihomo builds its own `GLOBAL` selector before reading a subscription and lists `DIRECT` first, so `DIRECT` is what it selected. A user who switched to Global mode, which people do precisely to force everything through the VPN, got the opposite. Nova now defines `GLOBAL` itself.

## Hiddify and Karing never received the 1.29.0 transport fix

Nova picks the subscription format from the client's User-Agent, and matched only `sing-box`. Hiddify sends `HiddifyNext/...`, so it fell through to the plain list and kept receiving XHTTP entries its core cannot implement, which was the original complaint 1.29.0 set out to fix. Hiddify, Karing and the official sing-box apps are now recognised.

HiddifyNG is deliberately excluded: despite the name it is an Xray fork, and handing it a sing-box document would take it from a partly working list to one it cannot parse at all.

## Certificates are now verified rather than assumed

Two places trusted a flag or a filename instead of the certificate itself:

- A **bridge domain** both joins the exit's certificate list and rewrites the SNI of every link that dials that bridge. Nova only checked that the certificate and key files existed, so an expired or wrong-domain certificate silently rewrote the SNI and broke every affected config. Coverage and validity are now checked, and the expiry is re-evaluated on every use, because a failed renewal leaves the file unchanged on disk.
- A subscription link pointing at the wrong server returned an error that read like an expired account. Both link forms now explain what is actually wrong, with identical wording for panels and nodes so the response cannot be used to tell them apart.

## Links that current Xray refuses outright

Xray-core removed `allowInsecure` and now refuses to start on a configuration that sets it. A no-domain server's plain-TLS links carry exactly that, so they are dead on v2rayNG, v2rayN and Streisand rather than merely insecure. The health check now reports those inbounds and offers to convert them to Reality, which needs no certificate.

## Verification

Emitted configurations were checked against real client binaries: xray-core 26.3.27, mihomo 1.19.29, and sing-box 1.11.15, 1.12.16, 1.13.15 and 1.14.0-beta.4. The subscription and certificate paths were exercised end to end against live servers, including an Android emulator running Hiddify 4.1.1.

Two areas remain **untested** and are called out deliberately: certificate issuance through Cloudflare DNS-01, and per-inbound certificates for individual domains. Both need DNS write access that was not available. If you use either, treat this release as unproven for that path.

## Upgrading

Nodes with automatic updates enabled will take this on their next check. To update now, use the panel's update button, or re-run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
