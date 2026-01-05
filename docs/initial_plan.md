Launchpad — AWS + Kubernetes (EKS) Template

This document describes a step-by-step plan and concise requirements for an enterprise-grade DevOps template designed for deployment on AWS via Kubernetes (EKS), with future migration in mind.

⸻

1. Overall Goal

Build a simple but properly designed demo project that:
• uses a monorepo
• has a client (Vite) and API (NestJS)
• includes a shared package with types used by both frontend and backend
• can be deployed to Kubernetes
• is ready for AWS (EKS) and multi-host setups

⸻

2. Monorepo

Technologies
• TurboRepo
• pnpm (recommended)
• TypeScript

Requirements
• single git repository
• parallel dev mode (client + api)
• shared package used as a workspace dependency

Structure

repo/
├── apps/
│ ├── api/ # NestJS backend
│ └── client/ # Vite + React frontend
├── packages/
│ └── shared/ # shared types / contracts
├── k8s/
│ ├── terraform/ # AWS / EKS infrastructure
│ ├── helm/ # Helm charts
│ └── argocd/ # Argo CD applications
├── .github/
│ └── workflows/ # CI/CD pipelines
├── scripts/ # Helper scripts
│ ├── setup-local.sh
│ ├── build-images.sh
│ └── update-helm-tags.sh
├── docs/ # Documentation
│ ├── initial_plan.md
│ ├── architecture.md
│ └── runbooks/
├── .env.example # Environment template
├── docker-compose.yml # Local development
├── turbo.json
├── package.json
└── pnpm-workspace.yaml

⸻

3. Shared Package (Types / Contracts)

Purpose

Single source of truth for contracts between frontend and backend.

Requirements
• TypeScript only
• DTO / response types
• no runtime logic (optional zod in the future)

Example Contract

Endpoint: GET /api/v1/health

export type HealthResponse = {
ok: true
service: "api"
time: string // ISO date
}

⸻

4. Backend — NestJS (apps/api)

Requirements
• NestJS (minimal setup)
• 1 example controller
• CORS enabled
• uses types from packages/shared

Endpoint
• GET /api/v1/health
• returns HealthResponse

Architectural Notes
• no complex business logic
• container-ready

⸻

5. Frontend — Vite (apps/client)

Requirements
• Vite + React
• fetch API via VITE_API_BASE_URL
• typed response using shared package

UI
• simple page
• displays API status (OK / error)

⸻

6. Docker

Requirements
• separate Dockerfile for client and api
• multi-stage builds
• client built as static assets and served via Nginx (or similar)

Artifacts
• apps/api/Dockerfile
• apps/client/Dockerfile

⸻

7. Kubernetes

For Each Service (api / client)

Requirements
• Deployment
• Service (ClusterIP)
• Ingress
• env vars via ConfigMap / values
• readiness + liveness probes
• resource requests / limits

⸻

8. Ingress

Requirements
• single ingress controller (NGINX or Traefik)
• domains:
• app.example.com → client
• api.example.com or /api → backend
• TLS can be added in a later phase

⸻

9. Helm

Requirements
• separate charts for:
• api
• client
• configuration via values.yaml
• support for environments (dev / prod)

Structure

k8s/helm/
├── charts/
│ ├── api/
│ │ ├── Chart.yaml
│ │ ├── values.yaml
│ │ ├── values-dev.yaml
│ │ ├── values-staging.yaml
│ │ └── values-prod.yaml
│ └── client/
│ └── ...
├── umbrella-chart/ # Parent chart for all services
│ ├── Chart.yaml
│ └── values.yaml
└── README.md

Best Practices
• Use Helm hooks for migrations (if DB added)
• Helm secrets for sensitive data
• Chart testing (helm lint, helm test)

⸻

10. Argo CD (CD / GitOps)

Requirements
• Argo CD installed in the cluster
• applications read Helm charts from this repository
• Git is the single source of truth

Sync Policy
• dev / staging: auto-sync
• prod: manual approval (optional)

⸻

11. CI/CD (GitHub Actions)

GitHub Actions Workflows

1. PR Pipeline (.github/workflows/pr.yml)
   • Lint (ESLint, Prettier)
   • Type check (TypeScript)
   • Unit tests + coverage
   • Build verification
   • Security scan (Trivy)

2. Main Branch Pipeline (.github/workflows/main.yml)
   • All PR checks
   • Build & push Docker images to ECR
   • Tag images with git SHA + branch
   • Update Helm values (automated PR or commit)

3. Release Pipeline (.github/workflows/release.yml)
   • Triggered on git tag (v*.*.\*)
   • Build production images
   • Tag as :latest and :v1.2.3
   • Update prod Helm values
   • Create GitHub Release with changelog

4. Terraform Pipeline (.github/workflows/terraform.yml)
   • Plan on PR
   • Apply on merge to main (with approval)
   • State in S3 + DynamoDB lock

Notes
• CI does not deploy directly to cluster — Argo CD does (GitOps)
• Images tagged with git SHA for traceability

⸻

12. Terraform (AWS)

Minimal Scope
• VPC + subnets
• EKS cluster
• Managed Node Group (EC2) with autoscaling
• IAM / OIDC for Kubernetes
• (optional) ECR repositories

Structure

k8s/terraform/
├── envs/
│ ├── dev/
│ │ ├── main.tf
│ │ ├── variables.tf
│ │ └── terraform.tfvars
│ └── prod/
│ └── ...
├── modules/
│ ├── network/
│ ├── eks/
│ └── ecr/
└── backend.tf # S3 + DynamoDB for state

