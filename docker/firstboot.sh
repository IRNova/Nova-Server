#!/usr/bin/env bash
# Recoverable first-boot installer for the Docker node.
#
# The marker and database live on a persistent volume, while the installed
# runtime lives in the container layer. A marker alone therefore proves
# nothing after a container is recreated. Every boot verifies the runtime and
# local API. Missing runtime files trigger an idempotent reinstall from the
# installer and checksum-pinned agent package bundled into the signed image.
set -euo pipefail

readonly MARKER=/var/lib/nova/.docker-installed
readonly DB=/var/lib/nova/nova.db
readonly CERT_DIR=/etc/nova
readonly ADMIN_PASS_FILE=/etc/nova/docker-admin-pass
readonly INSTALLER=/opt/nova/nova-node.sh
readonly AGENT_ARCHIVE=/opt/nova/release/nova-node-agent.tar.gz
readonly AGENT_CHECKSUM=/opt/nova/release/nova-node-agent.tar.gz.sha256

mkdir -p /var/lib/nova "$CERT_DIR"
chown root:nogroup "$CERT_DIR" 2>/dev/null || true
chmod 750 "$CERT_DIR" 2>/dev/null || true

runtime_present() {
  [ -s /opt/nova-node-agent/bin/nova-agent.mjs ] \
    && [ -s /etc/systemd/system/nova-agent.service ] \
    && [ -x /usr/local/bin/nova-passwd ]
}

panel_base() {
  local panel_path=""
  if [ -s "$DB" ] && [ -s /opt/nova-node-agent/src/kv/sqlite.mjs ]; then
    panel_path="$(
      NOVA_DB="$DB" node -e '
        import("/opt/nova-node-agent/src/kv/sqlite.mjs").then(async ({ openKv }) => {
          const kv = openKv(process.env.NOVA_DB);
          try {
            const s = JSON.parse(await kv.get("network-settings.json") || "{}");
            const p = String(s.panelPath || "").replace(/^\/+|\/+$/g, "");
            process.stdout.write(/^[A-Za-z0-9_-]{3,64}$/.test(p) ? p : "");
          } finally {
            kv.close();
          }
        }).catch(() => {});
      ' 2>/dev/null || true
    )"
  fi
  printf 'http://127.0.0.1:8088%s' "${panel_path:+/$panel_path}"
}

database_ready() {
  [ -s "$DB" ] && [ -s /opt/nova-node-agent/src/kv/sqlite.mjs ] || return 1
  local state
  state="$(
    NOVA_DB="$DB" node -e '
      import("/opt/nova-node-agent/src/kv/sqlite.mjs").then(async ({ openKv }) => {
        const kv = openKv(process.env.NOVA_DB);
        try {
          const admin = await kv.get("admin_pass");
          const s = JSON.parse(await kv.get("network-settings.json") || "{}");
          process.stdout.write(admin || s.nodeMode === true ? "ready" : "");
        } finally {
          kv.close();
        }
      }).catch(() => {});
    ' 2>/dev/null || true
  )"
  [ "$state" = ready ]
}

managed_node_ready() {
  [ -s "$DB" ] && [ -s /opt/nova-node-agent/src/kv/sqlite.mjs ] || return 1
  local state
  state="$(
    NOVA_DB="$DB" node -e '
      import("/opt/nova-node-agent/src/kv/sqlite.mjs").then(async ({ openKv }) => {
        const kv = openKv(process.env.NOVA_DB);
        try {
          const s = JSON.parse(await kv.get("network-settings.json") || "{}");
          process.stdout.write(s.nodeMode === true ? "managed" : "");
        } finally {
          kv.close();
        }
      }).catch(() => {});
    ' 2>/dev/null || true
  )"
  [ "$state" = managed ]
}

runtime_healthy() {
  runtime_present || return 1
  systemctl daemon-reload >/dev/null 2>&1 || return 1
  systemctl enable nova-agent >/dev/null 2>&1 || return 1
  systemctl start nova-agent >/dev/null 2>&1 || return 1
  systemctl start xray >/dev/null 2>&1 || return 1

  local base response front_response front_port panel_suffix
  base="$(panel_base)"
  panel_suffix="${base#http://127.0.0.1:8088}"
  front_port="$(
    awk -F= '$1 == "NOVA_FRONT_PORT" { print $2; exit }' /etc/nova/agent.env 2>/dev/null || true
  )"
  case "$front_port" in
    ""|*[!0-9]*) front_port=443 ;;
  esac
  for _ in $(seq 1 40); do
    response="$(curl -fsS "$base/install/status" 2>/dev/null || true)"
    case "$response" in
      *'"build":"nova-node-agent/'*)
        if database_ready && systemctl is-active --quiet xray; then
          front_response="$(
            curl -kfsS --max-time 3 \
              "https://127.0.0.1:$front_port$panel_suffix/install/status" 2>/dev/null || true
          )"
          case "$front_response" in
            *'"build":"nova-node-agent/'*) return 0 ;;
          esac
        fi
        ;;
    esac
    sleep 1
  done
  return 1
}

