#!/usr/bin/env bash
# =============================================================================
#  Nova node via Docker  -  one-line setup
#
#  Installs Docker if it is missing, fetches the Nova compose files, and starts
#  the node in a container. Same options as the native installer, passed as env:
#     NOVA_ADMIN_PASS  NOVA_DOMAIN  NOVA_DOMAIN_EMAIL  NOVA_PANEL_PATH  NOVA_PANEL_PORT
#
#  Run on a fresh Ubuntu/Debian VPS (Docker needs a real Linux host with host
#  networking; it will not work on Docker Desktop for Mac/Windows):
#     bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker/nova-docker.sh)
# =============================================================================
set -euo pipefail

c_grn=$'\033[0;32m'; c_cyn=$'\033[0;36m'; c_yel=$'\033[1;33m'; c_rst=$'\033[0m'
say()  { printf '%s\n' "${c_cyn}==>${c_rst} $*"; }
ok()   { printf '%s\n' "${c_grn}OK${c_rst}  $*"; }
warn() { printf '%s\n' "${c_yel}!!${c_rst}  $*"; }
die()  { printf '%s\n' "xx  $*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "Please run as root (sudo)."
DOCKER_BASE="${NOVA_DOCKER_BASE:-https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker}"
DOCKER_BASE="${DOCKER_BASE%/}"
RELEASE_BASE="${DOCKER_BASE%/docker}"
DIR="${NOVA_DIR:-/opt/nova-docker}"

# ---- container runtime -------------------------------------------------------
# Docker is the default. Podman works too, and is picked automatically when it is
# the only runtime present; force either one with NOVA_CONTAINER_RUNTIME.
RUNTIME="${NOVA_CONTAINER_RUNTIME:-}"
if [ -z "$RUNTIME" ]; then
  if command -v docker >/dev/null 2>&1; then RUNTIME=docker
  elif command -v podman >/dev/null 2>&1; then RUNTIME=podman
  else RUNTIME=docker
  fi
fi
case "$RUNTIME" in
  docker|podman) ;;
  *) die "NOVA_CONTAINER_RUNTIME must be 'docker' or 'podman' (got '$RUNTIME')." ;;
esac

if [ "$RUNTIME" = docker ]; then
  if ! command -v docker >/dev/null 2>&1; then
    say "Installing Docker"
    curl -fsSL https://get.docker.com | sh >/dev/null 2>&1 || die "Docker install failed. Install Docker, then re-run."
  fi
  # `docker compose` (v2) or the legacy `docker-compose`.
  if docker compose version >/dev/null 2>&1; then DC="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then DC="docker-compose"
  else die "Docker Compose not found. Install the Docker Compose plugin, then re-run."
  fi
  # A node binds the host's :443 and needs the host's network namespace. Docker
  # Desktop puts a VM in the way and cannot do that, so say so now rather than
  # letting the operator discover it from a container that never serves anything.
  host_os="$(docker info --format '{{.OperatingSystem}}' 2>/dev/null || true)"
  case "$host_os" in
    *"Docker Desktop"*|*"docker desktop"*)
      die "Docker Desktop cannot give a container the host's :443. Run this on a Linux VPS, or use the native installer." ;;
  esac
  ok "docker $(docker --version | awk '{print $3}' | tr -d ,)"
else
  command -v podman >/dev/null 2>&1 || die "Podman not found. Install podman and podman-compose, then re-run."
  if podman compose version >/dev/null 2>&1; then DC="podman compose"
  elif command -v podman-compose >/dev/null 2>&1; then DC="podman-compose"
  else die "No Podman Compose found. Install podman-compose (or the docker-compose binary podman can delegate to), then re-run."
  fi
  # Rootless Podman cannot bind :443 and cannot load the host's kernel modules,
  # so a node started that way looks healthy and serves nothing. This script
  # already requires root, so this only fires on an unusual setup.
  if [ "$(podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null || echo false)" = true ]; then
    die "Rootless Podman cannot bind the host's :443. Re-run this with sudo so Podman runs rootful."
  fi
  ok "podman $(podman --version | awk '{print $3}')"
