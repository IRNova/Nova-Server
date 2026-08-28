# Nova Server 1.75.2

Installing on a fresh server stopped after the questions.

## What you saw

The installer asked its questions, and then the shell prompt came back. No
output, no error, nothing installed.

It was not your server, your domain, your email or your connection. Retrying,
using a different domain, or running it through the bot all did the same thing,
because the failure had nothing to do with any of that.

## What was happening

1.73.0 added code that remembers which internal port an existing install uses,
so re-running the installer never moves it. That code reads a settings file
which, by definition, only exists on a machine Nova has already been installed
on.

On a new machine the read failed, and because the installer stops on any
unexpected failure, it stopped. The message that would have explained it was
suppressed, because a missing file there is normal and worth ignoring; what was
not intended was that the read itself would end the script.

So it broke exactly one case: the first install on a clean server. Every node
that already had Nova kept updating correctly, which is why it took until now to
surface.

## Fixed

The read now treats a missing settings file as what it is on a fresh machine:
no previous port, carry on.

**If you hit this, just run the installer again.** Nothing was left behind and
nothing needs cleaning up first.

## Why no test caught it

Every installer test in this project reads the script as text and checks it says
the right things. None of them ran it. A check that reads cannot see a script
that exits.

There is now a test that executes the actual port-reading lines under the same
shell options the installer uses, against a directory that does not exist. Its
first version passed against the broken code, because it wrote its own version
of the call instead of using the installer's, so it is written to slice the real
lines out of the script.

## Upgrading

Update and restart. Existing installs were never affected by this.
