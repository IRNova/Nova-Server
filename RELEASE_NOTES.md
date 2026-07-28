# Nova Server v1.13.1

A factory reset and an in-panel log viewer, plus the 1.13.0 feature set.

## Added

- **Factory reset (Settings, Danger zone).** One button wipes all users, inbounds,
  plans, sub-admins, tunnel, routing, nodes, and automation back to a fresh install,
  while keeping your admin login (password and 2FA) and the panel reachable (domain,
  path, certificate). Requires typing `RESET` to confirm. Owner-only.
- **In-panel log viewer (Xray settings).** Read the last 100 to 1000 lines of the
  agent, Xray, or sing-box journal right in the panel, so "why is it lagging / not
  running" is a click, not an SSH session. Owner-only.

## Fixed

- Factory reset now preserves the owner's 2FA (it lives in the settings doc), so a
  reset never silently drops your second factor.

## Also in 1.13.1 (from 1.13.0)

- Resellers and managers with a sellable-plan quality gate and prepaid balance.
- Iran bridge fronts ALL inbounds (every protocol and port), keeping the exit SNI so
  certificates validate; a payload-health gate refuses to publish links to a bridge
  that is not actually forwarding data.
- HWID device binding, per-user usage charts, node self-diagnostics.
- Preview-first user migration from Marzban, Marzneshin, 3x-ui/x-ui, s-ui, Hiddify,
  Remnawave, and Nova JSON.
- Install-on-busy-443 fix, tunnel port-collision auto-pick, Hysteria2/TUIC UDP through
  the tunnel (`accept_udp`), and full revert on disable.

## Notes

- Nova Server ships as an obfuscated build by design; Nova Proxy and the verified tools
  stay open.
- The Iran bridge is domain-oriented and needs an Iran VPS with a **direct public IP**
  (not behind NAT) to reliably carry traffic.
