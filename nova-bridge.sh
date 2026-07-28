#!/usr/bin/env bash
# =============================================================================
#  Nova Bridge  -  lightweight Iran-side tunnel installer.
#
#  This sets up ONLY the tunnel "server" (bridge) on an Iran VPS: it installs the
#  one selected tunnel backend, writes the config, and runs it as a service. It
#  does NOT install xray, sing-box, the panel, or any of the heavier Nova stack,
#  so it works on a restricted Iran box with minimal prerequisites.
#
#  You do not run this by hand. On your FOREIGN Nova panel, open Tunnels, set the
#  exit up, and copy the one-line bridge command it shows you. Run that here.
#
#  Flags (all supplied by the panel command):
#     --backend <backhaul|backpack|rathole|wstunnel>
#     --exec-b64 <base64 of the full ExecStart line>
#     --config-b64 <base64 of the config file>   (omitted for wstunnel)
#     --config-path <path>                        (omitted for wstunnel)
#     --cert                                      (mint a self-signed TLS cert)
#     --port <n>                                  (informational, for the summary)
# =============================================================================
set -euo pipefail

c_grn=$'\033[0;32m'; c_red=$'\033[0;31m'; c_yel=$'\033[1;33m'; c_cyn=$'\033[0;36m'; c_bld=$'\033[1m'; c_rst=$'\033[0m'
say()  { printf '%s\n' "${c_cyn}==>${c_rst} $*"; }
ok()   { printf '%s\n' "${c_grn}OK${c_rst}  $*"; }
warn() { printf '%s\n' "${c_yel}!!${c_rst}  $*"; }
die()  { printf '%s\n' "${c_red}xx${c_rst}  $*" >&2; exit 1; }

usage() {
  cat <<USAGE
Nova Bridge - lightweight Iran-side tunnel installer.

You normally do NOT type these flags yourself. On your FOREIGN Nova panel open
Tunnels, configure the tunnel, and click "Generate the Iran bridge command", then
run the ready one-liner it gives you on this Iran VPS.

Flags (filled in by the panel command):
  --backend <backhaul|backpack|rathole|wstunnel>
  --exec-b64 <base64 of the ExecStart line>
  --config-b64 <base64 of the config file>   (omitted for wstunnel)
  --config-path <path>                        (omitted for wstunnel)
  --cert                                      (mint a self-signed TLS cert)
  --port <n>                                  (informational)

Remove the bridge later with:  systemctl disable --now nova-tunnel
USAGE
}
case "${1:-}" in -h|--help|"") usage; exit 0;; esac

[ "$(id -u)" = 0 ] || die "Please run as root (sudo)."

BACKEND=""; EXEC_B64=""; CONFIG_B64=""; CONFIG_PATH=""; WANT_CERT=0; PORT=""
FORWARDS=""; REPORT_URL=""; REPORT_TOKEN=""
while [ $# -gt 0 ]; do
  case "$1" in
    --backend)     BACKEND="$2"; shift 2;;
    --exec-b64)    EXEC_B64="$2"; shift 2;;
    --config-b64)  CONFIG_B64="$2"; shift 2;;
    --config-path) CONFIG_PATH="$2"; shift 2;;
    --cert)        WANT_CERT=1; shift;;
    --port)        PORT="$2"; shift 2;;
    # Ports this bridge forwards to end-users, e.g. "443,8443/udp". Used to open
    # the firewall for exactly what the tunnel carries.
    --forwards)    FORWARDS="$2"; shift 2;;
    # Optional phone-home: after the bridge is up, tell the foreign exit this
    # server's IP so the panel auto-fills the bridge address. Token-gated.
    --report-url)  REPORT_URL="$2"; shift 2;;
    --report-token) REPORT_TOKEN="$2"; shift 2;;
    *) die "unknown argument: $1";;
  esac
done
[ -n "$BACKEND" ] || die "missing --backend"
[ -n "$EXEC_B64" ] || die "missing --exec-b64"

CONF_DIR=/etc/nova/tunnel
UNIT=nova-tunnel

# ---- prerequisites -----------------------------------------------------------
say "Installing prerequisites"
export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y curl tar unzip ca-certificates openssl >/dev/null 2>&1 || true
fi

arch="$(uname -m)"
case "$arch" in
  x86_64)        garch="amd64"; tarch="x86_64";;
  aarch64|arm64) garch="arm64"; tarch="aarch64";;
  *)             garch="amd64"; tarch="x86_64";;
esac

gh_asset() { # repo  match
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
    | grep browser_download_url | grep -i "$2" | head -1 | cut -d'"' -f4
}

