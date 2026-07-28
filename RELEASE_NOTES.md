# Nova Server v1.13.3

Fixes "apply tunnel to all user links" so client subscriptions actually move to
the Iran bridge, and stops rerouting inbounds the bridge does not carry.

## Fixed

- **Clash and sing-box subscriptions now follow the bridge.** The Clash / sing-box
  renderer ignored the published bridge address, so users on v2rayNG, mihomo,
  sing-box and Streisand kept getting links pointed at the foreign exit even after
  "apply tunnel to all user links". It now reroutes the front proxy to the bridge
  IP while keeping the real SNI and Host, exactly like the plain (base64) list.
- **Only forwarded ports are rerouted.** A link is pointed at the bridge only for a
  port the tunnel actually forwards (443 and 8443/udp by default). An inbound on a
  port the bridge does not carry now stays on the real host instead of being pointed
  at a bridge port with nothing listening, which is why "changed inbounds did not
  work". Add a port to the tunnel's Forwards list to carry that inbound too.

## Notes

- No config change is needed: re-open the panel, and both link formats are correct
  on the next subscription refresh. Disabling the tunnel still reverts every link.
- Nova Server ships as an obfuscated build by design; Nova Proxy and the verified
  tools stay open.
- The Iran bridge is domain-oriented and needs an Iran VPS with a direct public IP
  (not behind NAT) to reliably carry traffic.