fi

# ---- fetch the immutable image inputs ----------------------------------------
say "Fetching Nova image inputs into $DIR"
mkdir -p "$DIR/docker"
for f in Dockerfile entry.sh logstream.sh firstboot.sh nova-firstboot.service docker-compose.yml .dockerignore .env.example; do
  curl -fsSL "$DOCKER_BASE/$f" -o "$DIR/docker/$f" || die "Could not download docker/$f"
done
curl -fsSL "$RELEASE_BASE/nova-node.sh" -o "$DIR/docker/nova-node.sh" \
  || die "Could not download nova-node.sh"
curl -fsSL "$RELEASE_BASE/nova-node-agent.tar.gz" -o "$DIR/docker/nova-node-agent.tar.gz" \
  || die "Could not download nova-node-agent.tar.gz"
curl -fsSL "$RELEASE_BASE/nova-node-agent.tar.gz.sha256" -o "$DIR/docker/nova-node-agent.tar.gz.sha256" \
  || die "Could not download nova-node-agent.tar.gz.sha256"
chmod +x "$DIR/docker/entry.sh" "$DIR/docker/logstream.sh" "$DIR/docker/firstboot.sh" "$DIR/docker/nova-node.sh"

expected="$(awk 'NR == 1 { print $1 }' "$DIR/docker/nova-node-agent.tar.gz.sha256")"
case "$expected" in
  ""|*[!0-9A-Fa-f]*) die "Published agent checksum is invalid." ;;
esac
[ "${#expected}" = 64 ] || die "Published agent checksum is invalid."
got="$(sha256sum "$DIR/docker/nova-node-agent.tar.gz" | awk '{ print $1 }')"
[ "$got" = "$expected" ] || die "Agent checksum verification failed."
ok "agent package checksum verified"

# ---- .env from the passed options --------------------------------------------
# Compose expands what it reads out of .env, so some characters never arrive as
# typed. Measured with `docker compose` on Linux: NOVA_ADMIN_PASS='Str0ng$Pass-1!'
# reaches the container as "Str0ng-1!", a 15-character password silently cut to
# nine, and an unquoted '#' after a space truncates the rest of the line.
# Quoting fixes the '#'; nothing fixes the '$', including passing it through the
# process environment instead. So say no, with the reason, rather than install a
# node whose admin password is not the one the operator chose.
for v in NOVA_ADMIN_PASS NOVA_DOMAIN NOVA_DOMAIN_EMAIL NOVA_PANEL_PATH NOVA_PANEL_PORT; do
  case "$(eval "printf '%s' \"\${$v:-}\"")" in
    *'$'*|*\\*|*\'*|*'"'*|*'`'*)
      die "$v cannot contain \$ \\ \` ' or \". Compose rewrites those before the container sees them. Pick another value, or leave NOVA_ADMIN_PASS blank and change the password in the panel afterwards." ;;
    *$'\n'*|*$'\r'*)
      die "$v must be a single line." ;;
  esac
done
# umask BEFORE the redirection: it can hold NOVA_ADMIN_PASS, and a chmod after
# the fact leaves the password briefly world-readable on disk. Single quotes so
# a space or a '#' inside a value is not read as the start of a comment.
(
  umask 077
  {
    printf "NOVA_ADMIN_PASS='%s'\n" "${NOVA_ADMIN_PASS:-}"
    printf "NOVA_DOMAIN='%s'\n" "${NOVA_DOMAIN:-}"
    printf "NOVA_DOMAIN_EMAIL='%s'\n" "${NOVA_DOMAIN_EMAIL:-}"
    printf "NOVA_PANEL_PATH='%s'\n" "${NOVA_PANEL_PATH:-}"
    printf "NOVA_PANEL_PORT='%s'\n" "${NOVA_PANEL_PORT:-}"
  } > "$DIR/docker/.env"
)
chmod 600 "$DIR/docker/.env"

