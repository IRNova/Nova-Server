#!/usr/bin/env bash
# =============================================================================
#  Nova Node  —  one-line VPS installer for the full Nova panel
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
# =============================================================================
set -euo pipefail

TARBALL_URL="${NOVA_TARBALL_URL:-https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node-agent.tar.gz}"
AGENT_DIR=/opt/nova-node-agent
CERT_DIR=/etc/nova
DB_DIR=/var/lib/nova

c_grn=$'\033[0;32m'; c_red=$'\033[0;31m'; c_yel=$'\033[1;33m'; c_cyn=$'\033[0;36m'; c_bld=$'\033[1m'; c_rst=$'\033[0m'
say()  { printf '%s\n' "${c_cyn}==>${c_rst} $*"; }
ok()   { printf '%s\n' "${c_grn}OK${c_rst}  $*"; }
warn() { printf '%s\n' "${c_yel}!!${c_rst}  $*"; }
die()  { printf '%s\n' "${c_red}xx${c_rst}  $*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "Please run as root (sudo)."

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

# ---- xray-core ---------------------------------------------------------------
if ! command -v xray >/dev/null 2>&1 && [ ! -x /usr/local/bin/xray ]; then
  say "Installing xray-core"
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1 \
    || die "xray-core install failed."
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
  systemctl daemon-reload
  systemctl enable sing-box >/dev/null 2>&1 || true
  HAS_SINGBOX=1
  ok "sing-box installed"
  # grpcurl: the agent uses it to read sing-box's per-user stats for quota.
  if ! command -v grpcurl >/dev/null 2>&1; then
    garch="$(uname -m)"; case "$garch" in aarch64) garch=arm64;; x86_64) garch=x86_64;; esac
    curl -fsSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_linux_${garch}.tar.gz" -o /tmp/grpcurl.tgz 2>/dev/null \
      && tar -xzf /tmp/grpcurl.tgz -C /usr/local/bin grpcurl 2>/dev/null \
      && chmod +x /usr/local/bin/grpcurl 2>/dev/null || warn "grpcurl install failed; Hysteria2 usage will not be metered."
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
  DEBIAN_FRONTEND=noninteractive apt-get install -y tor >/dev/null 2>&1 \
    && systemctl enable --now tor >/dev/null 2>&1 && ok "Tor installed" \
    || warn "Could not install Tor; the Tor exit will be unavailable."
fi
if [ ! -x /etc/psiphon/psiphon-tunnel-core-x86_64 ]; then
  say "Installing Psiphon (local SOCKS exit on 1080)"
  mkdir -p /etc/psiphon
  arch="$(uname -m)"; pbin="psiphon-tunnel-core-x86_64"
  [ "$arch" = "aarch64" ] && pbin="psiphon-tunnel-core-arm64"
  if curl -fsSL -o /etc/psiphon/"$pbin" "https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/linux/$pbin" \
     && curl -fsSL -o /etc/psiphon/psiphon.config "https://raw.githubusercontent.com/IRNova/Nova-Server/main/psiphon.config"; then
    chmod +x /etc/psiphon/"$pbin"
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

# ---- agent code --------------------------------------------------------------
say "Fetching the Nova node agent"
mkdir -p "$AGENT_DIR" "$DB_DIR" "$CERT_DIR"
tmp="$(mktemp -d)"
curl -fsSL "$TARBALL_URL" -o "$tmp/agent.tar.gz" || die "Could not download the agent."
tar xzf "$tmp/agent.tar.gz" -C "$AGENT_DIR" || die "Could not extract the agent."
rm -rf "$tmp"
ok "agent installed at $AGENT_DIR"

# ---- host + TLS cert ---------------------------------------------------------
PUBIP="$(curl -fsSL https://api.ipify.org 2>/dev/null || curl -fsSL https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
# The node always comes up self-signed on its public IP. If NOVA_DOMAIN is set we
# switch it to a trusted Let's Encrypt cert further down, once the agent is live
# (same code path the app/panel "add a domain" button uses).
HOST="$PUBIP"; INSECURE=true

