#!/usr/bin/env bash
# First-boot installer for the Docker node. Runs once (guarded by a marker on the
# persistent volume), installing the node with the same published installer as the
# native path. Re-runs of the container skip this and just start the existing node.
set -euo pipefail

MARKER=/var/lib/nova/.docker-installed
mkdir -p /var/lib/nova
[ -f "$MARKER" ] && { echo "Nova already installed on this volume; skipping."; exit 0; }

# Never prompt inside a container; take everything from the passed env vars.
export NOVA_NO_PROMPT=1

INSTALLER="${NOVA_INSTALLER_URL:-https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh}"
echo "==> Installing Nova node (first boot)"
if bash <(curl -fsSL "$INSTALLER"); then
  touch "$MARKER"
  echo "==> Nova node installed."
else
  echo "xx  Nova install failed; will retry on the next container start." >&2
  exit 1
fi
