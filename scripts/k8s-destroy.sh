#!/bin/bash
set -e

ENVIRONMENT="${1:-development}"
NAMESPACE="launchpad-$ENVIRONMENT"
RELEASE_NAME="launchpad"

echo "🗑️  Destroying Launchpad deployment..."
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo "Release: $RELEASE_NAME"
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed"
    exit 1
fi

# Uninstall Helm release
if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
    echo "🔥 Uninstalling Helm release: $RELEASE_NAME"
    helm uninstall $RELEASE_NAME -n $NAMESPACE
    echo "✅ Helm release uninstalled"
else
    echo "ℹ️  Helm release not found: $RELEASE_NAME"
fi

# Delete namespace
if kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "🗑️  Deleting namespace: $NAMESPACE"
    kubectl delete namespace $NAMESPACE --timeout=60s
    echo "✅ Namespace deleted"
else
    echo "ℹ️  Namespace not found: $NAMESPACE"
fi

echo ""
echo "✅ Cleanup complete!"
