# Nova Server 1.70.0

## Removing a reseller left their customers behind

The confirmation said "their users are not deleted", which read like a decision.
The state it actually left was not one anybody had chosen: every customer that
reseller had sold to stayed on the node with `ownerId` still naming an admin
that no longer existed.

Two things followed from that pointer. Scoping matches a customer's owner
against a live admin, so those customers appeared in no reseller's list and
nobody was looking at them. And the volume allowance is rebuilt from
`settings.admins` on every pass, so once the reseller was gone the allowance
stopped existing with them: a reseller who had exhausted their volume could be
deleted, and every customer that allowance had suspended came straight back,
uncapped.

That second one is why this is not tidying. Deleting an exhausted volume
reseller quietly handed all of their customers unlimited data.

Removal now says how many customers are involved and asks. Keeping them, which
is what happens if you do nothing, makes them the owner's own with their access,
their credentials and their links untouched. Ticking the box removes them with
the reseller, and only an explicit tick does: nothing else counts as yes. The
activity log records which of the two happened and for how many people, because
"Reseller admin removed" no longer tells those two apart.

The health check finds the customers earlier releases already stranded, names
them, and offers to take them over. That fix is deliberately kept out of "fix
everything": it widens no access, but it decides who owns a paying customer, and
an operator may want them handed to a different reseller instead.

Reported by an operator who deleted a test reseller and found its customers
still on the node.

## The panel search knows the symptoms

1.69.0 added the AmneziaWG packet size field and the WARP "Try another address"
button, both with their labels in all three languages and nothing in the search
index pointing at either. The words somebody types are the symptom, not the
setting: "connects but nothing loads", "downloads stop halfway", "warp stopped
working". Those reach the two controls now, in English, Persian and Russian, and
the guide answers the same two as questions.

## Upgrading

Update and restart. Existing customers, resellers and settings are untouched. If
you have removed a reseller in the past, run the health check afterwards: it will
list anybody left stranded by it and offer to take them over.
