# Nova Server v1.14.6

Tunnel reliability and honest diagnostics.

## Fixed

- The Iran bridge installer now mints its self-signed certificate with a
  SubjectAltName for the bridge's public IP. Without it, a wssmux exit rejects the
  certificate ("bad certificate") and the tunnel never connects. Re-running the
  bridge command on an affected Iran server fixes it.

## Changed

- The tunnel health check now recognizes a working data path even when the exit
  fronts port 443 with a proxy that does not expose the Nova status endpoint. That
  shows as an amber "Tunnel up, unverified" instead of a red "payload blocked", you
  can point client links at the bridge from it, and the health monitor no longer
  alerts on it.
- The Tunnel status card now gives plain-language advice for each failure (a
  rejected certificate, an unreachable bridge or token/single-exit conflict, the
  service not running), in English, Persian, and Russian.

## Notes

- Existing nodes pick this up through the panel's version-gated update.
- Nova Server ships as an obfuscated build by design; the installer and the verified
  tools stay open.
