# Nova Server 1.85.4

Deleting a tunnel now deletes its domains with it.

## What was wrong

When you build a tunnel you can give it a domain, which gets its own
certificate so the exit can answer that name.

Deleting the tunnel cleared the tunnel and its address, and stopped there. The
bridge domain stayed in the panel's list, and its certificate and private key
stayed on disk, for a tunnel that no longer existed. So you deleted a domain and
the panel went on showing it.

The code even claimed otherwise: the comment on that step said it "fully clears
the tunnel".

## What changed

Deleting a tunnel now removes its bridge domains and their certificate files,
which is exactly what deleting a single one of those domains has always done.
Deleting the whole thing should not be weaker than deleting one part of it.

This also closes a quieter problem. A private key left on disk for a domain
nothing references is a key nobody is watching, and re-adding that domain later
would have silently reused it instead of issuing a fresh one.

## Upgrading

Update from the panel, or run the installer again. If you have a leftover domain
from before, delete it from the tunnel card once and it will stay deleted.
