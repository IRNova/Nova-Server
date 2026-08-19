# Nova Server 1.70.1

Two things the installer said that were not true. Both were found by watching a
real update of a live node to 1.70.0 finish successfully and then describe
itself wrongly.

## It told a node with a domain that it had none

Re-running the install command on a node that already had a domain printed the
machine's bare IP as the panel address, and then:

```
No domain: this uses a self-signed certificate.
  - In the Nova app: Connect your VPS, turn ON "My server has no domain".
  - In a browser: accept the certificate warning once.
```

The node was correct throughout. Its stored settings said the domain and
`insecure: false`, and the panel was answering on that domain with a valid
certificate at the moment those lines were printed.

`HOST` and `INSECURE` start every run holding the first-install defaults, the
public IP and a self-signed certificate, and are only corrected when a
certificate is issued in that same run. A re-install issues no certificate, so
nothing ever corrected them and the summary could only ever describe a first
install. It reads the node's own stored settings now, and a certificate issued
in the current run still wins over them.

This is the same mistake as the readiness poll fixed in 1.69.1: believing the
run's own local variables over what the node actually persisted. The advice was
the harmful part, since switching a domain node's app into no-domain mode is
wrong, and the Telegram installer bot runs this command over ssh, so its users
saw the same banner.

Reporting a domain node that genuinely does serve a self-signed certificate is
unchanged: the fix only stops the summary claiming to know something it had not
looked up.

## It printed three errors during a healthy install

Updating over ssh emitted `/dev/tty: No such device or address` three times, once
per question the installer asks.

Asking used `[ -r /dev/tty ]` to decide whether anyone was there to answer. That
tests permissions on the device node, which succeed even when the process has no
controlling terminal; opening it then fails with ENXIO, and the shell prints
that line before the prompt can run. The check is now whether the device can be
opened, which is the thing actually being asked, and its failure is silent.

The record the installer reads its state from is also split positionally now
instead of by last field. The old form took whichever field happened to be last,
which is how a previous release came to read the hostname as the node mode, and
adding a field this release would have repeated it.

## Upgrading

Update and restart. Nothing about how the node runs changes. If a previous
re-install left you believing a domain node had no domain, it did not; run the
installer again and the summary will say so.
