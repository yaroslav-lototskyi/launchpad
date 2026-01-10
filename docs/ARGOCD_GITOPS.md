# Argo CD GitOps Guide

This guide explains the GitOps workflow using Argo CD for continuous deployment.

## What is GitOps?

**GitOps** is a deployment methodology where Git is the single source of truth for infrastructure and application configuration.

### Traditional CI/CD (what we had before):

```
Code Change → CI Build → CI Deploy → Kubernetes
                          ↓
                    kubectl/helm apply
```

**Problems**:

- Cluster state can drift from Git
- No automatic detection of manual changes
- Rollback requires re-running CI pipeline

### GitOps with Argo CD:

```
Code Change → Git Commit → Argo CD Watches → Auto-Sync → Kubernetes
                            ↓
                      Continuous Monitoring
```

**Benefits**:

- ✅ Git = single source of truth
- ✅ Automatic drift detection
- ✅ Easy rollback (git revert)
- ✅ Audit trail (Git history)
- ✅ Declarative configuration

## Architecture

### Components

1. **Argo CD Server**: Web UI and API
2. **Application Controller**: Monitors Git and syncs to cluster
3. **Repo Server**: Fetches manifests from Git
4. **Image Updater**: Automatically updates image tags

### Workflow

```
1. Developer pushes code
   ↓
2. GitHub Actions builds Docker image
   ↓
3. Image Updater detects new image
   ↓
4. Updates Helm values in Git
   ↓
5. Argo CD detects Git change
   ↓
6. Syncs to Kubernetes cluster
```

## Directory Structure

```
k8s/argocd/
├── install/
│   ├── argocd-install.yaml         # Installation instructions
│   ├── argocd-ingress.yaml        # Ingress configuration
│   └── image-updater-install.yaml  # Image Updater setup
├── projects/
│   ├── development.yaml            # Dev project RBAC
│   ├── staging.yaml                # Staging project RBAC
│   └── production.yaml             # Prod project RBAC
└── apps/
    ├── launchpad-development.yaml  # Dev application
    ├── launchpad-staging.yaml      # Staging application
    └── launchpad-production.yaml   # Prod application
```

## Installation

### 1. Install Argo CD

```bash
# Automated installation
./k8s/scripts/argocd-setup.sh

# Or manual installation
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Access Argo CD UI

**Option A: Port Forward (local)**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Open browser
open https://localhost:8080
# Username: admin
# Password: (from above)
```

**Option B: Ingress (production)**

```bash
# Update domain in argocd-ingress.yaml
kubectl apply -f k8s/argocd/install/argocd-ingress.yaml

# Access via domain
open https://argocd.launchpad.io
```

### 3. Install Argo CD CLI

```bash
brew install argocd

# Or manual install
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-darwin-amd64
chmod +x /usr/local/bin/argocd
```

### 4. Install Image Updater

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/v0.15.0/manifests/install.yaml
```

## Configuration

### Projects

Projects provide multi-tenancy and RBAC:

```bash
# Apply all projects
kubectl apply -f k8s/argocd/projects/
```

**Project Features**:

- **Development**: Full access, any repository
- **Staging**: Controlled access, specific resources
- **Production**: Restricted access, manual approval, sync windows

### Applications

Applications define what to deploy and where:

```bash
# Apply applications
kubectl apply -f k8s/argocd/apps/launchpad-development.yaml
kubectl apply -f k8s/argocd/apps/launchpad-staging.yaml
kubectl apply -f k8s/argocd/apps/launchpad-production.yaml
```

## Sync Policies

### Development: Automatic Sync

```yaml
syncPolicy:
  automated:
    prune: true # Delete removed resources
    selfHeal: true # Auto-fix manual changes
```

**Behavior**:

- Commits to `develop` branch → Automatic deployment
- Manual changes in cluster → Automatically reverted
- Deleted resources in Git → Automatically deleted

### Staging: Automatic Sync

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

**Behavior**:

- Same as development
- Tracks `develop` branch
- Auto-deploys on every commit

### Production: Manual Sync

```yaml
syncPolicy:
  # No automated section = manual sync required
  syncWindows:
    - schedule: '0 2-4 * * *' # 2-4 AM UTC
      duration: 2h
