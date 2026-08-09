#!/usr/bin/env bash
# Container entrypoint. It does three things before handing PID 1 to systemd.
#
# 1. Makes /sys/fs/cgroup match this container's cgroup namespace. The compose
#    file asks for the host namespace and bind-mounts the host tree, which is
#    what Docker needs. podman-compose silently drops that request, so under
#    Podman the container lands in a PRIVATE cgroup namespace still holding a
#    bind mount of a tree it does not own, and systemd exits immediately with no
#    output whatsoever. Remounting cgroup2 gives systemd the namespaced view it
#    needs. This is the same thing Podman's own systemd mode does.
#
# 2. Starts the log relay. systemd points its own stdout at /dev/null and sends
#    everything else to the journal, so the install, the panel URL and the admin
#    password never reach `docker compose logs`. The relay is started HERE,
#    before the handover, so it inherits the container's real stdout and can
#    mirror the first-boot log to it for the life of the container.
#
# 3. Persists the container's NOVA_* environment for the first-boot installer.
set -e

# NOT /var/log/nova: the installer chowns that directory to nobody:nogroup so
# xray can write its access log there, which would let anything running as xray
# read or replace a file holding the panel admin password. /var/log itself stays
# root-owned, so a 0600 root file directly in it is the safe place.
readonly NOVA_LOG=/var/log/nova-firstboot.log

# ---- 1. cgroups --------------------------------------------------------------
# A private cgroup namespace reports "0::/" for every process in it, and its own
# cgroup root then holds this container's PID 1. If it does not, what is mounted
# at /sys/fs/cgroup belongs to somebody else and systemd will exit instantly with
# no output at all. Replacing it with a plain cgroup2 mount gives the namespaced
# view; the bind mount has to go first, because mounting over it returns EBUSY.
#
# Nothing here runs under a host cgroup namespace, which is what the compose file
# asks Docker for, so the proven Docker path is untouched.
cgroup_v2_ok() {
  [ -e /sys/fs/cgroup/cgroup.controllers ] || return 1
  grep -qx 1 /sys/fs/cgroup/cgroup.procs 2>/dev/null
}
if [ -e /sys/fs/cgroup/cgroup.controllers ] \
  && [ "$(cat /proc/self/cgroup 2>/dev/null || true)" = "0::/" ] \
  && ! cgroup_v2_ok; then
  # --make-rprivate FIRST. The shipped compose file bind-mounts /sys/fs/cgroup
  # without a propagation flag, so the umount cannot escape; but the README
  # invites operators to hand-edit that file, and one `:rshared` there would send
  # this umount to the HOST's cgroup tree. Verified: with :rshared and without
  # this line, a submount disappears from the host.
  mount --make-rprivate /sys/fs/cgroup 2>/dev/null || true
  umount -R /sys/fs/cgroup 2>/dev/null || true
  # Keep the hardening flags the original mount had; a plain remount drops them.
  mount -t cgroup2 -o nosuid,nodev,noexec cgroup2 /sys/fs/cgroup 2>/dev/null || true
  cgroup_v2_ok \
    || echo "!!  Could not give systemd a usable /sys/fs/cgroup. If this is Podman, add --cgroupns=host." >&2
fi

# ---- 2. the log the operator is told to read ---------------------------------
# Recreated on every container start, so a restart never replays an old install
# (and never re-prints an old admin password) into the container log. rm before
# create so an inherited symlink or a foreign-owned file cannot be appended to.
umask 077
rm -f "$NOVA_LOG"
: > "$NOVA_LOG"
chown 0:0 "$NOVA_LOG" 2>/dev/null || true
chmod 600 "$NOVA_LOG" 2>/dev/null || true

if [ -x /opt/nova/logstream.sh ]; then
  /opt/nova/logstream.sh &
fi

# ---- 3. the installer's environment ------------------------------------------
mkdir -p /run/nova
chmod 700 /run/nova 2>/dev/null || true
# The file can hold NOVA_ADMIN_PASS, so create it 0600 BEFORE writing any secret,
# not world-readable at the default umask.
: > /run/nova/env
chmod 600 /run/nova/env 2>/dev/null || true
# Only NOVA_* keys, one per line, for a root unit's EnvironmentFile.
#
# Read NUL-separated, because `env | grep '^NOVA_...='` cannot tell a variable
# from the second line of one. A value containing a newline printed the rest of
# itself at the start of a line, where grep matched it as another NOVA_ variable
# and wrote it into this file: NOVA_ADMIN_PASS=$'pw\nNOVA_JOIN_URL=https://...'
# smuggled a fleet enrolment past the five keys the compose file forwards.
#
# Anything systemd's EnvironmentFile parser would read as something other than
# the literal value is refused out loud rather than written in a form that means
# something else. Unquoted, that parser continues a line ending in a backslash,
# trims surrounding whitespace, and treats a leading quote as the start of a
# quoted value. A refused password is not a lost node: first boot generates one
# and prints it.
skip_env() { echo "!!  Ignoring $1: $2. Nova will use its default instead." >&2; }
while IFS= read -r -d '' kv; do
  name="${kv%%=*}"
  value="${kv#*=}"
  case "$name" in
    NOVA_*) ;;
    *) continue ;;
  esac
  case "${name#NOVA_}" in
    ""|*[!A-Z0-9_]*) continue ;;
  esac
  case "$value" in
    *$'\n'*|*$'\r'*) skip_env "$name" "the value contains a line break"; continue ;;
    *\\*)            skip_env "$name" "the value contains a backslash"; continue ;;
    \"*|\'*)         skip_env "$name" "the value starts with a quote"; continue ;;
    " "*|*" "|$'\t'*|*$'\t') skip_env "$name" "the value starts or ends with a space"; continue ;;
  esac
  printf '%s=%s\n' "$name" "$value" >> /run/nova/env
done < <(env -0 2>/dev/null || true)

exec "$@"
