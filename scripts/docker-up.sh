#!/bin/bash

set -e

MODE=${1:-prod}

if [ "$MODE" = "dev" ]; then
  echo "🚀 Starting Launchpad in DEVELOPMENT mode with hot reload..."
  docker compose -f deployment/development/docker-compose.yml up --build
elif [ "$MODE" = "prod" ]; then
  echo "🚀 Starting Launchpad in PRODUCTION mode..."
  docker compose -f deployment/production/docker-compose.yml up --build
else
  echo "❌ Invalid mode: $MODE"
  echo "Usage: ./scripts/docker-up.sh [dev|prod]"
  exit 1
fi
