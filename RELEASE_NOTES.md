# Nova Server v1.26.3

Nova Server 1.26.3 fixes inconsistent data quota units in the user editor. A limit entered as 10 GB now displays as 10 GB everywhere instead of 10.7 GB.

## Consistent user quotas

- The user list, edit modal, and full user detail page now format usage and limits with the same binary unit basis used by quota enforcement.
- Both user editors convert total, upload, and download limits through one shared helper.
- Opening and saving a user no longer changes a quota between decimal and binary units.
- Saved plans, CSV import and export, subscriptions, and Telegram already used this binary convention and now agree with the panel.
- Existing quota bytes and usage counters are not migrated or reset.
- A regression test executes the panel helpers and verifies that 10 GB round-trips to exactly 10 GB.

## Upgrade

Existing servers can update normally from the panel. No database migration is required.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

The public repository contains only the obfuscated runtime package, installers, checksums, documentation, and Docker release context. The unobfuscated server source remains private.
