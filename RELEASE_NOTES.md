# Nova Server 1.75.1

Updating over SSH printed four errors instead of the ports list.

## What you saw

```
==> Ports this install will use
/dev/tty: No such device or address
/dev/tty: No such device or address
/dev/tty: No such device or address
/dev/tty: No such device or address
```

Nothing was wrong with the install. Nothing was skipped, no port was moved, and
the node came up exactly as it should have. The list of ports simply never
printed, and four errors printed in its place.

## Why

1.75.0 added that list and wrote it to the terminal device rather than to normal
output. A command run over SSH, which is how most updates happen and how the
installer bot works, has no controlling terminal, so every line failed.

The redirect carried a `2>/dev/null || true` that looked like it covered this
and could not: the shell reports a failed redirection itself, before the command
runs, so the command's own error handling never sees it.

The list is ordinary output now, like every other line the installer prints.

There is a note in the installer, written the last time this happened to the
setup questions, saying that a shell with no terminal still passes the obvious
check and that "the install was always fine; it just looked like it had errored
three times". The same mistake was made again twenty lines below it. There is a
test now, since the note was not enough.

## Upgrading

Update and restart. Nothing else changed.
