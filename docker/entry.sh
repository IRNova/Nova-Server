#!/usr/bin/env bash
# Persist the container's NOVA_* environment so the first-boot installer (a
# systemd oneshot) can read it, then hand off to systemd as PID 1.
set -e
mkdir -p /run/nova
chmod 700 /run/nova 2>/dev/null || true
# The file can hold NOVA_ADMIN_PASS, so create it 0600 BEFORE writing any secret,
# not world-readable at the default umask.
umask 077
: > /run/nova/env
chmod 600 /run/nova/env 2>/dev/null || true
# Only NOVA_* keys, quoted safely for EnvironmentFile.
env | grep -E '^NOVA_[A-Z_]+=' >> /run/nova/env 2>/dev/null || true
exec "$@"
