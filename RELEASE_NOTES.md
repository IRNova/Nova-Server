# Nova Server v1.43.2

## mieru with no users: the panel now says why, instead of blaming the port

If you turned mieru on before giving it to any user, the server never started
and the panel told you "nothing is listening" on its port. That is the symptom.
The cause is that the mieru server refuses to start with an empty user list, and
nothing said so anywhere: not the health page, not the activity log, not the
logs on the server.

One operator hit this twice, on two different ports, and reasonably concluded
the port was the problem. It was not, and neither was UDP. It was that nobody
had been granted mieru yet.

Three things change:

- **The health page names the cause.** "mieru is on, but no user has been given
  it, and the mieru server refuses to start with an empty user list. That is why
  its port shows nothing listening." In English, Persian and Russian. There is
  deliberately no one-click fix, because which user to grant is your decision
  and granting widens what that account can reach.
- **Nova no longer asks the server to start when it cannot.** Enabling mieru
  before granting it is a perfectly reasonable order to work in, and it is now
  reported as the half-configured state it is rather than as a failure.
- **A failed start now says what went wrong.** The real message, "no user
  found", reaches your activity log. Previously a failure carried no reason at
  all, so the log recorded "mieru enabled" and nothing else.

**If your mieru is showing red right now:** open any user, turn mieru on for
them, and save. The server starts on its own. Nothing else needs changing, and
no client configuration is affected.

## A translation gap that could have let this happen again

The health findings live in their own translation tables, and the check that
guards English, Persian and Russian parity did not cover them. A finding added
in English only would have passed every gate and reached the one screen people
open when they are already stuck. That check now covers them, and also fails if
the server can emit a finding the panel has no translation for.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release.
