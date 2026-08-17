# Nova Server 1.63.1

One fix, and it is worth updating for: an inbound you create today may be
serving nobody.

## New inbounds served nobody, silently

Create an inbound, hand out its link, and every connection opens and then hangs.
Not refused, not an error, just nothing back. It looked like a broken server, a
bad certificate, or a client problem, and it was none of those.

Which customers an inbound serves is decided per customer, and a customer's own
list of inbounds is checked before the inbound's own "serve everyone" setting.
Nova is built so that a customer with no list is served by everything, including
inbounds that do not exist yet, and that is what almost every customer should
have.

The panel was not saving it that way. When you left every inbound ticked, which
is the default, it saved a list naming each one instead of saving no list at
all. That froze the customer at the moment you last saved them. Any inbound
created afterwards was in nobody's list, so it started with an empty client
list, and an inbound with no clients rejects every handshake on purpose, which
is what produced the hang.

Anyone who added an inbound after their customers existed hit this. The only way
out was to open and re-save every customer, one at a time, and nothing said so.

**Fixed in three places.** The user form and the plan template now save "no
list" when everything is selected. And on the first start after this update, any
customer whose stored list already covers every inbound has it removed, so
existing nodes repair themselves.

A customer you deliberately restricted to some inbounds keeps that restriction.
That is a choice, and it still means they will not be on inbounds you add later,
which is what choosing a subset has always meant.

## Country exits would not start

Every per-country Tor exit showed as Stopped, on every country at once, with
"nothing is listening on this exit's local port". Tor itself was installed and
running fine.

The service Nova writes for each country named /usr/bin/tor, and current Debian
and Ubuntu ship the binary at /usr/sbin/tor. So each one failed the instant it
started and sat retrying. The panel could only report the symptom, which reads
like a problem with that country rather than a wrong path, and the natural
conclusion (that country has no exit relays) was wrong.

Nova now resolves tor when the service starts rather than naming a directory, so
a package update that moves it cannot break the exits either. If tor is genuinely
missing you will now see `env: 'tor': No such file or directory` in the journal
instead of a bare failure.

## Upgrading

Update and restart. The customer repair runs once, by itself, and the activity
log says how many customers it applied to. Country exits are rewritten and
restarted on the same boot.

If you created inbounds recently and some customers could never connect through
them, they should work now without any change on the customer's side.
