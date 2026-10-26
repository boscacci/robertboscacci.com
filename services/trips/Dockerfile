FROM caddy:2.11.7-builder@sha256:c2fc374fd352439d76e1777b28d97d9f6d9c1dd86116db9227460374d46097d5 AS builder
RUN xcaddy build v2.11.7 --with github.com/caddy-dns/route53@v1.6.2
FROM caddy:2.11.7-alpine@sha256:eb4d35b7452d1ab6171fbdbe8d9275b2301dad6dad92115d91e19fb9b24d510f
# Caddy is self-contained; remove unused curl and its vulnerable Brotli dependency.
RUN apk del --no-cache curl
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY services/trips/Caddyfile /etc/caddy/Caddyfile
USER 1000:1000
ENV AWS_PROFILE=trips-dns AWS_SHARED_CREDENTIALS_FILE=/run/secrets/aws XDG_DATA_HOME=/data XDG_CONFIG_HOME=/config
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 CMD wget -q -O /dev/null "http://127.0.0.1:${HEALTH_PORT}/healthz" || exit 1
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
