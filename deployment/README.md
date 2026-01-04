# Deployment Configurations

This directory contains deployment configurations for different environments.

## Structure

```
deployment/
├── development/           # Development environment
│   └── docker-compose.yml # Docker Compose for local dev with hot reload
└── production/            # Production environment
    └── docker-compose.yml # Docker Compose for production deployment
```

## Development

The development environment includes:

- Hot reload for both API and Client
- Volume mounting for live code changes
- Development-optimized Docker images
- Fast rebuild times

**Start development environment:**

```bash
./scripts/docker-up.sh dev
```

## Production

The production environment includes:

- Multi-stage optimized Docker builds
- Minimal image sizes
- Security hardening (non-root users)
- Health checks
- Production-ready Nginx configuration

**Start production environment:**

```bash
./scripts/docker-up.sh prod
```

## Service-Specific Dockerfiles

Each service (API and Client) has its own deployment configurations:

### API

- `apps/api/deployment/development/Dockerfile` - Development build
- `apps/api/deployment/production/Dockerfile` - Production build

### Client

- `apps/client/deployment/development/Dockerfile` - Development build
- `apps/client/deployment/production/Dockerfile` - Production build with Nginx
- `apps/client/deployment/production/nginx.conf` - Nginx configuration

## Usage

See the main [README.md](../README.md) for detailed usage instructions.
