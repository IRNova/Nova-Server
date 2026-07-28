# Nova Server v1.14.0

Makes the Iran bridge reliable to set up: check the server before you install, find
a port Iran actually lets through, and see the bridge's health in the panel.

## Added

- **Bridge readiness check.** Run the bridge command with `--check` and it verifies,
  without installing anything, that the Iran server has a direct public IP (not NAT)
  and that the forwarded ports are free, naming whatever is holding a busy port. A real
  install runs the same check first and stops with a clear reason instead of leaving a
  dead tunnel behind. This catches the two things that silently break a bridge: a NAT'd
  box, and a port already used by another service (for example running a full node on
  the same server).
- **Port-viability sweep.** Iran blocks or throttles some ports. The bridge now tests a
  pool of Iran-friendly candidate ports against your exit, measures which ones connect
  and how fast, and recommends the best control port. You can still set any custom port.
- **Bridge health card** in the panel (Tunnel status): direct-IP vs NAT, forward ports
  free, the recommended live port, and the full sweep results, refreshed as the bridge
  reports in. Failed/recovered tunnel alerts (Telegram + webhook) continue as before.

## Fixed

- IP detection now uses Iran-reachable services (`api.ipify.org` and friends). The old
  `ifconfig.me` fallback is blocked from Iran (HTTP 403) and silently failed there.

## Notes

- No client-side change: existing subscriptions keep working. This release is about
  standing up and monitoring the Iran bridge.
- Nova Server ships as an obfuscated build by design; Nova Proxy and the verified tools
  stay open.
- A bridge still needs an Iran VPS with a direct public IP (not behind NAT) to carry
  traffic. The readiness check now tells you before you install.
