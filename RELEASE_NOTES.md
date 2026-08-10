# Nova Server v1.54.1
## The v2rayNG import button, fixed properly this time

1.54.0 changed the one-tap v2rayNG button to use the subscription entry point,
which was right, and appended the operator's brand name as a URI fragment so the
imported subscription would arrive named, which was wrong.

Reported from a real Android handset within hours: the subscription **is** added
and then downloads no configurations at all. Deleting the name and the `#` by
hand made it work.

The reason is that v2rayNG does not use that fragment as the subscription's
name. `UrlSchemeActivity.parseUri` appends it to the inner URL and hands the
result to the importer, so it is stored as part of the subscription URL. Every
later fetch then asks the server for `<token>%23<brand>`, which matches no
customer, and the server correctly answers with nothing.

The fragment is gone from all three places that build that link. The
subscription arrives with v2rayNG's own default name, which is a small price for
one that actually carries configurations. The fragment plumbing was removed
rather than left switched off, so it cannot come back by accident, and the test
now fails if any v2rayNG link contains a `#`.

Nothing else changed in this release.

### If you are on 1.54.0

Update, then ask any customer who imported through that button to remove the
subscription in v2rayNG and tap the button again. A subscription added while
1.54.0 was live has the broken URL stored in the app and will keep downloading
nothing until it is re-added.
