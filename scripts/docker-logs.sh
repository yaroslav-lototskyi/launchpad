#!/bin/bash

SERVICE=${1:-}
MODE=${2:-prod}

if [ -z "$SERVICE" ]; then
  echo "Usage: ./scripts/docker-logs.sh [api|client] [dev|prod]"
  exit 1
fi

COMPOSE_FILE="deployment/production/docker-compose.yml"
if [ "$MODE" = "dev" ]; then
  COMPOSE_FILE="deployment/development/docker-compose.yml"
fi

if [ "$SERVICE" = "api" ]; then
  docker compose -f $COMPOSE_FILE logs -f api
elif [ "$SERVICE" = "client" ]; then
  docker compose -f $COMPOSE_FILE logs -f client
else
  echo "❌ Invalid service: $SERVICE"
  echo "Available services: api, client"
  exit 1
fi
