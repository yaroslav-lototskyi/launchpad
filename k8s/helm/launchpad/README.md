# Launchpad Helm Chart

A Helm chart for deploying the Launchpad application (API + Client) to Kubernetes.

## Prerequisites

- Kubernetes 1.20+
- Helm 3.0+
- NGINX Ingress Controller (for Ingress support)

## Installing the Chart

### Local Development

```bash
# Install with default development values
helm install launchpad ./k8s/helm/launchpad \
  --namespace launchpad-development \
  --create-namespace

# Or use the helper script
./k8s/scripts/k8s-deploy.sh development
```

### Staging

```bash
helm install launchpad ./k8s/helm/launchpad \
  --namespace launchpad-staging \
  --values ./k8s/helm/launchpad/values-staging.yaml \
  --create-namespace

# Or use the helper script
./k8s/scripts/k8s-deploy.sh staging launchpad-staging
```

### Production

```bash
helm install launchpad ./k8s/helm/launchpad \
  --namespace launchpad-production \
  --values ./k8s/helm/launchpad/values-production.yaml \
  --create-namespace

# Or use the helper script
./k8s/scripts/k8s-deploy.sh production launchpad-production
```

## Uninstalling the Chart

```bash
helm uninstall launchpad --namespace launchpad-development

# Or use the helper script
./k8s/scripts/k8s-destroy.sh development
```

## Configuration

The following table lists the configurable parameters and their default values.

### Global Parameters

| Parameter            | Description        | Default           |
| -------------------- | ------------------ | ----------------- |
| `global.environment` | Environment name   | `development`     |
| `global.domain`      | Application domain | `launchpad.local` |

### API Parameters

| Parameter                       | Description            | Default                                    |
| ------------------------------- | ---------------------- | ------------------------------------------ |
| `api.enabled`                   | Enable API deployment  | `true`                                     |
| `api.replicaCount`              | Number of API replicas | `2`                                        |
| `api.image.repository`          | API image repository   | `ghcr.io/yaroslav-lototskyi/launchpad/api` |
| `api.image.tag`                 | API image tag          | `latest`                                   |
| `api.image.pullPolicy`          | API image pull policy  | `IfNotPresent`                             |
| `api.service.type`              | API service type       | `ClusterIP`                                |
| `api.service.port`              | API service port       | `3001`                                     |
| `api.resources.limits.cpu`      | API CPU limit          | `500m`                                     |
| `api.resources.limits.memory`   | API memory limit       | `512Mi`                                    |
| `api.resources.requests.cpu`    | API CPU request        | `250m`                                     |
| `api.resources.requests.memory` | API memory request     | `256Mi`                                    |
| `api.autoscaling.enabled`       | Enable API autoscaling | `false`                                    |
| `api.autoscaling.minReplicas`   | Minimum API replicas   | `2`                                        |
| `api.autoscaling.maxReplicas`   | Maximum API replicas   | `5`                                        |

### Client Parameters

| Parameter                          | Description               | Default                                       |
| ---------------------------------- | ------------------------- | --------------------------------------------- |
| `client.enabled`                   | Enable Client deployment  | `true`                                        |
| `client.replicaCount`              | Number of Client replicas | `2`                                           |
| `client.image.repository`          | Client image repository   | `ghcr.io/yaroslav-lototskyi/launchpad/client` |
| `client.image.tag`                 | Client image tag          | `latest`                                      |
| `client.image.pullPolicy`          | Client image pull policy  | `IfNotPresent`                                |
| `client.service.type`              | Client service type       | `ClusterIP`                                   |
| `client.service.port`              | Client service port       | `80`                                          |
| `client.resources.limits.cpu`      | Client CPU limit          | `200m`                                        |
| `client.resources.limits.memory`   | Client memory limit       | `128Mi`                                       |
| `client.resources.requests.cpu`    | Client CPU request        | `100m`                                        |
| `client.resources.requests.memory` | Client memory request     | `64Mi`                                        |
| `client.autoscaling.enabled`       | Enable Client autoscaling | `false`                                       |

### Ingress Parameters

| Parameter             | Description                 | Default         |
| --------------------- | --------------------------- | --------------- |
| `ingress.enabled`     | Enable Ingress              | `true`          |
| `ingress.className`   | Ingress class name          | `nginx`         |
| `ingress.annotations` | Ingress annotations         | `{}`            |
| `ingress.hosts`       | Ingress hosts configuration | See values.yaml |
| `ingress.tls`         | Ingress TLS configuration   | See values.yaml |

## Examples

### Custom Values

Create a custom values file:

```yaml
# my-values.yaml
api:
  replicaCount: 3
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi

client:
  replicaCount: 5
```

Install with custom values:

```bash
helm install launchpad ./k8s/helm/launchpad \
  --namespace launchpad-custom \
  --values my-values.yaml \
  --create-namespace
```

### Upgrade Deployment

```bash
# Upgrade to new image tag
helm upgrade launchpad ./k8s/helm/launchpad \
  --namespace launchpad-development \
  --set api.image.tag=v1.2.3 \
  --set client.image.tag=v1.2.3
```

### Enable Autoscaling

```bash
helm upgrade launchpad ./k8s/helm/launchpad \
  --namespace launchpad-production \
  --set api.autoscaling.enabled=true \
  --set client.autoscaling.enabled=true
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n launchpad-development
kubectl describe pod <pod-name> -n launchpad-development
```

### View Logs

```bash
# API logs
kubectl logs -n launchpad-development -l app.kubernetes.io/component=api --tail=100 -f

# Client logs
kubectl logs -n launchpad-development -l app.kubernetes.io/component=client --tail=100 -f
```

### Check Ingress

```bash
kubectl get ingress -n launchpad-development
kubectl describe ingress -n launchpad-development
```

### Port Forward for Testing

```bash
# Forward API port
kubectl port-forward -n launchpad-development svc/launchpad-api 3001:3001

# Forward Client port
kubectl port-forward -n launchpad-development svc/launchpad-client 8080:80
```

## Notes

- For local development with Kind, use the helper script `./k8s/scripts/k8s-setup-kind.sh` to set up the cluster
- The chart creates a ServiceAccount for each deployment
- Resource limits and requests are configured for optimal performance
- Liveness and readiness probes are included for both services
- Horizontal Pod Autoscaling can be enabled per service