# ---- install the one selected backend ---------------------------------------
install_backend() {
  command -v "$BACKEND" >/dev/null 2>&1 && { ok "$BACKEND already installed"; return; }
  say "Installing $BACKEND"
  case "$BACKEND" in
    backhaul)
      curl -fsSL -o /tmp/backhaul.tgz "https://github.com/Musixal/Backhaul/releases/latest/download/backhaul_linux_${garch}.tar.gz" \
        && tar -xzf /tmp/backhaul.tgz -C /usr/local/bin backhaul 2>/dev/null \
        && chmod +x /usr/local/bin/backhaul || die "Could not install Backhaul."
      ;;
    backpack)
      bpurl="$(gh_asset AminMGMT/BackPack "backpack_linux_${garch}.tar.gz")"
      bpsum="$(gh_asset AminMGMT/BackPack "SHA256SUMS")"
      [ -n "$bpurl" ] && curl -fsSL -o /tmp/backpack.tgz "$bpurl" && curl -fsSL -o /tmp/backpack.sums "${bpsum:-/dev/null}" 2>/dev/null || die "Could not download BackPack."
      want="$(grep -i "backpack_linux_${garch}.tar.gz" /tmp/backpack.sums 2>/dev/null | awk '{print $1}' | head -1)"
      got="$(sha256sum /tmp/backpack.tgz 2>/dev/null | awk '{print $1}')"
      [ -n "$want" ] && [ "$want" = "$got" ] && tar -xzf /tmp/backpack.tgz -C /usr/local/bin backpack 2>/dev/null \
        && chmod +x /usr/local/bin/backpack || die "BackPack checksum mismatch or extract failed."
      ok "BackPack installed (checksum verified)"; return
      ;;
    rathole)
      rmatch="x86_64-unknown-linux-gnu.zip"; [ "$tarch" = "aarch64" ] && rmatch="aarch64-unknown-linux-musl.zip"
      rurl="$(gh_asset rapiz1/rathole "$rmatch")"
      [ -n "$rurl" ] && curl -fsSL -o /tmp/rathole.zip "$rurl" \
        && unzip -o /tmp/rathole.zip -d /usr/local/bin rathole >/dev/null 2>&1 \
        && chmod +x /usr/local/bin/rathole || die "Could not install rathole."
      ;;
    wstunnel)
      wurl="$(gh_asset erebe/wstunnel "linux_${garch}.tar.gz")"
      [ -n "$wurl" ] && curl -fsSL -o /tmp/wstunnel.tgz "$wurl" \
        && tar -xzf /tmp/wstunnel.tgz -C /usr/local/bin wstunnel 2>/dev/null \
        && chmod +x /usr/local/bin/wstunnel || die "Could not install wstunnel."
      ;;
    *) die "unknown backend: $BACKEND";;
  esac
  ok "$BACKEND installed"
}
install_backend

# ---- write config + optional cert -------------------------------------------
mkdir -p "$CONF_DIR" && chmod 700 "$CONF_DIR"
if [ "$WANT_CERT" = 1 ]; then
  if [ ! -s "$CONF_DIR/cert.pem" ] || [ ! -s "$CONF_DIR/key.pem" ]; then
    say "Generating a self-signed tunnel certificate"
    openssl req -x509 -newkey rsa:2048 -nodes -keyout "$CONF_DIR/key.pem" -out "$CONF_DIR/cert.pem" \
      -days 3650 -subj '/CN=nova-tunnel' >/dev/null 2>&1 || warn "could not mint a cert; a TLS transport may fail."
  fi
fi
if [ -n "$CONFIG_B64" ] && [ -n "$CONFIG_PATH" ]; then
  printf '%s' "$CONFIG_B64" | base64 -d > "$CONFIG_PATH" || die "could not write the tunnel config."
  chmod 600 "$CONFIG_PATH"
  ok "config written to $CONFIG_PATH"
fi

# ---- systemd unit ------------------------------------------------------------
EXEC_LINE="$(printf '%s' "$EXEC_B64" | base64 -d)"
[ -n "$EXEC_LINE" ] || die "could not decode the service command."
cat > /etc/systemd/system/${UNIT}.service <<UNITEOF
[Unit]
Description=Nova bridge tunnel (Iran side)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${EXEC_LINE}
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
UNITEOF

# ---- firewall: open exactly what the tunnel carries -------------------------
# The tunnel control port (TCP) plus each forwarded port, protocol-aware. Opened
# before the service starts so the very first client can connect.
fw_specs() {
  [ -n "$PORT" ] && printf '%s\n' "$PORT/tcp"
  local f num
  IFS=',' read -ra _fw <<< "${FORWARDS:-443,8443/udp}"
  for f in "${_fw[@]}"; do
    f="$(printf '%s' "$f" | tr -d '[:space:]')"; [ -n "$f" ] || continue
    num="${f%%/*}"
    case "$f" in *['/']udp) printf '%s\n' "$num/udp";; *) printf '%s\n' "$num/tcp";; esac
  done
}
open_firewall() {
  local specs; specs="$(fw_specs | sort -u)"
  [ -n "$specs" ] || return 0
  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi active; then
    while read -r s; do [ -n "$s" ] && ufw allow "$s" >/dev/null 2>&1 || true; done <<< "$specs"
    ok "Opened firewall (ufw): $(echo $specs)"
  elif command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
    while read -r s; do [ -n "$s" ] && firewall-cmd --permanent --add-port="$s" >/dev/null 2>&1 || true; done <<< "$specs"
    firewall-cmd --reload >/dev/null 2>&1 || true
    ok "Opened firewall (firewalld): $(echo $specs)"
  elif command -v iptables >/dev/null 2>&1; then
    while read -r s; do
      [ -n "$s" ] || continue
      local n="${s%/*}" p="${s#*/}"
      iptables -C INPUT -p "$p" --dport "$n" -j ACCEPT 2>/dev/null || iptables -I INPUT -p "$p" --dport "$n" -j ACCEPT 2>/dev/null || true
    done <<< "$specs"
    ok "Opened firewall (iptables): $(echo $specs)"
  else
    warn "No firewall manager found. If these ports are filtered, open them: $(echo $specs)"
  fi
}

