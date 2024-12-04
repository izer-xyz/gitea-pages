# gitea-pages

Rudimentary Github Pages like solution for Gitea. It is a reverse proxy that rewrites URLs, forwards the request to Gitea, and fixes the returned Content-Type: 

 * `https://sub.example.domain` => `http://git:3000/sub/sub.example.domain/raw/branch/pages/index.html`
 * `Content-Type: text/html` <= `Content-Type: text/plain` 


## Configuration 

Basic config using `docker-compose.yml`: 
```yaml

services:

  proxz: # use traefik as a reverse proxy for all containers 
    image: traefik:3
    # ....
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - TRAEFIK_ENTRYPOINTS_http_ADDRESS=:80
      - TRAEFIK_ENTRYPOINTS_http_HTTP_REDIRECTIONS_ENTRYPOINT_TO=https
      - TRAEFIK_ENTRYPOINTS_https_ADDRESS=:443
      - TRAEFIK_PROVIDERS_DOCKER_EXPOSEDBYDEFAULT=false
      - TRAEFIK_PROVIDERS_DOCKER_DEFAULTRULE=Host(`{{ `{{ index .Labels "com.docker.swarm.service.name" | splitList "_" | last }}` }}.example.domain`)

  git: # Gitea instance 
    image: gitea/gitea:latest-rootless
    labels:
      traefik.enable: 'true'
      traefik.http.services.git.loadbalancer.server.port: 3000 # Rootless container is using port 3000
      traefik.http.routers.git.entrypoints: 'https'

  raw: # Pages reverse proxy
    image: ghcr.io/izer-xyz/gitea-pages:latest
    environment:
      - GITEA_HOST=git:3000
    labels:
      traefik.enable: 'true'
      # Expose the default raw.example.domain subdomain to proxy to any repo with the right Content-Type 
      # e.g.
      #   http://raw.example.domain/sub/sub.example.domain/raw/branch/main/app.js => http://git:3000/sub/sub.example.domain/raw/branch/main/app.js
      traefik.http.routers.raw.entrypoints: 'https'
      # add another subdomain sub
      #   https://sub.example.domain => http://git:3000/sub/sub.example.domain/raw/branch/pages/index.html
      traefik.http.routers.sub.rule: Host(`sub.example.domain`)
      traefik.http.routers.sub.entrypoints: 'https'
```

## Page Resolution

Page resolution (details: [Caddyfile#L99](https://github.com/izer-xyz/gitea-pages/blob/ca3eb082ee25cf7bb2b9385112342221fb5ac3e0/Caddyfile#L99)) for a request like `https://sub.example.domain/app/` - the first HTTP 200 response will be returned:
1. http:// git:3000 / **sub** / **sub.example.domain** /raw/branch/ **pages** / **app/**:
   * Owner: `sub`
   * Repository: `sub.example.domain`
   * Branch: `pages`
   * File: `/app/`
2. http:// git:3000 / **sub** / **sub.example.domain** /raw/branch/ **pages** / **app** /index.html:
   * Owner: `sub`
   * Repository: `sub.example.domain`
   * Branch: `pages`
   * File: `/app/index.html`
3. http:// git:3000 / **sub** / **sub.example.domain** /raw/ **app/**:
   * Owner: `sub`
   * Repository: `sub.example.domain`
   * Branch: default branch `main` or `master`
   * File: `/app/`
4. http:// git:3000 / **sub** / **sub.example.domain** /raw/ **app** /index.html:
   * Owner: `sub`
   * Repository: `sub.example.domain`
   * Branch: default branch `main` or `master`
   * File: `/app/index.html`

## Customise 

Download the [Caddyfile](Caddyfile) and make any changes you want (e.g. different URL pattern, or don't want to use Traefik for TLS termination). If you remove the cache (first few lines) directive it should work with the offical caddy image / binaries.  
