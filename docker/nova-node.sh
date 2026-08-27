#!/usr/bin/env bash
# =============================================================================
#  Nova Node: one-line VPS installer for the full Nova panel
#
#  Installs xray-core + the Nova node agent and wires them together so ONE
#  public port (443) serves both the admin panel and the tunnel:
#    - xray terminates TLS on :443 and dispatches by path
#        <wsPath>     -> the VLESS/VMess/Trojan tunnel inbounds (loopback)
#        everything else -> the agent's HTTP panel + browser dashboard
#  The agent is managed from the Nova app, a browser (https://<your-vps>), or
#  the built-in Telegram bot. Runs entirely on YOUR server; nothing is sent out.
#
#  Run on your own VPS (Debian/Ubuntu):
#     bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
#
#  Options (env vars):
#     NOVA_ADMIN_PASS=...   panel admin password (a random one is generated if unset)
#     NOVA_DOMAIN=...       a domain that points at this server (optional). Without
#                          one, the node uses the public IP with a self-signed cert
#                          and the app's "no domain" switch.
#     NOVA_PANEL_PATH=...   secret panel subpath (stealth). Unset = a random one is
#                          generated on a fresh install; "none" = panel at the root.
#     NOVA_PANEL_PORT=...   extra HTTPS port that serves only the panel (optional).
#     NOVA_NO_PROMPT=1      never ask questions (use env values / defaults).
#
#  Managed-node (fleet) mode: install a box that is driven from a main panel,
#  with no panel of its own. The main panel's "Add node" button prints the exact
#  one-liner, which sets:
#     NOVA_JOIN_URL=...     the main panel's address
#     NOVA_JOIN_TOKEN=...   a one-time join token from that panel
#  The node installs, registers itself with the main panel, and then locks its
#  own panel (a stub page, no sign-in). Everything else installs the same way.
# =============================================================================
set -euo pipefail

# The public release channel. A preview or mirror copy of this script overrides
# the two URLs below; either way the node is pinned to whatever it installed
# from, and PUBLIC_TARBALL_URL is what "is this the public build" is measured
# against, so it must keep pointing at the real release.
PUBLIC_TARBALL_URL="https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node-agent.tar.gz"
TARBALL_URL="${NOVA_TARBALL_URL:-$PUBLIC_TARBALL_URL}"
PUBLIC_VERSION_URL="https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node-agent.version"
VERSION_URL="${NOVA_VERSION_URL:-$PUBLIC_VERSION_URL}"
# Set to 1 only in a published preview/mirror copy of this script. Env cannot
# turn it on, so a pasted NOVA_TARBALL_URL= cannot make itself permanent.
PERSIST_CHANNEL=0
AGENT_DIR=/opt/nova-node-agent
CERT_DIR=/etc/nova
DB_DIR=/var/lib/nova

c_grn=$'\033[0;32m'; c_red=$'\033[0;31m'; c_yel=$'\033[1;33m'; c_cyn=$'\033[0;36m'; c_bld=$'\033[1m'; c_rst=$'\033[0m'
say()  { printf '%s\n' "${c_cyn}==>${c_rst} $*"; }
ok()   { printf '%s\n' "${c_grn}OK${c_rst}  $*"; }
warn() { printf '%s\n' "${c_yel}!!${c_rst}  $*"; }
die()  { printf '%s\n' "${c_red}xx${c_rst}  $*" >&2; exit 1; }
mark_owned() {
  install -d -m 700 "$DB_DIR/.owned"
  : > "$DB_DIR/.owned/$1"
  chmod 600 "$DB_DIR/.owned/$1"
}

[ "$(id -u)" = 0 ] || die "Please run as root (sudo)."

# ---- setup questions ---------------------------------------------------------
# Asked up front so the rest of the install runs unattended. Reads /dev/tty so
# both `bash <(curl ...)` and `curl ... | bash` forms work; with no terminal (or
# NOVA_NO_PROMPT=1) the env values / defaults are used silently.
ask() { # prompt  ->  REPLY
  REPLY=""
  [ "${NOVA_NO_PROMPT:-0}" = 1 ] && return 0
  # Whether /dev/tty can actually be OPENED, not whether the device node is
  # readable. A process with no controlling terminal (the installer bot's ssh,
  # or `ssh host 'bash <(curl ...)'`) still passes `[ -r /dev/tty ]`, because
  # that only checks permissions on the node, and then open() fails with ENXIO
  # and bash prints "/dev/tty: No such device or address" for every prompt. The
  # install was always fine; it just looked like it had errored three times.
  { : > /dev/tty; } 2>/dev/null || return 0
  printf '%s' "${c_cyn}?${c_rst} $1 " > /dev/tty 2>/dev/null || return 0
  IFS= read -r REPLY < /dev/tty || REPLY=""
}

# Managed-node mode when the main panel handed us a join URL + token. The node
# has no panel of its own, so the panel path/port questions do not apply; a
# domain is still honored (a node with a real cert is nicer for the parent).
NODE_MODE=0
if [ -n "${NOVA_JOIN_URL:-}" ] && [ -n "${NOVA_JOIN_TOKEN:-}" ]; then
  NODE_MODE=1
  NOVA_NO_PROMPT=1
  say "Managed-node install: this box will be controlled from ${NOVA_JOIN_URL}"
fi

if [ "$NODE_MODE" = 0 ] && [ -z "${NOVA_DOMAIN:-}" ]; then
  ask "Do you have a domain pointing at this server? It gets a trusted (Let's Encrypt) certificate automatically. [y/N]"
  case "$REPLY" in
    [yY]*)
      ask "Domain (e.g. node.example.com):"
      NOVA_DOMAIN="$(printf '%s' "$REPLY" | tr -d '[:space:]')"
      if [ -n "$NOVA_DOMAIN" ]; then
        ask "Email for certificate expiry notices (optional, Enter to skip):"
        NOVA_DOMAIN_EMAIL="$(printf '%s' "$REPLY" | tr -d '[:space:]')"
      fi
      ;;
  esac
fi

if [ "$NODE_MODE" = 0 ] && [ -z "${NOVA_PANEL_PATH:-}" ]; then
  ask "Secret panel path: hides the panel behind https://<server>/<path>/ so scanners see nothing. [Enter = auto-generate / type your own / \"none\" = panel at the root]"
  case "$(printf '%s' "$REPLY" | tr -d '[:space:]')" in
    "")     NOVA_PANEL_PATH="" ;;   # stays empty -> auto-generated below on a fresh install
    none|no) NOVA_PANEL_PATH="none" ;;
    *)      NOVA_PANEL_PATH="$(printf '%s' "$REPLY" | tr -d '[:space:]/')" ;;
  esac
fi
if [ -n "${NOVA_PANEL_PATH:-}" ] && [ "$NOVA_PANEL_PATH" != "none" ] \
   && ! printf '%s' "$NOVA_PANEL_PATH" | grep -qE '^[A-Za-z0-9_-]{3,64}$'; then
  warn "Panel path must be 3-64 letters/digits/-/_ ; a random one will be generated instead."
  NOVA_PANEL_PATH=""
fi

if [ "$NODE_MODE" = 0 ] && [ -z "${NOVA_PANEL_PORT:-}" ]; then
  ask "Extra panel port (the panel also gets its own HTTPS port, e.g. 2053). [Enter = none, panel stays on 443]"
  NOVA_PANEL_PORT="$(printf '%s' "$REPLY" | tr -d '[:space:]')"
fi
if [ -n "${NOVA_PANEL_PORT:-}" ] && ! printf '%s' "$NOVA_PANEL_PORT" | grep -qE '^[0-9]{1,5}$'; then
  warn "Panel port must be a number; skipping the extra port."
  NOVA_PANEL_PORT=""
fi

# Front port: Nova's panel + proxy front normally binds :443. If :443 is already
# taken by another service on this box, offer an alternate so the WHOLE front (and
# every generated panel/subscription link) uses that port instead. Only relevant
# for a full panel install; a managed node keeps :443.
FRONT_PORT="${NOVA_FRONT_PORT:-443}"
if [ "$NODE_MODE" = 0 ] && [ "$FRONT_PORT" = 443 ] && command -v ss >/dev/null 2>&1; then
  if ss -tlnH "sport = :443" 2>/dev/null | grep -q . && ! ss -tlnpH "sport = :443" 2>/dev/null | grep -qi xray; then
    ask ":443 is already used by another service on this server. Enter an alternate HTTPS port for the Nova panel + proxy (e.g. 4430) so the whole front and its links use it. [Enter = keep 443]"
    ALT="$(printf '%s' "$REPLY" | tr -d '[:space:]')"
    if printf '%s' "$ALT" | grep -qE '^[0-9]{1,5}$' && [ "$ALT" -ge 1 ] && [ "$ALT" -le 65535 ] && [ "$ALT" != 443 ]; then
      FRONT_PORT="$ALT"
      warn "Nova will serve its front on :$FRONT_PORT. Make sure that port is open to the internet."
    fi
  fi
fi

# ---- ports -------------------------------------------------------------------
# What this install will bind, said out loud before it binds anything.
#
# Reported because an operator running Nova alongside other services asked for
# it: they had moved a dockerised Nova to :4443 and had no way to know what else
# Nova was going to take. Nova asks about :443 and the extra panel port above;
# everything else was silent until something failed to start.
#
# The two loopback ports are the ones this can actually FIX without asking. They
# are internal (the agent's own HTTP port and xray's gRPC API), nothing outside
# the box reaches them, and their numbers are written to agent.env, so moving
# one off a collision costs nothing and needs no decision from anybody. A public
# port is the opposite: moving it changes every link this node hands out, so
# those are reported and left alone.
port_busy() {
  command -v ss >/dev/null 2>&1 || return 1
  ss -tlnH "sport = :$1" 2>/dev/null | grep -q .
}
# The first free port at or after $1, giving up after 40 tries.
free_port_from() {
  _p="$1"; _n=0
  while [ "$_n" -lt 40 ]; do
    port_busy "$_p" || { printf '%s' "$_p"; return 0; }
    _p=$((_p + 1)); _n=$((_n + 1))
  done
  printf '%s' "$1"
}

