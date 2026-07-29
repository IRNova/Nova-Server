# Nova Server v1.14.7

Simpler tunnel setup, and errors that explain themselves.

## Added

- **Real errors, not generic ones.** The Tunnel status now reads the tunnel's own
  log and tells you the actual cause with the fix: a rejected certificate, a
  rejected token (another exit may be on this bridge), a connection reset (Iran DPI,
  use wssmux), an unreachable bridge. In English, Persian, and Russian.
- **One-click Diagnose.** A "Diagnose" button runs the whole chain in order (service
  running, bridge control port reachable, certificate accepted, traffic flows
  end-to-end) and shows a pass/fail checklist, so the broken step is obvious.
- **Fewer steps.** Once the data path is confirmed, Nova points client links at the
  bridge automatically, so setup is just: run the bridge command, done. It only ever
  points forward and never auto-reverts, so a brief hiccup cannot strand users off
  the bridge. A form toggle turns it off if you prefer the manual button.

## Notes

- A heads-up on the tunnel form: one Iran IP can bridge only one exit's port 443, so
  a second exit needs its own Iran server or a different forwarded port.
- Existing nodes pick this up through the panel's version-gated update. Nova Server
  ships as an obfuscated build by design; the installer and verified tools stay open.
