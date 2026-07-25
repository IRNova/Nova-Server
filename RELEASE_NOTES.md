# Nova Server v1.6.0

A second DNS-tunnel engine, and a security pass on the tunnel install path.

## New

- **CottenDns DNS-tunnel engine.** The DNS Tunnel now has a choice of engine. **MasterDnsVPN** stays the simple default; **CottenDns** is the more capable engine for very lossy or heavily probed networks: it adds DNS-over-TLS and DNS-over-HTTPS resolver transport, balances across several resolvers, and recovers from packet loss. It never binds :443, so it coexists with the panel. Pick the engine in the DNS Tunnel card (Settings). Both bind port 53, so only one runs at a time; switching takes the port from the other. Users connect with the engine's own client ([CottenDns](https://github.com/TaJirax/CottenDns) or [MasterDnsVPN](https://github.com/masterking32/MasterDnsVPN)), and the panel exports the client config. Trilingual and owner-only.

## Hardened

- **Pinned + checksummed tunnel binaries.** Both DNS-tunnel engines now download a **pinned release** (not a floating "latest") and verify the archive against a hardcoded SHA-256 before running it as root. A mismatch, or an architecture with no pinned checksum, fails closed.
- **Trustworthy client IP behind a proxy.** With `TRUST_PROXY` set, the panel now reads the proxy-observed (rightmost) `X-Forwarded-For` hop instead of the client-supplied leftmost one, so the login guard and rate limiter can't be bypassed or turned into a lockout with a forged header.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Or with Docker:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/docker/nova-docker.sh)
```

Existing nodes update themselves from Settings > Updates.
