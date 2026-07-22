# Nova Server, container / PaaS image (runflare, or any Docker HTTP-ingress host).
#
# WebSocket-only proxy: the platform edge terminates TLS and forwards the WS
# stream to this container's port, where xray's front listens plaintext, routes
# by WS path to VLESS/VMess/Trojan, and falls back to the admin panel. No UDP
# protocols here (Hysteria2, WireGuard) and no systemd. For a full node with UDP,
# use the VPS installer (nova-node.sh). See DEPLOY.md.
#
# The image ships Nova's OBFUSCATED release: it pulls the published tarball from
# IRNova/Nova-Server rather than any source. Node 24 has built-in sqlite; Nova
# has zero runtime npm dependencies, so there is no install step.

FROM node:24-slim

RUN apt-get update && apt-get install -y --no-install-recommends curl unzip ca-certificates \
  && arch="$(dpkg --print-architecture)" \
  && case "$arch" in arm64) xarch=arm64-v8a ;; *) xarch=64 ;; esac \
  && curl -fsSL -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${xarch}.zip" \
  && unzip -o /tmp/xray.zip xray -d /usr/local/bin && chmod +x /usr/local/bin/xray \
  && mkdir -p /usr/local/share/xray \
  && curl -fsSL -o /usr/local/share/xray/geoip.dat  "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat" \
  && curl -fsSL -o /usr/local/share/xray/geosite.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat" \
  && mkdir -p /app \
  && curl -fsSL -o /tmp/nova.tgz "https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node-agent.tar.gz" \
  && tar xzf /tmp/nova.tgz -C /app \
  && apt-get purge -y --auto-remove unzip \
  && rm -rf /tmp/xray.zip /tmp/nova.tgz /var/lib/apt/lists/*

WORKDIR /app

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray \
    NOVA_PAAS=1 \
    NOVA_FRONT_TLS=none \
    NOVA_XRAY_BIN=/usr/local/bin/xray \
    NOVA_XRAY_CONFIG=/data/xray.json \
    NOVA_DB=/data/nova.db \
    NOVA_ACCESS_LOG=/data/access.log \
    NOVA_PORT=8088 \
    NOVA_XRAY_API=127.0.0.1:10085 \
    PORT=3000 \
    NOVA_FRONT_PORT=3000

RUN mkdir -p /data
VOLUME ["/data"]
EXPOSE 3000

CMD ["node", "bin/nova-paas.mjs"]