# An existing install KEEPS the port it already has, and that is the whole rule.
#
# Nova's own agent is listening on 8088 during a re-run, so probing for a free
# port finds its own process and walks to 8089. The agent would move; xray's
# front, which falls back to the agent by number, would not, and the panel and
# every /sub would answer on :443 with nothing behind them. The readiness poll
# below would still pass, because it reads the new port, so the installer would
# print a clean success over a node whose public surface just died. Every
# further re-run would walk it again.
#
# The :443 probe twenty lines up already excludes Nova's own process for exactly
# this reason. This does it by remembering rather than by sniffing, because the
# answer is written down: a port only gets chosen on a node that has none.
PREV_AGENT_PORT="$(sed -n 's/^NOVA_PORT=//p' "$CERT_DIR/agent.env" 2>/dev/null | tail -n 1)"
case "$PREV_AGENT_PORT" in ''|*[!0-9]*) PREV_AGENT_PORT="" ;; esac
PREV_API_PORT="$(sed -n 's/^NOVA_XRAY_API=127\.0\.0\.1://p' "$CERT_DIR/agent.env" 2>/dev/null | tail -n 1)"
case "$PREV_API_PORT" in ''|*[!0-9]*) PREV_API_PORT="" ;; esac

NOVA_AGENT_PORT="${PREV_AGENT_PORT:-$(free_port_from 8088)}"
NOVA_XRAY_API_PORT="${PREV_API_PORT:-$(free_port_from 10085)}"
[ "$NOVA_AGENT_PORT" != 8088 ] \
  && warn "127.0.0.1:8088 is in use, so the Nova agent will listen on 127.0.0.1:$NOVA_AGENT_PORT instead."
[ "$NOVA_XRAY_API_PORT" != 10085 ] \
  && warn "127.0.0.1:10085 is in use, so the xray API will listen on 127.0.0.1:$NOVA_XRAY_API_PORT instead."

say "Ports this install will use"
printf '   %-22s %s\n' "${FRONT_PORT:-443}/tcp" "panel and proxy front (public)" > /dev/tty 2>/dev/null || true
[ -n "${NOVA_PANEL_PORT:-}" ] \
  && { printf '   %-22s %s\n' "$NOVA_PANEL_PORT/tcp" "extra panel port (public)" > /dev/tty 2>/dev/null || true; }
printf '   %-22s %s\n' "127.0.0.1:$NOVA_AGENT_PORT" "agent, loopback only" > /dev/tty 2>/dev/null || true
printf '   %-22s %s\n' "127.0.0.1:$NOVA_XRAY_API_PORT" "xray API, loopback only" > /dev/tty 2>/dev/null || true
printf '   %s\n' "Protocol ports (mieru, MTProto, Hysteria2, AmneziaWG, Tor, Psiphon) are chosen in the panel later, and the panel refuses a port another Nova service already holds." > /dev/tty 2>/dev/null || true

# A public port already in use is reported and NOT changed. Nova cannot pick a
# different one on the operator's behalf here: the front port is written into
# every subscription and share link this node produces, so moving it silently
# would hand customers links to a port the operator never agreed to.
for _pp in "${FRONT_PORT:-443}" ${NOVA_PANEL_PORT:-}; do
  # Nova's own xray holds this on every re-run; warning about it would train an
  # operator to ignore the one message that matters. Same exclusion the :443
  # prompt above uses.
  if port_busy "$_pp" && ! ss -tlnpH "sport = :$_pp" 2>/dev/null | grep -qi xray; then
    warn "Port $_pp is already in use by another service. Nova will try to bind it anyway and may fail to start; free it, or rerun with NOVA_FRONT_PORT set to a port that is free."
  fi
done

# ---- preflight ---------------------------------------------------------------
say "Installing prerequisites"
export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y curl unzip ca-certificates openssl tar >/dev/null 2>&1 \
    || die "Could not install prerequisites via apt-get."
else
  die "This installer targets Debian/Ubuntu (apt-get not found)."
fi

# ---- low-memory boxes: add swap rather than fail halfway ---------------------
# Reported from the field: "on 512 MB RAM the install is simply not possible,
# but with swap I ran it for an hour with no problem". That operator was right,
# and they had to work it out themselves because the installer said nothing.
#
# What actually runs out: `apt-get install nodejs` and the Node runtime itself
# are the peaks, so the failure lands in the middle of the install with an
# out-of-memory message from apt rather than anything mentioning memory. A
# little swap carries the box through, and it stays useful afterwards because
# the agent, xray and sing-box all sit resident.
#
# Deliberately conservative: swap is only ADDED when there is none at all, the
# file is sized once and never resized, and any failure is a warning rather
# than a stop, because plenty of 512 MB boxes have swap already or run a
# provider image that forbids swapfiles. Nova never removes an operator's own
# swap, and the ownership marker means the uninstaller only removes a file this
# script created.
mem_mb="$(awk '/^MemTotal:/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)"
swap_mb="$(awk '/^SwapTotal:/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)"
if [ "${mem_mb:-0}" -gt 0 ] && [ "$mem_mb" -lt 1024 ] && [ "${swap_mb:-0}" -lt 256 ]; then
  say "Only ${mem_mb} MB of RAM and no swap; adding a 1 GB swap file"
  if [ ! -e /swapfile ] \
     && { fallocate -l 1G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=1024 status=none 2>/dev/null; } \
     && chmod 600 /swapfile && mkswap /swapfile >/dev/null 2>&1 && swapon /swapfile 2>/dev/null; then
    grep -q '^/swapfile ' /etc/fstab 2>/dev/null || printf '/swapfile none swap sw 0 0\n' >> /etc/fstab
    mark_owned swapfile
    ok "swap enabled (1 GB), so the install and the panel have room"
  else
    # Clean up a half-made swap file. Some hosts allow the file but refuse
    # swapon (containers, and providers that block it), and leaving a stray 1 GB
    # behind takes disk from the very box that had none to spare. Only ever the
    # file this branch just created, never one that already existed.
    if [ ! -f "$DB_DIR/.owned/swapfile" ] && [ -e /swapfile ] && ! swapon --show 2>/dev/null | grep -q '^/swapfile '; then
      rm -f /swapfile
    fi
    warn "Could not add swap. On ${mem_mb} MB the install may fail; add swap yourself and re-run."
  fi
fi

# ---- Node 24 -----------------------------------------------------------------
need_node=1
if command -v node >/dev/null 2>&1; then
  maj="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  [ "${maj:-0}" -ge 24 ] && need_node=0
fi
if [ "$need_node" = 1 ]; then
  say "Installing Node.js 24"
  curl -fsSL https://deb.nodesource.com/setup_24.x | bash - >/dev/null 2>&1 \
    || die "Could not add the NodeSource repository."
  apt-get install -y nodejs >/dev/null 2>&1 || die "Could not install Node.js."
fi
ok "node $(node -v)"

# Build JSON request bodies without shell interpolation. Arguments are sent to
# Node over a NUL-delimited stdin stream, so quotes, backslashes and newlines in
# operator input stay data and never alter the JSON structure.
json_body() { # key type value ... ; type = string|boolean|number|json
  printf '%s\0' "$@" | node -e '
    const fs = require("node:fs");
    const parts = fs.readFileSync(0).toString("utf8").split("\0");
    if (parts.at(-1) === "") parts.pop();
    if (parts.length % 3) process.exit(2);
    const out = {};
    for (let i = 0; i < parts.length; i += 3) {
      const [key, type, raw] = parts.slice(i, i + 3);
      if (type === "string") out[key] = raw;
      else if (type === "boolean") out[key] = raw === "true";
      else if (type === "number") {
        const n = Number(raw);
        if (!Number.isFinite(n)) process.exit(2);
        out[key] = n;
      } else if (type === "json") out[key] = JSON.parse(raw);
      else process.exit(2);
    }
    process.stdout.write(JSON.stringify(out));
  '
}

# ---- xray-core ---------------------------------------------------------------
# Fetch XTLS's installer to a file, CHECK it, then run it.
#
# It used to be `bash -c "$(curl -L https://github.com/.../raw/main/...)"`, and
# that URL began returning a 404 HTML page. curl -L without -f exits 0 on a 404,
# so the page was handed to bash, which died on "<!DOCTYPE html>", and the only
# thing anybody saw was "xray-core install failed" with the real error swallowed
# by >/dev/null. Every new install failed at that line.
#
# Three changes, each of which would have caught it on its own: the canonical
# raw.githubusercontent.com host (which serves it correctly), `-f` so an error
# response is a failure rather than a payload, and a look at what arrived before
# executing it. Piping an unverified download straight into a root shell is
# worth not doing regardless of who is serving it.
xray_installer() {
  local out="$1" u
  for u in \
    "https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh" \
    "https://github.com/XTLS/Xray-install/raw/main/install-release.sh"
  do
    if curl -fsSL --max-time 60 -o "$out" "$u" 2>/dev/null \
       && [ -s "$out" ] && head -c 2 "$out" | grep -q '#!' ; then
      return 0
    fi
  done
  return 1
}

# Which version to install, resolved HERE rather than by XTLS's script.
#
# Their script asks GitHub for the full release LIST, and that endpoint began
# answering `200 []` for Xray-core -- an empty array, not an error -- so it
# concluded there were no releases and stopped with "Failed to get the latest
# release version". Every fresh install died there. The `/releases/latest`
# endpoint answers correctly throughout, so Nova asks that one and hands the
# answer over with --version, which skips the list entirely.
#
# Empty is not fatal: without --version the script does what it always did, so
# if GitHub starts answering again nothing here has to change.
xray_latest_tag() {
  curl -fsSL --max-time 30 -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/XTLS/Xray-core/releases/latest" 2>/dev/null \
    | sed 'y/,/\n/' | grep '"tag_name"' | awk -F '"' '{print $4}' | head -1
}

