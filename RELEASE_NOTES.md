# Nova Server v1.20.1

UI fix.

## Fixed

- The **Open subscription** button on the dashboard Quick connect card no longer shows a stray underline. It is a link styled as a button, and the base button style was missing the text-decoration reset, so the label rendered underlined (most visible in the Persian panel). Fixed globally for every link-button.

## Notes

- Cosmetic only; no behavior change. Existing nodes pick it up through the version-gated update.
