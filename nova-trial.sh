#!/usr/bin/env bash
# Nova trial: is this VPS actually usable from Iran?
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-trial.sh)
#
# WHY THIS EXISTS
#
# You buy a VPS, SSH answers, check-host pings it from everywhere, and then you
# install a panel, hand a customer a config, and discover the IP is useless from
# Tehran. SSH and ICMP prove the address ROUTES. They do not prove it passes
# proxy traffic, and in Iran those are different questions: filtering is
# protocol- and port-specific, so an IP can answer every ping while 443 is
# throttled to nothing.
#
# The only honest test is a real connection from inside. This stands up a
# throwaway server, prints configs you can import on a phone in Iran, and then
# removes itself completely. Run it BEFORE you commit to a server, before Nova
# is installed and before you have configured anything.
#
# WHAT IT SERVES, AND WHY EACH ONE
#
# Two protocols, so one blocked transport cannot make you throw away a good IP:
#
#   TCP 443   VLESS + Reality    what a real node runs, and the port that matters
#   UDP 443   Hysteria2          the QUIC/UDP path, blocked independently of TCP
#
# and the same two on one random high port, which is what turns a failure into a
# diagnosis:
#
#   both ports fail          the IP itself is burned, return it
#   443 fails, high passes   the IP is fine and 443 is being targeted; a CDN
#                            front or a non-standard port will work here
#   443 passes               ship it
#
# Nothing is built from source and no kernel module is involved: it is one
# static sing-box binary, so a fresh box is answering within seconds. AmneziaWG
# would be closer to what a Nova node serves WireGuard users, but as a SERVER it
# needs kernel headers and a DKMS build, which is minutes on a fresh VPS and the
# step most likely to fail outright. A test that cannot start teaches nothing.
#
# WHAT IT LEAVES BEHIND
#
# Nothing, after an hour. That is not a courtesy, it is the point: this prints a
# working credential into a terminal, and terminals get pasted into chats. The
# expiry is an absolute deadline on disk, enforced by a systemd timer that also
# checks on boot, so it survives the SSH session ending and survives a reboot. A
# backgrounded `sleep 3600 && rm` does neither, which is why it is not used.
#
# The purge removes only what this script created. It records every file, unit
# and firewall rule it adds and undoes exactly those, so running this on a box
# that already has Nova cannot take Nova's sing-box, ports or rules with it.
set -euo pipefail

TRIAL_DIR=/etc/nova-trial
BIN=/usr/local/bin/sing-box-nova
OWNED="$TRIAL_DIR/owned"
DEADLINE="$TRIAL_DIR/deadline"
PURGE=/usr/local/sbin/nova-trial-purge
REAP=/usr/local/sbin/nova-trial-reap
SINGBOX_URL="${NOVA_SINGBOX_URL:-https://github.com/IRNova/Tools/releases/download/sing-box/sing-box-nova.gz}"
SINGBOX_SHA_URL="${NOVA_SINGBOX_SHA_URL:-${SINGBOX_URL}.sha256}"
# An hour by default, because that is long enough to import a config, walk to a
# different network and try again, and short enough that a forgotten trial is
# not a standing back door.
TRIAL_MINUTES="${NOVA_TRIAL_MINUTES:-60}"