# ---- build + start -----------------------------------------------------------
cd "$DIR/docker"
say "Building the image and starting the node"
# Before, not after: `logs` replays the whole container history, and on a re-run
# that does not recreate the container that history still holds a completed
# install. Following it unbounded matched THAT success line within a second and
# reprinted an old password as if it were this run's.
START_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
$DC up -d --build || die "Could not start the container. Check: $DC logs nova-node"

# Do NOT stop here. Printing "the container is starting" and exiting is how an
# operator ends up staring at an empty log with no panel URL and no password.
# Follow the install to its end and report what actually happened.
echo
say "First boot is installing Nova. This takes a few minutes; the panel URL and password come last."
echo
# A FIFO rather than a process substitution: breaking out of the loop has to
# also stop the follower, and only a real PID can be killed. Without that the
# script sits there long after the install finished, which looks exactly like
# the hang this whole change exists to remove.
FIFO_DIR="$(mktemp -d)"
chmod 700 "$FIFO_DIR"
FIFO="$FIFO_DIR/logs"
# 0600 inside a 0700 directory. At the default root umask a bare `mkfifo` in
# /tmp is world-readable, and every line of the install, including the generated
# admin password and the subscription token, flows through it for the length of
# the install. The trap covers a Ctrl-C.
mkfifo -m 600 "$FIFO"
trap 'rm -rf "$FIFO_DIR"' EXIT

# --since, so history cannot be mistaken for this run: `logs` replays everything
# the container ever printed, and on a re-run that does not recreate it that
# history holds a completed install whose password may since have been changed.
# A runtime that will not take --since gets no verdict from this script at all,
# because a wrong "installed, here is your password" is worse than no answer.
STATUS=timeout
if $DC logs --since "$START_TS" --tail 1 nova-node >/dev/null 2>&1; then
  timeout "${NOVA_INSTALL_TIMEOUT:-1800}" $DC logs -f --since "$START_TS" nova-node >"$FIFO" 2>/dev/null &
  FOLLOW_PID=$!
  while IFS= read -r line; do
    printf '%s\n' "$line"
    case "$line" in
      *"Nova node installed and healthy."*|*"Nova runtime is installed and healthy."*|*"Nova managed node recovery completed."*)
        STATUS=ok; break ;;
      *"no completion marker was written"*|*"produced no output after"*)
        STATUS=failed; break ;;
    esac
  done < "$FIFO"
  kill "$FOLLOW_PID" 2>/dev/null || true
  wait "$FOLLOW_PID" 2>/dev/null || true
else
  STATUS=nofollow
fi
rm -rf "$FIFO_DIR"

echo
case "$STATUS" in
  ok)
    ok "Nova node is installed and running."
    printf '  %s\n' "Your panel URL and admin password are in the log above. Save them now."
    printf '  %s\n' "Lost the panel URL?  cd $DIR/docker && $DC exec nova-node nova-access"
    printf '  %s\n' "Change the password: cd $DIR/docker && $DC exec nova-node nova-passwd 'NewPassword'"
    ;;
  failed)
    warn "First boot did not finish. The lines above say why."
    printf '  %s\n' "Full log:  cd $DIR/docker && $DC exec nova-node journalctl -u nova-firstboot --no-pager"
    ;;
  nofollow)
    warn "This compose command cannot show only this run's log, so nothing is reported here."
    printf '  %s\n' "Watch the install yourself: cd $DIR/docker && $DC logs -f nova-node"
    printf '  %s\n' "Your panel URL and admin password are at the end of it."
    ;;
  *)
    warn "Stopped following the install log before it finished. The node may still be installing."
    printf '  %s\n' "Keep watching:  cd $DIR/docker && $DC logs -f nova-node"
    ;;
esac
echo
printf '  %s\n' "Watch again: cd $DIR/docker && $DC logs -f nova-node"
printf '  %s\n' "Stop:        cd $DIR/docker && $DC down"
printf '  %s\n' "Update:      re-run this setup command to fetch and build a verified release"
echo
warn "A container node needs a real Linux host with host networking, and cannot run the"
warn "AmneziaWG server unless the host kernel already provides the module. Every other"
warn "protocol works. On Docker Desktop (Mac/Windows) use the native installer instead."
