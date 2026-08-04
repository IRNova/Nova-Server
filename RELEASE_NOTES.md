# Nova Server v1.32.6

## A server without a domain has been handing out links that cannot connect

Xray-core removed `allowInsecure` and now refuses any configuration that sets it. A no-domain server serves a self-signed certificate, so its links carried exactly that, and the replacement was to pin the certificate instead: same result without a domain, and strictly safer than "trust anything", because a substituted certificate no longer passes.

That replacement was written, and never switched on. The function producing the pin existed, was correct, and was documented at length, but nothing ever called it. The rewrite only runs when a pin is present, so on every server without a domain it never ran at all, and the links kept the parameter that current Xray rejects.

The effect: on a no-domain server, every VLESS, VMess and Trojan link has been dead on v2rayNG, v2rayN and Streisand. Not degraded, refused at load. Sing-box and Clash clients use a different parameter and were unaffected throughout, which is why this could go unnoticed.

The pin is now supplied wherever subscriptions are built. Links from a no-domain server carry `pcs`, a pin of that server's exact certificate, and no longer carry the parameter that breaks them.

Nothing changes for a server with a domain, which is most of them.

## Verification

Checked against a certificate rather than a fixture: the pin matches the SHA-256 of the leaf certificate's DER, in hex rather than base64, since Xray hex-decodes the field and refuses the whole configuration otherwise. Both outcomes are covered, no pin leaving links untouched and a real pin producing `pcs` with `allowInsecure` gone, along with the rule that any subscription that can be built in insecure mode is also handed the pin, so this cannot silently come unwired again.

## Upgrading

Nodes with automatic updates enabled will take this on their next check. To update now, use the panel's update button, or re-run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
