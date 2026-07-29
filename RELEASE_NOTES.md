# Nova Server v1.14.5

Guidance and a smarter default for the recommended Iran-bridge setup.

## Changed

- The Tunnel **Forwards** field now defaults to just **443** (previously 443 and
  8443/udp). Forwarding only your main VLESS link is the recommended setup: your
  other inbounds stay direct and faster while the exit is reachable, and the
  VLESS-through-bridge link is the always-working fallback if the exit's IP is ever
  blocked. The client's url-test picks the fastest working one, so you get speed now
  and resilience when you need it.
- The Forwards hint, the in-panel tunnel guide (English, Persian, Russian), and the
  README now explain this reasoning, and note that Hysteria2 and other UDP protocols
  stay direct because they cannot ride a backhaul tunnel.

## Notes

- No change is needed for an existing tunnel. This makes new setups land on the best
  balance of speed and resilience by default.
- Nova Server ships as an obfuscated build by design; Nova Proxy and the verified tools
  stay open.
