# Nova Server v1.14.1

Security hardening. No behavior change for normal use.

## Fixed

- **Webhook secrets are no longer sent back to the browser.** `GET /admin/webhooks`
  now returns a `hasSecret` flag instead of the raw shared secret, and editing a
  webhook without re-entering the secret keeps the stored one. Test pings still sign
  with the real secret.
- **Webhook SSRF guard.** A webhook URL must now be a public http(s) endpoint.
  Loopback, private, link-local (including the `169.254.169.254` cloud metadata
  address), and `localhost`/`.internal` targets are rejected. If you deliberately run
  a receiver on the same box or a private network, set `NOVA_ALLOW_PRIVATE_WEBHOOK=1`.
- **Tunnel config injection.** The tunnel token and each forward target are now
  charset-checked, so they cannot break out of the generated tunnel config.

## Notes

- Nova Server ships as an obfuscated build by design; Nova Proxy and the verified tools
  stay open.
