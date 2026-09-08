# Nova Server 1.84.0

A server with more than one public IP can now use all of them, and a failed
certificate says what actually went wrong.

## More than one IP on this server

A VPS with a reserved or floating IP answers on more than one address. Nova
published whichever one the operating system happened to list first, so there
was no way to hand a customer an AmneziaWG, mieru or Telegram proxy config on
the other address. Those three are the ones that matter here: none of them can
go through a CDN, so each carries a bare IP.

The Network page has a new **Server IP addresses** card. It lists every address
this node answers on and lets you mark the one it should lead with.

## The addresses Nova cannot find

Detection alone was never going to be enough. A DigitalOcean reserved IP reaches
your droplet through its anchor address and never appears on a network
interface, so nothing running on the server can see it, no matter how hard it
looks.

So the card takes typed-in addresses too. Each row says which kind it is:

- **Found on this server** came from the network interfaces. One of these that
  does not work is a firewall question.
- **Added by you** is one you entered. One of these that does not work is either
  a provider routing it invisibly, which is normal, or a typo.

An address you add and later give back to your provider stops being published
by itself. It is checked against the node's real addresses when a config is
built, so a released IP does not linger in new configs.

## A certificate failure that says something

Two failures used to arrive as "check DNS and port 80", which is a catch-all and
was sometimes advice about the only two things that were definitely fine:

- **Let's Encrypt is rate limiting the domain.** You only reach this by
  retrying, so by the time you see it you have usually checked DNS and port 80
  twice, and retrying again is the one thing that makes it worse. It now says
  so, tells you the wait, and points at Automatic Cloudflare, which validates
  over DNS and is not affected.
- **This server cannot reach Let's Encrypt.** The opposite direction from every
  other check, and it needs the opposite fix. It shows up on nodes whose
  outbound traffic runs through a WARP or VPN tunnel.

Anything still unrecognised now carries one line of what Let's Encrypt actually
reported, so you are not left guessing. That line is filtered: nothing
mentioning a credential, key or token is ever shown, because these messages get
pasted into support chats.

## Upgrading

Update from the panel, or run the installer again. Nothing here changes an
existing configuration, and no customer needs a new link. If you have only one
IP, nothing about your node changes.
