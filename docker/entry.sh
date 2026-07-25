#!/usr/bin/env bash
# Persist the container's NOVA_* environment so the first-boot installer (a
# systemd oneshot) can read it, then hand off to systemd as PID 1.
set -e
mkdir -p /run/nova
# Only NOVA_* keys, quoted safely for EnvironmentFile.
env | grep -E '^NOVA_[A-Z_]+=' > /run/nova/env 2>/dev/null || true
exec "$@"
