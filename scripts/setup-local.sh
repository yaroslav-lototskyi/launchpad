#!/bin/bash

# Setup script for local development
set -e

echo "🚀 Setting up local development environment..."

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js >= 20.0.0"
    exit 1
fi

if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm is not installed. Installing pnpm..."
    npm install -g pnpm
fi

echo "✅ Prerequisites check passed"

# Install dependencies
echo "📦 Installing dependencies..."
pnpm install

# Copy environment files
echo "📝 Setting up environment files..."

if [ ! -f apps/api/.env ]; then
    cp apps/api/.env.example apps/api/.env
    echo "✅ Created apps/api/.env"
else
    echo "⏭️  apps/api/.env already exists"
fi

if [ ! -f apps/client/.env ]; then
    cp apps/client/.env.example apps/client/.env
    echo "✅ Created apps/client/.env"
else
    echo "⏭️  apps/client/.env already exists"
fi

# Setup git hooks
if [ -d .git ]; then
    echo "🪝 Setting up git hooks..."
    pnpm prepare
    echo "✅ Git hooks installed"
fi

echo ""
echo "✨ Setup complete! You can now run:"
echo ""
echo "  pnpm dev       # Start development servers"
echo "  pnpm build     # Build all packages"
echo "  pnpm test      # Run tests"
echo ""
echo "🌐 URLs:"
echo "  Frontend: http://localhost:5173"
echo "  Backend:  http://localhost:3001"
echo "  Health:   http://localhost:3001/api/v1/health"
echo ""
