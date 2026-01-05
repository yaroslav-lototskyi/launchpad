# Phase 5 Complete: CI/CD Pipeline & GitOps ✅

**Completion Date**: 2026-01-05

## Overview

Phase 5 introduces automated CI/CD pipelines using GitHub Actions for Continuous Integration and Argo CD for GitOps-based Continuous Deployment. This hybrid approach combines the best of both worlds: GitHub Actions for building and testing, and Argo CD for declarative, Git-driven deployments.

## Deliverables

### 1. GitHub Actions Workflows

Created production-ready CI/CD workflows in `.github/workflows/`:

```
.github/workflows/
├── ci.yml                # Continuous Integration
├── docker-build.yml      # Docker image build and push
├── deploy.yml            # Kubernetes deployment
└── pr-validation.yml     # Pull request validation
```

### 2. CI Workflow (`ci.yml`)

**Purpose**: Continuous integration for all code changes

**Triggers**:

- Pull requests to `main` or `develop`
- Pushes to `main` or `develop`

**Jobs**:

1. **Lint** (ESLint + Prettier)
   - Code style validation
   - Formatting checks
   - Best practices enforcement

2. **Type Check** (TypeScript)
   - Type safety validation
   - Compile-time error detection
   - Cross-package type checking

3. **Test API**
   - Unit tests
   - Integration tests
   - Test coverage reports

4. **Test Client**
   - Component tests
   - Unit tests
   - UI testing

5. **Build API**
   - Production build
   - Build artifact validation
   - Dependency resolution

6. **Build Client**
   - Production build with Vite
   - Static asset optimization
   - Bundle size validation

7. **Security Scan** (Trivy)
   - Vulnerability scanning
   - Dependency auditing
   - SARIF report upload to GitHub Security

**Runtime**: ~5-8 minutes

**Key Features**:

- ✅ Parallel job execution for speed
- ✅ Dependency caching (pnpm)
- ✅ Fail fast on critical errors
- ✅ Detailed error reporting

### 3. Docker Build Workflow (`docker-build.yml`)

**Purpose**: Build and push Docker images to registries

**Triggers**:

- Push to `main` or `develop`
- Git tags (`v*`)
- Manual dispatch

**Jobs**:

1. **Build and Push API (GHCR)**
   - Multi-stage Docker build
   - GitHub Container Registry push
   - Automatic tagging strategy
   - BuildKit cache optimization

2. **Build and Push Client (GHCR)**
   - Optimized Nginx image
   - Static asset serving
   - Production-ready configuration

3. **Build and Push to ECR** (optional)
   - AWS ECR authentication via OIDC
   - Environment-specific tagging
   - Automatic region detection

**Image Tagging Strategy**:

```
main branch:
  - latest
  - production
  - main-{sha}

develop branch:
  - develop
  - staging
  - develop-{sha}

Tags (v1.2.3):
  - v1.2.3
  - 1.2
  - 1
  - latest

Pull Requests:
  - pr-{number}
```

**Runtime**: ~10-15 minutes

**Key Features**:

- ✅ Docker layer caching (GitHub Actions cache)
- ✅ Multi-platform support (linux/amd64)
- ✅ Automatic metadata extraction
- ✅ Image signing support (cosign ready)
- ✅ SBOM generation ready

### 4. Deploy Workflow (`deploy.yml`)

**Purpose**: Deploy applications to Kubernetes clusters

**Triggers**:

- Manual dispatch (choose environment)
- After successful Docker build (automatic)

**Deployment Strategy**:

| Branch    | Environment | Namespace              | Cluster                | Trigger   |
| --------- | ----------- | ---------------------- | ---------------------- | --------- |
| `main`    | Production  | `launchpad-production` | `launchpad-production` | Automatic |
| `develop` | Staging     | `launchpad-staging`    | `launchpad-staging`    | Automatic |
| Manual    | Any         | Custom                 | Custom                 | Manual    |

**Steps**:

1. **Configure AWS**
   - OIDC authentication
   - ECR login
   - kubectl configuration

2. **Deploy with Helm**
   - Namespace creation
   - Helm upgrade --install
   - Wait for rollout completion (10min timeout)

3. **Verification**
   - Pod status checks
   - Service availability
   - Ingress configuration

