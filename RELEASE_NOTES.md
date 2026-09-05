# Nova Server 1.82.0

A button in a dialog could look like it did nothing, while it was telling you
exactly what went wrong.

## What you saw

You pressed Apply in a confirmation dialog. The button stopped spinning. Nothing
else happened, and the dialog stayed open.

The most common way to meet this was the health page. A server in your fleet
could not be reached, the page offered to push configuration to it, and pressing
that button appeared to do nothing at all.

## What was happening

When an action confirmed in a dialog fails, the dialog deliberately stays open
so you can read the reason and try again, and the reason appears as a message
along the bottom of the screen.

That message was being drawn underneath the dialog's own dark backdrop. It was
there every time, correct every time, and invisible every time.

Nothing behind the button was broken. The failure was worked out properly and
sent somewhere you could not see it.

## What changed

The message now appears above the dialog, where it was always meant to be.

This was fixed as a rule about which layer sits on top rather than at the one
button that reported it, because every action confirmed in a dialog had the same
problem, and there are a number of them.

## Upgrading

Panel: Settings, then Update. Or run the installer again over SSH:

    bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