if ! command -v xray >/dev/null 2>&1 && [ ! -x /usr/local/bin/xray ]; then
  say "Installing xray-core"
  XRAY_SH="$(mktemp)"
  if ! xray_installer "$XRAY_SH"; then
    rm -f "$XRAY_SH"
    die "could not download the xray-core installer (checked raw.githubusercontent.com and github.com). Check the server's connectivity to GitHub and try again."
  fi
  XRAY_TAG="$(xray_latest_tag || true)"
  # An array, not `set --`: this script has its own positional parameters and
  # overwriting them here would be a nasty thing to leave behind.
  XRAY_ARGS=(install)
  case "$XRAY_TAG" in
    v[0-9]*) XRAY_ARGS=(install --version "$XRAY_TAG") ;;
  esac
  # Kept out of the log on success, shown on failure: the message this replaces
  # said only "install failed" and hid the reason, which is how a broken URL
  # went unnoticed.
  XRAY_LOG="$(mktemp)"
  if bash "$XRAY_SH" "${XRAY_ARGS[@]}" >"$XRAY_LOG" 2>&1; then
    mark_owned xray
    rm -f "$XRAY_SH" "$XRAY_LOG"
  else
    echo "--- xray-core installer output ---" >&2
    tail -20 "$XRAY_LOG" >&2
    rm -f "$XRAY_SH" "$XRAY_LOG"
    die "xray-core install failed."
  fi
fi
XRAY_BIN="$(command -v xray || echo /usr/local/bin/xray)"
ok "xray $("$XRAY_BIN" version 2>/dev/null | head -1 | awk '{print $2}')"

# Geo databases: the routing engine references geosite:category-ads-all / cn and
# geoip:ir/cn/ru. Refresh with the comprehensive Loyalsoldier set so those codes
# always resolve (a missing code makes xray refuse to start). Best-effort; the
# stock dat that ships with xray stays as the fallback.
GEO_DIR=/usr/local/share/xray
mkdir -p "$GEO_DIR"
for g in geoip geosite; do
  curl -fsSL -o "$GEO_DIR/$g.dat.new" \
    "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/$g.dat" 2>/dev/null \
    && mv "$GEO_DIR/$g.dat.new" "$GEO_DIR/$g.dat" || rm -f "$GEO_DIR/$g.dat.new"
done

# ---- sing-box (Hysteria2 / QUIC gaming path) --------------------------------
# A custom sing-box build (compiled with the v2ray stats API) so the agent can
# meter Hysteria2 per-user, same as xray. Pulled as a single gzipped binary,
# no apt/.deb, so this step is reliable on a fresh box.
HAS_SINGBOX=0
SINGBOX_BIN=/usr/local/bin/sing-box-nova
SINGBOX_URL="${NOVA_SINGBOX_URL:-https://github.com/IRNova/Tools/releases/download/sing-box/sing-box-nova.gz}"
if [ ! -x "$SINGBOX_BIN" ]; then
  say "Installing sing-box (Hysteria2)"
  for attempt in 1 2 3; do
    if curl -fsSL "$SINGBOX_URL" -o /tmp/sb.gz && gunzip -f /tmp/sb.gz \
       && mv -f /tmp/sb "$SINGBOX_BIN" && chmod +x "$SINGBOX_BIN"; then
      mark_owned sing-box-nova
      break
    fi
    warn "sing-box download failed (try $attempt), retrying..."; sleep 3
  done
fi
if [ -x "$SINGBOX_BIN" ]; then
  mkdir -p /etc/sing-box
  # Our own unit: run as root so it can read the origin key, and use our config
  # path. The agent writes /etc/sing-box/config.json and bounces this service.
  cat > /etc/systemd/system/sing-box.service <<UNIT
[Unit]
Description=Nova sing-box (Hysteria2 UDP)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$SINGBOX_BIN run -c /etc/sing-box/config.json
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
UNIT
  mark_owned sing-box-service
  systemctl daemon-reload
  systemctl enable sing-box >/dev/null 2>&1 || true
  HAS_SINGBOX=1
  ok "sing-box installed"
  # grpcurl: the agent uses it to read sing-box's per-user stats for quota.
  if ! command -v grpcurl >/dev/null 2>&1; then
    garch="$(uname -m)"; case "$garch" in aarch64) garch=arm64;; x86_64) garch=x86_64;; esac
    if curl -fsSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_linux_${garch}.tar.gz" -o /tmp/grpcurl.tgz 2>/dev/null \
      && tar -xzf /tmp/grpcurl.tgz -C /usr/local/bin grpcurl 2>/dev/null \
      && chmod +x /usr/local/bin/grpcurl 2>/dev/null; then
      mark_owned grpcurl
    else
      warn "grpcurl install failed; Hysteria2 usage will not be metered."
    fi
  fi
else
  warn "Could not install sing-box; the node will run without Hysteria2."
fi

# ---- AmneziaWG (obfuscated WireGuard server) ---------------------------------
# Optional: lets the node host an AmneziaWG exit (junk packets + magic headers)
# that survives DPI where plain WireGuard/WARP is blocked. Best-effort: a failed
# install just leaves the "AmneziaWG server" panel card showing "not installed".
if ! command -v awg >/dev/null 2>&1; then
  say "Installing AmneziaWG (obfuscated WireGuard)"
  if add-apt-repository -y ppa:amnezia/ppa >/dev/null 2>&1 && apt-get update >/dev/null 2>&1 \
     && apt-get install -y linux-headers-"$(uname -r)" amneziawg amneziawg-tools >/dev/null 2>&1; then
    modprobe amneziawg 2>/dev/null || true
    ok "AmneziaWG installed"
  else
    warn "Could not install AmneziaWG; the node will run without the AmneziaWG server."
  fi
fi

# ---- Tor + Psiphon exits (optional egress paths) -----------------------------
# Local SOCKS services the panel's routing rules can send an inbound out through
# (random / DPI-resistant IPs). Best-effort: if a download fails the matching
# "Tor exit" / "Psiphon exit" toggle simply has nothing behind it.
if ! command -v tor >/dev/null 2>&1; then
  say "Installing Tor (local SOCKS exit on 9050)"
  if DEBIAN_FRONTEND=noninteractive apt-get install -y tor >/dev/null 2>&1 \
     && systemctl enable --now tor >/dev/null 2>&1; then
    mark_owned tor
    ok "Tor installed"
  else
    warn "Could not install Tor; the Tor exit will be unavailable."
  fi
fi
arch="$(uname -m)"; pbin="psiphon-tunnel-core-x86_64"
[ "$arch" = "aarch64" ] && pbin="psiphon-tunnel-core-arm64"
if [ ! -x "/etc/psiphon/$pbin" ]; then
  say "Installing Psiphon (local SOCKS exit on 1080)"
  mkdir -p /etc/psiphon
  if curl -fsSL -o /etc/psiphon/"$pbin" "https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/linux/$pbin" \
     && curl -fsSL -o /etc/psiphon/psiphon.config "https://raw.githubusercontent.com/IRNova/Nova-Server/main/psiphon.config"; then
    chmod +x /etc/psiphon/"$pbin"
    mark_owned psiphon
    cat > /etc/systemd/system/psiphon.service <<PSI
[Unit]
Description=Psiphon tunnel (local SOCKS exit for Nova)
After=network-online.target
Wants=network-online.target
[Service]
WorkingDirectory=/etc/psiphon
ExecStart=/etc/psiphon/$pbin -config /etc/psiphon/psiphon.config
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
PSI
    systemctl daemon-reload && systemctl enable --now psiphon >/dev/null 2>&1 && ok "Psiphon installed" \
      || warn "Psiphon installed but the service did not start."
  else
    warn "Could not install Psiphon; the Psiphon exit will be unavailable."
  fi
fi

# ---- standalone protocol backends (Telegram MTProto proxy, mieru) ------------
# Neither protocol can be served by a core Nova already runs: xray-core dropped
# its mtproto inbound, and the sing-box build here refuses a mieru outbound
# ("unknown outbound type"). Both are therefore separate daemons the agent
# manages, and both are OFF until an operator turns them on in the panel; this
# only puts the binary in place.
#
# Pinned by version AND by SHA-256, and served from IRNova/Tools rather than
# from upstream. A node runs these as a service, so whoever controls the bytes
# controls the node: pulling a publisher's "latest" would let an upstream
# account compromise reach every Nova node with no release of ours in between.
# The mirrored files are byte-identical copies of upstream's releases, so these
# hashes are also upstream's own published checksums.
#
# KEEP IN SYNC WITH src/binaries.mjs. The agent installs the same artifacts on
# demand, because a node that already exists never re-runs this script, and
# test/binary-pins.mjs fails if the two ever disagree.
MTGMULTI_VERSION="1.15.0"
MITA_VERSION="3.35.0"

# `set -e` is on, so the architecture choice is a case statement rather than a
# `[ ... ] && var=...` one-liner: on x86_64 that pattern ends the line with a
# non-zero status and takes the whole installer down.
case "$(uname -m)" in
  aarch64|arm64)
    barch="arm64"
    MTGMULTI_SHA256="9ed776b2052b95e8344896d43fbe01250014f36d7cfdd7f29f7903179bce4bed"
    MITA_SHA256="808849223d34ccd9ad86afc0eedef4d6c827133258e96dc3f3794bd17e7d54de"
    ;;
  *)
    barch="amd64"
    MTGMULTI_SHA256="f1f8763504753fb863a0ddff83eab19c856747289c376275c44b717f1747908e"
    MITA_SHA256="a07d5afc5e1353ab346bb3ddbe95c7f960828204be529f4a88d688dfe83e252d"
    ;;
esac

# Verify a downloaded archive against a pinned SHA-256. Fails CLOSED: a host
# with no sha256 tool refuses rather than installing something unchecked, which
# is the rule the self-updater learned the hard way in 1.34.1.
sha_is() { # file expected
  _got=""
  if command -v sha256sum >/dev/null 2>&1; then _got="$(sha256sum "$1" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then _got="$(shasum -a 256 "$1" | awk '{print $1}')"
  else return 1; fi
  [ "$_got" = "$2" ]
}

