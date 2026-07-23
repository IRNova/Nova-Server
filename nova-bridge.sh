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
while [ $# -gt 0 ]; do
  case "$1" in
    --backend)     BACKEND="$2"; shift 2;;
    --exec-b64)    EXEC_B64="$2"; shift 2;;
    --config-b64)  CONFIG_B64="$2"; shift 2;;
    --config-path) CONFIG_PATH="$2"; shift 2;;
    --cert)        WANT_CERT=1; shift;;
    --port)        PORT="$2"; shift 2;;
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

systemctl daemon-reload
systemctl enable ${UNIT} >/dev/null 2>&1 || true
systemctl restart ${UNIT} || die "Could not start the tunnel."
sleep 2

# ---- summary -----------------------------------------------------------------
echo
if systemctl is-active --quiet ${UNIT}; then
  printf '%s\n' "${c_grn}${c_bld}Nova bridge is up.${c_rst}"
else
  printf '%s\n' "${c_yel}${c_bld}Bridge installed, but the service is not active yet.${c_rst}"
  printf '  %s\n' "Check it with:  journalctl -u ${UNIT} -n 40 --no-pager"
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