```

**Behavior**:

- NO automatic deployment
- Requires manual approval in UI
- Sync windows: only 2-4 AM UTC (configurable)
- Manual sync allowed anytime

## Image Update Automation

### Development & Staging

**Strategy**: `latest` - always use newest image

```yaml
argocd-image-updater.argoproj.io/image-list: |
  api=ghcr.io/org/launchpad/api:develop
argocd-image-updater.argoproj.io/api.update-strategy: latest
```

**Behavior**:

1. New image pushed to `develop` tag
2. Image Updater detects new digest
3. Updates Helm values in Git
4. Argo CD syncs new image

### Production

**Strategy**: `semver` - only semantic version tags

```yaml
argocd-image-updater.argoproj.io/image-list: |
  api=ghcr.io/org/launchpad/api:~v
argocd-image-updater.argoproj.io/api.update-strategy: semver
argocd-image-updater.argoproj.io/api.allow-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$
```

**Behavior**:

1. New tag `v1.2.3` pushed
2. Image Updater detects new version
3. Updates Helm values in Git (creates PR or commits)
4. **Manual sync required** in Argo CD UI

## Deployment Workflow

### Development Flow

```
1. Push to develop branch
   ↓
2. GitHub Actions builds image (tag: develop)
   ↓
3. Image Updater detects new image
   ↓
4. Updates values-development.yaml
   ↓
5. Argo CD auto-syncs to cluster
   ✅ Deployed to development
```

### Staging Flow

```
1. Merge PR to develop
   ↓
2. GitHub Actions builds image (tag: staging)
   ↓
3. Image Updater detects new image
   ↓
4. Updates values-staging.yaml
   ↓
5. Argo CD auto-syncs to cluster
   ✅ Deployed to staging
```

### Production Flow

```
1. Create release tag (v1.2.3)
   ↓
2. GitHub Actions builds image (tag: v1.2.3)
   ↓
3. Image Updater creates PR with new version
   ↓
4. Review and merge PR
   ↓
5. **Manual sync in Argo CD UI**
   ↓
6. Approve and sync
   ✅ Deployed to production
```

## Common Operations

### Sync Application

**Via UI**:

1. Open Argo CD UI
2. Select application
3. Click "Sync"
4. Choose sync options
5. Click "Synchronize"

**Via CLI**:

```bash
# Login
argocd login argocd.launchpad.io

# Sync application
argocd app sync launchpad-production

# Sync with options
argocd app sync launchpad-staging \
  --prune \
  --timeout 600
```

### Rollback Deployment

**Via Git**:

```bash
# Revert last commit
git revert HEAD
git push

# Argo CD will automatically sync to previous state
```

**Via Argo CD**:

```bash
# Rollback to previous version
argocd app rollback launchpad-production

# Rollback to specific revision
argocd app rollback launchpad-production 5
```

### View Application Status

**Via UI**:

- Open application in UI
- View resource tree
- Check sync status
- View events and logs

**Via CLI**:

```bash
# Get application info
argocd app get launchpad-production

# Get application logs
argocd app logs launchpad-production

# List applications
argocd app list
```

### Diff Local Changes

Before syncing, see what will change:

```bash
argocd app diff launchpad-production
```

## Troubleshooting

### Application OutOfSync

**Issue**: Application shows "OutOfSync" status

**Solution**:

```bash
# Check what's different
argocd app diff launchpad-production

# If expected, sync
argocd app sync launchpad-production

# If unexpected drift, check recent changes
kubectl get events -n launchpad-production
```

### Sync Failed

**Issue**: Sync operation failed

**Solution**:

```bash
# View sync errors
argocd app get launchpad-production

# Check pod events
kubectl describe pod <pod-name> -n launchpad-production

