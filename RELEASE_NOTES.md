# Nova Server v1.14.3

Makes the Iran bridge work reliably when set up from the panel.

## Fixed

- **Duplicate forward crash.** When the tunnel forwarded a port that a local inbound
  also used (for example `8443/udp` plus an inbound on `8443`), the generated bridge
  config listed that port twice and the tunnel backend died with "address already in
  use", leaving the bridge stuck. Forwards are now de-duplicated by port, so the
  bridge always starts cleanly. If any duplicate was UDP, UDP is still carried.

## Changed

- **New tunnels default to the wssmux transport.** It disguises the tunnel as ordinary
  TLS, which is what survives Iran's deep packet inspection. Plain TCP tends to get
  reset on the wire, so this default saves a lot of "the tunnel connects but drops"
  trouble. You can still pick any other transport.
- Custom control and forward ports were always editable in the tunnel form; they are
  now covered by tests so they stay that way.

## Notes

- No change is needed for an existing working tunnel. This helps new setups from the
  panel come up correctly the first time.
- Nova Server ships as an obfuscated build by design; Nova Proxy and the verified tools
  stay open.