if [ ! -s "$CERT_DIR/origin.pem" ] || [ ! -s "$CERT_DIR/origin.key" ]; then
  say "Generating a TLS certificate for $HOST"
  openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout "$CERT_DIR/origin.key" -out "$CERT_DIR/origin.pem" \
    -subj "/CN=$HOST" -addext "subjectAltName=DNS:$HOST,IP:$PUBIP" >/dev/null 2>&1 \
    || openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
       -keyout "$CERT_DIR/origin.key" -out "$CERT_DIR/origin.pem" -subj "/CN=$HOST" >/dev/null 2>&1
fi
# xray runs as user 'nobody' (group nogroup); let it read the key.
chgrp nogroup "$CERT_DIR/origin.pem" "$CERT_DIR/origin.key" 2>/dev/null || true
chmod 640 "$CERT_DIR/origin.pem" "$CERT_DIR/origin.key"
ok "certificate ready"

# ---- env + systemd -----------------------------------------------------------
say "Configuring services"
cat > "$CERT_DIR/agent.env" <<ENV
NOVA_DB=$DB_DIR/nova.db
NOVA_PORT=8088
NOVA_HOST=127.0.0.1
NOVA_POLL_MS=30000
NOVA_XRAY_API=127.0.0.1:10085
NOVA_XRAY_BIN=$XRAY_BIN
ENV

NODE_BIN="$(command -v node)"
cat > /etc/systemd/system/nova-agent.service <<UNIT
[Unit]
Description=Nova VPS node agent (admin panel + xray bridge)
After=network-online.target xray.service
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$AGENT_DIR
ExecStart=$NODE_BIN $AGENT_DIR/bin/nova-agent.mjs
EnvironmentFile=$CERT_DIR/agent.env
Restart=always
RestartSec=2
User=root
StateDirectory=nova

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now nova-agent >/dev/null 2>&1 || die "Could not start nova-agent."

# wait for the agent's local API
for i in $(seq 1 20); do
  curl -fsS "http://127.0.0.1:8088/install/status" >/dev/null 2>&1 && break
  sleep 1
done
ok "agent running"

# ---- configure the panel -----------------------------------------------------
ADMIN_PASS="${NOVA_ADMIN_PASS:-$(openssl rand -base64 12 | tr -dc 'A-Za-z0-9' | head -c 14)}"
UA='User-Agent: Nova/1.0.0 (desktop; sing-box)'
B=http://127.0.0.1:8088
CJ="$(mktemp)"

say "Setting up the panel"
# First run only; ignore "already configured" on re-install.
curl -fsS -c "$CJ" -X POST "$B/install/set" -H "$UA" -H 'Content-Type: application/json' \
  -d "{\"password\":\"$ADMIN_PASS\"}" >/dev/null 2>&1 || {
    warn "Panel already configured; keeping the existing password."
    ADMIN_PASS="(unchanged from a previous install)"
  }
# Log in (works whether we just set it or it already existed and the caller passed NOVA_ADMIN_PASS).
if [ "${NOVA_ADMIN_PASS:-}" != "" ]; then
  curl -fsS -c "$CJ" -X POST "$B/login" -H "$UA" -H 'Content-Type: application/json' \
    -d "{\"password\":\"$NOVA_ADMIN_PASS\"}" >/dev/null 2>&1 || true
fi

# Host, self-signed flag, and every protocol on by default (the app then
# auto-picks the fastest); Hysteria2 only when sing-box installed.
HY2=false; [ "${HAS_SINGBOX:-0}" = 1 ] && HY2=true
curl -fsS -b "$CJ" -X POST "$B/admin/network-settings.json" -H "$UA" -H 'Content-Type: application/json' \
  -d "{\"host\":\"$HOST\",\"insecure\":$INSECURE,\"protocols\":{\"vless\":true,\"vmess\":true,\"trojan\":true,\"hysteria2\":$HY2}}" >/dev/null 2>&1 || true

