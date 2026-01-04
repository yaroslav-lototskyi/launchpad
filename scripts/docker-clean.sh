#!/bin/bash

set -e

echo "🧹 Cleaning Docker resources for Launchpad..."

# Stop and remove containers
echo "Stopping containers..."
docker compose -f deployment/production/docker-compose.yml down 2>/dev/null || true
docker compose -f deployment/development/docker-compose.yml down 2>/dev/null || true

# Remove images
echo "Removing images..."
docker rmi launchpad/api:production 2>/dev/null || true
docker rmi launchpad/api:latest 2>/dev/null || true
docker rmi launchpad/api:development 2>/dev/null || true
docker rmi launchpad/client:production 2>/dev/null || true
docker rmi launchpad/client:latest 2>/dev/null || true
docker rmi launchpad/client:development 2>/dev/null || true

# Remove dangling images
echo "Removing dangling images..."
docker image prune -f

# Remove volumes (optional)
read -p "Do you want to remove volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  docker volume prune -f
fi

echo "✅ Cleanup complete!"
