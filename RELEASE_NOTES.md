# Nova Server v1.41.4

## WARP kept telling you its data was low when nothing was wrong

If you use WARP on a free account, Nova has been warning you, on Telegram and in
the activity log, that your **WARP+ data is low, about 0 MB left**. Repeatedly,
and for as long as WARP was registered.

There was nothing wrong. Cloudflare reports `warp_plus: true` on a brand new
free account that has never had a licence, and Nova read that as "this is a paid
plan", so it went looking for the remaining data, found none, and warned about
it. Verified against Cloudflare's live API with a control: an account with no
licence at all comes back exactly the same as one with a licence applied.

Nova now decides from the plan itself, so a free account is left alone. A real
WARP+ plan still warns when it genuinely runs low or expires, including a plan
that has run down to zero, which is the case the warning exists for.

## A licence key that changes nothing is no longer reported as success

Applying a key showed the account as **plus** straight away. That reading came
from Cloudflare's reply to the update, which does not include the plan, so Nova
filled in the optimistic answer.

Nova now reads the account back after applying a key and tells you what it
actually says. If the key was accepted but left you on the free plan with no
data, you are told that instead of being congratulated.

**Worth knowing if you use the free "WARP+ key" channels.** Every key from those
bots that we tested was accepted by Cloudflare and granted nothing: applying one
attaches your device to an existing account that is itself on the free plan with
no data left, because the same key has been handed to thousands of people. The
key is not rejected, it simply does nothing, which is why it looked like Nova
was at fault.

## And the same false alarm on the WARP card

The panel showed **Data left: 0 B** in the warning colour on every free account,
for the same reason. A free account reports zero because the figure does not
apply to it, not because you have run out. That row is now left out unless there
is a number worth showing, and the warning colour stays with the paid plans.

Three smaller things found while checking the above: applying a key when
Cloudflare would not confirm the result afterwards reported success and
overwrote your stored plan with "free", which is reachable simply by applying
two keys quickly, since that endpoint is rate limited. An expired plan that
Cloudflare has reverted to free now still reports as expired, which the plan
check would otherwise have hidden. And nodes upgrading from an earlier build
have the flag the false alarm left behind cleared, so a later genuine warning is
not swallowed.

---

**Updating:** Settings, then Check for updates. No user, inbound, or setting is
changed by this release.
