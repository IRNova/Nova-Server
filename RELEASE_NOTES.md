# Nova Server v1.13.0

Resell with confidence, front every inbound through Iran, bind devices, and see exactly what each user does, on top of the central fleet.

## Added

- **Resellers and managers, done safely.** Create staff accounts with any capability
  set. Resellers build users only from the sellable plans you define (real nodes and
  protocols, not the free front), each provision charges their prepaid balance, and a
  running balance sits at the top of their panel with a "please recharge" prompt when
  it runs out. They see only their own users; you see everyone.
- **Iran bridge fronts ALL inbounds, not just 443.** With a tunnel active, every local
  inbound (VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, WireGuard) now carries
  the Iran bridge IP as its connection address while keeping the exit's real SNI, so
  certificates still validate. One click points every user link at the bridge; disabling
  the tunnel reverts them all. The bridge forwards every inbound's port automatically.
- **HWID device binding.** An optional per-user device limit that counts distinct
  hardware IDs (clients that report `x-hwid`), on top of the existing IP limit. See a
  user's bound-device count and reset it from their detail page.
- **Per-user usage chart.** A daily up/down usage graph on each user, alongside the
  existing dashboard and per-inbound traffic charts.
- **Preview-first user migration.** Import user accounts from **Marzban, Marzneshin,
  3x-ui / x-ui, s-ui, Hiddify, Remnawave**, and Nova JSON, with a preview before you
  commit. Nova also exports portable JSON and CSV. Quotas, expiry, used traffic, status,
  notes, reset policy, and device/IP limits are preserved.
- **Node self-diagnostics.** A one-click health check that verifies each config is
  actually listening and reachable, plus a firewall and reserved-ports view with
  one-click fixes, so a dead config is caught before a user pastes it into their app.
- **Tunnel payload-health detection.** The panel distinguishes "control channel up but
  no data forwarding" from a genuinely working tunnel, and gates address publishing on a
  real end-to-end probe, so a half-up bridge never silently points links at a dead path.
- **Richer dashboard**: business-focused KPI cards (active, expiring, expired), a
  reseller ledger, and a cleaner, reorganized navigation.

## Fixed

- **Install on a busy 443.** If port 443 is already taken, the installer asks for an
  alternate front port and every generated panel/subscription link uses it.
- **Tunnel would not start on 443 or 8443.** The tunnel control port must differ from
  every forwarded port; the panel now auto-picks a free control port and blocks a
  colliding one, with a clear message.
- **Hysteria2/TUIC through the tunnel.** A UDP forward now sets Backhaul's `accept_udp`
  so UDP protocols actually survive the bridge instead of silently opening TCP only.
- **Disable now fully reverts.** Turning a tunnel off returns every config, including
  per-country exits, to the real host, with nothing left pointing at the bridge.
- Rathole advertises only its deployable transports; hardened auth (dated Telegram
  webapp validation), and assorted robustness fixes.

## Notes

- Nova Server ships as an obfuscated build by design; Nova Proxy and the verified tools
  stay open. See the project for details.
- The Iran bridge is a domain-oriented feature and needs an Iran VPS with a **direct
  public IP** (not behind NAT) to reliably carry traffic.
