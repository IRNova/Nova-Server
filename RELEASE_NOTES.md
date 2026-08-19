# Nova Server 1.69.1

Updating a node reported a failure that had not happened.

## "The agent did not respond in time", on a node that was fine

Every update on a node with a domain configured ended with that line, in red,
after the agent had already restarted and was serving customers. Three updates
in a row said it on a node whose panel answered normally the whole time.

The cause is a decoy. A Nova node answers a request whose address it does not
recognise with an ordinary "welcome" page, so a scanner cannot tell there is a
panel here. The installer asked the agent for its status over the machine's own
loopback address, which is not a name the agent recognises, so it received the
decoy page and kept looking for a word the decoy does not contain. Forty
attempts later it gave up and said the agent had not responded, while the agent
had been answering correctly the entire time.

It now asks under the hostname the panel actually answers on. Nothing about the
update itself changed, only whether it tells you the truth when it finishes.

## Upgrading

Update and restart, and this time the last line should be the summary rather
than an error. If you saw that message on an earlier update, nothing was wrong
and nothing needs redoing.
