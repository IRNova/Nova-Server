#!/usr/bin/env bash
# Mirrors the Nova first-boot log to the container's stdout.
#
# systemd is PID 1 in this image. It sends service output to the journal and
# points its own stdout at /dev/null, so `docker compose logs -f nova-node` (the
# command the setup script and the README tell operators to run) showed nothing
# at all: no progress, no panel URL, no admin password. entry.sh starts this
# script BEFORE it hands off to systemd, so this process inherits the container's
# real stdout and keeps it for the life of the container.
#
# It also acts as a watchdog. If the first-boot unit never produces output, this
# is the only place that can say so where an operator will actually see it.

readonly LOG=/var/log/nova-firstboot.log
readonly WAIT_SECONDS=300

say() { printf '%s\n' "$*"; }

say "==> Nova node container started."
say "    First boot installs the node. On a small VPS this takes a few minutes."
say "    Your panel URL and admin password are printed at the end of this log."
say ""

# From byte 0, and follow by name so a truncation or a rewrite is picked up.
tail -n +1 -F "$LOG" 2>/dev/null &
tail_pid=$!

waited=0
while [ "$waited" -lt "$WAIT_SECONDS" ]; do
  sleep 10
  waited=$((waited + 10))
  [ -s "$LOG" ] && break
  if [ $((waited % 60)) -eq 0 ]; then
    say "    (${waited}s) waiting for the Nova first-boot installer to start..."
  fi
done

if [ ! -s "$LOG" ]; then
  say ""
  say "xx  The Nova first-boot installer produced no output after ${waited}s."
  say "xx  This is the diagnostic information to report:"
  systemctl status nova-firstboot.service --no-pager -l 2>&1 | sed 's/^/    /'
  journalctl -u nova-firstboot.service --no-pager -n 60 2>&1 | sed 's/^/    /'
  say ""
fi

wait "$tail_pid"
