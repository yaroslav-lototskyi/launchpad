#!/bin/bash

# Configure Argo CD ApplicationSet with dynamic values

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

# Get GitHub repo info
get_github_info() {
    local remote_url=$(git config --get remote.origin.url)

    if [[ -z "$remote_url" ]]; then
        print_error "No git remote found"
        exit 1
    fi

    if [[ $remote_url =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
        GITHUB_ORG="${BASH_REMATCH[1]}"
        GITHUB_REPO="${BASH_REMATCH[2]}"
    else
        print_error "Could not parse GitHub URL: $remote_url"
        exit 1
    fi
}

# Get base domain
get_base_domain() {
    # Try to get from environment or use default
    BASE_DOMAIN="${BASE_DOMAIN:-}"

    if [[ -z "$BASE_DOMAIN" ]]; then
        print_warn "BASE_DOMAIN not set"
        read -p "Enter base domain (e.g., example.com): " BASE_DOMAIN

        if [[ -z "$BASE_DOMAIN" ]]; then
            print_error "BASE_DOMAIN is required"
            exit 1
        fi
    fi
}

# Main script
main() {
    print_info "========================================="
    print_info "Argo CD ApplicationSet Configuration"
    print_info "========================================="

    # Get info
    print_info "Detecting repository information..."
    get_github_info
    get_base_domain

    print_info "GitHub Organization: $GITHUB_ORG"
    print_info "GitHub Repository: $GITHUB_REPO"
    print_info "Base Domain: $BASE_DOMAIN"
    print_info "========================================="

    # Configure files
    local template="k8s/argocd/applicationsets/launchpad-previews.yaml"
    local output="k8s/argocd/applicationsets/launchpad-previews.configured.yaml"

    if [[ ! -f "$template" ]]; then
        print_error "Template not found: $template"
        exit 1
    fi

    print_info "Configuring ApplicationSet..."

    sed -e "s|{{GITHUB_ORG}}|$GITHUB_ORG|g" \
        -e "s|{{GITHUB_REPO}}|$GITHUB_REPO|g" \
        -e "s|{{BASE_DOMAIN}}|$BASE_DOMAIN|g" \
        "$template" > "$output"

    print_info "Created: $output"
    print_info "========================================="
    print_info "Configuration complete!"
    print_info "========================================="
    echo ""
    print_info "Next steps:"
    echo ""
    echo "  1. Create GitHub token (if not exists):"
    echo "     https://github.com/settings/tokens/new"
    echo "     Scope: repo (public_repo for public repos)"
    echo ""
    echo "  2. Create Kubernetes secret:"
    echo "     kubectl create secret generic github-token \\"
    echo "       --from-literal=token=YOUR_GITHUB_TOKEN \\"
    echo "       -n argocd"
    echo ""
    echo "  3. Apply ApplicationSet:"
    echo "     kubectl apply -f $output"
    echo ""
    echo "  4. Verify:"
    echo "     kubectl get applicationset -n argocd"
    echo ""
    echo "  5. Usage:"
    echo "     - Create PR"
    echo "     - Add label 'deploy' to PR"
    echo "     - Wait ~3 minutes"
    echo "     - Preview at: preview-pr-{NUMBER}.${BASE_DOMAIN}"
    echo ""
    print_info "========================================="
}

# Run
main
