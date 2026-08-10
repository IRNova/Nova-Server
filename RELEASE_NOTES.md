# Nova Server v1.51.0
## Four things operators asked for, two of them on the page your customers open

### The Telegram proxy button now opens Telegram

A customer with their own Telegram proxy has a button for it on their
subscription page. On a phone it was landing them in a web browser, looking at a
page about a proxy they could not add.

There are two forms of a Telegram proxy link. `tg://` is the one both the
Telegram apps and Telegram Desktop claim as their own, so it hands the proxy
straight to the app. `https://t.me/proxy` is a web page, and a phone browser
that has not been told Telegram owns those links simply shows it. The button was
using the second one.

**Open in Telegram** is now the first form, so it goes to the app wherever one
is installed. **Open through t.me** sits beside it for a device with no Telegram
app at all, and the copy button is unchanged. If a customer tells you the button
took them to a website, they pressed the second one, or that device has no
Telegram installed.

### Your customers can now get the JSON configuration themselves

1.48.0 added an **Xray JSON** subscription for the people using v2rayN and
v2rayNG, who import a "custom config" rather than a link. It went on the
Distribution page, which is the panel, so you could find it and your customer
could not. That is the wrong way round for this one in particular: the
client-side fragment operators went looking for only exists in that format,
because a `vless://` link has nowhere to put one.

It is on the customer's own page now, under **JSON configuration**, with copy
naming the two apps it is for. It appears only for a customer who actually holds
something Xray can dial, so a customer whose access is Hysteria2 is not handed a
link that would serve them an empty list.

### Bulk days go both ways

The bulk toolbar could add days to a selection and never take any off. If you
had given a batch a month too much, the only route back was one customer at a
time. Worse, sending it a reduction reported success and changed nothing.

**Days** now asks which direction, exactly as **Change data** does, and shows
you a summary before it writes anything:

- **Adding is unchanged.** For anybody already expired it starts from today, so
  "add 30" still means thirty days of service.
- **Taking days off stops one day from now.** Cutting a batch of customers off
  in the middle of a month is what **Disable** is for, and Disable can be undone
  where an overwritten date cannot. Everyone the floor stops is counted for you.
- **A customer who never expires is left alone** on the way down, because
  subtracting from "never" would have to invent a date you never typed. So is a
  customer whose date has already gone: they are not revived and not pushed
  further back. Both are counted separately in the preview.
- **A customer who has not connected yet is left alone in both directions.** An
  account created from a plan carries the plan's length and gets no date at all
  until its first byte, so one you have sold and not handed out looks exactly
  like one that never expires. Writing a date to it would start the month before
  the customer had used a minute of it, replace the plan's own length with
  whatever you typed, and switch off the count-from-first-use rule permanently.
  They get their own line in the preview.
- **Adding a date to a customer who genuinely never expires is now reported**,
  because it quietly turns an unlimited customer into a limited one. It still
  happens, it just no longer happens silently.

Taking days off is free for a reseller. What adding them costs follows the
renewal pricing on the Settings page, as every other reseller renewal does.

### Enable and disable moved into the access window too

They were one press each in the toolbar with no summary, so you could see
exactly what taking a protocol away would do and nothing at all about switching
fifty customers off, including how many of them were already off.

**Give or take away access** now starts with **the account itself**, above the
protocols. Taking it away switches the customer off, giving it back switches
them on, and the preview says how many actually change. It also says how many
stay cut off anyway because their expiry date has already passed, which the
switch does not undo. The one-press buttons in the toolbar are still there.

## Upgrading

Nothing changes on its own, and no customer's configuration, subscription or
allowance is altered by taking this release. Two changes are worth knowing about
before you use the buttons:

- A bulk **Days** request with no number, or an unreadable one, is now refused.
  It used to be treated as zero days, and zero days was not harmless: for a
  customer with no expiry date it set one to the current moment, which expired
  them on the spot.
- Bulk **enable**, **disable** and **days** now report only the customers that
  actually changed. A selection where nothing was going to happen used to report
  every row as affected. If you drive `POST /admin/users.json` from a script and
  check that the affected count equals the number of ids you sent, it will now
  be lower whenever some of them were already in that state.
