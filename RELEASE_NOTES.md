# Nova Server v1.1.8

Two fixes on top of 1.1.7.

## Fixes
- **Saving settings no longer errors on a node with standalone inbounds.** A settings save (for example the per-operator carriers) was still triggering a full xray restart, because the hot-patch path is skipped when standalone inbounds exist, and the restart briefly drops the panel ("cannot reach the node"). A settings save that does not change users or the xray config now leaves xray completely alone, so it is instant and the panel never drops. Saves that do change the config still apply, but only after responding, so the panel stays put.
- **Per-carrier optimization toggles render correctly.** The TLS fragment and Mux switches were collapsing (the knob floated over the labels) because a general form rule was overriding the switch layout. Fixed, and verified by rendering.

## Install
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```
