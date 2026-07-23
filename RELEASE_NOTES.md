# Nova Server v1.1.3

A fix for a broken transport in the latest xray. Update in one click from the panel (Settings, General, self-update).

## Fix
- **mKCP no longer breaks the node.** The current xray release removed the old mKCP transport format, so a node that had an mKCP inbound could not save any change, including creating a user (xray rejected the whole config). Nova now:
  - skips any mKCP inbound when building the config, so a leftover one can never brick the node,
  - removes an existing mKCP inbound automatically on update,
  - and no longer offers mKCP when adding an inbound.

  If you saw "xray rejected the new config" or could not create users, this fixes it. Existing users, inbounds, and settings are untouched.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```