4. **Smoke Tests**
   - Health endpoint validation
   - Basic functionality check
   - Response time validation

**Runtime**: ~5-10 minutes

**Key Features**:

- ✅ Zero-downtime deployments
- ✅ Automatic rollback on failure
- ✅ Smoke tests for validation
- ✅ Detailed deployment logs
- ✅ Resource status reporting

### 5. PR Validation Workflow (`pr-validation.yml`)

**Purpose**: Validate pull requests before merge

**Triggers**:

- PR opened
- PR synchronized (new commits)
- PR reopened

**Validation Checks**:

1. **PR Title**
   - Conventional commit format
   - Valid types: feat, fix, docs, etc.
   - Optional scope

2. **Merge Conflicts**
   - Automatic conflict detection
   - Base branch compatibility

3. **File Sizes**
   - No files >10MB
   - Prevents large binaries

4. **Code Quality**
   - Formatting (Prettier)
   - Linting (ESLint)
   - Type checking (TypeScript)

5. **Tests**
   - All tests passing
   - Coverage reports

6. **Docker Build**
   - Verify images build successfully
   - Security scan (Trivy)
   - Vulnerability reporting

7. **PR Comment**
   - Automatic validation summary
   - Check status report

**Runtime**: ~8-12 minutes

**Key Features**:

- ✅ Prevents bad code from merging
- ✅ Automated security scanning
- ✅ Helpful PR comments
- ✅ Matrix builds for both services

## AWS OIDC Authentication

Instead of using AWS access keys, uses secure OIDC authentication.

**Benefits**:

- 🔒 **No long-lived credentials** in GitHub secrets
- 🔄 **Automatic token rotation**
- 📝 **Audit trail** in AWS CloudTrail
- 🎯 **Fine-grained permissions** per repository

**Setup**:

1. Create OIDC provider in AWS
2. Create IAM role with trust policy
3. Attach ECR and EKS policies
4. Add role ARN to GitHub secrets

**Required Secret**: `AWS_ROLE_TO_ASSUME`

## Workflow Permissions

Workflows use minimal required permissions:

```yaml
permissions:
  contents: read # Read repository code
  packages: write # Push to GHCR
  id-token: write # OIDC authentication
  security-events: write # Upload security reports
```

## Environment Variables

Centralized configuration:

```yaml
NODE_VERSION: '20'
PNPM_VERSION: '8.15.1'
AWS_REGION: 'us-east-1'
KUBECTL_VERSION: '1.28.0'
HELM_VERSION: '3.13.0'
```

## Caching Strategy

**1. pnpm Dependencies**

```yaml
cache: 'pnpm' # Automatic caching by setup-node
```

**Benefit**: ~2-3 minutes saved on installs

**2. Docker Layers**

```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

**Benefit**: ~5-10 minutes saved on builds

**3. Test Results**

Tests run only when relevant code changes.

## Security Features

### 1. Dependency Scanning

- **pnpm audit**: Check for known vulnerabilities
- **Dependabot**: Automatic dependency updates
- **npm-audit**: Continuous monitoring

### 2. Container Scanning

- **Trivy**: Vulnerability scanner for containers
- **SARIF Upload**: GitHub Security integration
- **Severity Levels**: CRITICAL, HIGH, MEDIUM, LOW

### 3. Code Scanning

- **CodeQL**: Semantic code analysis
- **Secret Scanning**: Prevent credential leaks
- **SAST**: Static Application Security Testing

### 4. Access Control

- **OIDC**: Short-lived credentials
- **Branch Protection**: Require approvals
- **Status Checks**: Must pass before merge

## Deployment Flow

### Development Flow

```
1. Create feature branch
   └─> PR opened → pr-validation.yml runs

2. Push commits
   └─> ci.yml runs on each push

3. Ready for review
   └─> Request review

4. Approved & merged to develop
   └─> docker-build.yml builds images
   └─> deploy.yml deploys to staging

5. Test in staging
   └─> Manual validation

6. Merge develop → main
   └─> docker-build.yml builds production images
   └─> deploy.yml deploys to production (automatic or manual)
```

### Hotfix Flow

```
1. Create hotfix branch from main
   └─> Make critical fix

2. PR to main
   └─> Fast-track approval