# A private directory per download. A fixed /tmp/<name> is world-predictable,
# and the window between `tar` and `install` is long enough for an unprivileged
# local account to swap the file, which would put attacker bytes into
# /usr/local/bin as root and defeat the checksum that was just verified.
#
# Cleaned up explicitly rather than with `trap ... EXIT`: a second EXIT trap
# silently REPLACES the first, and 1.34.1 records that exact bug swallowing the
# self-updater's status file. `mktemp -d` is 0700, so a leak on an abort costs
# nothing.
btmp="$(mktemp -d)"

# mtg-multi, not 9seconds/mtg: the fork carries a [secrets] table, a loopback
# management API and per-secret counters, which is what makes a per-customer
# Telegram proxy with its own data limit possible. See docs/mtg-multi-adoption.md.
if [ ! -x /usr/local/bin/mtg-multi ]; then
  say "Installing mtg-multi (Telegram MTProto proxy)"
  if curl -fsSL --proto '=https' --proto-redir '=https' -o "$btmp/mtg.tar.gz" \
       "https://github.com/IRNova/Tools/releases/download/mtgMulti/mtg-multi-${MTGMULTI_VERSION}-linux-${barch}.tar.gz" \
     && sha_is "$btmp/mtg.tar.gz" "$MTGMULTI_SHA256" \
     && tar -xzf "$btmp/mtg.tar.gz" -C "$btmp" --strip-components=1 "mtg-multi-${MTGMULTI_VERSION}-linux-${barch}/mtg-multi" \
     && install -m 0755 "$btmp/mtg-multi" /usr/local/bin/mtg-multi; then
    id -u nova-mtg >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin --user-group nova-mtg >/dev/null 2>&1 || true
    mark_owned mtgMulti
    ok "mtg-multi installed (checksum verified)"
  else
    warn "Could not install mtg-multi; the Telegram proxy will be unavailable."
  fi
fi

if [ ! -x /usr/local/bin/mita ]; then
  say "Installing mita (mieru server)"
  if curl -fsSL --proto '=https' --proto-redir '=https' -o "$btmp/mita.tar.gz" \
       "https://github.com/IRNova/Tools/releases/download/mita/mita_${MITA_VERSION}_linux_${barch}.tar.gz" \
     && sha_is "$btmp/mita.tar.gz" "$MITA_SHA256" \
     && tar -xzf "$btmp/mita.tar.gz" -C "$btmp" mita \
     && install -m 0755 "$btmp/mita" /usr/local/bin/mita; then
    id -u mita >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin --user-group mita >/dev/null 2>&1 || true
    install -d -m 750 -o mita -g mita /etc/mita /var/lib/mita /var/run/mita 2>/dev/null || true
    mark_owned mita
    ok "mita installed (checksum verified)"
  else
    warn "Could not install mita; mieru will be unavailable."
  fi
fi
rm -rf "$btmp"

# ---- tunnel backends (Iran bridge <-> foreign exit) --------------------------
# Selectable reverse-tunnel tools so an Iran box can front a foreign Nova exit
# over a censorship-resistant transport. Best-effort: a missing binary just means
# that backend is greyed out in the panel's Tunnel section. All carry UDP so
# Hysteria2 survives the hop.
tarch="$(uname -m)"; garch="amd64"; [ "$tarch" = "aarch64" ] && garch="arm64"
install -d /usr/local/bin

# Resolve a release asset's download URL by matching a substring against the
# latest release (handles versioned/arch-specific asset names that a static
# /latest/download/ path cannot).
gh_asset() { # repo  match
  # The trailing "|| true" is load-bearing. This script runs under `set -euo
  # pipefail`, and every caller assigns this to a variable: rurl="$(gh_asset ...)".
  # A rate-limited or blocked GitHub API makes curl exit non-zero, pipefail makes
  # the pipeline non-zero, and the bare assignment then kills the whole install on
  # the spot, without printing a word, before any of the "could not install that
  # backend, carrying on" branches below can run. In a container that turns into a
  # first-boot unit that restarts forever. An empty result is what the callers
  # already expect and handle.
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
    | grep browser_download_url | grep -i "$2" | head -1 | cut -d'"' -f4 || true
}

# Backhaul (default): widest transport set, connection pooling, self-signed OK.
if ! command -v backhaul >/dev/null 2>&1; then
  say "Installing Backhaul tunnel backend"
  if curl -fsSL -o /tmp/backhaul.tgz "https://github.com/Musixal/Backhaul/releases/latest/download/backhaul_linux_${garch}.tar.gz" \
     && tar -xzf /tmp/backhaul.tgz -C /usr/local/bin backhaul 2>/dev/null; then
    chmod +x /usr/local/bin/backhaul && mark_owned backhaul && ok "Backhaul installed"
  else
    warn "Could not install Backhaul; that tunnel backend will be unavailable."
  fi
fi

# BackPack: Backhaul-class Go reverse tunnel; ships checksum-verified binaries.
if ! command -v backpack >/dev/null 2>&1; then
  say "Installing BackPack tunnel backend"
  bpurl="$(gh_asset AminMGMT/BackPack "backpack_linux_${garch}.tar.gz")"
  bpsum="$(gh_asset AminMGMT/BackPack "SHA256SUMS")"
  if [ -n "$bpurl" ] && curl -fsSL -o /tmp/backpack.tgz "$bpurl" && curl -fsSL -o /tmp/backpack.sums "${bpsum:-/dev/null}" 2>/dev/null; then
    # Verify against the published SHA256SUMS before trusting the binary.
    want="$(grep -i "backpack_linux_${garch}.tar.gz" /tmp/backpack.sums 2>/dev/null | awk '{print $1}' | head -1)"
    got="$(sha256sum /tmp/backpack.tgz 2>/dev/null | awk '{print $1}')"
    if [ -n "$want" ] && [ "$want" = "$got" ] && tar -xzf /tmp/backpack.tgz -C /usr/local/bin backpack 2>/dev/null; then
      chmod +x /usr/local/bin/backpack && mark_owned backpack && ok "BackPack installed (checksum verified)"
    else
      warn "BackPack checksum mismatch or extract failed; skipping that backend."
    fi
  else
    warn "Could not download BackPack; that tunnel backend will be unavailable."
  fi
fi

# rathole: lightweight Rust, TCP+UDP, Noise/TLS. (aarch64 ships musl only.)
if ! command -v rathole >/dev/null 2>&1; then
  say "Installing rathole tunnel backend"
  rmatch="x86_64-unknown-linux-gnu.zip"; [ "$tarch" = "aarch64" ] && rmatch="aarch64-unknown-linux-musl.zip"
  rurl="$(gh_asset rapiz1/rathole "$rmatch")"
  if [ -n "$rurl" ] && curl -fsSL -o /tmp/rathole.zip "$rurl" \
     && unzip -o /tmp/rathole.zip -d /usr/local/bin rathole >/dev/null 2>&1; then
    chmod +x /usr/local/bin/rathole && mark_owned rathole && ok "rathole installed"
  else
    warn "Could not install rathole; that tunnel backend will be unavailable."
  fi
fi

# wstunnel: tunnels over WebSocket/HTTPS, fronts cleanly behind a CDN. Asset
# names carry the version, so resolve via the API.
if ! command -v wstunnel >/dev/null 2>&1; then
  say "Installing wstunnel tunnel backend"
  warch="amd64"; [ "$tarch" = "aarch64" ] && warch="arm64"
  wurl="$(gh_asset erebe/wstunnel "linux_${warch}.tar.gz")"
  if [ -n "$wurl" ] && curl -fsSL "$wurl" -o /tmp/wstunnel.tgz \
     && tar -xzf /tmp/wstunnel.tgz -C /usr/local/bin wstunnel 2>/dev/null; then
    chmod +x /usr/local/bin/wstunnel && mark_owned wstunnel && ok "wstunnel installed"
  else
    warn "Could not install wstunnel; that tunnel backend will be unavailable."
  fi
fi
mkdir -p /etc/nova/tunnel && chmod 700 /etc/nova/tunnel

# A convenience shortcut so a locked-out admin can reset their password over SSH:
#   nova-passwd 'NewPassword' [--clear-2fa]
cat > /usr/local/bin/nova-passwd <<'NPW'
#!/bin/bash
if [ -r /etc/nova/agent.env ]; then
  nova_front_port="$(sed -n 's/^NOVA_FRONT_PORT=//p' /etc/nova/agent.env | tail -n 1)"
  case "$nova_front_port" in ''|*[!0-9]*) ;; *) export NOVA_FRONT_PORT="$nova_front_port" ;; esac
fi
exec node /opt/nova-node-agent/bin/reset-password.mjs "$@"
NPW
chmod +x /usr/local/bin/nova-passwd 2>/dev/null || true

# A convenience shortcut to recover or change panel + subscription access from the
# server when the panel is unreachable (bad domain / Cloudflare / SSL change):
#   nova-access            show the current panel URL
#   nova-access --reset    revert to a self-signed no-domain node (server IP)
cat > /usr/local/bin/nova-access <<'NAC'
#!/bin/bash
if [ -r /etc/nova/agent.env ]; then
  nova_front_port="$(sed -n 's/^NOVA_FRONT_PORT=//p' /etc/nova/agent.env | tail -n 1)"
  case "$nova_front_port" in ''|*[!0-9]*) ;; *) export NOVA_FRONT_PORT="$nova_front_port" ;; esac
fi
exec node /opt/nova-node-agent/bin/reset-access.mjs "$@"
NAC
chmod +x /usr/local/bin/nova-access 2>/dev/null || true

# Reclaim a managed node whose parent panel is gone (turns nodeMode off and sets a
# new admin password so you can sign in locally):  nova-unlock 'YourPassword'
cat > /usr/local/bin/nova-unlock <<'NUL'
#!/bin/bash
if [ -r /etc/nova/agent.env ]; then
  nova_front_port="$(sed -n 's/^NOVA_FRONT_PORT=//p' /etc/nova/agent.env | tail -n 1)"
  case "$nova_front_port" in ''|*[!0-9]*) ;; *) export NOVA_FRONT_PORT="$nova_front_port" ;; esac
fi
exec node /opt/nova-node-agent/bin/unlock-node.mjs "$@"
NUL
chmod +x /usr/local/bin/nova-unlock 2>/dev/null || true

