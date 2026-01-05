# Launchpad 🚀

[![PR Checks](https://github.com/OWNER/launchpad/actions/workflows/pr.yml/badge.svg)](https://github.com/OWNER/launchpad/actions/workflows/pr.yml)
[![Main CI/CD](https://github.com/OWNER/launchpad/actions/workflows/main.yml/badge.svg)](https://github.com/OWNER/launchpad/actions/workflows/main.yml)
[![Release](https://github.com/OWNER/launchpad/actions/workflows/release.yml/badge.svg)](https://github.com/OWNER/launchpad/actions/workflows/release.yml)

Enterprise-grade monorepo template for modern cloud deployments with AWS, Kubernetes (EKS), and GitOps.

## 🎯 Overview

This project demonstrates a production-ready setup for deploying full-stack applications to cloud infrastructure:

- **Monorepo**: Turborepo + pnpm
- **Frontend**: Vite + React + TypeScript
- **Backend**: NestJS + TypeScript
- **Shared Types**: Type-safe contracts between frontend/backend
- **Infrastructure**: Terraform (AWS EKS) + Helm Charts + Argo CD
- **CI/CD**: GitHub Actions + GitOps workflows

## 📁 Project Structure

```
launchpad/
├── apps/
│   ├── api/                    # NestJS backend API
│   │   └── deployment/         # Docker configs (dev/prod)
│   └── client/                 # Vite + React frontend
│       └── deployment/         # Docker configs + Nginx
├── packages/
│   └── shared/                 # Shared TypeScript types
├── deployment/                 # Environment-specific configs
│   ├── development/            # Dev docker-compose
│   └── production/             # Prod docker-compose
├── k8s/                      # Infrastructure as code (Phase 3+)
│   ├── terraform/              # AWS infrastructure
│   ├── helm/                   # Kubernetes Helm charts
│   └── argocd/                 # Argo CD applications
├── .github/
│   └── workflows/              # CI/CD pipelines
├── scripts/                    # Helper automation scripts
└── docs/                       # Documentation
```

## 🚀 Quick Start

### Prerequisites

- Node.js >= 20.0.0
- pnpm >= 8.0.0
- Docker Desktop (recommended for Phase 1+)

### Local Development (without Docker)

```bash
# Install dependencies
pnpm install

# Copy environment files
cp apps/api/.env.example apps/api/.env
cp apps/client/.env.example apps/client/.env

# Start development servers (both client and api)
pnpm dev
```

### Docker Development (recommended)

```bash
# Quick setup script
./k8s/scripts/setup-local.sh

# Start in development mode (with hot reload)
./k8s/scripts/docker-up.sh dev

# Or start in production mode
./k8s/scripts/docker-up.sh prod
```

### Accessing the Application

**Local Development:**

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:3001
- **Health Check**: http://localhost:3001/api/v1/health

**Docker Production:**

- **Frontend**: http://localhost
- **Backend API**: http://localhost:3001
- **Health Check**: http://localhost:3001/api/v1/health

## 📦 Available Scripts

### NPM Scripts

```bash
# Development
pnpm dev          # Start all apps in parallel
pnpm build        # Build all apps
pnpm test         # Run tests
pnpm lint         # Lint code
pnpm type-check   # TypeScript type checking
pnpm format       # Format code with Prettier
pnpm clean        # Clean all build artifacts
```

### Docker Scripts

```bash
# Build Docker images
./k8s/scripts/docker-build.sh

# Start containers (dev mode with hot reload)
./k8s/scripts/docker-up.sh dev

# Start containers (production mode)
./k8s/scripts/docker-up.sh prod

# Stop containers
./k8s/scripts/docker-down.sh [dev|prod]

# View logs
./k8s/scripts/docker-logs.sh [api|client] [dev|prod]

# Clean Docker resources
./k8s/scripts/docker-clean.sh

# Setup local environment
./k8s/scripts/setup-local.sh
```

## 🏗️ Implementation Phases

### ✅ Phase 0 — Skeleton (COMPLETE)

- Monorepo setup with Turborepo + pnpm
- Client (Vite + React) with health check UI
- API (NestJS) with `/api/v1/health` endpoint
- Shared types package for type safety
- Local development with hot reload

### ✅ Phase 1 — Local Dev Experience (COMPLETE)

- Docker + docker-compose for services
- Multi-stage Dockerfiles for optimized builds
- Development and production compose files
- Environment variable management
- Setup scripts for quick start
- Pre-commit hooks (Husky + lint-staged)
- Docker helper scripts

### ✅ Phase 2 — CI/CD Foundation (COMPLETE)

- GitHub Actions workflows (PR checks, main branch CI/CD, releases)
- Docker image builds and push to GHCR
- Security scanning with Trivy
- Automated changelog generation
- Multi-tag strategy for releases

### ✅ Phase 3 — Kubernetes Local (COMPLETE)

- Helm charts for API and Client services
- Environment-specific values (development, staging, production)
- Kubernetes deployments with resource limits and health checks
- Service and Ingress configuration
- Helper scripts for Kind cluster setup
- Horizontal Pod Autoscaling support

### 🔄 Phase 4 — AWS Infrastructure

- Terraform modules for EKS, VPC, networking
- IAM roles and policies
- ECR repositories

### 🔄 Phase 5 — GitOps

- Argo CD setup
- Automated sync from Git
- Environment-specific deployments

### 🔄 Phase 6 — Observability

- Structured logging (JSON)
- Prometheus metrics
- Grafana dashboards
- Alerts

### 🔄 Phase 7 — Production Hardening

- Security scanning (Trivy)
- Network policies
- Secrets management
- Load testing

## 🏛️ Architecture

### Health Check Flow

```
Client (React)
    ↓
  HTTP GET /api/v1/health
    ↓
NestJS API (HealthController)
    ↓
HealthService
    ↓
Returns: { ok, service, time, version, uptime }
    ↓
Typed with @repo/shared
```

## 🔧 Tech Stack

| Layer          | Technology                      |
| -------------- | ------------------------------- |
| Frontend       | Vite, React 18, TypeScript      |
| Backend        | NestJS, Express, TypeScript     |
| Monorepo       | Turborepo, pnpm workspaces      |
| Testing        | Jest, Vitest, Supertest         |
| Linting        | ESLint, Prettier                |
| Infrastructure | Terraform, Helm, Kubernetes     |
| Cloud          | AWS (EKS, ECR, VPC, ALB)        |
| CI/CD          | GitHub Actions, Argo CD         |
| Observability  | Prometheus, Grafana, CloudWatch |

## 🔐 Environment Variables

### Backend (`apps/api/.env`)

```bash
PORT=3001
NODE_ENV=development
CORS_ORIGIN=http://localhost:5173
APP_VERSION=0.1.0
```

### Frontend (`apps/client/.env`)

```bash
VITE_API_BASE_URL=http://localhost:3001
```

## 📚 Documentation

- [Initial Plan](./docs/initial_plan.md) - Comprehensive implementation plan
- [Phase 1 Complete](./docs/PHASE_1_COMPLETE.md) - Local Dev Experience summary
- [Phase 2 Complete](./docs/PHASE_2_COMPLETE.md) - CI/CD Foundation summary
- [Phase 3 Complete](./docs/PHASE_3_COMPLETE.md) - Kubernetes Local deployment
- [Helm Chart README](./k8s/helm/launchpad/README.md) - Helm chart documentation
- [Architecture](./docs/architecture.md) - System architecture (Phase 1+)
- [Runbooks](./docs/runbooks/) - Production runbooks (Phase 6+)

## 🤝 Contributing

1. Create a feature branch
2. Make changes
3. Run `pnpm lint` and `pnpm type-check`
4. Run `pnpm test`
5. Submit a pull request

## 📝 License

ISC

## 🎓 Use Cases

- Learning DevOps and cloud deployment
- Portfolio/interview projects
- Microservices template
- SaaS product foundation
- Production deployment reference

---

**Status**: Phase 3 Complete ✅
**Next**: Phase 4 - AWS Infrastructure