⸻

13. Autoscaling (Later Phase)

Requirements
• HPA for backend (CPU or custom metrics)
• Cluster Autoscaler or Karpenter
• correct resource requests / limits

⸻

14. Observability

Logging
• Structured JSON logs (Winston/Pino for NestJS)
• Log aggregation: AWS CloudWatch Logs or Loki
• Request ID tracing across services

Metrics
• Prometheus metrics endpoint on each service
• Grafana dashboards
• Key metrics: latency, error rate, throughput (RED method)

Tracing (Optional Phase 2)
• OpenTelemetry or AWS X-Ray
• Distributed tracing for debugging

Alerts
• CloudWatch Alarms or Prometheus AlertManager
• Slack/PagerDuty integration
• SLO-based alerting

⸻

15. Security

Image Scanning
• Trivy or Snyk in CI pipeline
• Block vulnerable images

Secrets Management
• AWS Secrets Manager or External Secrets Operator
• NEVER commit secrets to git
• Kubernetes secrets sealed with SealedSecrets or SOPS

Network Policies
• Kubernetes NetworkPolicies for pod isolation
• Service mesh (Istio/Linkerd) for production (optional)

RBAC
• Least privilege IAM roles (IRSA for pods)
• K8s RBAC for namespaces
• Audit logging enabled

⸻

16. Testing Strategy

Unit Tests
• Jest for backend (NestJS)
• Vitest for frontend
• Coverage threshold: 80%

Integration Tests
• Supertest for API endpoints
• Test containers for dependencies (if DB added)

E2E Tests (Optional)
• Playwright or Cypress
• Run in CI on PR

Load Testing
• k6 or Artillery
• Baseline performance tests
• Run before major releases

⸻

17. Local Development

Requirements
• Docker Desktop + Kind or Minikube
• pnpm, Node.js 20+
• kubectl, helm, terraform

Quick Start

# Setup

pnpm install
cp .env.example .env

# Run locally (docker-compose)

docker-compose up -d
pnpm dev

# Deploy to local K8s

./k8s/scripts/deploy-local-k8s.sh

Hot Reload
• Vite HMR for client
• NestJS watch mode for API
• Tilt or Skaffold for K8s dev (optional)

⸻

18. Cost Management

AWS Cost Controls
• Use Spot instances for dev/staging nodes
• Cluster Autoscaler or Karpenter
• Schedule scale-down for non-prod (nights/weekends)
• AWS Cost Explorer tags

Monitoring
• Kubecost for K8s cost visibility
• Budget alerts in AWS
• Regular cost reviews

⸻

19. Disaster Recovery

Backup Strategy
• Terraform state: S3 with versioning
• Helm values: Git (already backed up)
• EKS cluster config: eksctl or Terraform
• DB backups (if added): AWS RDS automated backups

Recovery Plan
• Document cluster recreation steps
• Test recovery quarterly
• RTO/RPO targets defined

⸻

20. Documentation (Critical)

Required Docs
• README.md: Quick start, architecture overview
• CONTRIBUTING.md: Development guidelines
• docs/architecture.md: Diagrams (C4, sequence)
• docs/runbooks/

- incident-response.md
- deployment.md
- rollback.md
- scaling.md
  • ADRs (Architecture Decision Records)

⸻

21. Developer Tools

Pre-commit Hooks
• Husky + lint-staged
• Auto format, type check before commit

IDE Setup
• VSCode workspace settings
• Recommended extensions (.vscode/extensions.json)
• Debug configurations

Automation Scripts
• scripts/setup-local.sh
• scripts/build-and-push.sh
• scripts/update-helm-image.sh
• scripts/port-forward-services.sh

⸻

22. Implementation Phases

Phase 0 — Skeleton
• Monorepo setup (Turborepo + pnpm)
• apps/client (Vite + React)
• apps/api (NestJS)
• packages/shared (TypeScript types)
• 1 health endpoint
• Local dev with hot reload
• Basic scripts

Phase 1 — Local Dev Experience
• Docker + docker-compose
• .env management
• Scripts for quick start
• Pre-commit hooks (Husky)

Phase 2 — CI/CD Foundation
• GitHub Actions for lint/test/build
• Image registry (ECR setup)
• Automated testing

Phase 3 — Kubernetes Local
• Helm charts (api + client)
• Deploy to Kind/Minikube
• Ingress without TLS
• Test full stack locally

Phase 4 — AWS Infrastructure
• Terraform for EKS + VPC
• ECR repositories
• IAM roles (IRSA)
• Security groups

Phase 5 — GitOps
• Argo CD setup
• Sync policies (auto for dev, manual for prod)
• Image update automation

Phase 6 — Observability
• Structured logging
• Metrics + Prometheus + Grafana
• Alerts setup
• Dashboards

Phase 7 — Production Hardening
• Security scanning (Trivy)
• NetworkPolicies
• Secrets management
• Load testing
• Documentation complete

⸻

23. Result

Outcome:
• Educational but production-like DevOps template
• Enterprise-grade architecture
• AWS-ready with EKS
• GitOps-driven deployments
• Observable and secure by default
• Scalable by design
• Suitable for future migration (e.g. to GCP, Azure)
• Complete CI/CD automation
• Infrastructure as Code

Use Cases:
• Foundation for real SaaS products
• DevOps learning and training
• Interview/portfolio projects
• Microservices template
• Production deployment reference

⸻

This plan serves as a comprehensive DevOps template combining modern cloud-native practices with enterprise reliability standards.
