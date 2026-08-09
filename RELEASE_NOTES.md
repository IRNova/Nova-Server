# Nova Server v1.50.0
## The container install shows you what it is doing, and works on Podman

If you installed a node with Docker, you saw the container start and then
nothing. `docker compose logs -f nova-node`, the command the setup script tells
you to run, printed no output at all: no progress, no panel URL, no admin
password. The container was not broken. It installed the node correctly every
time. But the only copy of the generated password and the secret panel path went
somewhere you could not see, so a finished install and a dead container looked
exactly alike, and there was no way in from either.

The cause is that the container runs systemd, and systemd keeps its services'
output in its own journal, inside the container, where `docker logs` never
looks. The image now starts a small relay before systemd takes over, and the
first boot writes through it. So the install streams live where you were always
told to look:

```bash
docker compose logs -f nova-node
```

The setup script no longer walks away either. It used to say "the container is
starting" and hand you back your prompt. It now follows the first boot to the
end and tells you whether it worked, with your panel URL and password in front
of you. If the first boot produces nothing at all, it says so, with the
diagnostics, instead of leaving you to guess.

Three smaller things came with it:

- **Podman works.** It is picked up automatically when it is the runtime you
  have, and `NOVA_CONTAINER_RUNTIME=podman` forces it on a host with both. The
  reason it did not work before is that `podman-compose` quietly drops one line
  of the compose file, which left systemd inside the container unable to start
  and, once again, unable to say so. The image now sorts that out for itself.
- **The setup script refuses what cannot work, instead of half doing it.**
  Docker Desktop on Mac or Windows, and rootless Podman, cannot give a container
  the host's port 443, so a node started there would look healthy and serve
  nobody. Both are now refused with the reason.
- **A blocked or rate-limited GitHub API no longer kills the install.** Fetching
  one of the optional tunnel backends could fail in a way that ended the whole
  install on the spot, without printing a word, which in a container turned into
  a first boot that restarted forever. A backend that cannot be downloaded is
  now skipped with a warning, which is what it was always meant to do.

One honest limit, now written down in the manual: **a container node cannot run
the AmneziaWG server**, because that needs a kernel module and a container
cannot build one for the host. Everything else works, including Reality,
Hysteria2, TUIC, the Telegram MTProto proxy, mieru and the tunnel backends. And
because a container node takes the host's real ports, there can only be one node
per host: a second container, or a native install next to one, fights over port
443 and neither comes up.


## Upgrading

Nothing changes on its own. The two new bulk operations are buttons you have to
press, and the health-check change only ever removes a report this panel could
not stand behind. No customer's configuration, subscription or allowance is
altered by taking this release.

If you run a node in a container, rebuild it to get the log fix: re-run the
setup command, or `docker compose up -d --build` in the directory it created.
Your users, settings and certificate live on volumes and are not touched. A
rebuilt container prints its panel URL again, and the admin password line will
say it is unchanged from your first install, because it is.
