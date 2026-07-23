# Nova Server v1.1.5

Two new features for Iran deployments. Update in one click from the panel (Settings, General, self-update).

## Lightweight Iran bridge (no full install on the Iran side)
Setting up an Iran bridge tunnel used to mean running the whole Nova installer on the Iran box, with all its prerequisites, on exactly the kind of restricted line where that is painful. Now it does not.

- On your foreign (exit) node's panel, open Tunnels, configure the tunnel, and click **Generate the Iran bridge command**.
- Run that single command on your Iran VPS. It installs **only** the one tunnel backend and starts it, no xray, no sing-box, no panel.
- Or run it directly:
  ```bash
  bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-bridge.sh) --help
  ```
  (You normally use the ready command from the panel, which fills in the backend, config and secret for you.)

## Per-operator configs in the subscription (for normal clients)
Per-carrier tuning used to require the custom Nova client. Now you can turn on **Per-operator configs in subscription** in Settings, and each user's subscription gets one extra VLESS config per Iranian carrier, each carrying that carrier's uTLS fingerprint and labeled by carrier. Users on v2rayNG, sing-box and similar just pick the config matching their SIM. Off by default; no effect on existing configs when off.

## Install
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```
