# Nova Server v1.14.8

A small hygiene release.

## Changed

- The shipped test fixtures no longer contain a real server IP. They now use a
  TEST-NET placeholder address, so nothing operational is embedded in the tarball.
  No runtime behavior changes.

## Notes

- Existing nodes pick this up through the panel's version-gated update.
- Nova Server ships as an obfuscated build by design; the installer and the verified
  tools stay open.
