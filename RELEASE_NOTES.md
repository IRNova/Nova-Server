# Nova Server v1.13.2

Guide and documentation polish for the factory reset and log viewer shipped in 1.13.1.

## Changed

- The in-panel manual now covers both newer tools. The Settings guide describes the
  Danger zone factory reset (wipes users, inbounds, and settings back to a clean
  install while keeping your admin login), and the Xray settings guide describes the
  log viewer (read the last lines of the agent, Xray, or sing-box journal in the panel,
  no SSH). Updated in all three languages: English, Persian, and Russian.
- README (English and Persian) now lists the factory reset and the in-panel log viewer
  under Operations.

## Notes

- No behavior changes: this is a docs and guide release. The reset and log viewer
  themselves are unchanged from 1.13.1.
- Nova Server ships as an obfuscated build by design; Nova Proxy and the verified tools
  stay open.
- The Iran bridge is domain-oriented and needs an Iran VPS with a direct public IP
  (not behind NAT) to reliably carry traffic.
