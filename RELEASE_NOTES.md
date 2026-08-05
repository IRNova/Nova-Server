# Nova Server v1.33.1

A patch on 1.33.0. It fixes a wizard bug that lost your answers, lets the setup
wizard handle an Iran bridge and a second node together, gives the panel owner a
real control over reseller renewal pricing, and clears four issues found by the
pre-release security review.

## Skipping a step no longer throws you back to the start

Tapping "Skip, use the server IP" on the certificate step sent you back to the
first question with every answer gone. The step you were standing on was removed
from the plan by the skip itself, and the code then looked for it in a plan that
no longer contained it. It moves forward correctly now.

This affected 1.33.0 from release. If you started the wizard and skipped the
certificate, that is what happened.

## The wizard sets up a bridge and a node in one run

"Do you have another server?" is now a multiple choice rather than one-of. An
operator with an Iran bridge in front of a foreign exit and a second node abroad
can set both up in a single pass; before, one of the two had to be done by hand
afterwards. Each gets its own step, so the progress rail still tells the truth,
and skipping one leaves the other alone.

## Fixes found by the pre-release security review

Four issues were found and fixed before this went out. Two are worth knowing
about:

- **Skipping the Iran bridge left a tunnel running.** Reaching the connect step
  already configured and started the exit tunnel, and skipping only cleared the
  answer, so the server was left listening on an extra port for a bridge that
  would never arrive. On a new install the Tunnels page is hidden, so there was
  no obvious way to find or remove it. Skipping now tears down what that run
  started, and never touches a bridge you already had.
- **A second enrolment token could be minted** by stepping back and forward
  while the first request was still in flight, leaving an extra 24-hour
  credential valid. Changing the other server's address also kept handing you
  the command built for the old address. Both fixed.

The review also confirmed that a reseller cannot change the renewal pricing:
that endpoint is owner-only and was tested with a live reseller session, not
just read.

## Renewal pricing is yours to set

Whether extending an expiry or resetting usage costs your resellers anything had
no control in the panel at all. The only way to change it was the health check's
one-click fix, which could switch charging on and never off, and the free
allowance could not be set from the panel at any point.

The Resellers page now carries the switch, the goodwill allowance, and an
explanation of how the price derives from the customer's own plan. Nothing
changes by default: if renewals were free on your server, they still are.

## Validation

- 602 automated tests pass.
- A security review ran over the change before release.
- The wizard was driven in a browser: both peers selected, the rail growing to
  nine steps with two work segments, and the skip path confirmed to move forward.
- The certificate challenge path was proven against a real new domain
  (a certbot dry run for ir.innovio.ae succeeded), which had never been
  demonstrated before this release.
