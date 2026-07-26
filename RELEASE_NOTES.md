# Nova Server v1.8.0

Node lifecycle: enrollment that never strands a box, plus clean ways to remove or
reclaim a node.

## Fixed

- **A failed managed-node enrollment no longer strands the server.** If a node
  could not register with its main panel, the installer used to lock it into
  managed mode anyway (no sign-in, password cleared), leaving an orphaned box you
  could neither manage nor easily remove. Now the node only locks when enrollment
  succeeds; a failed enrollment leaves a normal standalone panel with clear next
  steps.
- **Enrollment race fixed.** The installer now waits for the node's own API on
  :443 to answer and retries enrollment, instead of calling back during the brief
  xray reload right after setup (the usual cause of a spurious "address
  unreachable").
- **Manual add-node is clearer.** Adding a self-signed (no-domain) node without
  ticking "this node has no domain" now says exactly that, instead of a generic
  "unreachable".
- **Installer no longer aborts on a missing checksum.** A transient failure to
  fetch `SHA256SUMS` now warns and continues, as intended, rather than silently
  stopping the install.

## Added

- **Remove a node with an optional full uninstall.** On the Nodes page, "Remove"
  can now also tell the node to tear itself down completely (xray, panel, all
  data). It stays best-effort: an unreachable node is still removed from the fleet.
- **`nova-unlock`** reclaims a managed node back into a standalone panel:
  `nova-unlock 'NewPassword'` on the server turns managed mode off and sets a new
  owner password. Users and traffic are untouched.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Existing nodes update themselves from Settings > Updates.
