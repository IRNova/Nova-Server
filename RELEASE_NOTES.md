# Nova Server v1.13.4

Documents the corrected Iran-bridge behavior from 1.13.3 in the in-panel guide and
the README.

## Changed

- The tunnel guide and the Forwards / "apply to all links" hints now explain, in all
  three languages, that pointing client links at the bridge applies across every app
  format (raw, Clash, sing-box), and that only the ports you forward travel through
  the bridge. To route another inbound through Iran, add its port to Forwards.
- README (English and Persian) Iran-bridge section updated with the same two points.

## Notes

- No behavior change from 1.13.3: this release only updates the guide and docs.
- Nova Server ships as an obfuscated build by design; Nova Proxy and the verified
  tools stay open.
- The Iran bridge needs an Iran VPS with a direct public IP (not behind NAT) to
  reliably carry traffic.
