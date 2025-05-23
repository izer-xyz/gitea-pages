FROM caddy:2.10.0-builder AS builder

RUN xcaddy build \
    --with github.com/caddyserver/cache-handler
    
FROM caddy:2.10.0

COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