# Shortcut to configure + enable the built-in Telegram control bot, e.g.
#   nova-tgbot '123456789:AA...' '<admin-chat-id>'
cat > /usr/local/bin/nova-tgbot <<'NTB'
#!/bin/bash
exec node /opt/nova-node-agent/bin/set-tgbot.mjs "$@"
NTB
chmod +x /usr/local/bin/nova-tgbot 2>/dev/null || true

# Shortcut to remove Nova and all its data:  nova-uninstall  (add --yes to skip
# the prompt). Bundled with the agent, so it works offline after install.
cat > /usr/local/bin/nova-uninstall <<'NUN'
#!/bin/bash
exec bash /opt/nova-node-agent/install/nova-uninstall.sh "$@"
NUN
chmod +x /usr/local/bin/nova-uninstall 2>/dev/null || true

# ---- agent code --------------------------------------------------------------
say "Fetching the Nova node agent"
mkdir -p "$AGENT_DIR" "$DB_DIR" "$CERT_DIR"
# xray writes its access log here and runs as 'nobody'; create it up front owned by
# that user so xray can write it (the agent also self-heals this, belt and braces).
mkdir -p /var/log/nova && chown nobody:nogroup /var/log/nova 2>/dev/null || true
tmp="$(mktemp -d)"
curl -fsSL "$TARBALL_URL" -o "$tmp/agent.tar.gz" || die "Could not download the agent."
# Verify a release checksum when the publisher provides one. Operators may also
# pin it explicitly with NOVA_TARBALL_SHA256 for an out-of-band trust anchor.
expected="${NOVA_TARBALL_SHA256:-}"
if [ -z "$expected" ] && curl -fsSL "${TARBALL_URL}.sha256" -o "$tmp/agent.sha256" 2>/dev/null; then
  expected="$(awk 'NR==1 {print $1}' "$tmp/agent.sha256")"
fi
if [ -n "$expected" ]; then
  case "$expected" in (*[!0-9A-Fa-f]*|"") die "Published agent checksum is invalid.";; esac
  got="$(sha256sum "$tmp/agent.tar.gz" | awk '{print $1}')"
  [ "$got" = "$expected" ] || die "Agent checksum verification failed."
fi
if tar -tzf "$tmp/agent.tar.gz" | grep -Eq '(^/|(^|/)\.\.(/|$))'; then
  die "Agent archive contains an unsafe path."
fi
# --warning=no-unknown-keyword: hide the harmless "Ignoring unknown extended
# header keyword" lines GNU tar prints when a release tarball was built on macOS
# (Apple provenance xattrs). Extraction succeeds either way; the flag keeps the
# output clean so a successful install never looks like it errored.
tar --warning=no-unknown-keyword -xzf "$tmp/agent.tar.gz" -C "$AGENT_DIR" || die "Could not extract the agent."
rm -rf "$tmp"
ok "agent installed at $AGENT_DIR"

# ---- host + TLS cert ---------------------------------------------------------
# Iran-reachable IP echoes only: ifconfig.me is sanction-blocked from Iran (403).
PUBIP="$(curl -fsSL --max-time 6 https://api.ipify.org 2>/dev/null || curl -fsSL --max-time 6 https://icanhazip.com 2>/dev/null || curl -fsSL --max-time 6 https://ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}')"
# The IP-echo endpoints are network-reachable, so treat their output as untrusted:
# it lands in the network-settings.json body below, and a crafted response could
# otherwise inject JSON. Keep only a bare IPv4/IPv6 literal; blank anything else.
PUBIP="$(printf '%s' "$PUBIP" | tr -d '[:space:]')"
case "$PUBIP" in *[!0-9.:a-fA-F]* | "") PUBIP="" ;; esac
# The node always comes up self-signed on its public IP. If NOVA_DOMAIN is set we
# switch it to a trusted Let's Encrypt cert further down, once the agent is live
# (same code path the app/panel "add a domain" button uses).
HOST="$PUBIP"; INSECURE=true

url_host() {
  case "$1" in *:*) printf '[%s]' "$1";; *) printf '%s' "$1";; esac
}

json_error() {
  node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{try{const v=JSON.parse(s);console.log(String(v.error||'').replace(/[\\r\\n]+/g,' ').slice(0,500))}catch{}})" 2>/dev/null || true
}

if [ ! -s "$CERT_DIR/origin.pem" ] || [ ! -s "$CERT_DIR/origin.key" ]; then
  say "Generating a TLS certificate for $HOST"
  # A SubjectAltName, always. Every current TLS stack rejects a certificate that
  # has only a CN, so a cert generated without one still gets SERVED and the
  # panel still answers with -k, while every client refuses the subscription
  # link. The old fallback here dropped the SAN silently, which is how a node
  # ended up in that state with nothing in the output to say so: if $PUBIP was
  # empty, `IP:` was invalid, the first command failed, and the second produced
  # exactly the certificate no client accepts.
  #
  # So the fallback keeps a SAN and only changes what goes in it: the detected
  # address, else whatever HOST is, as an IP or a name depending on its shape.
  case "$HOST" in
    *[!0-9.]*) SAN_HOST="DNS:$HOST" ;;
    *)         SAN_HOST="IP:$HOST" ;;
  esac
  [ -n "${PUBIP:-}" ] && SAN_TRY="IP:$PUBIP" || SAN_TRY="$SAN_HOST"
  openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout "$CERT_DIR/origin.key" -out "$CERT_DIR/origin.pem" \
    -subj "/CN=$HOST" -addext "subjectAltName=$SAN_TRY" >/dev/null 2>&1 \
    || openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
       -keyout "$CERT_DIR/origin.key" -out "$CERT_DIR/origin.pem" \
       -subj "/CN=$HOST" -addext "subjectAltName=$SAN_HOST" >/dev/null 2>&1
  # And say so if it still has no SAN, rather than leaving the operator to find
  # out from a customer whose client will not import the link.
  if ! openssl x509 -in "$CERT_DIR/origin.pem" -noout -ext subjectAltName >/dev/null 2>&1; then
    warn "the certificate has no SubjectAltName; clients will refuse it. Reissue it from Settings > Domain."
  fi
fi
# xray runs as user 'nobody' (group nogroup); let it read the key.
chgrp nogroup "$CERT_DIR/origin.pem" "$CERT_DIR/origin.key" 2>/dev/null || true
chmod 640 "$CERT_DIR/origin.pem" "$CERT_DIR/origin.key"
ok "certificate ready"

# ---- kernel network tuning ---------------------------------------------------
# TCP BBR + fq: better throughput on lossy, high-latency links (Iran's routes).
# Helps every TCP protocol; Hysteria2 has its own CC. Safe since kernel 4.9. The
# agent also re-applies this on boot per the panel toggle, so it self-heals.
modprobe tcp_bbr 2>/dev/null || true
cat > /etc/sysctl.d/99-nova-net.conf <<'SYSCTL'
# Nova: BBR congestion control for better throughput on lossy/high-latency links.
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
SYSCTL
sysctl -p /etc/sysctl.d/99-nova-net.conf >/dev/null 2>&1 || true

# ---- env + systemd -----------------------------------------------------------
say "Configuring services"
# This is a truncating write, and re-running the installer is the documented way
# to repair or update a node, so anything the operator added here by hand is
# about to be lost. STATS_OPTOUT is a promise ("nothing is ever sent"), and the
# panel tells them to set it here, so silently dropping it on the next repair
# would quietly reverse that promise. Carry it across.
#
# Both writes below are VALIDATED. agent.env is the EnvironmentFile of a root
# service, and the agent reads NOVA_TARBALL_URL and NOVA_VERSION_URL out of that
# environment to decide what the self-updater downloads. A newline inside a value
# appends attacker-chosen KEY=value lines to it, which is why NOVA_VERSION_URL
# and NOVA_TARBALL_URL are already newline-checked further down and why
# docker/entry.sh does the same. STATS_OPTOUT is a boolean, so it is checked as
# one, and the carried-over line must match the shape it was written in. A
# trailing backslash matters too: systemd treats it as a line continuation and it
# would swallow the next setting.
case "${STATS_OPTOUT:-}" in
  ""|0|1|true|false|yes|no|on|off|TRUE|FALSE|YES|NO|ON|OFF) ;;
  *) die "STATS_OPTOUT must be 1 or 0." ;;
esac
KEEP_OPTOUT="$(grep -hE '^STATS_OPTOUT=[A-Za-z0-9]+$' "$CERT_DIR/agent.env" 2>/dev/null | tail -n 1 || true)"
cat > "$CERT_DIR/agent.env" <<ENV
NOVA_DB=$DB_DIR/nova.db
NOVA_PORT=${NOVA_AGENT_PORT:-8088}
NOVA_HOST=127.0.0.1
NOVA_POLL_MS=30000
NOVA_XRAY_API=127.0.0.1:${NOVA_XRAY_API_PORT:-10085}
NOVA_XRAY_BIN=$XRAY_BIN
ENV
[ -n "${STATS_OPTOUT:-}" ] && printf 'STATS_OPTOUT=%s\n' "$STATS_OPTOUT" >> "$CERT_DIR/agent.env"
[ -z "${STATS_OPTOUT:-}" ] && [ -n "$KEEP_OPTOUT" ] && printf '%s\n' "$KEEP_OPTOUT" >> "$CERT_DIR/agent.env"
# Custom front port (443 was taken): the agent fronts xray here and every link uses it.
[ "${FRONT_PORT:-443}" != 443 ] && printf 'NOVA_FRONT_PORT=%s\n' "$FRONT_PORT" >> "$CERT_DIR/agent.env"

