#!/bin/bash

# Pre-commit check script
set -e

echo "🔍 Running pre-commit checks..."

echo "1️⃣  Type checking..."
pnpm type-check

echo "2️⃣  Linting..."
pnpm lint

echo "3️⃣  Formatting check..."
pnpm format --check || {
    echo "❌ Code is not formatted. Run 'pnpm format' to fix."
    exit 1
}

echo "4️⃣  Building..."
pnpm build

echo "5️⃣  Running tests..."
pnpm test

echo "✅ All checks passed!"
