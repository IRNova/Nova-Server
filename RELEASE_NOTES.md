# Nova Server v1.32.2

Covers 1.32.x. **This release contains a security fix that applies to every panel, including ones that never took 1.32.0.**

## Security: a reseller could hand out any plan's access, for free

If you use resellers, take this release, and take it promptly.

Applying a plan to customers in bulk did not check that the plan was one you had marked sellable, and did not charge the reseller for it. A reseller could name any plan you had ever created, including a private one, and grant their customer its inbounds and its node access without spending a single unit of balance. The plan could be named by its name as well as its id, and resellers can already see your plan list, so this took two clicks in their own panel.

Bulk plan application is now gated to sellable plans for resellers, and charged per customer, matching every other reseller provisioning path. Nothing changes for owners.

Two related gaps are **not** closed here, deliberately, because they need a pricing decision rather than a fix: a reseller can still extend a customer's expiry and reset their usage without being charged, so a customer bought once can be renewed indefinitely for nothing. If that matters to you, restrict user editing for your resellers until those can be priced.

## Applying a plan no longer resets what a customer paid for

Applying a plan to change a customer's access also overwrote their traffic allowance, expiry and device limit. The apply-plan dialog now offers "Only give access, keep their current traffic and expiry".

Note what that does and does not do: the plan's inbounds and nodes **replace** the customer's current access, they are not added to it. Traffic and expiry are left alone.

## Per-profile SNI

Setting a different SNI on each profile works for ordinary TLS and gRPC. It does not work for Reality, or for Hysteria2, TUIC and NaiveProxy, and it cannot: Reality only accepts an SNI that is one of the inbound's own server names, and the QUIC protocols present a single certificate, so every profile is published on that one name.

Reality now honours a profile SNI **that is one of its server names**, so a profile can choose which of them to present. Where a profile's SNI cannot be used, the health check says so, instead of leaving you to wonder whether the field saved.

## Health check: three new things it tells you

- **An inbound on a node whose egress that node cannot provide.** WARP needs its own Cloudflare registration on the node, and per-country exits run only on the main server, so the node's core has no definition for the tag and every connection through that inbound is dropped. Tor and Psiphon are reported separately as a note, because a node does build those, and they work if Tor or Psiphon is running on that node.
- **An outbound that is defined but disabled**, which dangles exactly like a missing one.
- **Hysteria2, TUIC and NaiveProxy listen on UDP.** They never appear in `ss -lnt` or `netstat -tlnp`, which is what most people check, so "the port is not listening" is usually a TCP-only check. The panel now says this and names the port.

## Verification

Emitted configurations were checked against real client binaries: xray-core 26.3.27, mihomo 1.19.29, and sing-box 1.11.15 through 1.14.0-beta.4. Every config on a live panel and its node was driven through a real client end to end.

Cloudflare DNS-01 certificate issuance and per-inbound certificates remain **untested**. If you use either, treat this release as unproven for that path.

## Upgrading

Nodes with automatic updates enabled will take this on their next check. To update now, use the panel's update button, or re-run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