# ---- diagnose a failed start -------------------------------------------------
diagnose_failure() {
  printf '%s\n' "${c_red}${c_bld}The tunnel did not start.${c_rst}"
  local logs badport holder
  logs="$(journalctl -u ${UNIT} -n 25 --no-pager 2>/dev/null || true)"
  if printf '%s' "$logs" | grep -qi 'address already in use'; then
    badport="$(printf '%s' "$logs" | grep -i 'address already in use' | grep -oE ':[0-9]+' | tr -d ':' | head -1)"
    printf '  %s\n' "Reason: port ${badport:-(the tunnel port)} on THIS server is already used by"
    printf '  %s\n' "another program, so the tunnel could not bind it."
    if [ -n "$badport" ] && command -v ss >/dev/null 2>&1; then
      holder="$(ss -tlnpH "sport = :${badport}" 2>/dev/null | grep -oE '"[^"]+"' | head -1 | tr -d '"')"
      [ -n "$holder" ] && printf '  %s\n' "Currently held by: ${holder}"
    fi
    printf '%s\n' "  ${c_bld}Fix:${c_rst} on your FOREIGN panel, change the tunnel port to a free one and"
    printf '  %s\n' "regenerate this command. The tunnel port must differ from 443 and 8443."
  else
    printf '  %s\n' "Last log lines:"
    printf '%s\n' "$logs" | tail -8 | sed 's/^/    /'
    printf '  %s\n' "Full log:  journalctl -u ${UNIT} -n 40 --no-pager"
  fi
}

# ---- best-effort phone-home --------------------------------------------------
# Tell the foreign exit this server's IP so the panel auto-fills the bridge
# address. Iran->foreign can be throttled, so keep it short and never fail the
# install if it does not get through; the manual bridge-address entry still works.
phone_home() {
  [ -n "$REPORT_URL" ] && [ -n "$REPORT_TOKEN" ] || return 0
  # The exit sees only 127.0.0.1 for requests through its front, so this server
  # detects and reports its own public IP. Try a few echo services (some may be
  # filtered from Iran); give up quietly if none answer.
  local ip
  ip="$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null \
        || curl -fsS --max-time 5 https://ifconfig.me 2>/dev/null \
        || curl -fsS --max-time 5 https://icanhazip.com 2>/dev/null)"
  ip="$(printf '%s' "$ip" | tr -d '[:space:]')"
  if [ -z "$ip" ]; then
    warn "Could not detect this server's public IP to auto-report; set the Bridge address by hand: this-server-ip:${PORT}"
    return 0
  fi
  if curl -fsS --max-time 8 -X POST "$REPORT_URL" -H 'content-type: application/json' \
       -d "{\"token\":\"${REPORT_TOKEN}\",\"ip\":\"${ip}\",\"port\":\"${PORT}\"}" >/dev/null 2>&1; then
    ok "Reported this server (${ip}:${PORT}) to the foreign panel; bridge address auto-filled."
  else
    warn "Could not reach the panel to auto-report; set the Bridge address by hand: ${ip}:${PORT}"
  fi
}

systemctl daemon-reload
systemctl enable ${UNIT} >/dev/null 2>&1 || true
open_firewall
systemctl restart ${UNIT} || die "Could not start the tunnel."
sleep 2

# ---- summary -----------------------------------------------------------------
echo
if systemctl is-active --quiet ${UNIT}; then
  printf '%s\n' "${c_grn}${c_bld}Nova bridge is up.${c_rst}"
  phone_home
else
  diagnose_failure
fi
echo
printf '  %-14s %s\n' "Backend:" "$BACKEND"
[ -n "$PORT" ] && printf '  %-14s %s\n' "Tunnel port:" "$PORT"
printf '  %-14s %s\n' "Service:" "${UNIT} (systemd)"
echo
printf '  %s\n' "End-users now connect to THIS server's IP. Point your Nova subscriptions"
printf '  %s\n' "at this Iran IP; traffic tunnels to your foreign exit automatically."
printf '  %s\n' "Manage:  systemctl status ${UNIT}   |   remove:  systemctl disable --now ${UNIT}"
echo
