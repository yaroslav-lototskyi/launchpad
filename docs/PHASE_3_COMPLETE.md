# Phase 3 Complete: Kubernetes Local Deployment ✅

**Completion Date**: 2026-01-04

## Overview

Phase 3 introduces Kubernetes deployment capabilities with Helm charts, enabling local and cloud-based orchestration of the Launchpad application.

## Deliverables

### 1. Helm Chart Structure

Created production-ready Helm chart at `infra/helm/launchpad/`:

```
infra/helm/launchpad/
├── Chart.yaml                    # Helm chart metadata
├── .helmignore                   # Files to exclude from package
├── README.md                     # Chart documentation
├── values.yaml                   # Default configuration
├── values-development.yaml       # Development overrides
├── values-staging.yaml          # Staging overrides
├── values-production.yaml       # Production overrides
└── templates/
    ├── _helpers.tpl             # Reusable template functions
    ├── api-deployment.yaml      # API Deployment manifest
    ├── api-service.yaml         # API Service manifest
    ├── api-hpa.yaml            # API HorizontalPodAutoscaler
    ├── client-deployment.yaml   # Client Deployment manifest
    ├── client-service.yaml      # Client Service manifest
    ├── client-hpa.yaml         # Client HorizontalPodAutoscaler
    ├── ingress.yaml            # Ingress routing configuration
    └── serviceaccount.yaml      # ServiceAccount for pods
```

### 2. Kubernetes Resources

#### API Service

- **Deployment**: 2 replicas (default), configurable per environment
- **Resources**: 250m-500m CPU, 256Mi-512Mi memory
- **Health Checks**:
  - Liveness probe: `GET /api/v1/health` on port 3001
  - Readiness probe: Same endpoint, faster checks
- **Autoscaling**: Optional HPA with 2-5 replicas based on 80% CPU
- **Environment Variables**: PORT, NODE_ENV, CORS_ORIGIN, LOG_LEVEL
- **Security**: Non-root user (1001), no privilege escalation

#### Client Service

- **Deployment**: 2 replicas (default), configurable per environment
- **Resources**: 100m-200m CPU, 64Mi-128Mi memory
- **Health Checks**:
  - Liveness probe: `GET /` on port 80
  - Readiness probe: Same endpoint
- **Autoscaling**: Optional HPA with 2-10 replicas based on 80% CPU
- **Security**: Same security context as API

#### Ingress

- **Class**: nginx
- **Routing**:
  - `/api/*` → API Service (port 3001)
  - `/*` → Client Service (port 80)
- **TLS**: Configurable per environment with cert-manager integration
- **Annotations**: Rate limiting, CORS, cert-manager issuer

### 3. Environment Configurations

#### Development (`values-development.yaml`)

- **Replicas**: 1 for both services
- **Image Tag**: `latest`
- **Domain**: `launchpad.local`
- **Resources**: Minimal (optimized for local development)
- **Autoscaling**: Disabled
- **TLS**: Disabled
- **Logging**: Debug level

#### Staging (`values-staging.yaml`)

- **Replicas**: 2 for both services
- **Image Tag**: `main`
- **Domain**: `staging.launchpad.io`
- **Resources**: Medium (250m-500m CPU for API)
- **Autoscaling**: Enabled (2-4 for API, 2-8 for Client)
- **TLS**: Let's Encrypt staging issuer
- **Logging**: Info level

#### Production (`values-production.yaml`)

- **Replicas**: 3 for both services
- **Image Tag**: `production`
- **Domain**: `launchpad.io`
- **Resources**: Higher limits (500m-1000m CPU for API)
- **Autoscaling**: Enabled (3-10 for API, 3-15 for Client)
- **TLS**: Let's Encrypt production issuer
- **Rate Limiting**: 100 requests/minute per IP
- **Logging**: Warn level

### 4. Helper Scripts

#### `scripts/k8s-setup-kind.sh`

Creates local Kubernetes cluster using Kind:

- Creates cluster with Ingress port mappings (80, 443)
- Installs NGINX Ingress Controller
- Adds `launchpad.local` to `/etc/hosts`
- Validates cluster readiness

**Usage**:

```bash
./scripts/k8s-setup-kind.sh
```

#### `scripts/k8s-deploy.sh`

Deploys Helm chart to Kubernetes:

- Accepts environment parameter (development, staging, production)
- Creates namespace if needed
- Selects appropriate values file
- Deploys with `helm upgrade --install`
- Shows deployment status and helpful commands

