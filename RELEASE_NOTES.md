# Nova Server v1.23.1

Hotfix.

## Fixed

- **Garbled Persian and Russian in the panel.** A text-encoding slip in the 1.23.0 build corrupted the non-English panel strings (they showed as mojibake). Restored correct UTF-8 across the whole panel. English was unaffected. Update to 1.23.1 and hard-refresh.
