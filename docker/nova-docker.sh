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
BASE="${NOVA_DOCKER_BASE:-https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker}"
DIR="${NOVA_DIR:-/opt/nova-docker}"

# ---- Docker ------------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  say "Installing Docker"
  curl -fsSL https://get.docker.com | sh >/dev/null 2>&1 || die "Docker install failed. Install Docker, then re-run."
fi
# `docker compose` (v2) or the legacy `docker-compose`.
if docker compose version >/dev/null 2>&1; then DC="docker compose"; elif command -v docker-compose >/dev/null 2>&1; then DC="docker-compose"; else
  die "Docker Compose not found. Install the Docker Compose plugin, then re-run."
fi
ok "docker $(docker --version | awk '{print $3}' | tr -d ,)"

# ---- fetch the compose files -------------------------------------------------
say "Fetching Nova compose files into $DIR"
mkdir -p "$DIR"; cd "$DIR"
for f in Dockerfile entry.sh firstboot.sh nova-firstboot.service docker-compose.yml; do
  curl -fsSL "$BASE/$f" -o "$f" || die "Could not download $f"
done
chmod +x entry.sh firstboot.sh

# ---- .env from the passed options --------------------------------------------
{
  echo "NOVA_ADMIN_PASS=${NOVA_ADMIN_PASS:-}"
  echo "NOVA_DOMAIN=${NOVA_DOMAIN:-}"
  echo "NOVA_DOMAIN_EMAIL=${NOVA_DOMAIN_EMAIL:-}"
  echo "NOVA_PANEL_PATH=${NOVA_PANEL_PATH:-}"
  echo "NOVA_PANEL_PORT=${NOVA_PANEL_PORT:-}"
} > .env
chmod 600 .env

# ---- build + start -----------------------------------------------------------
say "Building the image and starting the node (first boot installs Nova; give it a few minutes)"
$DC up -d --build || die "Could not start the container. Check: $DC logs nova-node"

echo
ok "Nova node container is starting."
echo
printf '  %s\n' "Watch the install + get your panel URL:   ${c_grn}cd $DIR && $DC logs -f nova-node${c_rst}"
printf '  %s\n' "Stop:      cd $DIR && $DC down"
printf '  %s\n' "Update:    cd $DIR && $DC pull; $DC up -d --build"
printf '  %s\n' "The panel URL (with the secret path) is printed near the end of the first-boot log."
echo
warn "Docker needs a real Linux host with host networking. It will not work on Docker Desktop (Mac/Windows)."