# Update channel. Persisting this is what keeps a preview or mirror node from
# replacing itself with the public build on its next check, but it is also the
# node's SUPPLY CHAIN: agent.env is the EnvironmentFile of a root service, the
# self-updater reads the URL from there, and the .sha256 it verifies against
# comes from the same origin, so the checksum proves nothing about a URL someone
# else chose. Three gates, because a one-liner with a variable prepended is a
# shape operators already see and paste.
if [ "$TARBALL_URL" != "$PUBLIC_TARBALL_URL" ] || [ "$VERSION_URL" != "$PUBLIC_VERSION_URL" ]; then
  # Every gate below guards what gets WRITTEN, so all of it lives inside the
  # PERSIST_CHANNEL branch. Validating earlier would reject installs that
  # persist nothing: the Docker image installs from a local file:// archive
  # (docker/firstboot.sh), so an https check out here refuses to build or
  # recreate any container, and the failure lands after agent.env is written but
  # before the systemd unit exists.
  if [ "$PERSIST_CHANNEL" = 1 ]; then
    # 1. No shell or systemd metacharacters. A newline would append arbitrary
    #    extra KEY=value lines to a root service's environment; a quote or
    #    backslash corrupts the file through systemd's own parsing.
    case "$TARBALL_URL$VERSION_URL" in
      *[!A-Za-z0-9:/._~%?=+-]*) die "Refusing to persist a malformed update URL." ;;
    esac
    # 2. Plain http would let anyone on the path replace the agent.
    case "$TARBALL_URL" in https://*) ;; *) die "A persisted update channel must be https." ;; esac
    case "$VERSION_URL" in https://*) ;; *) die "A persisted update channel must be https." ;; esac
    # Both halves must come from the same place. A custom tarball with the
    # public version marker pins the node to a build that never sees another
    # update while the panel reports "up to date"; the reverse restarts the
    # agent every 24h without ever converging.
    if [ "$TARBALL_URL" != "$PUBLIC_TARBALL_URL" ] && [ "$VERSION_URL" = "$PUBLIC_VERSION_URL" ]; then
      die "A persisted channel needs NOVA_VERSION_URL from the same origin as NOVA_TARBALL_URL."
    fi
    if [ "$VERSION_URL" != "$PUBLIC_VERSION_URL" ] && [ "$TARBALL_URL" = "$PUBLIC_TARBALL_URL" ]; then
      die "A persisted channel needs NOVA_TARBALL_URL from the same origin as NOVA_VERSION_URL."
    fi
    printf 'NOVA_TARBALL_URL=%s\n' "$TARBALL_URL" >> "$CERT_DIR/agent.env"
    printf 'NOVA_VERSION_URL=%s\n' "$VERSION_URL" >> "$CERT_DIR/agent.env"
    warn "This node tracks a custom update channel, not the public Nova release."
  else
    # PERSIST_CHANNEL is baked into a rebranded installer by whoever publishes
    # that channel, and cannot be set from the environment, so a pasted
    # NOVA_TARBALL_URL= is a ONE-TIME install and updates stay on the public
    # release. Silent for file:// (the Docker image's normal path).
    case "$TARBALL_URL$VERSION_URL" in
      *file://*) ;;
      *) warn "Installed once from a custom URL. Updates still come from the public release." ;;
    esac
  fi
fi

NODE_BIN="$(command -v node)"
cat > /etc/systemd/system/nova-agent.service <<UNIT
[Unit]
Description=Nova VPS node agent (admin panel + xray bridge)
After=network-online.target xray.service
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$AGENT_DIR
# --max-old-space-size caps V8's heap. Without it V8 sizes the heap from total
# system RAM and never returns it, so a busy node's agent settles at a few
# hundred MB and the operator sees "the panel's RAM keeps climbing". 192 MB is
# well above what a large registry needs and small enough that the agent can
# never be what fills a 1 GB VPS. MemoryMax is a wall well above the measured
# working set, and Restart=always means a genuine leak restarts the agent
# instead of taking the node down (xray keeps serving). No MemoryHigh: it would
# throttle a node that never receives the heap flag, and the agent writes the
# same MemoryMax as a drop-in, which is parsed last and must not disagree.
ExecStart=$NODE_BIN --max-old-space-size=192 $AGENT_DIR/bin/nova-agent.mjs
EnvironmentFile=$CERT_DIR/agent.env
Restart=always
RestartSec=2
MemoryMax=768M
User=root
StateDirectory=nova

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable nova-agent >/dev/null 2>&1 || true
# restart (not just enable --now): on a re-run the agent is already active and
# "enable --now" would NOT pick up freshly extracted code. restart starts it when
# stopped and reloads new code when running, so re-running the one-liner also
# updates an existing node.
systemctl restart nova-agent >/dev/null 2>&1 || die "Could not start nova-agent."

# A reinstall can start with an existing secret panel path in the persistent DB.
# Read it locally so installer API calls use the real path instead of receiving
# the deliberate root-path 404 decoy. This is also what lets a recreated Docker
# container restore its image-layer runtime without resetting panel state.
LOCAL_STATE="$(
  NOVA_DB="$DB_DIR/nova.db" node -e '
    import("/opt/nova-node-agent/src/kv/sqlite.mjs").then(async ({ openKv }) => {
      const kv = openKv(process.env.NOVA_DB);
      try {
        const s = JSON.parse(await kv.get("network-settings.json") || "{}");
        const p = String(s.panelPath || "").replace(/^\/+|\/+$/g, "");
        const safe = /^[A-Za-z0-9_-]{3,64}$/.test(p) ? p : "";
        /* The hostname the panel answers on. The agent serves the decoy page
         * to a request whose Host it does not recognise, so polling loopback
         * without this is how a perfectly healthy update came to report "The
         * agent did not respond in time" on every run.
         * NOTE: no apostrophes in here, the whole block is single-quoted. */
        const h = String(s.host || "").replace(/:\d+$/, "").trim();
        const host = /^[A-Za-z0-9.\-]{1,253}$/.test(h) ? h : "";
        /* Whether this node serves a real certificate. Needed because HOST and
         * INSECURE below still hold their first-run defaults on a re-install,
         * and only a certificate issued in THIS run corrects them. */
        const insec = s.insecure === false ? "0" : "1";
        process.stdout.write(safe + "|" + (s.nodeMode === true ? "1" : "0") + "|" + host + "|" + insec);
      } finally {
        kv.close();
      }
    }).catch(() => process.stdout.write("|0||"));
  ' 2>/dev/null || true
)"
# Split positionally. NOT with ${VAR##*|}, which takes whatever field happens to
# be LAST: that is how PERSISTED_NODE_MODE came to read the hostname when the
# host field was appended, and appending `insecure` here would have done the
# same to LOCAL_HOST. `read` cannot fail the `set -e` here because the here-doc
# always supplies the trailing newline it wants.
IFS='|' read -r LOCAL_PANEL_PATH PERSISTED_NODE_MODE LOCAL_HOST LOCAL_INSECURE <<LOCAL_STATE_EOF
$LOCAL_STATE
LOCAL_STATE_EOF
# Ask as the panel's own hostname; without it the agent serves the decoy and the
# loop below never sees "configured", however healthy the agent is.
HOSTARG=""
[ -n "$LOCAL_HOST" ] && HOSTARG="-H Host:$LOCAL_HOST"
# The port the agent was actually given, not the default. A reinstall on a box
# where 8088 was taken moves the agent, and a poll left on 8088 would time out
# against a perfectly healthy node and print "the agent did not respond in
# time", which is the exact failure test/installer-readiness.mjs exists to stop.
# Read back from agent.env so this cannot drift from what was written there.
AGENT_PORT="$(sed -n 's/^NOVA_PORT=//p' "$CERT_DIR/agent.env" 2>/dev/null | tail -n 1)"
case "$AGENT_PORT" in ''|*[!0-9]*) AGENT_PORT=8088 ;; esac
B=http://127.0.0.1:$AGENT_PORT
[ -n "$LOCAL_PANEL_PATH" ] && B="$B/$LOCAL_PANEL_PATH"

# Wait for the agent's local API to answer /install/status with a real JSON body,
# and read whether the panel is already configured. Reading the actual state (not
# just "did any HTTP code come back") is what lets us tell a genuine re-install
# from a momentary hiccup during first boot, so a single transient can never make
# the installer skip configuring a fresh node.
CONFIGURED=""
for i in $(seq 1 40); do
  RESP="$(curl -fsS $HOSTARG "$B/install/status" 2>/dev/null || true)"
  case "$RESP" in
    *'"configured"'*)
      case "$RESP" in *'"configured":true'*) CONFIGURED=true;; *) CONFIGURED=false;; esac
      break;;
  esac
  sleep 1
done
# Managed nodes intentionally have no local admin password, so their public
# install status reports configured=false. The persisted nodeMode setting is
# authoritative during an idempotent runtime restore and prevents the installer
# from reopening or replaying first-claim and enrollment.
if [ "$PERSISTED_NODE_MODE" = 1 ]; then
  CONFIGURED=true
  NODE_MODE=0
  NOVA_INSTALL_RESUME=0
  NOVA_ADMIN_PASS=""
  NOVA_DOMAIN=""
  NOVA_DOMAIN_EMAIL=""
  NOVA_PANEL_PATH=""
  NOVA_PANEL_PORT=""
fi
[ -n "$CONFIGURED" ] || die "The agent did not respond in time. Check: journalctl -u nova-agent -n 50"
ok "agent running"

# ---- configure the panel -----------------------------------------------------
ADMIN_PASS="${NOVA_ADMIN_PASS:-$(openssl rand -base64 12 | tr -dc 'A-Za-z0-9' | head -c 14)}"
UA='User-Agent: Nova/1.0.0 (desktop; sing-box)'
CJ="$(mktemp)"
FRESH_SETUP=0
[ "$CONFIGURED" = false ] && FRESH_SETUP=1
if [ "$CONFIGURED" = true ] && [ "${NOVA_INSTALL_RESUME:-0}" = 1 ]; then
  [ -n "${NOVA_ADMIN_PASS:-}" ] || die "Interrupted install recovery requires NOVA_ADMIN_PASS."
  FRESH_SETUP=1
  warn "Resuming an interrupted first-time setup."
fi

say "Setting up the panel"
if [ "$CONFIGURED" = true ]; then
  # Genuinely already configured (a re-install): keep the existing password.
  warn "Panel already configured; keeping the existing password."
  ADMIN_PASS="(unchanged from a previous install)"
