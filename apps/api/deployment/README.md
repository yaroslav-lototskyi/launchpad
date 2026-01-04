# API Deployment

Deployment configurations for the Launchpad API (NestJS).

## Structure

```
deployment/
├── development/
│   └── Dockerfile        # Dev build with hot reload
└── production/
    └── Dockerfile        # Production multi-stage build
```

## Development Dockerfile

**Features:**

- Based on Node 20 Alpine
- pnpm package manager
- All dependencies installed
- Volume mounting support for hot reload
- Fast iteration cycle

**Build:**

```bash
docker build -f apps/api/deployment/development/Dockerfile -t launchpad-api:dev .
```

## Production Dockerfile

**Features:**

- Multi-stage build (base, deps, build, runtime)
- Minimal final image (~200MB)
- Non-root user for security
- Health check included
- Production dependencies only

**Stages:**

1. **Base** - Node 20 Alpine + pnpm
2. **Deps** - Install all dependencies
3. **Build** - Compile TypeScript
4. **Runtime** - Minimal production image

**Build:**

```bash
docker build -f apps/api/deployment/production/Dockerfile -t launchpad-api:latest .
```

## Environment Variables

See `apps/api/.env.example` for available environment variables.

## Health Check

The production image includes a health check that calls `/api/v1/health` endpoint.

## Security

- Runs as non-root user (nodejs:1001)
- Minimal dependencies
- No dev dependencies in production
- Clean build artifacts
