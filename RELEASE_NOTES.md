# Nova Server v1.2.0

A feature release focused on how you install, secure, and scale your panel.

## New

- **The panel now hides behind a secret path.** A fresh install puts the panel at `https://your-server/p-xxxxxx/` instead of the bare root, and every other address returns a plain 404. Scanners that hit the raw IP or domain see nothing, like the web base path of other panels. You can change the path, clear it back to the root, or give the panel its own extra HTTPS port any time under Settings > Panel access. If you ever lose the path, run `nova-passwd` over SSH and it prints the current panel URL.

- **The installer now asks setup questions.** Run the one-liner and it asks whether you have a domain (if yes, it gets a free Let's Encrypt certificate automatically), a secret panel path (Enter to auto-generate, type your own, or `none` for the root), and an optional extra panel port. Everything can still be scripted with env vars: `NOVA_DOMAIN`, `NOVA_DOMAIN_EMAIL`, `NOVA_PANEL_PATH`, `NOVA_PANEL_PORT`, `NOVA_ADMIN_PASS`, and `NOVA_NO_PROMPT=1`.

- **Add nodes with one command.** Install the panel once on your main server, then open the Nodes page and click "Generate command". Run the single line it gives you on a fresh VPS and that server installs as a managed node: no panel of its own, it registers itself with the main panel automatically, and you drive it entirely from there. The join command works once and expires in 24 hours.

## Fixes

- **Consistent Persian font.** Some panel elements rendered Persian text in a mismatched system font. The whole panel now uses Vazirmatn everywhere.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

Existing nodes update themselves from Settings > Updates, or with the one-liner above.
