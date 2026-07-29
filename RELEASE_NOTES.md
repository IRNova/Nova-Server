# Nova Server v1.14.4

A bridge speed optimizer, so the tunnel uses the fastest port, not just a reachable one.

## Added

- **Throughput-aware port sweep.** When you set up or check a bridge, the sweep now
  measures real download speed (Mbps) for each candidate control port, not only its
  latency. A port Iran throttles shows a low speed and is passed over. The panel's
  bridge health card shows the speed and latency per port and recommends the fastest
  one to use as your control port.

## Notes

- wssmux remains the recommended transport for an Iran bridge: it disguises the tunnel
  as ordinary TLS and survives deep packet inspection.
- No change is needed for an existing tunnel. This helps you pick the best port when
  setting one up or re-checking it.
- Nova Server ships as an obfuscated build by design; Nova Proxy and the verified tools
  stay open.
