# Nova Server v1.33.0

Nova Server 1.33.0 makes the setup wizard finish the job, collapses the
configuration an operator has to face, and fixes three defects reported from a
live node, one of which stopped new users from connecting at all.

## Three fixes for problems on running nodes

**New users did not connect while existing ones kept working.** Two independent
causes, both fixed.

- The proxy core identifies a client by name, and Nova let you create a second
  user with a name that was already taken. The core keeps only the first, so the
  new account got a complete-looking subscription whose configs completed a
  handshake and then failed authentication, with nothing in the panel to say why.
  Duplicate names are now refused, in the Add User form and on the server. A node
  that already contains duplicates stays saveable, so its operator can still
  change settings and rename the duplicates; only a save that adds a NEW
  collision is rejected.
- Adding a user as the panel owner never pushed that user to the fleet. The
  owner's panel writes the whole settings document, and that path synced nodes
  only on a configuration change, so an account assigned to an inbound running on
  a node was unknown to that node until the ten-minute reconcile caught up. The
  reseller path was unaffected, which is why this looked intermittent. The same
  fix closes it in the other direction: a user you delete or disable now stops
  working on every node immediately instead of at the next reconcile.

**A REALITY inbound disappeared after an update.** The setup assistant removed a
managed inbound it no longer wanted instead of switching it off. For Reality that
destroys the keypair and the short IDs, so the inbound could not be restored even
by recreating it: every client link carrying the old public key was dead. It now
disables the record in place, preserving the port, the keys and the secret. A
parked inbound binds no listener and appears in no subscription, so the effect on
traffic is unchanged, and turning it back on is one click.

Related, and the likely reason an operator was put in front of that choice at
all: the first-run wizard was opening by itself on nodes that were already
configured. It treated "has never run the wizard" as "is not set up", which is
true of every node configured by hand. It now checks whether the node has any
users.

## The setup wizard finishes the job

The wizard asks five questions and then does the work, instead of collecting
answers and directing you to other pages.

- **Who is this server for**, **where will people connect from**, **how will
  people reach it**, **do you have another server**, and **who will use it**.
- It issues the certificate itself, in the window, when you give it a domain, and
  diagnoses a failure by cause: the domain not pointing here yet, port 80 closed,
  a rate limit, or Cloudflare proxying the name. Each one names the real values
  and gives numbered fixes rather than "something went wrong".
- It configures an Iran bridge or an extra node and hands you the single command
  to paste on that machine, then waits for it to check in.
- It finishes on a subscription link and a QR code for every person it created.

The step list is derived from the answers rather than fixed, so choosing a domain
visibly adds the certificate step and the counter stays true. Every question can
be skipped, each skip takes a working default that is printed before you tap it,
and the review lists what was skipped and what was used instead. Skipping the
last question still creates one account, so nobody leaves without a link.

Nothing is written to the server until you approve the review.

## Less configuration to face

- **One question replaces seven toggles.** Where your users connect from (open
  internet, Iran, China, Russia) now sets domestic bypass, TLS fragmenting, QUIC
  blocking and IPv6 egress together, and the wizard lists every setting it is
  about to change before it changes it. Previously these were seven independent
  switches, offered in two different places that could disagree.
- **Simple mode.** A newly installed node keeps the everyday pages and puts the
  engine internals away: the Xray settings page, the routing rule builder, custom
  outbounds, Iran tunnels, resellers, sign-in blocking, webhooks, API tokens, the
  panel path and extra port, and the DNS tunnel. One switch in Settings brings
  all of it back. It changes no setting, only which pages are listed.
- **An existing deployment is not touched.** Any node that predates this release
  starts with advanced mode on, so no page anyone was already using can disappear
  under an update. The switch also survives a factory reset.
- **The Iran bridge is one field instead of eight.** Give the wizard the Iran
  server's address and Nova derives the tunnel engine, transport, control port,
  shared secret, forwarded ports and multiplexing, all to the values the Tunnels
  page already recommended in prose. The full form is still there in advanced
  mode.

## A wizard that could silently undo your settings

Re-running the old wizard could turn settings off without being asked to. It
detected "restricted network" from one settings key but wrote three, so a node
whose keys did not agree was quietly normalised on the next run. Verified against
a production panel, where re-running it with its own detected answers would have
switched domestic bypass off.

Detection is now the exact inverse of what the wizard writes, and it reads the
settings themselves rather than a stored copy of your previous answers, so a
change made anywhere else can never disagree with it. Two tests assert the round
trip for every combination.

## Found by the pre-release security review

A full review of this release found five issues, all fixed before publishing.
Two are worth knowing about because they were reachable by ordinary use:

- Re-running the wizard against a bridge you already had would have rotated the
  shared secret, leaving the Iran server unable to authenticate and dropping
  every user riding it, and would have discarded any extra forwarded ports and
  failover bridges. Re-running against the same address is now a no-op, and
  pointing at a different one asks first.
- The new duplicate-name rule guarded only the owner's own form. A reseller can
  rename their own customer, so they could rename onto another operator's user
  and collide with it inside the running core. The rule now covers every path
  that writes a user, including the API and the Telegram bot.

The review also confirmed the two things most worth confirming: the simple-mode
navigation is presentation only, with every hidden page independently protected
on the server, and there is no HTML injection in the roughly one thousand lines
of new wizard markup.

## Validation

- 595 automated tests pass. Every fix in this release was mutation-checked: the
  fix was reverted and the new test confirmed to fail.
- The configuration changes were verified by replaying a production settings
  document through the new build in a sandbox: it backfills to advanced mode,
  keeps every page, and preserves every setting.
- The wizard was driven end to end in a browser against a real node, in English
  and in Persian right-to-left, including the certificate failure path.
