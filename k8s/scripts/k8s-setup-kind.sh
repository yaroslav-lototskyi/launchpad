#!/bin/bash
set -e

echo "🚀 Setting up local Kubernetes cluster with Kind..."

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ kind is not installed. Please install it first:"
    echo "   brew install kind"
    echo "   or visit: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first:"
    echo "   brew install kubectl"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed. Please install it first:"
    echo "   brew install helm"
    exit 1
fi

CLUSTER_NAME="${1:-launchpad-local}"

echo "📋 Creating Kind cluster: $CLUSTER_NAME"

# Create kind cluster with ingress support
cat <<EOF | kind create cluster --name $CLUSTER_NAME --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

echo "✅ Kind cluster created successfully"

# Install NGINX Ingress Controller
echo "📦 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
echo "⏳ Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo "✅ NGINX Ingress Controller is ready"

# Note: Add your domain to /etc/hosts manually
# Example: echo "127.0.0.1 your-domain.local" | sudo tee -a /etc/hosts

echo "✅ Kind cluster setup complete!"
echo ""
echo "Next steps:"
echo "1. Add your domain to /etc/hosts:"
echo "   echo \"127.0.0.1 your-domain.local\" | sudo tee -a /etc/hosts"
echo ""
echo "2. Deploy the application:"
echo "   ./k8s/scripts/k8s-deploy.sh development"
echo ""
echo "3. To delete the cluster:"
echo "   kind delete cluster --name $CLUSTER_NAME"