# Manual intervention if needed
kubectl delete pod <pod-name> -n launchpad-production
argocd app sync launchpad-production
```

### Image Not Updating

**Issue**: Image Updater not detecting new images

**Solution**:

```bash
# Check Image Updater logs
kubectl logs -n argocd deployment/argocd-image-updater

# Verify image tag exists
docker pull ghcr.io/org/launchpad/api:develop

# Force update
argocd app set launchpad-development \
  -p api.image.tag=develop-abc123

argocd app sync launchpad-development
```

### Can't Access Argo CD UI

**Issue**: Cannot access Argo CD UI

**Solution**:

```bash
# Check Argo CD pods
kubectl get pods -n argocd

# Check Ingress
kubectl get ingress -n argocd

# Port-forward as fallback
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Best Practices

### 1. Git Workflow

```
feature/xyz → develop → staging (auto-deploy)
                 ↓
              main → production (manual deploy)
```

### 2. Image Tags

- **Development**: `develop`, `latest`
- **Staging**: `staging`, `develop`
- **Production**: `v1.2.3` (semantic versioning only)

### 3. Sync Policies

- **Dev/Staging**: Automatic sync with self-heal
- **Production**: Manual sync with approval
- **Use sync windows**: Limit production deployments to maintenance windows

### 4. RBAC

- **Developers**: Read-only production access
- **Deployers**: Can sync staging
- **Admins**: Full production access

### 5. Monitoring

- Set up notifications (Slack, email)
- Monitor sync status
- Review drift regularly

### 6. Secrets Management

**Don't commit secrets to Git!**

Use one of:

- AWS Secrets Manager + External Secrets Operator
- Sealed Secrets
- Vault

## Integration with GitHub Actions

GitHub Actions handles CI (build, test, push images):

```yaml
# .github/workflows/ci.yml
# Runs tests, linting, type checking

# .github/workflows/docker-build.yml
# Builds Docker images and pushes to registry
```

**Separation of concerns**:

- **GitHub Actions**: CI (build, test, push images)
- **Argo CD**: CD (deploy, sync, monitor)

**How they work together**:

1. GitHub Actions builds and pushes Docker image (e.g., `develop`, `staging`, `v1.2.3`)
2. Argo CD Image Updater detects new image (polls every 2 minutes)
3. Image Updater updates Helm values in Git (creates commit)
4. Argo CD detects Git change (polls every 3 minutes)
5. Argo CD syncs automatically (dev/staging) or waits for manual approval (production)

## Security Considerations

### 1. Repository Access

Argo CD needs read access to Git repository:

```bash
# Create deploy key in GitHub
# Add to Argo CD:
argocd repo add https://github.com/org/launchpad \
  --ssh-private-key-path ~/.ssh/argocd_deploy_key
```

### 2. Image Registry Access

For private registries:

```bash
# Create secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=username \
  --docker-password=token \
  -n argocd
```

### 3. RBAC

Use AppProjects to restrict:

- Source repositories
- Destination clusters/namespaces
- Allowed resources
- User permissions

## Metrics and Monitoring

### Prometheus Metrics

Argo CD exports Prometheus metrics:

```
argocd_app_info
argocd_app_sync_total
argocd_app_health_status
```

### Health Checks

Argo CD automatically monitors:

- Deployment rollout status
- Pod health
- Service endpoints
- Custom health checks

## Advanced Features

### Multi-Cluster Deployment

Deploy to multiple clusters:

```yaml
destination:
  server: https://eks-production-cluster
  namespace: launchpad-production
```

### App of Apps Pattern

Manage multiple applications:

```yaml
# apps/root.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
spec:
  source:
    path: k8s/argocd/apps
  # This app deploys other apps
```

### Sync Waves

Control deployment order:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: '1' # Deploy first
```

## References

- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Argo CD Image Updater](https://argocd-image-updater.readthedocs.io/)
- [Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)

---

**GitOps Status**: ✅ Configured
**Next**: Monitor deployments and set up notifications
