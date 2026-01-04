#!/bin/bash

set -e

echo "🔨 Building Docker images for Launchpad..."

# Build API
echo "📦 Building API image..."
docker build -f apps/api/deployment/production/Dockerfile -t launchpad/api:production -t launchpad/api:latest .

# Build Client
echo "📦 Building Client image..."
docker build -f apps/client/deployment/production/Dockerfile -t launchpad/client:production -t launchpad/client:latest .

echo "✅ Docker images built successfully!"
echo ""
echo "Images created:"
echo "  - launchpad/api:production"
echo "  - launchpad/api:latest"
echo "  - launchpad/client:production"
echo "  - launchpad/client:latest"
