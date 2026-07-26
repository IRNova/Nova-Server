# Nova Server v1.9.0

Fleet enrollment that actually works for no-domain nodes, and visibility when it
doesn't.

## Fixed

- **No-domain (self-signed) nodes could never auto-enroll.** The parent panel
  reached child nodes through an import that isn't available at runtime, so every
  attempt to verify a self-signed node failed with "could not reach the node
  back", and the node fell back to standalone. This was the real reason
  one-command enrollment kept failing on bare-IP servers. The parent now reaches
  nodes with the built-in HTTPS client, so **running the "Add a node" command on a
  fresh server registers it automatically**, no manual step, domain or not.

## Added

- **Failed enrollments are visible on the panel.** When a node runs the join
  command but the panel can't reach it back (for example port 443 isn't open yet),
  it now shows up on the Nodes page as **Pending** with the reason and how to fix
  it, and the attempt is written to the activity log. Open 443 and press **Test**,
  or add it by hand, no more silent failures the owner never sees.
- **The enrollment sends the node's API token over a verified TLS connection** to a
  panel that has a real certificate, falling back to an unverified connection only
  for a self-signed panel (with a clear warning). Keeps the token safe in transit.
- **Clearer install output** when enrollment fails: the real HTTP status and a
  targeted hint (expired token, panel unreachable, node unreachable, rate-limited)
  instead of a blank "Response: none".

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Existing nodes update themselves from Settings > Updates.
