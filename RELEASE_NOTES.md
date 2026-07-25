# Nova Server v1.4.0

Two more protocols.

## New

- **TUIC v5** and **NaiveProxy** inbounds, on the co-located sing-box (like Hysteria2). Add them from the Inbounds page, each on its own port, per-user.
  - **TUIC** is QUIC/UDP: low-latency, great for gaming and calls, and it works on a no-domain node with a self-signed certificate.
  - **NaiveProxy** is HTTP/2 over TLS that blends in as ordinary HTTPS. It needs a trusted certificate (a real domain), so the panel lists it under "Needs Domain".

This closes the main protocol gap versus sing-box-based panels. Clients: sing-box, v2rayN, NekoBox, Clash.Meta (TUIC); the NaiveProxy client or sing-box (NaiveProxy).

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Existing nodes update themselves from Settings > Updates.
