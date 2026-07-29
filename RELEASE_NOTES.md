# Nova Server v1.18.0

Hysteria2 ECH, plus port-hopping interval.

## Added

- **ECH (Encrypted Client Hello) for Hysteria2.** Turn on ECH on a Hysteria2 inbound
  and Nova hides the TLS server name inside the handshake, so a censor cannot see
  which domain a client connects to. Nova generates the keypair on the node and
  delivers the public config through the sing-box subscription (the plain link cannot
  carry it, so ECH needs a sing-box or Hiddify client). Combine it with port hopping
  and obfs for a strong anti-filtering setup.
- **Hop interval.** A third box on the port-hopping field pins how often the client
  rotates ports, in seconds.
- Standalone Hysteria2 now also appears in the Clash and sing-box subscription
  formats (with its port range, interval, and obfs), not just the raw link.

## Notes

- ECH is opt-in per inbound and needs a sing-box-family client to take effect.
- Existing nodes pick this up through the panel's version-gated update. Nova Server
  ships as an obfuscated build by design; the installer and verified tools stay open.
