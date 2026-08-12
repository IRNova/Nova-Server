# Nova Server 1.57.2

## Adding a domain looked like it required a Cloudflare account

An operator reported that the panel told him to link his whole Cloudflare
account when all he wanted was to point one subdomain at his node and get a
certificate. It never did require that. The panel just made it look that way,
in three separate ways at once:

- **The method flipped by itself.** If a Cloudflare token was already stored,
  opening the Domains page silently moved the selection from Let's Encrypt to
  Cloudflare, in the Primary domain card and in Additional domains. An operator
  who never chose Cloudflare found it chosen. It no longer flips. Pasting a
  token by hand still switches the method, because that answers something you
  just did.
- **Two hints contradicted each other.** The Let's Encrypt hint said "No port 80
  setup required" while the help text a few lines below said to make TCP port 80
  reachable. Both were half true, and the half that was wrong is the one an
  operator read before hitting a failure that told them to open port 80.
- **The Cloudflare card sits inside the domain form** and read as step one. It
  now carries an Optional badge and says plainly that you do not need it.

## What the panel tells you now

The Let's Encrypt method carries the three things that actually have to be true,
as numbered steps, with the server's own address filled in:

1. An A record for that exact name pointing at this server. One subdomain is
   enough, and its DNS does not have to be on Cloudflare.
2. Grey cloud, if the name is on Cloudflare DNS. With the orange cloud on,
   Cloudflare answers the challenge instead of your server and issuance fails.
3. Inbound TCP port 80 reachable. Nova opens the server's own firewall and steps
   Xray aside by itself, but a firewall or security group at your provider has
   to allow it too.

Additional domains gained a hint under the certificate method, which had none,
so each of the four methods now says what it needs. The Cloudflare token hint
says to restrict the token to one zone under Zone Resources: Nova has never
needed the rest of an account, and the panel now says so where the token is
pasted. The built-in manual's Network and IPs section was rewritten to match, in
all three languages.

## A Persian layout fix

In the Farsi panel, "Zone > DNS > Edit" in the token hint rendered with its
arrows reversed. Latin runs are bidi-isolated so they survive right-to-left
text, but the isolation treats a space-separated word as the unit and leaves
`>` outside it, where it takes the paragraph's direction. Those two runs are now
isolated whole.

## Upgrading

No action required. Nothing here changes traffic, certificates already issued,
or how a certificate is requested. The wording, the guidance and one default
selection changed.
