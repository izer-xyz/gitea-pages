FROM caddy:2.8.3-builder AS builder

RUN xcaddy build \
    --with github.com/caddyserver/cache-handler
    
FROM caddy:2.8.3

COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
