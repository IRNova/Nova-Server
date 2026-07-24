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

# ---- setup questions ---------------------------------------------------------
# Asked up front so the rest of the install runs unattended. Reads /dev/tty so
# both `bash <(curl ...)` and `curl ... | bash` forms work; with no terminal (or
# NOVA_NO_PROMPT=1) the env values / defaults are used silently.
ask() { # prompt  ->  REPLY
  REPLY=""
  [ "${NOVA_NO_PROMPT:-0}" = 1 ] && return 0
  [ -r /dev/tty ] || return 0
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
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
    | grep browser_download_url | grep -i "$2" | head -1 | cut -d'"' -f4
}

# Backhaul (default): widest transport set, connection pooling, self-signed OK.
if ! command -v backhaul >/dev/null 2>&1; then
  say "Installing Backhaul tunnel backend"
  if curl -fsSL -o /tmp/backhaul.tgz "https://github.com/Musixal/Backhaul/releases/latest/download/backhaul_linux_${garch}.tar.gz" \
     && tar -xzf /tmp/backhaul.tgz -C /usr/local/bin backhaul 2>/dev/null; then
    chmod +x /usr/local/bin/backhaul && ok "Backhaul installed"
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
      chmod +x /usr/local/bin/backpack && ok "BackPack installed (checksum verified)"
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
    chmod +x /usr/local/bin/rathole && ok "rathole installed"
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
    chmod +x /usr/local/bin/wstunnel && ok "wstunnel installed"
  else
    warn "Could not install wstunnel; that tunnel backend will be unavailable."
  fi
fi
mkdir -p /etc/nova/tunnel && chmod 700 /etc/nova/tunnel

# A convenience shortcut so a locked-out admin can reset their password over SSH:
#   nova-passwd 'NewPassword' [--clear-2fa]
cat > /usr/local/bin/nova-passwd <<'NPW'
#!/bin/bash
exec node /opt/nova-node-agent/bin/reset-password.mjs "$@"
NPW
chmod +x /usr/local/bin/nova-passwd 2>/dev/null || true

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
# --warning=no-unknown-keyword: hide the harmless "Ignoring unknown extended
# header keyword" lines GNU tar prints when a release tarball was built on macOS
# (Apple provenance xattrs). Extraction succeeds either way; the flag keeps the
# output clean so a successful install never looks like it errored.
tar --warning=no-unknown-keyword -xzf "$tmp/agent.tar.gz" -C "$AGENT_DIR" || die "Could not extract the agent."
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
systemctl enable nova-agent >/dev/null 2>&1 || true
# restart (not just enable --now): on a re-run the agent is already active and
# "enable --now" would NOT pick up freshly extracted code. restart starts it when
# stopped and reloads new code when running, so re-running the one-liner also
# updates an existing node.
systemctl restart nova-agent >/dev/null 2>&1 || die "Could not start nova-agent."

# Wait for the agent's local API to answer /install/status with a real JSON body,
# and read whether the panel is already configured. Reading the actual state (not
# just "did any HTTP code come back") is what lets us tell a genuine re-install
# from a momentary hiccup during first boot, so a single transient can never make
# the installer skip configuring a fresh node.
CONFIGURED=""
for i in $(seq 1 40); do
  RESP="$(curl -fsS "http://127.0.0.1:8088/install/status" 2>/dev/null || true)"
  case "$RESP" in
    *'"configured"'*)
      case "$RESP" in *'"configured":true'*) CONFIGURED=true;; *) CONFIGURED=false;; esac
      break;;
  esac
  sleep 1
done
[ -n "$CONFIGURED" ] || die "The agent did not respond in time. Check: journalctl -u nova-agent -n 50"
ok "agent running"

# ---- configure the panel -----------------------------------------------------
ADMIN_PASS="${NOVA_ADMIN_PASS:-$(openssl rand -base64 12 | tr -dc 'A-Za-z0-9' | head -c 14)}"
UA='User-Agent: Nova/1.0.0 (desktop; sing-box)'
B=http://127.0.0.1:8088
CJ="$(mktemp)"

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
  for i in $(seq 1 10); do
    if curl -fsS -c "$CJ" -X POST "$B/install/set" -H "$UA" -H 'Content-Type: application/json' \
      -d "{\"password\":\"$ADMIN_PASS\"}" >/dev/null 2>&1; then SET_OK=1; break; fi
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

