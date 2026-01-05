#!/bin/bash

# AWS ECR Login Script for Launchpad
# Authenticates Docker with AWS ECR

set -e

# Colors for output
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

# Default region
AWS_REGION="${1:-us-east-1}"

print_info "========================================="
print_info "AWS ECR Login"
print_info "========================================="
print_info "Region: $AWS_REGION"
print_info "========================================="

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    echo "Install it with: brew install awscli"
    exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

# Get AWS account ID
print_info "Getting AWS account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$AWS_ACCOUNT_ID" ]; then
    print_error "Failed to get AWS account ID"
    print_error "Make sure AWS credentials are configured"
    exit 1
fi

print_info "AWS Account ID: $AWS_ACCOUNT_ID"

# Login to ECR
print_info "Logging in to ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

print_info "========================================="
print_info "Successfully logged in to ECR!"
print_info "========================================="
print_info "ECR Registry: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
print_info ""
print_info "You can now push images:"
echo "  docker tag launchpad/api:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/launchpad/api:latest"
echo "  docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/launchpad/api:latest"
print_info "========================================="
