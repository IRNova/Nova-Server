# Nova Server v1.29.0

Nova Server 1.29.0 stops the Clash and sing-box subscriptions from handing out configs that could never work, and changes what happens when a subscription has nothing in it.

Two of the problems below are not new. They have been present in every release to date, and both put a user's real address on the wire while their client reported it was connected. If you run Nova for anyone on a censored network, this is the release to take.

## Global mode sent everything outside the tunnel

mihomo, the core behind Clash Meta, Clash Verge, FlClash and ClashMetaForAndroid, builds its own `GLOBAL` selector before it reads a subscription, and that selector lists `DIRECT` first, so `DIRECT` is what it selects. Nova never defined a `GLOBAL` group of its own, so a user who switched their client to Global mode, which people do precisely to force everything through the VPN, got the exact opposite: every request left on their real IP with the real SNI, while the client showed a healthy connection and the correct server name.

Nova now defines `GLOBAL` itself, pointing at the working proxy group. Rule mode is unchanged.

## One inbound could take down every subscription

An inbound stored with Reality security but no key made the subscription builder throw. Because `/sub` renders every inbound in a single pass, one such record returned an error to **every** user on the panel, in every format, until it was found and deleted. The subscription page showed an empty list rather than an error, which made it look like a configuration problem rather than a fault.

Such an inbound is now left out instead. It is not emitted with an empty key either: sing-box answers `invalid public_key` and xray answers `empty password`, and both refuse the whole configuration, so one bad record would have cost that user every config they had.

## Transports those formats cannot express

XHTTP is Xray-only. sing-box has no implementation of it, and Nova's sing-box builder knows only WebSocket and gRPC. An XHTTP inbound was still written into both formats anyway:

- In sing-box, so Hiddify, Karing and anything else built on it, the entry lost its transport and dialled plain TLS at a server speaking XHTTP. It could not connect, and the error said nothing useful.
- In Clash the entry carried `network: xhttp`. mihomo does not reject a transport it does not recognise; it ignores the field and quietly falls back to plain TCP, so the client showed a working proxy that was speaking the wrong protocol.

XHTTP and httpupgrade are now left out of those two formats. Nothing is lost: the plain subscription link still carries both, and that is what an Xray client reads. If you use XHTTP, hand out the subscription link rather than a Clash or sing-box profile.

Hand-edited Advanced (JSON) inbounds are left out for the same reason, when their guided fields disagree with the pasted JSON. Nova did not build those inbounds and cannot describe them, so it was filling in defaults and publishing a Reality entry with a key nothing was listening with. The Advanced tab now says so.

## A subscription with nothing in it

The changes above make it possible for a subscription to contain no proxies. In practice the common reason is much more ordinary: the user expired, ran out of quota, or was disabled.

Both formats used to produce a file the client refused to load. That was accidental, but it was the safe outcome. The fix keeps the file loadable and makes the refusal deliberate: an empty subscription now blocks traffic rather than carrying it.

This matters because clients re-download subscriptions on a timer. Had the empty file simply allowed traffic through, a user whose plan lapsed overnight would open their client, see "connected", and browse with their real address in the clear, with nothing on screen to suggest the tunnel was gone.

Getting that right took more than a catch-all rule. In sing-box, `route.rules` govern only connections that arrive through an inbound; internal dialers such as a DNS transport with no detour go straight to whatever `final` names, so an ordinary direct outbound there kept leaking DNS after everything else was blocked. `final` now names an outbound that cannot carry anything.

## Nodes installed from a test build stay on it

The installer can record its update channel in `/etc/nova/agent.env`, so a node installed from a preview or mirror stops replacing itself with the public build. Persisting that is gated: the URL must contain no shell or systemd metacharacters, it must be https, and the choice lives in the installer script rather than in an environment variable, so a pasted one-liner cannot make itself permanent. Public installs are unaffected and nothing is written for them.

## Verification

The emitted configs were checked against the real clients rather than only against Nova's own tests: xray-core 26.3.27, mihomo 1.19.29, and sing-box 1.11.15, 1.12.16, 1.13.15 and 1.14.0-beta.4. Five security review passes ran before release, and three of them found a defect in the fix from the pass before.

## Upgrading

Nodes with automatic updates enabled will take this on their next check. To update now, use the panel's update button, or re-run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