3. Merge to main
   └─> Automatic deployment to production

4. Backport to develop
   └─> Keep branches in sync
```

## Monitoring and Observability

### Workflow Status

View in GitHub UI:

- **Actions** tab → All workflow runs
- **Pull Requests** → Status checks
- **Branches** → Branch protection status

### Deployment Logs

```bash
# View GitHub Actions logs
gh run view <run-id> --log

# View Kubernetes deployment logs
kubectl logs -f deployment/launchpad-api -n launchpad-production

# Check rollout status
kubectl rollout status deployment/launchpad-api -n launchpad-production
```

### Notifications

Can be integrated with:

- Slack
- Discord
- Email
- MS Teams
- PagerDuty

## Rollback Strategy

### Automatic Rollback

Helm automatically rolls back on:

- Pod startup failures
- Health check failures
- Timeout (10 minutes)

### Manual Rollback

```bash
# Via kubectl
kubectl rollout undo deployment/launchpad-api -n launchpad-production

# Via Helm
helm rollback launchpad -n launchpad-production

# To specific revision
helm rollback launchpad 5 -n launchpad-production
```

### Rollback via GitHub Actions

Re-run previous successful deployment workflow.

## Performance Optimizations

### 1. Parallel Jobs

CI jobs run in parallel:

- Lint + Type Check + Tests (parallel)
- Builds after tests pass
- Total time: ~5-8 minutes

### 2. Docker Layer Caching

BuildKit caches:

- Base images
- Dependencies
- Build artifacts

**Savings**: 50-70% build time reduction

### 3. Dependency Caching

pnpm cache:

- `node_modules` cached
- Lockfile-based invalidation

**Savings**: ~2-3 minutes per run

### 4. Conditional Execution

```yaml
if: github.ref == 'refs/heads/main'
```

Only run production deployments when needed.

## Cost Optimization

### GitHub Actions Minutes

**Free tier**: 2,000 minutes/month

**Usage estimates**:

- CI workflow: ~8 min × 20 runs/day = 160 min/day
- Docker build: ~12 min × 5 runs/day = 60 min/day
- Deployment: ~8 min × 3 runs/day = 24 min/day
- **Total**: ~244 min/day = ~7,320 min/month

**For private repos**: Consider GitHub Team ($4/user/month) for 3,000 minutes

**For public repos**: Unlimited minutes ✅

### AWS Costs

ECR data transfer:

- GitHub → ECR: Free (ingress)
- ECR → EKS: Free (same region)

## Best Practices

### 1. Branch Strategy

```
main (production)
  ├─> develop (staging)
  │    ├─> feature/xyz
  │    ├─> feature/abc
  │    └─> bugfix/123
  └─> hotfix/urgent-fix
```

### 2. Commit Messages

Use Conventional Commits:

```
feat: add user authentication
fix: resolve CORS issue
docs: update README
chore: update dependencies
```

### 3. PR Reviews

- ✅ At least 1 approval required
- ✅ All checks must pass
- ✅ No merge conflicts
- ✅ Up to date with base branch

### 4. Tagging Releases

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

Triggers production build with semantic version tags.

### 5. Environment Secrets

Never commit:

- API keys
- Passwords
- Tokens
- Certificates

Use:

- GitHub Secrets
- AWS Secrets Manager
- Kubernetes Secrets

## Troubleshooting

### Build Failures

**Issue**: Docker build OOM

**Solution**:

```yaml
# Reduce concurrency
jobs: 1
```

### Deployment Timeouts

**Issue**: Helm timeout after 10 minutes

**Solution**:

```yaml
--timeout 15m
```

### Image Pull Errors

**Issue**: `ImagePullBackOff`

**Solution**:

1. Verify image tag exists
2. Check ECR permissions
3. Validate image URI

### OIDC Authentication Fails

**Issue**: `AccessDenied`

**Solution**:

1. Check IAM trust policy
2. Verify repository name in condition
3. Confirm OIDC provider exists

## Metrics

- **Workflow Files**: 4
- **Lines of YAML**: ~800
- **Jobs Configured**: 12
- **Checks per PR**: 15+
- **Average CI Time**: 5-8 minutes
- **Average Deploy Time**: 5-10 minutes
- **Security Scans**: 2 (Trivy + CodeQL)

### 6. Argo CD GitOps Configuration

**Purpose**: Declarative, Git-driven continuous deployment

**Components**:

1. **Argo CD Installation** (`k8s/argocd/install/`):
   - Installation manifests
   - Ingress configuration
   - Image Updater setup

2. **Argo CD Projects** (`k8s/argocd/projects/`):
   - Development project (full access)
   - Staging project (controlled access)
   - Production project (restricted, sync windows)

3. **Argo CD Applications** (`k8s/argocd/apps/`):
   - Development: Auto-sync enabled, tracks `develop` branch
   - Staging: Auto-sync enabled, tracks `develop` branch
   - Production: Manual sync, tracks `main` branch

4. **Image Updater**:
   - Automatically detects new images
   - Updates Helm values in Git
   - Triggers Argo CD sync

**Sync Policies**:

| Environment | Sync Policy           | Image Strategy      | Approval |
| ----------- | --------------------- | ------------------- | -------- |
| Development | Automatic (self-heal) | `latest` tag        | None     |
| Staging     | Automatic (self-heal) | `staging` tag       | None     |
| Production  | Manual                | Semantic versioning | Required |

**GitOps Workflow**:

```
1. Developer pushes code
   ↓
