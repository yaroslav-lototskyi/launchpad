#!/bin/bash

set -e

MODE=${1:-prod}

if [ "$MODE" = "dev" ]; then
  echo "🛑 Stopping Launchpad (development)..."
  docker compose -f deployment/development/docker-compose.yml down
elif [ "$MODE" = "prod" ]; then
  echo "🛑 Stopping Launchpad (production)..."
  docker compose -f deployment/production/docker-compose.yml down
else
  echo "❌ Invalid mode: $MODE"
  echo "Usage: ./scripts/docker-down.sh [dev|prod]"
  exit 1
fi

echo "✅ Containers stopped"
