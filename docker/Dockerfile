# Nova node in Docker.
#
# A Nova node is a full VPN appliance: it binds :443 (TCP+UDP) and manages xray,
# sing-box, and optional systemd services (Tor/Psiphon exits, tunnel backends,
# AmneziaWG, the DNS tunnel). So this image runs systemd as PID 1 and installs
# the node on first boot with the same tested installer as the native path.
#
# It must run with host networking and elevated privileges (see docker-compose.yml):
# the tunnel needs the host's ports and, for the AmneziaWG server, the host kernel
# module. All node data lives on named volumes, so `docker compose down` + `up`
# keeps your users and settings.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive container=docker

# systemd + the few tools the installer expects before it runs. Strip the units
# that make no sense in a container so systemd boots cleanly.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      systemd systemd-sysv curl ca-certificates iproute2 kmod sudo openssl \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /lib/systemd/system/multi-user.target.wants/* \
          /etc/systemd/system/*.wants/* \
          /lib/systemd/system/local-fs.target.wants/* \
          /lib/systemd/system/sockets.target.wants/*udev* \
          /lib/systemd/system/sockets.target.wants/*initctl* \
          /lib/systemd/system/systemd-update-utmp* 2>/dev/null || true

# The Docker build context is docker/. The production build stages the installer
# and release package into that context before the signed image is built. First
# boot executes only these image-bundled artifacts and never downloads an
# installer from a mutable branch. The release tarball is checksum-verified at
# build time and again immediately before installation.
COPY entry.sh /opt/nova/entry.sh
COPY logstream.sh /opt/nova/logstream.sh
COPY firstboot.sh /opt/nova/firstboot.sh
COPY nova-firstboot.service /etc/systemd/system/nova-firstboot.service
COPY nova-node.sh /opt/nova/nova-node.sh
COPY nova-node-agent.tar.gz /opt/nova/release/nova-node-agent.tar.gz
COPY nova-node-agent.tar.gz.sha256 /opt/nova/release/nova-node-agent.tar.gz.sha256

RUN cd /opt/nova/release \
 && sha256sum -c nova-node-agent.tar.gz.sha256 \
 && chmod 0555 /opt/nova/entry.sh /opt/nova/logstream.sh /opt/nova/firstboot.sh \
               /opt/nova/nova-node.sh \
 && chmod 0444 /opt/nova/release/nova-node-agent.tar.gz \
               /opt/nova/release/nova-node-agent.tar.gz.sha256 \
 && systemctl enable nova-firstboot.service

# systemd's graceful-shutdown signal.
STOPSIGNAL SIGRTMIN+3

# entry.sh corrects the cgroup mount when the runtime gave us a private cgroup
# namespace (Podman), starts the log relay that mirrors the install to the
# container's stdout, captures the container's NOVA_* env for the first-boot
# installer, and then hands off to systemd (PID 1), which starts the node.
ENTRYPOINT ["/opt/nova/entry.sh"]
CMD ["/lib/systemd/systemd"]