C_OK=$'\033[0;32m'; C_ER=$'\033[0;31m'; C_WN=$'\033[1;33m'; C_IN=$'\033[0;36m'; C_0=$'\033[0m'
say()  { printf '%s==>%s %s\n' "$C_IN" "$C_0" "$*"; }
ok()   { printf '%s OK %s %s\n' "$C_OK" "$C_0" "$*"; }
warn() { printf '%s !! %s %s\n' "$C_WN" "$C_0" "$*"; }
die()  { printf '%s xx %s %s\n' "$C_ER" "$C_0" "$*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "Run this as root."
command -v systemctl >/dev/null 2>&1 || die "This needs systemd (Debian/Ubuntu)."

# Bounded, for the same reason the installer's downloads are: an unbounded curl
# against a host that stalls on connect freezes with no output, and a test tool
# that hangs is worse than one that fails.
dl() { curl -fsSL --connect-timeout 15 --max-time 120 --retry 2 --retry-delay 3 "$@"; }

# Everything this script creates gets a line here, and the purge reads it back.
# Recording rather than assuming is what makes it safe to run on a box that
# already has Nova: we never remove a path we did not put there.
mark() { printf '%s\n' "$1" >> "$OWNED"; }

# ---- refuse to fight an existing service ------------------------------------
port_busy() {
  if command -v ss >/dev/null 2>&1; then
    ss -lnH "sport = :$1" 2>/dev/null | grep -q . && return 0
  fi
  return 1
}

if [ -d "$TRIAL_DIR" ]; then
  warn "A trial is already set up. Removing it first."
  [ -x "$PURGE" ] && "$PURGE" >/dev/null 2>&1 || true
fi

say "Nova trial: checking whether this server is usable, before you commit to it"

# ---- pick ports --------------------------------------------------------------
# 443 is the one that matters, so it is tried first and its absence is reported
# rather than worked around silently: on a box that already runs something on
# 443 the high port still answers the "is this IP alive" half of the question.
USE_443=1
if port_busy 443; then
  USE_443=0
  warn "Something already listens on 443, so the trial uses only its high port."
  warn "That still tells you whether the IP is reachable, but not whether 443 is clean."
fi
# Deliberately above 32768 and random per run: a fixed port would itself become
# a signature worth blocking once this tool is used widely.
HIGH_PORT="$(( 33000 + RANDOM % 25000 ))"
while port_busy "$HIGH_PORT"; do HIGH_PORT="$(( 33000 + RANDOM % 25000 ))"; done

mkdir -p "$TRIAL_DIR"; chmod 700 "$TRIAL_DIR"
: > "$OWNED"
mark "$TRIAL_DIR"

# The purge is written FIRST, before anything it might have to remove exists.
#
# It used to be written near the end, next to the units, which reads naturally
# and is wrong: every failure between here and there (no Reality keys, a config
# sing-box rejects, a download that dies) left a directory, possibly a
# downloaded binary, and no way to clean up. A tool whose promise is "it removes
# itself" has to be able to do that from its first step, not only once it has
# succeeded.
write_purge() {
cat > "$PURGE" <<'PEOF'
#!/usr/bin/env bash
# Remove every trace of the Nova trial. Safe to run twice, and safe on a box
# that runs Nova: it only touches paths recorded in the owned list, so a
# sing-box that was already here when the trial started is left alone.
TRIAL_DIR=/etc/nova-trial
OWNED="$TRIAL_DIR/owned"
systemctl stop nova-trial.service 2>/dev/null
systemctl disable nova-trial.service 2>/dev/null
systemctl stop nova-trial-reaper.timer 2>/dev/null
systemctl disable nova-trial-reaper.timer 2>/dev/null
if [ -f "$OWNED" ]; then
  while IFS= read -r item; do
    case "$item" in
      ufw:*) p="${item#ufw:}"; ufw delete allow "$p" >/dev/null 2>&1 ;;
      ipt:*) p="${item#ipt:}"; port="${p%%/*}"; proto="${p##*/}"
             iptables -D INPUT -p "$proto" --dport "$port" -j ACCEPT 2>/dev/null ;;
      /*)    [ "$item" = "$TRIAL_DIR" ] || rm -rf "$item" ;;
    esac
  done < "$OWNED"
fi
rm -f /etc/systemd/system/nova-trial.service \
      /etc/systemd/system/nova-trial-reaper.service \
      /etc/systemd/system/nova-trial-reaper.timer
systemctl daemon-reload 2>/dev/null
rm -rf "$TRIAL_DIR"
rm -f /usr/local/sbin/nova-trial-reap
rm -f /usr/local/sbin/nova-trial-purge
exit 0
PEOF
chmod 0755 "$PURGE"
}
write_purge

# Either the trial is complete and can remove itself on a timer, or it never
# happened. There is no third state worth leaving on somebody's server.
TRIAL_DONE=0
on_exit() {
  [ "$TRIAL_DONE" = 1 ] && return 0
  warn "Setting up the trial failed; removing what it had created."
  [ -x "$PURGE" ] && "$PURGE" >/dev/null 2>&1
  rm -rf "$TRIAL_DIR" 2>/dev/null
  return 0
}
trap on_exit EXIT

# ---- the binary --------------------------------------------------------------
# Only downloaded when it is not already here, and only marked as ours when we
# are the ones who put it there. On a box that already runs Nova this reuses the
# node's binary and the purge leaves it alone.
if [ -x "$BIN" ]; then
  ok "using the sing-box already on this box"
else
  say "Fetching sing-box (one static binary, no build, no kernel module)"
  # The published sidecar covers the COMPRESSED file, which is what the node
  # installer verifies too. Hashing the decompressed binary instead looks
  # equally reasonable and fails every time, which is how this was found.
  want="$(dl --max-time 20 "$SINGBOX_SHA_URL" 2>/dev/null \
    | tr -d '\r' | awk 'NR==1{print $1}' | tr 'A-F' 'a-f' || true)"
  case "$want" in
    *[!0-9a-f]* | "") want="" ;;
    *) [ "${#want}" -eq 64 ] || want="" ;;
  esac
  tmpd="$(mktemp -d)"
  dl "$SINGBOX_URL" -o "$tmpd/sb.gz" || die "Could not download sing-box."
  if [ -n "$want" ]; then
    got="$(sha256sum "$tmpd/sb.gz" | awk '{print $1}')"
    [ "$got" = "$want" ] || die "sing-box checksum mismatch; refusing to run it."
    ok "checksum verified"
  else
    warn "No published checksum available; continuing without verifying it."
  fi
  gzip -dc "$tmpd/sb.gz" > "$tmpd/sb" 2>/dev/null || die "The sing-box download was not readable."
  install -m 0755 "$tmpd/sb" "$BIN"
  rm -rf "$tmpd"
  mark "$BIN"
fi

# ---- credentials -------------------------------------------------------------
UUID="$(cat /proc/sys/kernel/random/uuid)"
HY_PASS="$(head -c 18 /dev/urandom | base64 | tr -d '/+=' | head -c 24)"
KEYS="$("$BIN" generate reality-keypair 2>/dev/null || true)"
PRIV="$(printf '%s\n' "$KEYS" | awk '/PrivateKey/{print $2}')"
PUB="$(printf '%s\n' "$KEYS" | awk '/PublicKey/{print $2}')"
SID="$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')"
[ -n "$PRIV" ] && [ -n "$PUB" ] || die "Could not generate Reality keys."
# Borrowed as the TLS front. Any large site that is NOT blocked in Iran works;
# a blocked one would make the test fail for a reason that has nothing to do
# with this server.
SNI="${NOVA_TRIAL_SNI:-www.datadoghq.com}"

PUBIP="$(dl --max-time 6 https://api.ipify.org 2>/dev/null || dl --max-time 6 https://icanhazip.com 2>/dev/null || true)"
PUBIP="$(printf '%s' "$PUBIP" | tr -d '[:space:]')"
[ -n "$PUBIP" ] || die "Could not determine this server's public IP."

# ---- config ------------------------------------------------------------------
# A self-signed certificate for Hysteria2, which is fine here: the client config
# carries insecure=1 because this is a throwaway reachability test, not a
# confidentiality guarantee. Said plainly in the output too.
openssl req -x509 -nodes -newkey rsa:2048 -days 2 \
  -keyout "$TRIAL_DIR/key.pem" -out "$TRIAL_DIR/cert.pem" \
  -subj "/CN=$SNI" >/dev/null 2>&1 || die "Could not generate a certificate."

listeners=""
add_in() {  # proto, port
  case "$1" in
    hy2) listeners="$listeners"'
    {"type":"hysteria2","listen":"::","listen_port":'"$2"',
     "users":[{"password":"'"$HY_PASS"'"}],
     "tls":{"enabled":true,"alpn":["h3"],
            "certificate_path":"'"$TRIAL_DIR"'/cert.pem","key_path":"'"$TRIAL_DIR"'/key.pem"}},' ;;
    vless) listeners="$listeners"'
    {"type":"vless","listen":"::","listen_port":'"$2"',
     "users":[{"uuid":"'"$UUID"'","flow":"xtls-rprx-vision"}],
     "tls":{"enabled":true,"server_name":"'"$SNI"'",
            "reality":{"enabled":true,"handshake":{"server":"'"$SNI"'","server_port":443},
                       "private_key":"'"$PRIV"'","short_id":["'"$SID"'"]}}},' ;;
  esac
}
# A plain `[ ... ] && { ...; }` here would return non-zero whenever 443 was
# already taken, which under `set -e` ends the run: the exact case this branch
# exists to handle would have been the case that killed it.
if [ "$USE_443" = 1 ]; then
  add_in vless 443
  add_in hy2 443
fi
add_in vless "$HIGH_PORT"
add_in hy2 "$HIGH_PORT"

# The outbound block is the security-relevant half. A trial server is an open
# proxy for whoever holds the printed credential, so it must not become a way
# into this box's own neighbourhood: private ranges and the cloud metadata
# address are refused, which costs nothing for a reachability test and closes
# the one thing a leaked config could actually be abused for.
cat > "$TRIAL_DIR/config.json" <<EOF
{
  "log": { "level": "error" },
  "inbounds": [${listeners%,}
  ],
  "outbounds": [
    { "type": "direct", "tag": "out" },
    { "type": "block", "tag": "no" }
  ],
  "route": {
    "rules": [
      { "ip_cidr": ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16","127.0.0.0/8","169.254.0.0/16","::1/128","fc00::/7","fe80::/10"], "outbound": "no" }
    ],
    "final": "out"
  }
}
EOF
chmod 600 "$TRIAL_DIR/config.json"
"$BIN" check -c "$TRIAL_DIR/config.json" >/dev/null 2>&1 || die "The generated config was rejected by sing-box."

# ---- firewall ----------------------------------------------------------------
# Recorded, so the purge closes exactly these and nothing else.
open_port() {  # port, proto
  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    if ufw allow "$1/$2" >/dev/null 2>&1; then mark "ufw:$1/$2"; fi
  elif command -v iptables >/dev/null 2>&1; then
    if iptables -I INPUT -p "$2" --dport "$1" -j ACCEPT 2>/dev/null; then mark "ipt:$1/$2"; fi
  fi
  # ALWAYS zero. A firewall we could not touch must not end the run: plenty of
  # VPSes have no firewall at all, and on a container-based one iptables exists
  # but cannot insert without NET_ADMIN. Without this the script died here under
  # `set -e`, after writing the config but BEFORE writing the purge script, so
  # the one failure mode left a half-built trial that could not clean itself up.
  # Found by running it in a container that had iptables and no permission.
  return 0
}
if [ "$USE_443" = 1 ]; then
  open_port 443 tcp
  open_port 443 udp
fi
open_port "$HIGH_PORT" tcp
open_port "$HIGH_PORT" udp

# ---- units -------------------------------------------------------------------
cat > /etc/systemd/system/nova-trial.service <<EOF
[Unit]
Description=Nova trial server (self-destructs)
After=network-online.target

[Service]
ExecStart=$BIN run -c $TRIAL_DIR/config.json
Restart=on-failure
RestartSec=2
# Belt and braces on top of the reaper below: even if the timer is lost, the
# service itself will not outlive the trial window by more than a reboot.
RuntimeMaxSec=$(( TRIAL_MINUTES * 60 ))
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# The expiry check lives in its own file rather than inline in ExecStart.
#
# systemd treats `%` in a unit as a specifier prefix, and `%s` is a real one: it
# expands to the user's shell. So an inlined `date +%s` silently becomes
# `date +/bin/bash`, and the escape that avoids it (`%%s`) has to survive both
# this heredoc and systemd's parser. That is a lot of ways to get a silent
# no-op in the one component whose whole job is making sure this server does
# not stay up. A script file has no specifiers in it and cannot be got wrong.
cat > "$REAP" <<PEOF
#!/bin/sh
# Purge the trial if its absolute deadline has passed.
#
# An absolute deadline compared against the clock, never a countdown: that is
# what makes this survive a reboot. A machine that is switched off for two hours
# comes back already expired and is removed on the next tick, where a countdown
# would start again from the top and the trial would outlive its window.
[ -f "$DEADLINE" ] || exit 0
now=\$(date +%s)
end=\$(cat "$DEADLINE" 2>/dev/null || echo 0)
case "\$end" in ''|*[!0-9]*) exit 0 ;; esac
[ "\$now" -ge "\$end" ] && exec "$PURGE"
exit 0
PEOF
chmod 0755 "$REAP"

cat > /etc/systemd/system/nova-trial-reaper.service <<EOF
[Unit]
Description=Remove the Nova trial once its deadline has passed

[Service]
Type=oneshot
ExecStart=$REAP
EOF

cat > /etc/systemd/system/nova-trial-reaper.timer <<EOF
[Unit]
Description=Check whether the Nova trial has expired

[Timer]
OnBootSec=30s
OnUnitActiveSec=60s
AccuracySec=15s

[Install]
WantedBy=timers.target
EOF

date -d "+${TRIAL_MINUTES} minutes" +%s > "$DEADLINE" 2>/dev/null \
  || echo "$(( $(date +%s) + TRIAL_MINUTES * 60 ))" > "$DEADLINE"

systemctl daemon-reload
systemctl enable --now nova-trial.service >/dev/null 2>&1 || die "The trial server did not start."
systemctl enable --now nova-trial-reaper.timer >/dev/null 2>&1 \
  || warn "The expiry timer did not start; run $PURGE by hand when you are done."

sleep 2
systemctl is-active --quiet nova-trial.service \
  || die "The trial server started and then stopped. Check: journalctl -u nova-trial -n 30"

# Past this point the trial exists, is running, and has a timer that will remove
# it. Anything that goes wrong while PRINTING must not tear it down.
TRIAL_DONE=1

# ---- output ------------------------------------------------------------------
qr() { command -v qrencode >/dev/null 2>&1 && qrencode -t ANSIUTF8 -m 1 "$1" 2>/dev/null || true; }

vless_link() { printf 'vless://%s@%s:%s?encryption=none&security=reality&sni=%s&fp=chrome&pbk=%s&sid=%s&type=tcp&flow=xtls-rprx-vision#%s' \
  "$UUID" "$PUBIP" "$1" "$SNI" "$PUB" "$SID" "$2"; }
hy2_link()   { printf 'hysteria2://%s@%s:%s/?insecure=1&sni=%s#%s' \
  "$HY_PASS" "$PUBIP" "$1" "$SNI" "$2"; }

echo
printf '%s================ Nova trial is up ================%s\n' "$C_IN" "$C_0"
echo
printf '  Server:  %s\n' "$PUBIP"
printf '  Expires: %s  (in %s minutes, and it removes itself)\n' \
  "$(date -d "@$(cat "$DEADLINE")" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || cat "$DEADLINE")" "$TRIAL_MINUTES"
echo
echo "  Import these on a phone or laptop INSIDE Iran and try each one."
echo "  Which ones connect is the answer you came for:"
echo
if [ "$USE_443" = 1 ]; then
  printf '%s  --- port 443, the one that matters ---%s\n' "$C_IN" "$C_0"
  printf '  TCP  %s\n' "$(vless_link 443 "trial-443-tcp")"
  printf '  UDP  %s\n' "$(hy2_link 443 "trial-443-udp")"
  echo
fi
printf '%s  --- port %s, to tell a blocked PORT from a blocked IP ---%s\n' "$C_IN" "$HIGH_PORT" "$C_0"
printf '  TCP  %s\n' "$(vless_link "$HIGH_PORT" "trial-high-tcp")"
printf '  UDP  %s\n' "$(hy2_link "$HIGH_PORT" "trial-high-udp")"
echo
if [ "$USE_443" = 1 ]; then
  echo "  Reading the result:"
  echo "    443 works              -> this server is good, install Nova on it"
  echo "    only the high port     -> the IP is fine, 443 is being targeted here;"
  echo "                              plan on a CDN front or a non-standard port"
  echo "    only TCP, not UDP      -> usable, but avoid Hysteria2 on this server"
  echo "    nothing connects       -> the IP is burned, ask for a replacement"
else
  echo "  Reading the result:"
  echo "    connects    -> the IP itself is reachable from Iran"
  echo "    no connect  -> the IP is burned, ask for a replacement"
  echo "  (443 was already in use here, so this run cannot judge it.)"
fi
echo
if command -v qrencode >/dev/null 2>&1; then
  echo "  QR for the 443 TCP config (scan it in your client):"
  qr "$(vless_link "$([ "$USE_443" = 1 ] && echo 443 || echo "$HIGH_PORT")" trial)"
else
  echo "  Tip: apt-get install -y qrencode, then re-run, to get scannable QR codes."
fi
echo
printf '%s  This is a TEST server. It carries no obfuscation tuning, its Hysteria2%s\n' "$C_WN" "$C_0"
printf '%s  certificate is self-signed, and anyone holding the text above can use it%s\n' "$C_WN" "$C_0"
printf '%s  until it expires. Do not paste it into a public chat, and do not use it%s\n' "$C_WN" "$C_0"
printf '%s  for anything you care about.%s\n' "$C_WN" "$C_0"
echo
echo "  Done early? Remove it now:  $PURGE"
echo
