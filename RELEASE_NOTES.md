# Nova Server v1.5.0

Operator tools: a login shield, outbound webhooks, and per-inbound traffic.

## New

- **Login guard (fail2ban-style).** After too many failed sign-ins from one IP within a window, that address is blocked for a set time, so panel password guessing gets nowhere. On by default. Tune the attempt count, the window, and the ban length, and see every active ban with one-click **Unban** (or **Clear all**) under **Settings > Security**. The block survives restarts.

- **Webhooks.** Send a small signed JSON POST to your own URL when something happens on the node: a user is created, updated, deleted, expires, or hits quota; a node enrolls; or an IP is banned. Add any number of endpoints, pick which events each one wants (or leave it on all), and set an optional secret. With a secret, Nova signs the body with HMAC-SHA256 in the `X-Nova-Signature` header so your receiver can verify it. A **Test** button fires a sample delivery. Managed under **Settings > Security**.

- **Per-inbound traffic chart.** The Inbounds page now shows a daily traffic chart per inbound over the last 14 days, so you can see which entry points carry the load.

All three are trilingual (English, Persian, Russian) and owner-only.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Or with Docker:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker/nova-docker.sh)
```

Existing nodes update themselves from Settings > Updates.
