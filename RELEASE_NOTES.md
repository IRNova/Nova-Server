# Nova Server v1.42.3

Two things reported from installs this week.

## A 512 MB server can be installed on now

If you tried Nova on a 512 MB VPS, the install failed partway through with an
error from the package manager that said nothing about memory. Installing and
running Node.js is the peak, and 512 MB with no swap does not reach it.

Nova now checks before it gets there. On a server with less than 1 GB of RAM and
no swap worth the name, it adds a 1 GB swap file first, and tells you it did.
The install then completes, and the swap keeps helping afterwards because the
panel, Xray and sing-box all stay resident.

It is deliberately careful about this:

- It never touches swap you already have, and never replaces an existing
  `/swapfile`.
- If your provider does not allow swap files, it says so and carries on rather
  than stopping the install.
- Removing Nova removes only a swap file Nova created. Your own is left alone.

Thank you to the operator who worked this out and tested it for an hour before
telling us.

## "My panel shows 404"

This one is not a fault, and our own instructions were sending you the wrong way.

Nova installs your panel behind a **secret path**, so the address looks like
`https://your-server/a8f3k2/`. Anything arriving without that path gets a plain
"404 Not Found" **on purpose**, so that someone scanning your server cannot tell
there is a panel on it at all. A 404 means the disguise is working, not that the
install failed.

If you have lost the address, sign in to your server and run:

    nova-access

It prints the panel URL and changes nothing else. We previously told people to
run `nova-passwd`, which **resets your admin password** as a side effect of
showing the URL, and which prints nothing at all if you run it with no
arguments. That was our mistake. The installer and the in-panel guide now say
`nova-access`, in English, Persian and Russian.
