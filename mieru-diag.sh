#!/usr/bin/env bash
# Nova: mieru diagnostic collector.
#
# Run as root on the node, paste the whole output back. It only READS, changes
# nothing, and redacts credentials before printing: user names, password hashes
# and the node's own addresses are replaced, so the output is safe to paste into
# a group chat.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/mieru-diag.sh)
#
# or save it and run:  bash mieru-diag.sh

echo "=============== Nova mieru diagnostic ==============="
echo "date:     $(date -u '+%Y-%m-%d %H:%M UTC')"
echo "agent:    $(grep -o '"version": *"[0-9.]*"' /opt/nova-node-agent/package.json 2>/dev/null | grep -o '[0-9][0-9.]*' | head -1)"
echo "kernel:   $(uname -r | cut -d- -f1)   arch: $(uname -m)"
echo "memory:   $(awk '/^MemTotal:/ {printf "%d MB", $2/1024}' /proc/meminfo)  swap: $(awk '/^SwapTotal:/ {printf "%d MB", $2/1024}' /proc/meminfo)"
echo

echo "--- what Nova thinks mieru is set to ---"
node --experimental-sqlite -e '
const { DatabaseSync } = require("node:sqlite");
try {
  const db = new DatabaseSync("/var/lib/nova/nova.db");
  const s = JSON.parse(db.prepare("select v from kvstore where k=?").get("network-settings.json").v);
  const m = s.mieru || {};
  console.log("  enabled:     " + (m.enabled === true));
  console.log("  port:        " + (m.port || "(unset)"));
  console.log("  protocol:    " + (m.protocol || "(unset)"));
  console.log("  mtu:         " + (m.mtu || "(unset)"));
  console.log("  linkHost:    " + (m.linkHost ? "(set)" : "(automatic)"));
  console.log("  keySalt:     " + (m.keySalt ? "(present)" : "(MISSING, this would be a bug)"));
  console.log("  users given mieru: " + (s.users || []).filter(u => u && u.mieru === true).length);
  console.log("  hostProxied: " + (s.hostProxied === true));
} catch (e) { console.log("  could not read settings: " + e.message); }
' 2>/dev/null || echo "  (could not read the settings database)"
echo

echo "--- is the binary there, and which build ---"
ls -la /usr/local/bin/mita 2>/dev/null || echo "  mita is NOT installed"
/usr/local/bin/mita version 2>/dev/null || echo "  (mita would not report a version)"
echo "  ownership marker: $([ -f /var/lib/nova/.owned/mita ] && echo present || echo absent)"
echo

echo "--- the service ---"
systemctl is-active nova-mieru 2>/dev/null || true
systemctl is-enabled nova-mieru 2>/dev/null || true
echo "  restarts: $(systemctl show nova-mieru -p NRestarts --value 2>/dev/null)"
echo "  exit:     $(systemctl show nova-mieru -p ExecMainStatus --value 2>/dev/null)"
echo

echo "--- what mita itself says (passwords and names redacted) ---"
/usr/local/bin/mita status 2>&1 | head -3
/usr/local/bin/mita describe config 2>/dev/null \
  | sed -E 's/("(name|username|password|hashedPassword)"[[:space:]]*:[[:space:]]*)"[^"]*"/\1"<redacted>"/g' \
  | head -40 || echo "  (mita would not describe its config)"
echo

echo "--- what is actually bound ---"
echo "  UDP:"; ss -lnu 2>/dev/null | awk 'NR>1 {print "    " $4}' | sort -u | head -20
echo "  TCP:"; ss -lnt 2>/dev/null | awk 'NR>1 {print "    " $4}' | sort -u | head -20
echo

echo "--- firewall ---"
if command -v ufw >/dev/null 2>&1; then ufw status 2>/dev/null | head -12; else echo "  ufw not installed"; fi
echo


# journald stamps the machine hostname on every line, and it is chosen by the
# operator ("novavps", or their own name). The support bundle scrubs it for
# exactly that reason, so this does too. One scrubber, used by both journal
# reads, so the two cannot drift apart.
HOSTN="$(hostname 2>/dev/null || echo __nohost__)"
scrub() { sed -E -e "s/([0-9]{1,3}\.){3}[0-9]{1,3}/<ip>/g" -e "s/\b${HOSTN}\b/<host>/g"; }
echo "--- service log (addresses and hostname redacted) ---"
journalctl -u nova-mieru -n 40 --no-pager 2>/dev/null \
  | scrub \
  | tail -40 || echo "  (no journal)"
echo
echo "--- agent log, mieru lines only ---"
journalctl -u nova-agent --since "-2 hours" --no-pager 2>/dev/null \
  | grep -i "mieru\|mita" | scrub | tail -20 \
  || echo "  (nothing about mieru in the last 2 hours)"
echo
echo "=============== end ==============="
