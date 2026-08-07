#!/usr/bin/env bash
# =============================================================================
#  Nova Node uninstaller - removes Nova-managed services, binaries and all data.
#
#  Run on the server:
#     nova-uninstall            (installed with Nova; asks to confirm)
#     nova-uninstall --yes      (no prompt)
#
#  Or as a one-liner:
#     bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-uninstall.sh)
# =============================================================================
set -uo pipefail

c_grn=$'\033[0;32m'; c_red=$'\033[0;31m'; c_yel=$'\033[1;33m'; c_cyn=$'\033[0;36m'; c_bld=$'\033[1m'; c_rst=$'\033[0m'
say()  { printf '%s\n' "${c_cyn}==>${c_rst} $*"; }
ok()   { printf '%s\n' "${c_grn}OK${c_rst}  $*"; }
warn() { printf '%s\n' "${c_yel}!!${c_rst}  $*"; }
die()  { printf '%s\n' "${c_red}xx${c_rst}  $*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "Please run as root (sudo)."

ASSUME_YES=0
for a in "$@"; do case "$a" in -y|--yes) ASSUME_YES=1;; esac; done

if [ "$ASSUME_YES" != 1 ]; then
  printf '%s\n' "${c_yel}This removes Nova-managed services and ALL Nova data (users, configs, certs).${c_rst}"
  printf '%s' "Type 'yes' to continue: "
  read -r ans || true
  [ "$ans" = "yes" ] || die "Cancelled."
fi

OWNED_DIR=/var/lib/nova/.owned
owned() { [ -f "$OWNED_DIR/$1" ]; }

# ---- stop + disable services ------------------------------------------------
say "Stopping services"
for unit_file in /etc/systemd/system/nova-geo-*.service /etc/systemd/system/nova-tunnel-*.service; do
  [ -e "$unit_file" ] || continue
  unit_name="$(basename "$unit_file")"
  systemctl disable --now "$unit_name" >/dev/null 2>&1 || true
  case "$unit_name" in
    nova-geo-psiphon-??.service)
      cc="${unit_name#nova-geo-psiphon-}"; cc="${cc%.service}"
      rm -rf "/etc/psiphon/geo/$cc"
      ;;
  esac
done
for svc in nova-agent masterdnsvpn cottendns nova-tunnel nova-mtproto nova-mieru; do
  systemctl disable --now "$svc" >/dev/null 2>&1 || true
done
# mieru's daemon keeps its own store, so it is told to stop serving before the
# binary goes; otherwise a stale RUNNING state survives the removal.
if owned mita; then /usr/local/bin/mita stop >/dev/null 2>&1 || true; fi
if owned sing-box-service; then systemctl disable --now sing-box >/dev/null 2>&1 || true; fi
if owned psiphon; then systemctl disable --now psiphon >/dev/null 2>&1 || true; fi
if owned awg-config; then systemctl disable --now awg-quick@awg0 >/dev/null 2>&1 || true; fi
if owned tor; then
  systemctl disable --now tor >/dev/null 2>&1 || true
fi
ok "services stopped"

# ---- remove xray (official uninstaller if present, else manual) -------------
if owned xray; then
  say "Removing Nova-installed xray"
  if command -v curl >/dev/null 2>&1 && bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh 2>/dev/null)" @ remove --purge >/dev/null 2>&1; then
    ok "xray removed"
  else
    systemctl disable --now xray >/dev/null 2>&1 || true
    rm -f /usr/local/bin/xray
    rm -rf /usr/local/etc/xray /usr/local/share/xray
    rm -f /etc/systemd/system/xray.service /etc/systemd/system/xray@.service
    rm -rf /etc/systemd/system/xray.service.d
    warn "xray removed manually"
  fi
else
  say "Preserving xray because Nova has no ownership record for it"
fi

# ---- remove Nova files, units and helper commands ---------------------------
say "Removing Nova files"
if command -v ufw >/dev/null 2>&1; then
  for marker in "$OWNED_DIR"/ufw-panel-*; do
    [ -f "$marker" ] || continue
    port="${marker##*-}"
    case "$port" in *[!0-9]*|"") continue;; esac
    [ "$port" -ge 1 ] && [ "$port" -le 65535 ] || continue
    ufw --force delete allow "${port}/tcp" >/dev/null 2>&1 || true
  done
fi
rm -f /etc/systemd/system/nova-agent.service
if owned sing-box-service; then rm -f /etc/systemd/system/sing-box.service; fi
if owned psiphon; then rm -f /etc/systemd/system/psiphon.service; fi
rm -f /etc/systemd/system/masterdnsvpn.service
rm -f /etc/systemd/system/cottendns.service /etc/systemd/system/nova-tunnel.service
rm -f /etc/systemd/system/nova-geo-*.service /etc/systemd/system/nova-tunnel-*.service
rm -f /etc/systemd/system/nova-mtproto.service /etc/systemd/system/nova-mieru.service
# mieru's own configuration and state live outside /etc/nova, and only ours is
# removed: the ownership marker is what says Nova put mita there rather than the
# operator installing the distro package for something else.
if owned mita; then rm -rf /etc/mita /var/lib/mita /var/run/mita; fi
rm -rf /opt/nova-node-agent /opt/masterdnsvpn /opt/cottendns
if owned sing-box-config; then rm -f /etc/sing-box/config.json; fi
rmdir /etc/sing-box 2>/dev/null || true
if owned psiphon; then
  rm -f /etc/psiphon/psiphon-tunnel-core-x86_64
  rm -f /etc/psiphon/psiphon-tunnel-core-arm64 /etc/psiphon/psiphon.config
  rmdir /etc/psiphon/geo /etc/psiphon 2>/dev/null || true
fi
if owned awg-config; then
  rm -f /etc/amnezia/amneziawg/awg0.conf
  rmdir /etc/amnezia/amneziawg /etc/amnezia 2>/dev/null || true
fi
for artifact in sing-box-nova grpcurl backhaul backpack rathole wstunnel mtg mita; do
  if owned "$artifact"; then rm -f "/usr/local/bin/$artifact"; fi
done
# The two service accounts, but only the ones Nova created. `userdel` refuses
# while a process is still running, which is why the units are stopped above.
if owned mtg; then userdel nova-mtg >/dev/null 2>&1 || true; fi
if owned mita; then userdel mita >/dev/null 2>&1 || true; fi
rm -f /usr/local/bin/nova-passwd /usr/local/bin/nova-access /usr/local/bin/nova-unlock
rm -f /usr/local/bin/nova-tgbot /usr/local/bin/nova-uninstall
rm -f /etc/sysctl.d/99-nova-net.conf
if owned awg-config; then rm -f /etc/sysctl.d/99-nova-awg.conf; fi
rm -rf /var/lib/nova /etc/nova /var/log/nova
# The Telegram proxy's config lives outside /etc/nova on purpose (that directory
# is too tightly held for an unprivileged service to traverse), so it has to be
# named here or the secret would survive an uninstall.
rm -rf /etc/nova-mtproto
sysctl --system >/dev/null 2>&1 || true
systemctl daemon-reload 2>/dev/null || true
systemctl reset-failed 2>/dev/null || true
ok "Nova files removed"

echo
printf '%s\n' "${c_grn}${c_bld}Nova has been uninstalled.${c_rst}"
printf '  %s\n' "Nova-owned services, binaries, firewall rules, panel, and data are gone."
printf '  %s\n' "Pre-existing Tor, xray, Psiphon, and command-line tools were preserved."
echo