else
  # Fresh panel: set the admin password, retrying a few times in case the agent
  # is still settling right after its first start. A single failed attempt must
  # NOT be mistaken for "already configured" (that would skip host, protocols,
  # the panel path and the starter user, leaving the node half-set-up).
  SET_OK=0
  CLAIM_FILE="${NOVA_INSTALL_CLAIM_FILE:-$CERT_DIR/install-claim}"
  CLAIM_TOKEN="$(tr -d '[:space:]' < "$CLAIM_FILE" 2>/dev/null || true)"
  if [[ ! "$CLAIM_TOKEN" =~ ^[A-Fa-f0-9]{32}$ ]]; then
    die "The agent did not create a valid install claim token. Check: journalctl -u nova-agent -n 50"
  fi
  PASS_BODY="$(json_body password string "$ADMIN_PASS")"
  for i in $(seq 1 10); do
    if curl -fsS -c "$CJ" -X POST "$B/install/set" -H "$UA" -H 'Content-Type: application/json' \
      -H "X-Nova-Install-Claim: $CLAIM_TOKEN" \
      --data-binary @- <<< "$PASS_BODY" >/dev/null 2>&1; then SET_OK=1; break; fi
    # If a concurrent run set it in the meantime, stop and keep that password.
    if curl -fsS "$B/install/status" 2>/dev/null | grep -q '"configured":true'; then
      warn "Panel already configured; keeping the existing password."
      ADMIN_PASS="(unchanged from a previous install)"; SET_OK=1; break
    fi
    sleep 2
  done
  [ "$SET_OK" = 1 ] || die "Could not set the admin password (agent not responding). Check: journalctl -u nova-agent -n 50"
fi
# Log in (works whether we just set it or it already existed and the caller passed NOVA_ADMIN_PASS).
LOGIN_OK=0
if [ "${NOVA_ADMIN_PASS:-}" != "" ]; then
  LOGIN_BODY="$(json_body password string "$NOVA_ADMIN_PASS")"
  if curl -fsS -c "$CJ" -X POST "$B/login" -H "$UA" -H 'Content-Type: application/json' \
    --data-binary @- <<< "$LOGIN_BODY" >/dev/null 2>&1; then
    LOGIN_OK=1
  fi
fi
if [ "$CONFIGURED" = true ] && [ "$FRESH_SETUP" = 1 ] && [ "$LOGIN_OK" != 1 ]; then
  die "Could not authenticate to resume the interrupted first-time setup."
fi

# Seed host and the standard protocol set only on a genuinely fresh install or
# an explicitly resumed Docker first boot. Normal upgrades never overwrite an
# operator's later protocol choices.
if [ "$FRESH_SETUP" = 1 ]; then
  HY2=false; [ "${HAS_SINGBOX:-0}" = 1 ] && HY2=true
  PROTOCOLS_BODY="$(json_body vless boolean true vmess boolean true trojan boolean true hysteria2 boolean "$HY2")"
  SETTINGS_BODY="$(json_body host string "$HOST" insecure boolean "$INSECURE" protocols json "$PROTOCOLS_BODY")"
  if ! curl -fsS -b "$CJ" -X POST "$B/admin/network-settings.json" -H "$UA" -H 'Content-Type: application/json' \
    --data-binary @- <<< "$SETTINGS_BODY" >/dev/null 2>&1; then
    warn "Could not seed the initial protocol settings; finish setup from the panel."
  fi
fi

# A fresh standalone panel gets one unrestricted starter user. No inboundIds
# allowlist means every current and future all-users inbound is included in its
# personal subscription. Managed nodes receive users from their parent panel,
# and upgrades must never recreate a user an operator intentionally deleted.
if [ "$FRESH_SETUP" = 1 ] && [ "$NODE_MODE" != 1 ]; then
  USER_COUNT="$(curl -fsS -b "$CJ" "$B/admin/network-settings.json" -H "$UA" 2>/dev/null \
    | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{try{console.log((JSON.parse(s).users||[]).length)}catch{console.log(0)}})" 2>/dev/null || echo 0)"
  if [ "${USER_COUNT:-0}" = 0 ]; then
    UUID="$(cat /proc/sys/kernel/random/uuid)"
    USER_BODY="$(json_body id string me uuid string "$UUID" email string me enabled boolean true)"
    ADD_USER_BODY="$(json_body action string add user json "$USER_BODY")"
    if ! curl -fsS -b "$CJ" -X POST "$B/admin/users.json" -H "$UA" -H 'Content-Type: application/json' \
      --data-binary @- <<< "$ADD_USER_BODY" >/dev/null 2>&1; then
      warn "Could not create the starter user; add one from the Users page."
    fi
  fi
fi

# If a domain was requested, provision a trusted Let's Encrypt cert and switch
# the node over to it. Needs port 80 reachable and the domain's DNS pointing here.
if [ -n "${NOVA_DOMAIN:-}" ]; then
  say "Getting a certificate for $NOVA_DOMAIN (Let's Encrypt)"
  DOMAIN_ARGS=(domain string "$NOVA_DOMAIN" method string letsencrypt)
  [ -n "${NOVA_DOMAIN_EMAIL:-}" ] && DOMAIN_ARGS+=(email string "$NOVA_DOMAIN_EMAIL")
  DBODY="$(json_body "${DOMAIN_ARGS[@]}")"
  DOMAIN_START="$(curl -sS -b "$CJ" -X POST "$B/admin/domain" -H "$UA" -H 'Content-Type: application/json' \
    --data-binary @- <<< "$DBODY" 2>/dev/null || true)"
  DOMAIN_FINISHED=0
  case "$DOMAIN_START" in
    *'"error"'*)
      DOMAIN_FINISHED=1
      DOMAIN_ERROR="$(printf '%s' "$DOMAIN_START" | json_error)"
      warn "Certificate setup could not start; leaving the node on its IP + self-signed certificate."
      [ -n "$DOMAIN_ERROR" ] && warn "$DOMAIN_ERROR";;
  esac
  if [ "$DOMAIN_FINISHED" != 1 ]; then
    for i in $(seq 1 36); do
      sleep 5
      DST="$(curl -fsS -b "$CJ" "$B/admin/domain" -H "$UA" 2>/dev/null || true)"
      case "$DST" in
        *'"state":"active"'*) HOST="$NOVA_DOMAIN"; INSECURE=false; DOMAIN_FINISHED=1; ok "certificate issued for $NOVA_DOMAIN"; break;;
        *'"state":"error"'*)
          DOMAIN_FINISHED=1
          DOMAIN_ERROR="$(printf '%s' "$DST" | json_error)"
          warn "could not get a certificate; leaving the node on its IP + self-signed cert."
          [ -n "$DOMAIN_ERROR" ] && warn "$DOMAIN_ERROR"
          break;;
      esac
    done
  fi
  [ "$DOMAIN_FINISHED" = 1 ] || warn "Certificate setup did not finish within 3 minutes. The node remains available on its IP with a self-signed certificate; retry from the panel."
fi

SUBTOKEN="$(curl -fsS -b "$CJ" "$B/admin/network-settings.json" -H "$UA" 2>/dev/null | grep -oE '"subToken":"[a-f0-9]+"' | cut -d'"' -f4 || true)"

