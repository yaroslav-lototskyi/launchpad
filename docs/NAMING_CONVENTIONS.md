# Naming Conventions

**Project**: Launchpad
**Date**: 2026-01-04

## Overview

This document defines the naming conventions used across all Docker resources in the Launchpad project.

## Naming Pattern

All resources follow this pattern:

```
launchpad-{environment}-{service}
```

or for images:

```
launchpad/{service}:{environment}
```

## Docker Images

### Format

```
launchpad/{service}:{tag}
```

### Examples

**Development:**

- `launchpad/api:development`
- `launchpad/client:development`

**Production:**

- `launchpad/api:production`
- `launchpad/api:latest`
- `launchpad/client:production`
- `launchpad/client:latest`

### Tagging Strategy

1. **Environment tags**: `development`, `production`, `staging`
2. **Latest tag**: Points to production
3. **Version tags** (future): `v1.0.0`, `v1.0.1`
4. **Git SHA tags** (future): `sha-abc123`

## Container Names

### Format

```
launchpad-{environment}-{service}
```

### Examples

**Development:**

- `launchpad-development-api`
- `launchpad-development-client`

**Production:**

- `launchpad-production-api`
- `launchpad-production-client`

**Future (Staging):**

- `launchpad-staging-api`
- `launchpad-staging-client`

## Network Names

### Format

```
launchpad-{environment}
```

### Examples

- `launchpad-development`
- `launchpad-production`
- `launchpad-staging` (future)

## Volume Names (Future)

### Format

```
launchpad-{environment}-{service}-{purpose}
```

### Examples

- `launchpad-production-api-data`
- `launchpad-production-postgres-data`
- `launchpad-development-api-logs`

## Service Names (in docker-compose)

### Format

Simple service names without environment prefix (compose handles isolation)

### Examples

```yaml
services:
  api: # Not api-dev or api-prod
  client: # Not client-dev
  db: # Not database
```

**Why?** Docker Compose uses file location and project name for isolation.

## Environment-Specific Naming

### Development

- **Purpose**: Local development with hot reload
- **Pattern**: `launchpad-development-*`
- **Network**: `launchpad-development`
- **Image tags**: `:development`

### Production

- **Purpose**: Production deployment
- **Pattern**: `launchpad-production-*`
- **Network**: `launchpad-production`
- **Image tags**: `:production`, `:latest`

### Staging (Future)

- **Purpose**: Pre-production testing
- **Pattern**: `launchpad-staging-*`
- **Network**: `launchpad-staging`
- **Image tags**: `:staging`

## File Naming

### Dockerfiles

```
apps/{service}/deployment/{environment}/Dockerfile
```

Examples:

- `apps/api/deployment/development/Dockerfile`
- `apps/api/deployment/production/Dockerfile`
- `apps/client/deployment/production/Dockerfile`

### Docker Compose Files

```
deployment/{environment}/docker-compose.yml
```

Examples:

- `deployment/development/docker-compose.yml`
- `deployment/production/docker-compose.yml`
- `deployment/staging/docker-compose.yml` (future)

## Best Practices

### 1. Consistency

- Always use lowercase
- Use hyphens for separators in names
- Use slashes for image namespaces

### 2. Clarity

- Include environment in container/network names
- Use descriptive service names
- Tag images with environment

### 3. Avoid

- ❌ Short/cryptic names: `lp-dev-api`
- ❌ Inconsistent separators: `launchpad_dev_api`
- ❌ Missing environment: `launchpad-api`
- ❌ Unclear tags: `v1`, `test`, `new`

### 4. Use

- ✅ Full project name: `launchpad`
- ✅ Clear environment: `development`, `production`
- ✅ Descriptive service: `api`, `client`, `postgres`
- ✅ Semantic tags: `:development`, `:production`, `:latest`

## Migration from Old Names

### Old → New

**Images:**

- `launchpad-api:latest` → `launchpad/api:production` + `launchpad/api:latest`
- `launchpad-client:latest` → `launchpad/client:production` + `launchpad/client:latest`
- No tag → `launchpad/api:development`, `launchpad/client:development`

**Containers:**

- `launchpad-api-dev` → `launchpad-development-api`
- `launchpad-client-dev` → `launchpad-development-client`
- `launchpad-api` → `launchpad-production-api`
- `launchpad-client` → `launchpad-production-client`

**Networks:**

- `launchpad-network-dev` → `launchpad-development`
- `launchpad-network` → `launchpad-production`

## Examples

### Docker Commands

```bash
# Build development image
docker build -t launchpad/api:development -f apps/api/deployment/development/Dockerfile .

# Build production image with multiple tags
docker build -t launchpad/api:production -t launchpad/api:latest -f apps/api/deployment/production/Dockerfile .

# Run container
docker run --name launchpad-development-api launchpad/api:development

# List project images
docker images | grep launchpad/

# List project containers
docker ps -a | grep launchpad-

# List project networks
docker network ls | grep launchpad-
```

### Docker Compose

```yaml
services:
  api:
    image: launchpad/api:development
    container_name: launchpad-development-api
    networks:
      - launchpad-development

networks:
  launchpad-development:
    name: launchpad-development
```

## Future Additions

### Multi-Environment Tags

```
launchpad/api:v1.0.0-production
launchpad/api:v1.0.0-staging
launchpad/api:sha-abc123
```

### Registry Prefix (AWS ECR)

```
123456789.dkr.ecr.us-east-1.amazonaws.com/launchpad/api:production
123456789.dkr.ecr.us-east-1.amazonaws.com/launchpad/client:production
```

### Kubernetes Labels

```yaml
labels:
  app.kubernetes.io/name: launchpad
  app.kubernetes.io/component: api
  app.kubernetes.io/environment: production
```

## Verification

Run these commands to verify naming:

```bash
# Check all project resources
docker ps -a --filter name=launchpad
docker images | grep launchpad/
docker network ls | grep launchpad-

# Should see:
# - launchpad-{env}-{service} for containers
# - launchpad/{service}:{tag} for images
# - launchpad-{env} for networks
```

---

**Last Updated**: 2026-01-04
**Version**: 1.0
