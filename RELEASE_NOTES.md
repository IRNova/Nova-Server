# Nova Server v1.9.1

Hardening for fleet enrollment, on top of v1.9.0.

## Security

- **The enrollment to a self-signed panel is now pinned.** When your panel runs on
  a bare IP (self-signed certificate), the "Add a node" command already opts into
  an unverified connection so the node can reach the panel. It now also pins the
  panel's exact public key, so even that connection rejects a man-in-the-middle
  presenting a forged certificate. A panel with a real domain was already fully
  verified; this closes the last gap for the no-domain case.
- **Enrollment is race-safe.** A join token is bound to the first node address it
  is used with; concurrent attempts are now re-checked under the lock, so a token
  can never be raced into reaching more than the one node it was minted for.

Everything from v1.9.0 (no-domain nodes auto-enroll, Pending-node visibility, safe
token exchange) is included.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Existing nodes update themselves from Settings > Updates.
