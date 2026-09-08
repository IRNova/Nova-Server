# Nova Server 1.85.3

The fourth time an option added to the subscription route was missed in the
Telegram bot, and the first time a test found it instead of an operator.

## The bot ignored "Never in configurations"

The bot builds its own subscription options. The setting that keeps your panel
domain out of client configurations was never added there.

So an operator who switched it on saw it work on every subscription link, and
kept handing out the panel domain to every customer who takes their configs from
Telegram. The panel reported the setting was on the whole time.

If you use the bot and had this setting on, the configs it sent in that window
name your panel domain. Update, then re-send to anyone who took a config from
the bot since you switched it on.

## What else this release covers

The surface sweep added in 1.85.2 now also drives:

- the bot's own subscription builder, through the real builder rather than its
  source, so a builder that names an option and ignores it cannot pass
- the AmneziaWG `.conf` file an operator downloads and sends by hand, whose
  `Endpoint` line is the whole config

Removing either fix fails the suite.

## Upgrading

Update from the panel, or run the installer again.
