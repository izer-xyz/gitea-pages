FROM caddy:2.9.1-builder AS builder

RUN xcaddy build \
    --with github.com/caddyserver/cache-handler
    
FROM caddy:2.9.1

COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