# ---- managed-node enrollment -------------------------------------------------
# Create a local API token, register with the main panel, then lock this node
# (nodeMode = stub page + no sign-in). The parent drives it over that API token.
ENROLLED=0
if [ "$NODE_MODE" = 1 ]; then
  say "Registering this node with ${NOVA_JOIN_URL}"
  NODE_PORT_SFX=""; [ "${FRONT_PORT:-443}" != 443 ] && NODE_PORT_SFX=":$FRONT_PORT"
  NODE_URL="https://$(url_host "$HOST")$NODE_PORT_SFX"
  NODE_CERT_DER=""
  if [ "$INSECURE" = true ]; then
    NODE_CERT_DER="$(openssl x509 -in "$CERT_DIR/origin.pem" -outform DER 2>/dev/null | base64 -w0 2>/dev/null || true)"
  fi
  # Mint an owner-scoped API token on this node for the parent to use.
  NODE_TOKEN="$(curl -fsS -b "$CJ" -X POST "$B/admin/api-tokens" -H "$UA" -H 'Content-Type: application/json' \
    -d '{"name":"fleet-parent","role":"owner"}' 2>/dev/null | grep -oE '"token":"[^"]+"' | cut -d'"' -f4 || true)"
  if [ -z "$NODE_TOKEN" ]; then
    warn "Could not create an API token; this node was NOT registered. It still runs as a standalone panel."
  elif [ "$INSECURE" = true ] && [ -z "$NODE_CERT_DER" ]; then
    warn "Could not read this node's TLS certificate; enrollment was stopped before sending its owner token."
  elif [ -n "${NOVA_JOIN_PIN:-}" ] && [[ ! "$NOVA_JOIN_PIN" =~ ^sha256//[A-Za-z0-9+/]{43}=$ ]]; then
    warn "The main panel supplied an invalid certificate pin; enrollment was stopped."
  else
    NNAME="$(hostname -s 2>/dev/null || echo node)"
    EBODY="$(json_body token string "$NOVA_JOIN_TOKEN" url string "$NODE_URL" apiToken string "$NODE_TOKEN" name string "$NNAME" insecure boolean "$INSECURE" certDer string "$NODE_CERT_DER")"
    # A domain parent is verified by the normal CA chain. A self-signed parent
    # supplies its SPKI pin in the generated one-liner. curl enforces that pin
    # even with -k, so a different certificate never receives the owner token.
    # There is intentionally no unpinned -k fallback.
    ENROLL_TLS=()
    if [ -n "${NOVA_JOIN_PIN:-}" ]; then
      ENROLL_TLS=(-k --pinnedpubkey "$NOVA_JOIN_PIN")
    fi
    ERESP="$(curl -fsS ${ENROLL_TLS[@]+"${ENROLL_TLS[@]}"} -X POST "${NOVA_JOIN_URL%/}/nodes/enroll" -H 'Content-Type: application/json' --data-binary @- <<< "$EBODY" 2>/dev/null || true)"
    case "$ERESP" in
      *'"ok":true'*) ENROLLED=1; ok "node registered with the main panel" ;;
      *) warn "The main panel did not accept the enrollment (token expired or address unreachable). Response: ${ERESP:-none}" ;;
    esac
  fi
  # Only lock the node (nodeMode = no sign-in) and drop the temp password AFTER a
  # CONFIRMED enrollment. A failed enroll must leave a recoverable box: keep the
  # password and nodeMode off so the operator can still sign in locally or add the
  # node by hand, instead of orphaning it (no parent control AND no local login).
  if [ "$ENROLLED" = 1 ]; then
    curl -fsS -b "$CJ" -X POST "$B/admin/network-settings.json" -H "$UA" -H 'Content-Type: application/json' \
      -d '{"nodeMode":true}' >/dev/null 2>&1 || true
    NOVA_DB="$DB_DIR/nova.db" node -e 'import("/opt/nova-node-agent/src/kv/sqlite.mjs").then(async m=>{const kv=m.openKv(process.env.NOVA_DB);await kv.delete("admin_pass");}).catch(()=>{})' >/dev/null 2>&1 || true
  fi
  rm -f "$CJ"
  sleep 2
  echo
  if [ "$ENROLLED" = 1 ]; then
    printf '%s\n' "${c_grn}${c_bld}Nova managed node is ready.${c_rst}"
    echo
    printf '  %-16s %s\n' "Node address:" "$NODE_URL"
    printf '  %-16s %s\n' "Registered to:" "$NOVA_JOIN_URL"
    printf '  %s\n' "Manage this node from that panel's Nodes page. It has no panel of its own."
  else
    printf '%s\n' "${c_yel}${c_bld}Node installed, but NOT registered.${c_rst}"
    echo
    printf '  %s\n' "Kept as a normal panel so it is not stranded. To add it by hand in the main"
    printf '  %s\n' "panel (Nodes > add manually), use this address and API token:"
    printf '  %-16s %s\n' "Node address:" "$NODE_URL"
    printf '  %-16s %s\n' "API token:" "${NODE_TOKEN:-<none minted; re-run Add node for a fresh one-liner>}"
    printf '  %s\n' "For local sign-in on this box, set a password:  nova-passwd 'YourPassword'"
  fi
  echo
  exit 0
fi

# ---- panel access (stealth path + extra port) --------------------------------
# Applied LAST: after this save the /admin surface only answers under the path,
# so every root-scoped call above must already be done. Fresh installs default
# to a random secret path (NOVA_PANEL_PATH=none opts out); re-runs never touch
# an existing path. The agent opens the extra port in ufw by itself on save.
PANEL_PATH=""
if [ "$FRESH_SETUP" = 1 ] || [ "$ADMIN_PASS" != "(unchanged from a previous install)" ] || [ -n "${NOVA_ADMIN_PASS:-}" ]; then
  if [ "${NOVA_PANEL_PATH:-}" = "none" ]; then
    PANEL_PATH=""
  elif [ -n "${NOVA_PANEL_PATH:-}" ]; then
    PANEL_PATH="$NOVA_PANEL_PATH"
  elif [ "$FRESH_SETUP" = 1 ] && [ -z "$LOCAL_PANEL_PATH" ]; then
    # fresh install, nothing chosen: generate a random path with real entropy
    # (128-bit; the old 3-byte/24-bit path was guessable). It only needs to be
    # copy-pasted, never typed.
    PANEL_PATH="p-$(openssl rand -hex 16)"
  else
    PANEL_PATH="$LOCAL_PANEL_PATH"
  fi
  PANEL_ARGS=()
  [ -n "$PANEL_PATH" ] && PANEL_ARGS+=(panelPath string "$PANEL_PATH")
  if [ -n "${NOVA_PANEL_PORT:-}" ]; then
    PANEL_ARGS+=(panelPort number "$NOVA_PANEL_PORT")
  fi
  if [ "${#PANEL_ARGS[@]}" -gt 0 ]; then
    PBODY="$(json_body "${PANEL_ARGS[@]}")"
    say "Securing the panel (path/port)"
    if curl -fsS -b "$CJ" -X POST "$B/admin/network-settings.json" -H "$UA" -H 'Content-Type: application/json' \
      --data-binary @- <<< "$PBODY" >/dev/null 2>&1; then
      ok "panel access configured"
    else
      warn "Could not set the panel path/port; the panel stays at the root."
      PANEL_PATH=""; NOVA_PANEL_PORT=""
    fi
  fi
fi
rm -f "$CJ"

# SECURITY: we DELIBERATELY keep the admin password set (and print it below) rather
# than clearing it for a "set your password on first visit" screen. Clearing it
# left an unauthenticated window where anyone who reached the panel (only the
# stealth path stood in the way, and nothing at all with NOVA_PANEL_PATH=none)
# could POST /install/set and claim owner. With the password kept, /install/set is
# closed (409) from the start; the operator signs in with the printed password and
# can change it in Settings. Host, users and settings are untouched either way.
FIRST_RUN=0
sleep 2
ok "panel configured; xray $(systemctl is-active xray 2>/dev/null)"

# ---- summary -----------------------------------------------------------------
# The effective panel path/port straight from the node's DB: authoritative on
# both fresh installs and re-runs (where the local API is path-gated).
# path and port are joined with a literal '|' (never a space) so an empty path
# does not shift the port into the path field when we split them.
EFF="$(NOVA_DB="$DB_DIR/nova.db" node -e 'import("/opt/nova-node-agent/src/kv/sqlite.mjs").then(async m=>{const kv=m.openKv(process.env.NOVA_DB);try{const s=JSON.parse(await kv.get("network-settings.json")||"{}");const p=String(s.panelPath||"").replace(/^\/+|\/+$/g,"");const ok=/^[A-Za-z0-9_-]{3,64}$/.test(p)?p:"";const n=Math.floor(Number(s.panelPort||0));console.log(ok+"|"+((n>=1&&n<=65535)?n:0));}catch{console.log("|0")}kv.close&&kv.close();}).catch(()=>console.log("|0"))' 2>/dev/null || echo "|0")"
EFF_PATH="${EFF%%|*}"
EFF_PORT="${EFF##*|}"
# Carry the custom front port into every printed link so they point where the
# node actually serves (not the default 443 the box could not use).
PORT_SFX=""; [ "${FRONT_PORT:-443}" != 443 ] && PORT_SFX=":$FRONT_PORT"
# Report the node as it actually is, not as this run left its own variables.
# HOST and INSECURE are seeded with the first-run defaults (the public IP, a
# self-signed certificate) and are only corrected when a certificate is issued
# in THIS run. Re-running the installer on an already configured node with a
# domain therefore printed its IP and told the operator "No domain: this uses a
# self-signed certificate", followed by instructions to switch the app to
# no-domain mode and to accept a certificate warning that does not exist. The
# install was correct every time; only the summary was wrong. Same failure as
# the 1.69.1 readiness poll: believing this run's local state over the node's.
if [ "${DOMAIN_FINISHED:-0}" != 1 ] && [ -n "$LOCAL_HOST" ]; then
  HOST="$LOCAL_HOST"
  [ "$LOCAL_INSECURE" = 0 ] && INSECURE=false
fi
URL_HOST="$(url_host "$HOST")"
PANEL_URL="https://$URL_HOST$PORT_SFX/"
[ -n "$EFF_PATH" ] && PANEL_URL="https://$URL_HOST$PORT_SFX/$EFF_PATH/"
echo
printf '%s\n' "${c_grn}${c_bld}Nova node is ready.${c_rst}"
echo
printf '  %-16s %s\n' "Server address:" "$HOST"
if [ "${FIRST_RUN:-0}" = 1 ]; then
  printf '  %-16s %s\n' "Admin password:" "you set it on first visit (see below)"
else
  printf '  %-16s %s\n' "Admin password:" "$ADMIN_PASS"
fi
printf '  %-16s %s\n' "Web panel:" "$PANEL_URL"
[ -n "${EFF_PORT:-}" ] && [ "$EFF_PORT" != 0 ] && printf '  %-16s %s\n' "Panel port:" "https://$URL_HOST:$EFF_PORT/${EFF_PATH:+$EFF_PATH/}"
[ -n "${SUBTOKEN:-}" ] && printf '  %-16s %s\n' "Subscription:" "https://$URL_HOST$PORT_SFX/sub?token=$SUBTOKEN"
echo
if [ -n "$EFF_PATH" ]; then
  printf '  %s\n' "${c_yel}${c_bld}Save the panel URL: the secret path is what hides your panel.${c_rst}"
  printf '  %s\n' "  Anyone opening the bare address just sees \"404 Not Found\"."
  # nova-access, NOT nova-passwd. This used to say `nova-passwd 'NewPassword'`,
  # which resets the admin password as a side effect of asking where the panel
  # is: the URL is only printed AFTER the reset, and with no argument that
  # command exits with a usage error instead. Operators losing the URL and being
  # told to change their password to find it is how "the panel 404s" became a
  # recurring report.
  printf '  %s\n' "  Forgot it? Run ${c_bld}nova-access${c_rst} over SSH: it prints the URL and changes nothing."
  echo
fi
if [ "${FIRST_RUN:-0}" = 1 ]; then
  printf '  %s\n' "${c_cyn}${c_bld}Open the web panel above and create your admin password to begin.${c_rst}"
  echo
fi
if [ "$INSECURE" = true ]; then
  printf '  %s\n' "${c_yel}No domain: this uses a self-signed certificate.${c_rst}"
  printf '  %s\n' "  - In the Nova app: Connect your VPS, turn ON \"My server has no domain\"."
  printf '  %s\n' "  - In a browser: accept the certificate warning once."
else
  printf '  %s\n' "For a trusted certificate behind Cloudflare (Full strict), replace"
  printf '  %s\n' "$CERT_DIR/origin.pem + origin.key with your Cloudflare Origin Certificate."
fi
echo
printf '  %s\n' "Manage it: open the Nova app -> Connect your VPS -> enter the WEB PANEL"
printf '  %s\n' "URL above (including the secret path, if set) and the admin password,"
printf '  %s\n' "or just open the web panel URL in a browser."
echo
printf '  %s\n' "Uninstall anytime with:  ${c_bld}nova-uninstall${c_rst}"
echo