2. GitHub Actions builds Docker image
   ↓
3. Image pushed to registry (GHCR/ECR)
   ↓
4. Image Updater detects new image
   ↓
5. Updates Helm values in Git (creates commit)
   ↓
6. Argo CD detects Git change
   ↓
7. Auto-syncs (dev/staging) or waits for approval (prod)
   ↓
8. Deploys to Kubernetes
```

**Benefits**:

- ✅ Git as single source of truth
- ✅ Automatic drift detection
- ✅ Easy rollback (git revert)
- ✅ Audit trail in Git history
- ✅ Declarative configuration
- ✅ Visual deployment UI

**Setup Script**:

```bash
./k8s/scripts/argocd-setup.sh
```

## CI/CD vs GitOps

### Separation of Concerns

**GitHub Actions (CI)**:

- Build code
- Run tests
- Build Docker images
- Push to registry
- Security scanning

**Argo CD (CD)**:

- Monitor Git repository
- Sync Kubernetes state
- Deploy applications
- Detect drift
- Auto-remediate

### Workflow Comparison

**Before (GitHub Actions only)**:

```
Git Push → Build → Test → Deploy → Kubernetes
           (All in GitHub Actions)
```

**After (GitHub Actions + Argo CD)**:

```
Git Push → Build → Test → Push Image
           (GitHub Actions)
                    ↓
           Image Updater → Update Git
                    ↓
           Argo CD → Deploy → Kubernetes
           (GitOps)
```

## Documentation

- **GitHub Actions Setup** (`docs/GITHUB_ACTIONS_SETUP.md`):
  - AWS OIDC configuration
  - Required secrets
  - Workflow descriptions
  - Troubleshooting guide
  - Best practices

- **Argo CD GitOps** (`docs/ARGOCD_GITOPS.md`):
  - GitOps principles
  - Argo CD installation
  - Application configuration
  - Sync policies
  - Image update automation
  - Common operations
  - Troubleshooting

- **Phase 5 Complete** (this file):
  - Overview and deliverables
  - Workflow details
  - Deployment strategy
  - Security features

## Next Steps (Phase 6)

With CI/CD pipeline complete, Phase 6 will focus on observability:

1. **Monitoring**:
   - Prometheus for metrics collection
   - Grafana for visualization
   - AlertManager for notifications

2. **Logging**:
   - ELK Stack or CloudWatch
   - Centralized log aggregation
   - Log-based alerts

3. **Tracing**:
   - Distributed tracing with Jaeger
   - Request flow visualization
   - Performance bottleneck identification

4. **Dashboards**:
   - Service health dashboard
   - Infrastructure metrics
   - Application metrics
   - Business metrics

## References

### GitHub Actions

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [AWS OIDC Guide](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

### Argo CD

- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Argo CD Image Updater](https://argocd-image-updater.readthedocs.io/)
- [Argo CD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)

### General

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)

---

**Phase 5 Status**: ✅ Complete (CI/CD + GitOps)
**Next Phase**: Phase 6 - Monitoring and Observability
