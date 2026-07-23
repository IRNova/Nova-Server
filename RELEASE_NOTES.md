# Nova Server v1.1.4

A fix for per-country exits. Update in one click from the panel (Settings, General, self-update).

## Fix
- **Adding several per-country exits in a row no longer errors.** Each add used to restart xray immediately, which briefly dropped the panel it is served through, so a country clicked during that moment failed with "internal error" or "could not reach the node". Now the add responds first, starts the country instance, and coalesces the xray reload (one restart for a batch of changes). Add or remove as many countries as you like, back to back.
- Clearer messages: a duplicate country, an unavailable region, or no free port now returns a plain message instead of "internal error".

## Install
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```
