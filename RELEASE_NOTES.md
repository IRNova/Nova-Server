# Nova Server 1.85.1

A fix for 1.85.0, shipped the same day.

## "Never in configurations" only worked on half the outputs

1.85.0 added the setting that keeps your main domain out of client
configurations, and wired it into the ordinary subscription only.

Nova has two subscription builders. The raw one produces the ordinary
subscription; a second, structured one produces what the Nova app, Clash,
sing-box, Hiddify and Karing receive. Only the first honoured the new setting.

So an operator could turn it on, watch their panel domain disappear from the
normal subscription, confirm it worked, and still be handing that domain to
every customer using the Nova app. That is worse than not having the setting,
because the panel reported success.

Both builders honour it now, with the same strict rule: a configuration no other
domain can carry is left out rather than quietly kept on the panel domain.

## If you turned this on in 1.85.0

Update and check a Nova app subscription. Your panel domain was still travelling
in it until now.

## Upgrading

Update from the panel, or run the installer again. Nothing else changes.
