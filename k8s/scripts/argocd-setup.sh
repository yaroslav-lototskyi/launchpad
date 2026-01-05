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
CUSTOM_PASSWORD="${ARGOCD_ADMIN_PASSWORD:-}"  # Can set via env var

print_info "========================================="
print_info "Argo CD Setup for Launchpad"
print_info "========================================="
print_info "Version: $ARGOCD_VERSION"
print_info "Namespace: $NAMESPACE"
if [[ -n "$CUSTOM_PASSWORD" ]]; then
    print_info "Custom admin password will be set"
fi
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

# Check if Argo CD is already installed
if kubectl get deployment argocd-server -n $NAMESPACE &> /dev/null; then
    print_warn "Argo CD is already installed, skipping installation..."
else
    # Install Argo CD
    print_info "Installing Argo CD $ARGOCD_VERSION..."
    kubectl apply -n $NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml
fi

# Wait for Argo CD to be ready
print_info "Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/argocd-server \
    deployment/argocd-repo-server \
    -n $NAMESPACE

# Wait for application controller (StatefulSet)
kubectl wait --for=condition=ready --timeout=300s \
    pod -l app.kubernetes.io/name=argocd-application-controller \
    -n $NAMESPACE

print_info "Argo CD pods:"
kubectl get pods -n $NAMESPACE

# Configure Argo CD for HTTP access (insecure mode for local development)
print_info "Configuring Argo CD for HTTP access..."
kubectl patch configmap argocd-cmd-params-cm -n $NAMESPACE --type merge \
  -p '{"data":{"server.insecure":"true"}}' 2>/dev/null || \
  kubectl create configmap argocd-cmd-params-cm -n $NAMESPACE \
  --from-literal=server.insecure=true

# Restart Argo CD server to apply changes
print_info "Restarting Argo CD server..."
kubectl rollout restart deployment/argocd-server -n $NAMESPACE
kubectl rollout status deployment/argocd-server -n $NAMESPACE --timeout=120s

# Install Argo CD CLI (optional)
if ! command -v argocd &> /dev/null; then
    print_warn "Argo CD CLI not found"
    print_info "Install it with:"
    echo "  brew install argocd"
    echo "  # or"
    echo "  curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$ARGOCD_VERSION/argocd-darwin-amd64"
    echo "  chmod +x /usr/local/bin/argocd"
fi

# Get or set admin password
print_info "========================================="

if [[ -n "$CUSTOM_PASSWORD" ]]; then
    print_info "Setting custom admin password..."

    # Get current password first
    CURRENT_PASSWORD=$(kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "")

    if [[ -z "$CURRENT_PASSWORD" ]]; then
        print_error "Could not get initial password. Wait for Argo CD to be fully ready."
        exit 1
    fi

    # Use argocd CLI to change password (requires argocd CLI)
    if command -v argocd &> /dev/null; then
        # Login with initial password
        argocd login --core

        # Update password
        argocd account update-password \
          --current-password "$CURRENT_PASSWORD" \
          --new-password "$CUSTOM_PASSWORD"

        print_info "Custom password set successfully!"
    else
        print_warn "argocd CLI not found. Using kubectl method..."

        # Fallback: try htpasswd if available
        if command -v htpasswd &> /dev/null; then
            BCRYPT_HASH=$(htpasswd -nbBC 10 "" "$CUSTOM_PASSWORD" | tr -d ':\n' | sed 's/^//')

            kubectl -n $NAMESPACE patch secret argocd-secret \
              -p "{\"stringData\": {\"admin.password\": \"$BCRYPT_HASH\", \"admin.passwordMtime\": \"$(date +%FT%T%Z)\"}}"

            print_info "Custom password set successfully!"
        else
            print_warn "Neither argocd CLI nor htpasswd found."
            print_warn "Using generated password. Install argocd CLI to set custom password:"
            echo "  brew install argocd  # macOS"
            echo "  # or download from: https://github.com/argoproj/argo-cd/releases"
            CUSTOM_PASSWORD=""  # Reset to use generated password
        fi
    fi

    if [[ -n "$CUSTOM_PASSWORD" ]]; then
        ARGOCD_PASSWORD="$CUSTOM_PASSWORD"
        # Delete initial admin secret (for security)
        kubectl -n $NAMESPACE delete secret argocd-initial-admin-secret 2>/dev/null || true
    else
        ARGOCD_PASSWORD="$CURRENT_PASSWORD"
    fi
else
    print_info "Getting initial admin password..."
    ARGOCD_PASSWORD=$(kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null)

    if [[ -z "$ARGOCD_PASSWORD" ]]; then
        print_warn "Could not retrieve initial password. It may have been deleted."
        print_warn "Reset password with: argocd account update-password"
    else
        print_info "Generated password retrieved"
    fi
fi

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
if [[ -z "$CUSTOM_PASSWORD" ]]; then
    echo "  💡 Tip: Set custom password next time:"
    echo "     ARGOCD_ADMIN_PASSWORD='your-password' ./k8s/scripts/argocd-setup.sh"
    echo ""
fi
print_info "========================================="
print_info "Next steps:"
echo ""
echo "  1. Apply Ingress (optional):"
echo "     kubectl apply -f k8s/argocd/install/argocd-ingress.yaml"
echo ""
echo "  2. Install Argo CD Image Updater:"
echo "     kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/v0.15.0/manifests/install.yaml"
echo ""
echo "  3. Create Projects:"
echo "     kubectl apply -f k8s/argocd/projects/"
echo ""
echo "  4. Create Applications:"
echo "     kubectl apply -f k8s/argocd/apps/"
echo ""
print_info "========================================="

# Optionally install Image Updater
if kubectl get deployment argocd-image-updater -n $NAMESPACE &> /dev/null; then
    print_warn "Argo CD Image Updater is already installed"
else
    read -p "Install Argo CD Image Updater? (y/n): " install_updater

    if [ "$install_updater" == "y" ]; then
        print_info "Installing Argo CD Image Updater..."
        kubectl apply -n $NAMESPACE -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/v0.15.0/manifests/install.yaml

        print_info "Waiting for Image Updater to be ready..."
        kubectl wait --for=condition=available --timeout=120s \
            deployment/argocd-image-updater \
            -n $NAMESPACE || true

        print_info "Image Updater installed!"
    fi
fi

print_info "Setup complete! 🚀"
