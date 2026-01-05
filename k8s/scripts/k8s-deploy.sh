#!/bin/bash
set -e

ENVIRONMENT="${1:-development}"
NAMESPACE="${2:-launchpad-$ENVIRONMENT}"
RELEASE_NAME="launchpad"

echo "🚀 Deploying Launchpad to Kubernetes..."
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo "Release: $RELEASE_NAME"
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed. Please install it first:"
    echo "   brew install helm"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi

# Create namespace if it doesn't exist
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "📁 Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE
fi

# Validate values file exists
VALUES_FILE="k8s/helm/launchpad/values-$ENVIRONMENT.yaml"
if [ ! -f "$VALUES_FILE" ]; then
    echo "⚠️  Values file not found: $VALUES_FILE"
    echo "Using default values.yaml"
    VALUES_FILE="k8s/helm/launchpad/values.yaml"
fi

# Deploy with Helm
echo "📦 Deploying Helm chart..."
helm upgrade --install $RELEASE_NAME \
  ./k8s/helm/launchpad \
  --namespace $NAMESPACE \
  --values $VALUES_FILE \
  --wait \
  --timeout 5m \
  --create-namespace

echo ""
echo "✅ Deployment successful!"
echo ""
echo "📊 Checking deployment status..."
kubectl get pods -n $NAMESPACE
echo ""
kubectl get services -n $NAMESPACE
echo ""
kubectl get ingress -n $NAMESPACE
echo ""
echo "🌐 Access the application via Ingress hostname"
echo ""
echo "📝 View logs:"
echo "   kubectl logs -n $NAMESPACE -l app.kubernetes.io/component=api --tail=50 -f"
echo "   kubectl logs -n $NAMESPACE -l app.kubernetes.io/component=client --tail=50 -f"
echo ""
echo "🔍 Debug:"
echo "   kubectl get all -n $NAMESPACE"
echo "   kubectl describe ingress -n $NAMESPACE"