# ---- managed-node enrollment -------------------------------------------------
# Create a local API token, register with the main panel, then lock this node
# (nodeMode = stub page + no sign-in). The parent drives it over that API token.
ENROLLED=0
if [ "$NODE_MODE" = 1 ]; then
  say "Registering this node with ${NOVA_JOIN_URL}"
  NODE_URL="https://$HOST"
  # Mint an owner-scoped API token on this node for the parent to use.
  NODE_TOKEN="$(curl -fsS -b "$CJ" -X POST "$B/admin/api-tokens" -H "$UA" -H 'Content-Type: application/json' \
    -d '{"name":"fleet-parent","role":"owner"}' 2>/dev/null | grep -oE '"token":"[^"]+"' | cut -d'"' -f4 || true)"
  if [ -z "$NODE_TOKEN" ]; then
    warn "Could not create an API token; this node was NOT registered. It still runs as a standalone panel."
  else
    NNAME="$(hostname -s 2>/dev/null || echo node)"
    EBODY="{\"token\":\"$NOVA_JOIN_TOKEN\",\"url\":\"$NODE_URL\",\"apiToken\":\"$NODE_TOKEN\",\"name\":\"$NNAME\",\"insecure\":$INSECURE}"
    # The parent may itself be on a self-signed cert, so allow an insecure TLS
    # handshake for this one enrollment call (-k).
    ERESP="$(curl -fsS -k -X POST "${NOVA_JOIN_URL%/}/nodes/enroll" -H 'Content-Type: application/json' -d "$EBODY" 2>/dev/null || true)"
    case "$ERESP" in
      *'"ok":true'*) ENROLLED=1; ok "node registered with the main panel" ;;
      *) warn "The main panel did not accept the enrollment (token expired or address unreachable). Response: ${ERESP:-none}" ;;
    esac
  fi
  # Lock the node regardless: a managed node should never expose a sign-in, even
  # if enrollment needs a retry from the parent side.
  curl -fsS -b "$CJ" -X POST "$B/admin/network-settings.json" -H "$UA" -H 'Content-Type: application/json' \
    -d '{"nodeMode":true}' >/dev/null 2>&1 || true
  rm -f "$CJ"
  # Clear the temporary admin password (nodeMode already blocks sign-in; this
  # removes the credential entirely).
  NOVA_DB="$DB_DIR/nova.db" node -e 'import("/opt/nova-node-agent/src/kv/sqlite.mjs").then(async m=>{const kv=m.openKv(process.env.NOVA_DB);await kv.delete("admin_pass");}).catch(()=>{})' >/dev/null 2>&1 || true
  sleep 2
  echo
  printf '%s\n' "${c_grn}${c_bld}Nova managed node is ready.${c_rst}"
  echo
  printf '  %-16s %s\n' "Node address:" "$NODE_URL"
  if [ "$ENROLLED" = 1 ]; then
    printf '  %-16s %s\n' "Registered to:" "$NOVA_JOIN_URL"
    printf '  %s\n' "Manage this node from that panel's Nodes page. It has no panel of its own."
  else
    printf '  %s\n' "${c_yel}Not yet registered.${c_rst} In the main panel, add the node manually:"
    printf '  %s\n' "  URL: $NODE_URL   (mark \"no domain\" if it shows a self-signed cert)"
    printf '  %s\n' "  API token: shown once above was not captured; re-run \"Add node\" for a new one-liner."
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
if [ "$ADMIN_PASS" != "(unchanged from a previous install)" ] || [ -n "${NOVA_ADMIN_PASS:-}" ]; then
  if [ "${NOVA_PANEL_PATH:-}" = "none" ]; then
    PANEL_PATH=""
  elif [ -n "${NOVA_PANEL_PATH:-}" ]; then
    PANEL_PATH="$NOVA_PANEL_PATH"
  elif [ "$ADMIN_PASS" != "(unchanged from a previous install)" ]; then
    # fresh install, nothing chosen: generate a short random path
    PANEL_PATH="p-$(openssl rand -hex 3)"
  fi
  PBODY=""
  [ -n "$PANEL_PATH" ] && PBODY="\"panelPath\":\"$PANEL_PATH\""
  if [ -n "${NOVA_PANEL_PORT:-}" ]; then
    [ -n "$PBODY" ] && PBODY="$PBODY,"
    PBODY="$PBODY\"panelPort\":$NOVA_PANEL_PORT"
  fi
  if [ -n "$PBODY" ]; then
    say "Securing the panel (path/port)"
    if curl -fsS -b "$CJ" -X POST "$B/admin/network-settings.json" -H "$UA" -H 'Content-Type: application/json' \
      -d "{$PBODY}" >/dev/null 2>&1; then
      ok "panel access configured"
    else
      warn "Could not set the panel path/port; the panel stays at the root."
      PANEL_PATH=""; NOVA_PANEL_PORT=""
    fi
  fi
fi
rm -f "$CJ"

# Return the panel to its first-run "create your password" screen unless the
# operator pinned a password with NOVA_ADMIN_PASS. The temporary password above
# only existed so this installer could seed host, protocols and a starter user
# over the local API; clearing it now means the admin sets their own password on
# first visit, and nothing else (host, users, settings) is touched.
FIRST_RUN=0
if [ -z "${NOVA_ADMIN_PASS:-}" ] && [ "$ADMIN_PASS" != "(unchanged from a previous install)" ]; then
  NOVA_DB="$DB_DIR/nova.db" node -e 'import("/opt/nova-node-agent/src/kv/sqlite.mjs").then(async m=>{const kv=m.openKv(process.env.NOVA_DB);await kv.delete("admin_pass");}).catch(()=>{})' >/dev/null 2>&1 && FIRST_RUN=1 || true
fi
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
PANEL_URL="https://$HOST/"
[ -n "$EFF_PATH" ] && PANEL_URL="https://$HOST/$EFF_PATH/"
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
[ -n "${EFF_PORT:-}" ] && [ "$EFF_PORT" != 0 ] && printf '  %-16s %s\n' "Panel port:" "https://$HOST:$EFF_PORT/${EFF_PATH:+$EFF_PATH/}"
[ -n "${SUBTOKEN:-}" ] && printf '  %-16s %s\n' "Subscription:" "https://$HOST/sub?token=$SUBTOKEN"
echo
if [ -n "$EFF_PATH" ]; then
  printf '  %s\n' "${c_yel}${c_bld}Save the panel URL: the secret path is what hides your panel.${c_rst}"
  printf '  %s\n' "  Anyone opening the bare address just sees \"404 Not Found\"."
  printf '  %s\n' "  Forgot it? Run ${c_bld}nova-passwd 'NewPassword'${c_rst} over SSH - it prints the URL."
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
