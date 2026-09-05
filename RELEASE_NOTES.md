# Nova Server 1.81.0

Two health checks were telling you the wrong thing. Both are fixed.

## A working setup reported as broken

If an inbound was published on a domain behind a CDN, System Health called it a
hard failure and said your customers would receive a certificate for a different
name and refuse to connect.

They were connecting. A CDN terminates TLS itself and presents its own valid
certificate for the name the client asked for, so your server never needs one
for that name and never sees the handshake at all.

Nova already knew the domain was behind a CDN. It records that, and the check
sat three lines away from the code that could have told it. It simply did not
ask before reporting a failure.

If your health page has been showing this, nothing was wrong with your node and
nothing needs changing. The failure disappears after updating.

A domain Nova cannot classify is still reported, deliberately. Not knowing that
a name is behind a CDN is not the same as knowing it is not, and a direct name
with no certificate is a real problem worth being told about.

## A failing node that explained nothing

When a server in your fleet could not be reached, the panel printed the raw
error from the network library. One operator saw this:

    write EPROTO 405DADBF6D7D0000:error:0A000438:SSL routines:ssl3_read_bytes:
    tlsv1 alert internal error:.../rec_layer_s3.c:918:SSL alert number 80

That is accurate and useless. It does not say whether the panel broke, the node
is off, a certificate expired, or a firewall is in the way, and the answer took
a manual TLS handshake from a third machine to find.

The panel now says which it is, in a sentence: nothing is listening on that
address, the certificate has expired, it cannot be verified, it did not answer
in time, the address does not resolve, the node closed the connection and is
probably still restarting after an update, or it accepted the connection and
then refused to complete the secure handshake.

The technical detail still appears after the explanation, because that is what
you paste into a report when the sentence is not enough.

## Upgrading

Panel: Settings, then Update. Or run the installer again over SSH:

    bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