verify_bundled_release() {
  [ -r "$INSTALLER" ] || { echo "xx  Bundled Nova installer is missing." >&2; return 1; }
  [ -r "$AGENT_ARCHIVE" ] || { echo "xx  Bundled Nova agent package is missing." >&2; return 1; }
  [ -r "$AGENT_CHECKSUM" ] || { echo "xx  Bundled Nova checksum is missing." >&2; return 1; }

  local expected got
  expected="$(awk 'NR == 1 { print $1 }' "$AGENT_CHECKSUM")"
  case "$expected" in
    ""|*[!0-9A-Fa-f]*) echo "xx  Bundled Nova checksum is invalid." >&2; return 1 ;;
  esac
  [ "${#expected}" = 64 ] || { echo "xx  Bundled Nova checksum is invalid." >&2; return 1; }
  got="$(sha256sum "$AGENT_ARCHIVE" | awk '{ print $1 }')"
  [ "$got" = "$expected" ] || { echo "xx  Bundled Nova agent checksum does not match." >&2; return 1; }

  NOVA_TARBALL_URL="file://$AGENT_ARCHIVE"
  NOVA_TARBALL_SHA256="$expected"
  export NOVA_TARBALL_URL NOVA_TARBALL_SHA256
}

ensure_initial_password() {
  if [ -n "${NOVA_ADMIN_PASS:-}" ]; then
    return 0
  fi
  if [ ! -s "$ADMIN_PASS_FILE" ]; then
    umask 077
    openssl rand -hex 16 > "$ADMIN_PASS_FILE"
    chmod 600 "$ADMIN_PASS_FILE"
  fi
  NOVA_ADMIN_PASS="$(tr -d '\r\n' < "$ADMIN_PASS_FILE")"
  [ "${#NOVA_ADMIN_PASS}" -ge 12 ] || {
    echo "xx  Persistent Docker admin password is invalid." >&2
    return 1
  }
  export NOVA_ADMIN_PASS
}

write_marker() {
  local expected
  expected="$(awk 'NR == 1 { print $1 }' "$AGENT_CHECKSUM")"
  umask 077
  printf 'complete %s\n' "$expected" > "$MARKER"
  chmod 600 "$MARKER"
  rm -f "$ADMIN_PASS_FILE"
}

marker_matches_release() {
  local expected recorded
  expected="$(awk 'NR == 1 { print $1 }' "$AGENT_CHECKSUM")"
  recorded="$(awk 'NR == 1 && $1 == "complete" { print $2 }' "$MARKER" 2>/dev/null || true)"
  [ -n "$recorded" ] && [ "$recorded" = "$expected" ]
}

marker_existed=0
# Old Docker releases wrote a zero-byte marker with touch. Existence, not size,
# must select runtime-only restoration for those already-configured volumes.
[ -e "$MARKER" ] && marker_existed=1

verify_bundled_release
export NOVA_NO_PROMPT=1

if [ "$marker_existed" = 1 ] && marker_matches_release && runtime_healthy; then
  echo "Nova runtime is installed and healthy."
  exit 0
fi

if [ "$marker_existed" = 0 ] && managed_node_ready && runtime_healthy; then
  # Enrollment completed and removed the local password, but the container
  # stopped before firstboot wrote its marker. The node is already healthy and
  # must not replay a consumed join token.
  write_marker
  echo "==> Nova managed node recovery completed."
  exit 0
fi

if [ "$marker_existed" = 0 ]; then
  # Keep one password across retries. NOVA_INSTALL_RESUME tells the native
  # installer that a configured DB without our completion marker is an
  # interrupted first boot, not a normal upgrade.
  ensure_initial_password
  export NOVA_INSTALL_RESUME=1
  echo "==> Installing Nova node from the bundled release"
  bash "$INSTALLER"
else
  # Container recreation: settings, certificates, and the completed marker
  # survived, but image-layer binaries and units did not. Reinstall runtime
  # only. Do not replay one-time domain, panel, or fleet enrollment inputs.
  echo "==> Restoring Nova runtime from the bundled release"
  (
    unset NOVA_ADMIN_PASS NOVA_DOMAIN NOVA_DOMAIN_EMAIL NOVA_PANEL_PATH
    unset NOVA_PANEL_PORT NOVA_JOIN_URL NOVA_JOIN_TOKEN NOVA_JOIN_PIN
    unset NOVA_INSTALL_RESUME
    export NOVA_NO_PROMPT NOVA_TARBALL_URL NOVA_TARBALL_SHA256
    bash "$INSTALLER"
  )
fi

if ! runtime_healthy; then
  echo "xx  Nova install did not reach a healthy configured API; no completion marker was written." >&2
  exit 1
fi

write_marker
echo "==> Nova node installed and healthy."