# Seed one user so the node is usable immediately, but only on a fresh node
# (re-running the installer must not churn an existing user's UUID).
USER_COUNT="$(curl -fsS -b "$CJ" "$B/admin/network-settings.json" -H "$UA" 2>/dev/null \
  | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{try{console.log((JSON.parse(s).users||[]).length)}catch{console.log(0)}})" 2>/dev/null || echo 0)"
if [ "${USER_COUNT:-0}" = 0 ]; then
  UUID="$(cat /proc/sys/kernel/random/uuid)"
  curl -fsS -b "$CJ" -X POST "$B/admin/users.json" -H "$UA" -H 'Content-Type: application/json' \
    -d "{\"action\":\"add\",\"user\":{\"id\":\"me\",\"uuid\":\"$UUID\",\"email\":\"me\",\"enabled\":true}}" >/dev/null 2>&1 || true
fi

# If a domain was requested, provision a trusted Let's Encrypt cert and switch
# the node over to it. Needs port 80 reachable and the domain's DNS pointing here.
if [ -n "${NOVA_DOMAIN:-}" ]; then
  say "Getting a certificate for $NOVA_DOMAIN (Let's Encrypt)"
  DBODY="{\"domain\":\"$NOVA_DOMAIN\",\"method\":\"letsencrypt\""
  [ -n "${NOVA_DOMAIN_EMAIL:-}" ] && DBODY="$DBODY,\"email\":\"$NOVA_DOMAIN_EMAIL\""
  DBODY="$DBODY}"
  curl -fsS -b "$CJ" -X POST "$B/admin/domain" -H "$UA" -H 'Content-Type: application/json' \
    -d "$DBODY" >/dev/null 2>&1 || true
  for i in $(seq 1 36); do
    sleep 5
    DST="$(curl -fsS -b "$CJ" "$B/admin/domain" -H "$UA" 2>/dev/null || true)"
    case "$DST" in
      *'"state":"active"'*) HOST="$NOVA_DOMAIN"; INSECURE=false; ok "certificate issued for $NOVA_DOMAIN"; break;;
      *'"state":"error"'*)  warn "could not get a certificate; leaving the node on its IP + self-signed cert."; break;;
    esac
  done
fi

SUBTOKEN="$(curl -fsS -b "$CJ" "$B/admin/network-settings.json" -H "$UA" 2>/dev/null | grep -oE '"subToken":"[a-f0-9]+"' | cut -d'"' -f4 || true)"
rm -f "$CJ"
sleep 2
ok "panel configured; xray $(systemctl is-active xray 2>/dev/null)"

# ---- summary -----------------------------------------------------------------
echo
printf '%s\n' "${c_grn}${c_bld}Nova node is ready.${c_rst}"
echo
printf '  %-16s %s\n' "Server address:" "$HOST"
printf '  %-16s %s\n' "Admin password:" "$ADMIN_PASS"
printf '  %-16s %s\n' "Web panel:" "https://$HOST/"
[ -n "${SUBTOKEN:-}" ] && printf '  %-16s %s\n' "Subscription:" "https://$HOST/sub?token=$SUBTOKEN"
echo
if [ "$INSECURE" = true ]; then
  printf '  %s\n' "${c_yel}No domain: this uses a self-signed certificate.${c_rst}"
  printf '  %s\n' "  - In the Nova app: Connect your VPS, turn ON \"My server has no domain\"."
  printf '  %s\n' "  - In a browser: accept the certificate warning once."
else
  printf '  %s\n' "For a trusted certificate behind Cloudflare (Full strict), replace"
  printf '  %s\n' "$CERT_DIR/origin.pem + origin.key with your Cloudflare Origin Certificate."
fi
echo
printf '  %s\n' "Manage it: open the Nova app -> Connect your VPS -> enter the address"
printf '  %s\n' "and admin password above, or just open the web panel URL."
echo
