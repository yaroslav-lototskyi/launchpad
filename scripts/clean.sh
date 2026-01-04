#!/bin/bash

# Clean script - removes all build artifacts and dependencies
set -e

echo "🧹 Cleaning project..."

# Clean turbo cache
echo "Cleaning turbo cache..."
rm -rf .turbo

# Clean all node_modules
echo "Removing all node_modules..."
rm -rf node_modules
rm -rf apps/*/node_modules
rm -rf packages/*/node_modules

# Clean all build outputs
echo "Removing build outputs..."
rm -rf apps/*/dist
rm -rf apps/*/build
rm -rf packages/*/dist

# Clean test coverage
echo "Removing test coverage..."
rm -rf apps/*/coverage
rm -rf packages/*/coverage

echo "✅ Clean complete!"
echo ""
echo "Run 'pnpm install' to reinstall dependencies"
