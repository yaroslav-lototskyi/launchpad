# Client Deployment

Deployment configurations for the Launchpad Client (Vite + React).

## Structure

```
deployment/
├── development/
│   └── Dockerfile           # Dev build with HMR
└── production/
    ├── Dockerfile           # Production build with Nginx
    └── nginx.conf           # Nginx configuration
```

## Development Dockerfile

**Features:**

- Based on Node 20 Alpine
- pnpm package manager
- Vite dev server with HMR
- Volume mounting for instant updates
- Host network mode for browser access

**Build:**

```bash
docker build -f apps/client/deployment/development/Dockerfile -t launchpad-client:dev .
```

## Production Dockerfile

**Features:**

- Multi-stage build (base, deps, build, runtime)
- Static files served by Nginx
- Minimal final image (~50MB)
- Gzip compression
- Security headers
- SPA routing support

**Stages:**

1. **Base** - Node 20 Alpine + pnpm
2. **Deps** - Install dependencies
3. **Build** - Build static assets with Vite
4. **Runtime** - Nginx Alpine serving static files

**Build:**

```bash
docker build -f apps/client/deployment/production/Dockerfile -t launchpad-client:latest .
```

## Nginx Configuration

The production image uses a custom Nginx configuration (`nginx.conf`) that provides:

- **SPA Routing** - All routes serve `index.html`
- **Security Headers**:
  - X-Frame-Options: SAMEORIGIN
  - X-Content-Type-Options: nosniff
  - X-XSS-Protection: 1; mode=block
- **Gzip Compression** - For all text-based assets
- **Cache Control** - 1 year for static assets
- **Health Endpoint** - `/health` for container health checks

## Environment Variables

Build-time variables (passed during docker build):

- `VITE_API_BASE_URL` - Backend API URL

See `apps/client/.env.example` for all available variables.

## Health Check

The production image includes a health check on the `/health` endpoint.

## Security

- Runs as non-root user (nginx:1001)
- Security headers configured
- Static files only (no runtime code)
- Minimal Nginx image
