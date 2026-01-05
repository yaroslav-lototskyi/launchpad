#!/bin/bash

# Configure Argo CD Application with dynamic values
# This script replaces placeholders in Argo CD Application manifests

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

# Get GitHub repo info from git remote
get_github_info() {
    local remote_url=$(git config --get remote.origin.url)

    if [[ -z "$remote_url" ]]; then
        print_error "No git remote found"
        exit 1
    fi

    # Extract org and repo from URL
    # Supports both HTTPS and SSH URLs
    if [[ $remote_url =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
        GITHUB_ORG="${BASH_REMATCH[1]}"
        GITHUB_REPO="${BASH_REMATCH[2]}"
    else
        print_error "Could not parse GitHub URL: $remote_url"
        exit 1
    fi
}

# Replace placeholders in file
configure_file() {
    local file=$1
    local output=$2

    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi

    print_info "Configuring: $file"

    # Replace placeholders
    sed -e "s|{{GITHUB_ORG}}|$GITHUB_ORG|g" \
        -e "s|{{GITHUB_REPO}}|$GITHUB_REPO|g" \
        "$file" > "$output"

    print_info "Created: $output"
}

# Main script
main() {
    print_info "========================================="
    print_info "Argo CD Application Configuration"
    print_info "========================================="

    # Get GitHub info
    print_info "Detecting GitHub repository info..."
    get_github_info

    print_info "GitHub Organization: $GITHUB_ORG"
    print_info "GitHub Repository: $GITHUB_REPO"
    print_info "========================================="

    # Configure application
    local app_template="k8s/argocd/apps/launchpad-development.yaml"
    local app_output="k8s/argocd/apps/launchpad-development.configured.yaml"

    configure_file "$app_template" "$app_output"

    print_info "========================================="
    print_info "Configuration complete!"
    print_info "========================================="
    echo ""
    print_info "Next steps:"
    echo ""
    echo "  1. Review the configured file:"
    echo "     cat $app_output"
    echo ""
    echo "  2. Apply to cluster:"
    echo "     kubectl apply -f $app_output"
    echo ""
    echo "  3. Or apply directly:"
    echo "     kubectl apply -f k8s/argocd/projects/development.yaml"
    echo "     cat $app_output | kubectl apply -f -"
    echo ""
    print_info "========================================="
}

# Run main
main