**Usage**:

```bash
./scripts/k8s-deploy.sh [environment] [namespace]
# Examples:
./scripts/k8s-deploy.sh development
./scripts/k8s-deploy.sh staging launchpad-staging
./scripts/k8s-deploy.sh production launchpad-prod
```

#### `scripts/k8s-destroy.sh`

Cleans up Kubernetes deployment:

- Uninstalls Helm release
- Optionally deletes namespace
- Deletes Kind cluster (with confirmation)

**Usage**:

```bash
./scripts/k8s-destroy.sh [environment] [namespace]
```

### 5. Documentation

- **Helm Chart README** (`infra/helm/launchpad/README.md`):
  - Installation instructions
  - Configuration parameters reference
  - Usage examples
  - Troubleshooting guide

- **Main README Updates**:
  - Added Phase 3 status as complete
  - Updated project structure
  - Added Kubernetes deployment instructions
  - Updated status footer and next phase

## Key Features

### Resource Management

- CPU and memory limits for all containers
- Resource requests for guaranteed QoS
- Horizontal Pod Autoscaling support
- Environment-specific resource tuning

### High Availability

- Multiple replicas per service
- Health checks (liveness and readiness)
- Rolling updates with zero downtime
- Pod anti-affinity (configurable)

### Security

- Non-root container execution
- Read-only root filesystem option
- No privilege escalation
- ServiceAccount with minimal permissions
- Network policies ready (Phase 7)

### Observability

- Health check endpoints
- Resource metrics for autoscaling
- Labels for monitoring integration
- Ready for Prometheus/Grafana (Phase 6)

## Local Testing

### Setup Kind Cluster

```bash
# Install Kind if needed
brew install kind

# Create local cluster
./scripts/k8s-setup-kind.sh
```

### Deploy Application

```bash
# Deploy to development environment
./scripts/k8s-deploy.sh development

# Access the application
open http://launchpad.local
```

### Verify Deployment

```bash
# Check pods
kubectl get pods -n launchpad-development

# Check services
kubectl get svc -n launchpad-development

# Check ingress
kubectl get ingress -n launchpad-development

# View logs
kubectl logs -n launchpad-development -l app.kubernetes.io/component=api --tail=50 -f
```

### Cleanup

```bash
# Remove deployment
./scripts/k8s-destroy.sh development

# Delete Kind cluster
kind delete cluster --name launchpad-local
```

## Configuration Examples

### Custom Resource Limits

```yaml
# custom-values.yaml
api:
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi
```

### Enable Autoscaling

```yaml
# custom-values.yaml
api:
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

### Custom Domain

```yaml
# custom-values.yaml
global:
  domain: my-custom-domain.com

ingress:
  hosts:
    - host: my-custom-domain.com
      paths: [...]
```

## Troubleshooting

### Pods Not Starting

```bash
# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check resource quotas
kubectl describe resourcequota -n <namespace>
```

### Ingress Not Working

```bash
# Verify Ingress Controller is running
kubectl get pods -n ingress-nginx

# Check ingress configuration
kubectl describe ingress -n <namespace>

# Verify /etc/hosts entry (local)
cat /etc/hosts | grep launchpad.local
```

### Image Pull Failures

```bash
# Check if using correct image tag
kubectl get deployment <deployment-name> -n <namespace> -o yaml | grep image:

# For GHCR, ensure images are public or create image pull secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<username> \
  --docker-password=<token> \
  --namespace=<namespace>
```

## Next Steps (Phase 4)

With local Kubernetes deployment working, Phase 4 will focus on AWS infrastructure:

1. **Terraform Modules**:
   - VPC with public/private subnets
   - EKS cluster configuration
   - IAM roles and policies
   - ECR repositories

2. **AWS Integration**:
   - Replace GHCR with ECR
   - Configure ALB Ingress Controller
   - Set up AWS Load Balancer
   - Configure Route53 DNS

3. **Infrastructure as Code**:
   - Terraform workspaces for environments
   - Remote state in S3
   - State locking with DynamoDB
   - CI/CD integration with Terraform

## Metrics

- **Files Created**: 18
- **Lines of Code**: ~1100
- **Kubernetes Manifests**: 8
- **Environment Configs**: 3
- **Helper Scripts**: 3
- **Documentation Pages**: 2

## References

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Helm Chart README](../infra/helm/launchpad/README.md)

---

**Phase 3 Status**: ✅ Complete
**Next Phase**: Phase 4 - AWS Infrastructure
