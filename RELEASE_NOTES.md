# Nova Server v1.24.0

Security hardening (batch 1 of an external audit).

## Fixed

- **Failed enrollment no longer strands a node.** The installer now locks a node and clears its temporary password ONLY after the parent panel confirms enrollment. A failed/retried enroll keeps the node recoverable (local sign-in stays, and it prints the API token + a `nova-passwd` hint for a manual add).
- **`nova-unlock` is now installed.** The documented recovery command (reclaim a managed node whose parent is gone) shipped in docs but not on disk; the installer now installs the wrapper.
- **API is Bearer-only.** The REST API no longer accepts the token in a `?token=` query string, which could leak into access/proxy logs.
- **Node transport refuses cleartext.** The panel will not send a node`s owner-scoped token over plain http to a remote host (loopback still allowed).
- **Docker secret hardening.** The container env file (which can hold the admin password) is created 0600 before anything is written; `nova-passwd` can read the password from stdin instead of the process arguments.

## Notes

- Further hardening (enrollment key-pinning, per-node cert pinning, first-run claim token, Docker lifecycle, webhook SSRF) is in progress in following releases; after the enrollment-pinning release, operators should rotate their fleet node tokens.
- Existing nodes update through the version gate. Nova Server ships as an obfuscated build by design; the installer and verified tools stay open.
