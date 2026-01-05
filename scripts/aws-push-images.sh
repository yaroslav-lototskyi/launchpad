#!/bin/bash

# AWS ECR Push Images Script for Launchpad
# Builds and pushes Docker images to AWS ECR

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

# Parameters
ENVIRONMENT="${1:-development}"
IMAGE_TAG="${2:-latest}"
AWS_REGION="${3:-us-east-1}"

print_info "========================================="
print_info "AWS ECR Push Images"
print_info "========================================="
print_info "Environment: $ENVIRONMENT"
print_info "Image Tag: $IMAGE_TAG"
print_info "AWS Region: $AWS_REGION"
print_info "========================================="

# Get AWS account ID
print_info "Getting AWS account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$AWS_ACCOUNT_ID" ]; then
    print_error "Failed to get AWS account ID"
    exit 1
fi

ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
print_info "ECR Registry: $ECR_REGISTRY"

# Login to ECR
print_info "Logging in to ECR..."
./scripts/aws-ecr-login.sh "$AWS_REGION"

# Build and push API image
print_info "Building API image..."
docker build \
    -f apps/api/deployment/production/Dockerfile \
    -t launchpad/api:$IMAGE_TAG \
    -t $ECR_REGISTRY/launchpad/api:$IMAGE_TAG \
    -t $ECR_REGISTRY/launchpad/api:$ENVIRONMENT \
    .

print_info "Pushing API image to ECR..."
docker push $ECR_REGISTRY/launchpad/api:$IMAGE_TAG
docker push $ECR_REGISTRY/launchpad/api:$ENVIRONMENT

# Build and push Client image
print_info "Building Client image..."
docker build \
    -f apps/client/deployment/production/Dockerfile \
    -t launchpad/client:$IMAGE_TAG \
    -t $ECR_REGISTRY/launchpad/client:$IMAGE_TAG \
    -t $ECR_REGISTRY/launchpad/client:$ENVIRONMENT \
    .

print_info "Pushing Client image to ECR..."
docker push $ECR_REGISTRY/launchpad/client:$IMAGE_TAG
docker push $ECR_REGISTRY/launchpad/client:$ENVIRONMENT

print_info "========================================="
print_info "Images pushed successfully!"
print_info "========================================="
print_info "API Image: $ECR_REGISTRY/launchpad/api:$IMAGE_TAG"
print_info "Client Image: $ECR_REGISTRY/launchpad/client:$IMAGE_TAG"
print_info "========================================="
print_info "Next steps:"
echo "  1. Update Helm values to use ECR images"
echo "  2. Deploy to EKS cluster:"
echo "     ./scripts/k8s-deploy.sh $ENVIRONMENT"
print_info "========================================="
