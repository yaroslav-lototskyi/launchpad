#!/bin/bash

# Argo CD Setup Script for Launchpad
# Installs and configures Argo CD in Kubernetes cluster

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
ARGOCD_VERSION="${1:-v2.9.3}"
NAMESPACE="argocd"

print_info "========================================="
print_info "Argo CD Setup for Launchpad"
print_info "========================================="
print_info "Version: $ARGOCD_VERSION"
print_info "Namespace: $NAMESPACE"
print_info "========================================="

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    print_info "Configure kubectl first:"
    echo "  kubectl config current-context"
    exit 1
fi

print_info "Connected to cluster: $(kubectl config current-context)"

# Create namespace
print_info "Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Install Argo CD
print_info "Installing Argo CD $ARGOCD_VERSION..."
kubectl apply -n $NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml

# Wait for Argo CD to be ready
print_info "Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/argocd-server \
    deployment/argocd-repo-server \
    deployment/argocd-application-controller \
    -n $NAMESPACE

print_info "Argo CD pods:"
kubectl get pods -n $NAMESPACE

# Install Argo CD CLI (optional)
if ! command -v argocd &> /dev/null; then
    print_warn "Argo CD CLI not found"
    print_info "Install it with:"
    echo "  brew install argocd"
    echo "  # or"
    echo "  curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$ARGOCD_VERSION/argocd-darwin-amd64"
    echo "  chmod +x /usr/local/bin/argocd"
fi

# Get initial admin password
print_info "========================================="
print_info "Getting initial admin password..."
ARGOCD_PASSWORD=$(kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

print_info "========================================="
print_info "Argo CD installed successfully!"
print_info "========================================="
print_info "Access Argo CD:"
echo ""
echo "  1. Port-forward:"
echo "     kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "  2. Login:"
echo "     URL: https://localhost:8080"
echo "     Username: admin"
echo "     Password: $ARGOCD_PASSWORD"
echo ""
print_info "========================================="
print_info "Next steps:"
echo ""
echo "  1. Apply Ingress (optional):"
echo "     kubectl apply -f infra/argocd/install/argocd-ingress.yaml"
echo ""
echo "  2. Install Argo CD Image Updater:"
echo "     kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml"
echo ""
echo "  3. Create Projects:"
echo "     kubectl apply -f infra/argocd/projects/"
echo ""
echo "  4. Create Applications:"
echo "     kubectl apply -f infra/argocd/apps/"
echo ""
print_info "========================================="

# Optionally install Image Updater
read -p "Install Argo CD Image Updater? (y/n): " install_updater

if [ "$install_updater" == "y" ]; then
    print_info "Installing Argo CD Image Updater..."
    kubectl apply -n $NAMESPACE -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml

    print_info "Waiting for Image Updater to be ready..."
    kubectl wait --for=condition=available --timeout=120s \
        deployment/argocd-image-updater \
        -n $NAMESPACE || true

    print_info "Image Updater installed!"
fi

print_info "Setup complete! 🚀"
