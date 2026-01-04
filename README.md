# Launchpad 🚀

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
│   └── client/                 # Vite + React frontend
├── packages/
│   └── shared/                 # Shared TypeScript types
├── infra/
│   ├── terraform/              # AWS infrastructure as code
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
- Docker Desktop (for Phase 1+)

### Installation

```bash
# Install dependencies
pnpm install

# Copy environment files
cp apps/api/.env.example apps/api/.env
cp apps/client/.env.example apps/client/.env

# Start development servers (both client and api)
pnpm dev
```

### Accessing the Application

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:3001
- **Health Check**: http://localhost:3001/api/v1/health

## 📦 Available Scripts

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

## 🏗️ Implementation Phases

### ✅ Phase 0 — Skeleton (CURRENT)
- Monorepo setup with Turborepo + pnpm
- Client (Vite + React) with health check UI
- API (NestJS) with `/api/v1/health` endpoint
- Shared types package for type safety
- Local development with hot reload

### 🔄 Phase 1 — Local Dev Experience
- Docker + docker-compose for services
- Environment variable management
- Setup scripts for quick start
- Pre-commit hooks (Husky + lint-staged)

### 🔄 Phase 2 — CI/CD Foundation
- GitHub Actions workflows (lint, test, build)
- Docker image builds
- AWS ECR integration

### 🔄 Phase 3 — Kubernetes Local
- Helm charts for all services
- Local K8s deployment (Kind/Minikube)
- Ingress configuration

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

| Layer | Technology |
|-------|-----------|
| Frontend | Vite, React 18, TypeScript |
| Backend | NestJS, Express, TypeScript |
| Monorepo | Turborepo, pnpm workspaces |
| Testing | Jest, Vitest, Supertest |
| Linting | ESLint, Prettier |
| Infrastructure | Terraform, Helm, Kubernetes |
| Cloud | AWS (EKS, ECR, VPC, ALB) |
| CI/CD | GitHub Actions, Argo CD |
| Observability | Prometheus, Grafana, CloudWatch |

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

**Status**: Phase 0 Complete ✅
**Next**: Phase 1 - Local Dev Experience
