# Nova Server v1.1.2

An important reliability release. Update in one click from the panel (Settings, General, self-update), or reinstall with the one-line installer.

## Fixes
- **Fresh installs now come up reliably.** On a brand-new server the xray access-log directory did not exist yet when the config was validated, so xray rejected a perfectly valid config and the panel never became reachable on port 443. Nova now creates that directory (owned by the xray user) before validating, so a fresh node serves the panel right away. This also fixes the "site not loading" after a clean install.
- Re-running the installer reliably applies updates (it now restarts the agent), and install output is clean (no stray `tar` warnings).

## New
- **One-command uninstall.** Remove Nova, xray, sing-box and all data with `nova-uninstall` (add `--yes` to skip the prompt), or run it directly:
  ```bash
  bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-uninstall.sh)
  ```

## Changed
- Nova is now VPS-only. The Docker and PaaS (runflare) path has been removed to keep one clear, fully featured install.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```
