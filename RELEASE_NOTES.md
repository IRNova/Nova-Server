# Nova Server 1.77.0

Your server can be running a version of AmneziaWG it no longer has installed,
for weeks, with nothing saying so. The health page now says so.

## What happens

When your server installs its own package updates, a newer AmneziaWG is written
to disk. The one already carrying your tunnel keeps running, because nothing can
swap out a component while it is in use. The two only meet again when the server
restarts.

On a server built to stay up, that is not a few minutes. It is however long it
has been since the last restart.

Every sign an operator could check said the tunnel was healthy, and it was: the
software was installed, the tunnel was up, customers were connected. What was
not true is that the server was running the version it had.

## What you will see

A warning on the health page, on any server where the two differ:

> The tunnel is up, but it is running on AmneziaWG kernel module 1.0.20260611
> while 3.1.20260812 is the one installed on this server.

It names both versions and gives you the command that swaps them over. Running
it interrupts the tunnel for a few seconds and every customer reconnects on
their own. Restarting the server does the same thing.

It is a warning, not a fault. Nothing is broken, and nothing is disconnected
until you choose to act on it. What it costs you is that fixes in the newer
version are not in force, and version 3.0 cannot be switched on.

## The switch to 3.0 no longer fails halfway

Turning on version 3.0 on a server in that state used to get all the way to the
point of applying it, then fail with a message from the system that named
nothing you could act on:

    Unable to modify interface: Invalid argument

Your previous version was restored and your customers' files were never
affected, but the tunnel dropped for a moment on the way through, and the
message sent you to update packages that were often already up to date.

Nova now checks both halves before it tries anything, and if it cannot proceed
it tells you which of the two is wrong: packages that genuinely need updating,
or a version that is already installed and only waiting for the server to pick
it up. Nothing is applied and nobody is disconnected.

## Upgrading

Panel: Settings, then Update. Or run the installer again over SSH:

    bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)

The panel updater is enough for this release.
