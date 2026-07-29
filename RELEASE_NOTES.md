# Nova Server v1.16.0

Get-online-in-one-scan onboarding, and Hysteria2 port hopping.

## Added

- **Quick connect on the dashboard.** A genuinely fresh install now creates one
  ready-to-use starter user and a set of standard protocols, and the owner dashboard
  shows that user's personal subscription as a QR. Scan it with Nova, Hiddify,
  v2rayNG, Clash, or sing-box and you are online, no need to open the Users page
  first. Reruns and managed nodes are left untouched.
- **Hysteria2 port hopping.** A Hysteria2 inbound can now use a UDP port range. The
  client rotates across the range instead of a single fixed port, so a censor cannot
  pin every connection to one IP and port. Set a range like 20000 to 40000 on the
  inbound; the node redirects the whole range to it and the subscription link carries
  the range automatically. It is fully opt-in: with no range set, nothing changes.

## Notes

- Port hopping uses a dedicated firewall chain, so it never touches your other rules,
  and it is UDP-only. Pick a high, unused range that does not overlap another UDP
  service on the box.
- Existing nodes pick this up through the panel's version-gated update. Nova Server
  ships as an obfuscated build by design; the installer and verified tools stay open.
