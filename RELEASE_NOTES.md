# Nova Server v1.17.0

Multi-bridge tunnel failover.

## Added

- An exit can now dial **several Iran bridges** at once. List extra bridges in the
  new "Failover bridges" field on the exit tunnel form. Each user link is then
  offered once per bridge, so the client's url-test automatically shifts to a working
  bridge if one bridge IP is blocked. Set up each bridge on a different Iran server
  with the same bridge command and token.

## Notes

- Fully backward compatible: with one bridge, subscriptions are unchanged.
- Existing nodes pick this up through the panel's version-gated update. Nova Server
  ships as an obfuscated build by design; the installer and verified tools stay open.
