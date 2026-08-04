# Nova Server v1.32.3

**If you run fleet nodes, take this release.** Giving a node a second domain destroyed the first one, and there was no way to avoid it.

## Adding a domain to a node broke every link on its existing domain

Every TLS inbound on a server, and the node's own API, share a single certificate file. Asking a node for a certificate always ran the *primary* domain job, so issuing one for a second domain overwrote that file.

The node then presented a certificate naming only the new domain. Everything on the old one broke at the handshake: every client already using it, and the panel's own control channel, which failed with "Hostname/IP does not match certificate's altnames". Fleet sync stopped with it, so the node went on serving a configuration that quietly drifted out of date. That is the same invisible failure 1.31.0 was written to end, reintroduced through a different door.

There was no way to get the intended result either. Nothing could add a domain to a node, only replace its domain, so publishing one inbound on its own name was impossible.

Nodes now accept both, explicitly:

- **Adding a domain** issues a certificate into its own file and offers it alongside the primary, matched by SNI, exactly as bridge domains already work. The primary is untouched, so existing links keep working. This is what an inbound that needs its own name should use.
- **Replacing the primary** is still available, but it now has to be asked for. Since it orphans every link already issued on the old name and leaves the panel dialling a name the node no longer answers to, a request that would change the primary is refused and tells you both options instead of performing a silent outage.

The node's certificate status also reports additional domains separately from the primary, so a panel can follow one without mistaking it for the other.

Both are driven through the node API (`POST /api/v1/cert`, owner token) or the panel's `/admin/nodes` `cert` action, with `kind: "alias"` to add a domain and `replace: true` to change the primary. **There is still no button for this in the panel**, for node certificates generally, not just these two modes. That UI is the obvious next piece of work; this release makes the underlying operation safe and possible, which it was not before.

Three smaller faults on the same path went with it: the Cloudflare method was tested against a field that is never written, so DNS-01 was refused on nodes that genuinely had a token connected (and DNS-01 is the only method that does not stop xray for the challenge); a hand-installed certificate was reported back as a Cloudflare one; and a bad pasted certificate was accepted with a success response and only failed later.

Certificate jobs also queue behind one another, and a job that waited more than fifteen minutes for its turn was treated as dead before it started, then issued a certificate and rolled it back anyway. Provisioning several domains in a row is exactly what triggers it, which is what this release makes people do.

## Resellers can now be charged for renewals

1.32.2 closed a hole where a reseller could hand out any plan's access for free, and deliberately left two related gaps open because they needed a pricing decision: extending a customer's expiry and resetting their usage cost nothing, so a customer bought once could be renewed for ever.

Both are now priced, and no new price list was needed. Re-applying a plan was already a charged operation, so extend and reset were simply cheaper doors to the same commercial outcome. They now bill at the customer's own plan rate:

- **Extending** costs a share of the plan price, pro-rated by the plan's own length. Ten days of a thirty-day plan costs a third of it.
- **Resetting usage** costs a renewal, because it grants the plan's volume again.
- **Goodwill stays free.** The first three days of any extension cost nothing, so a few days after an outage need no thought. The allowance is configurable.
- A customer who is not on a plan has no price to derive from, so the renewal is refused with that explanation rather than being quietly free.

**Nothing changes for an existing deployment.** Updating does not re-price a running business: renewals stay free until you turn charging on, and the health check now points out that they are free and offers the switch. New installs start with charging on.

## Verification

Exercised end to end on a live panel and a live fleet node, against a real Let's Encrypt issuance, with two domains pointed at one node:

```
primary certificate  -> ir.vbhshm.cloud     (unchanged by the second issuance)
SNI ir.vbhshm.cloud  -> ir.vbhshm.cloud
SNI ir2.vbhshm.cloud -> ir2.vbhshm.cloud
```

Both names served their own certificate from one node, with the panel's control channel and fleet sync healthy throughout, and subscriptions serving unchanged.

Per-inbound certificates were listed as **untested** in 1.31.0 and 1.32.2. They are now tested, and the fault that testing exposed is what this release fixes. Certificate issuance through Cloudflare DNS-01 remains untested.

## Upgrading

Nodes with automatic updates enabled will take this on their next check. To update now, use the panel's update button, or re-run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
