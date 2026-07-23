#!/usr/bin/env bash
# =============================================================================
#  Nova Node uninstaller - removes the Nova agent, xray, sing-box and all data.
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
  printf '%s\n' "${c_yel}This removes Nova, xray, sing-box and ALL Nova data (users, configs, certs).${c_rst}"
  printf '%s' "Type 'yes' to continue: "
  read -r ans || true
  [ "$ans" = "yes" ] || die "Cancelled."
fi

# ---- stop + disable services ------------------------------------------------
say "Stopping services"
# Nova geo-exit units (per-country Tor/Psiphon), if any.
for u in $(systemctl list-units --all --type=service 2>/dev/null | grep -oE 'nova-geo-[a-z0-9-]+\.service' | sort -u); do
  systemctl disable --now "$u" >/dev/null 2>&1 || true
done
for svc in nova-agent sing-box tor; do
  systemctl disable --now "$svc" >/dev/null 2>&1 || true
done
ok "services stopped"

# ---- remove xray (official uninstaller if present, else manual) -------------
say "Removing xray"
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

# ---- remove Nova files, units and helper commands ---------------------------
say "Removing Nova files"
rm -f /etc/systemd/system/nova-agent.service /etc/systemd/system/sing-box.service
rm -f /etc/systemd/system/nova-geo-*.service
rm -rf /opt/nova-node-agent /var/lib/nova /etc/nova /var/log/nova
rm -rf /etc/sing-box
rm -f /usr/local/bin/sing-box-nova
rm -f /usr/local/bin/nova-passwd /usr/local/bin/nova-tgbot /usr/local/bin/nova-uninstall
systemctl daemon-reload 2>/dev/null || true
systemctl reset-failed 2>/dev/null || true
ok "Nova files removed"

echo
printf '%s\n' "${c_grn}${c_bld}Nova has been uninstalled.${c_rst}"
printf '  %s\n' "xray, sing-box, the agent, the panel, and all Nova data are gone."
printf '  %s\n' "Tor and grpcurl (if installed) were left in place; remove with apt if you like."
echo
