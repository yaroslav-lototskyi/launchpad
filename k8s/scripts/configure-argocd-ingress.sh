#!/bin/bash

# Configure Argo CD Ingress with dynamic domain

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

# Get base domain
BASE_DOMAIN="${BASE_DOMAIN:-}"

if [[ -n "$1" ]]; then
    BASE_DOMAIN="$1"
fi

if [[ -z "$BASE_DOMAIN" ]]; then
    print_warn "BASE_DOMAIN not set"
    read -p "Enter base domain (e.g., example.com): " BASE_DOMAIN

    if [[ -z "$BASE_DOMAIN" ]]; then
        print_error "BASE_DOMAIN is required"
        exit 1
    fi
fi

print_info "========================================="
print_info "Argo CD Ingress Configuration"
print_info "========================================="
print_info "Base Domain: $BASE_DOMAIN"
print_info "Argo CD will be accessible at: argocd.$BASE_DOMAIN"
print_info "========================================="

# Configure ingress
TEMPLATE="k8s/argocd/install/argocd-ingress.template.yaml"
OUTPUT="k8s/argocd/install/argocd-ingress.yaml"

if [[ ! -f "$TEMPLATE" ]]; then
    print_warn "Template not found, using existing file"
    exit 0
fi

sed "s|{{BASE_DOMAIN}}|$BASE_DOMAIN|g" "$TEMPLATE" > "$OUTPUT"

print_info "Created: $OUTPUT"
print_info ""
print_info "Next steps:"
echo ""
echo "  1. Apply Ingress:"
echo "     kubectl apply -f $OUTPUT"
echo ""
echo "  2. Add to /etc/hosts:"
echo "     sudo sh -c 'echo \"<EC2-IP> argocd.$BASE_DOMAIN\" >> /etc/hosts'"
echo ""
echo "  3. Access Argo CD:"
echo "     http://argocd.$BASE_DOMAIN"
echo ""
print_info "========================================="
