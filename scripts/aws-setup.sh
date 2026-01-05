#!/bin/bash

# AWS Infrastructure Setup Script for Launchpad
# This script initializes and applies Terraform configuration for AWS infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="${1:-development}"
ACTION="${2:-plan}"
TERRAFORM_DIR="infra/terraform"
ENV_DIR="$TERRAFORM_DIR/environments/$ENVIRONMENT"

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    echo "Usage: $0 [environment] [action]"
    echo "  environment: development, staging, or production (default: development)"
    echo "  action: plan, apply, or destroy (default: plan)"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    print_error "Invalid action: $ACTION"
    echo "Valid actions: plan, apply, destroy"
    exit 1
fi

# Check if environment directory exists
if [ ! -d "$ENV_DIR" ]; then
    print_error "Environment directory not found: $ENV_DIR"
    exit 1
fi

# Check if tfvars file exists
if [ ! -f "$ENV_DIR/terraform.tfvars" ]; then
    print_error "Terraform variables file not found: $ENV_DIR/terraform.tfvars"
    exit 1
fi

print_info "========================================="
print_info "AWS Infrastructure Setup"
print_info "========================================="
print_info "Environment: $ENVIRONMENT"
print_info "Action: $ACTION"
print_info "Terraform Dir: $TERRAFORM_DIR"
print_info "========================================="

# Check for AWS credentials
if [ -z "$AWS_ACCESS_KEY_ID" ] && [ -z "$AWS_PROFILE" ]; then
    print_warn "AWS credentials not found in environment"
    print_info "Make sure you have configured AWS credentials:"
    echo "  - Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
    echo "  - Or set AWS_PROFILE"
    echo "  - Or run 'aws configure'"
fi

# Navigate to Terraform directory
cd "$TERRAFORM_DIR"

# Initialize Terraform
print_info "Initializing Terraform..."
terraform init \
    -backend-config="key=terraform-${ENVIRONMENT}.tfstate" \
    -reconfigure

# Select or create workspace
print_info "Selecting Terraform workspace: $ENVIRONMENT"
terraform workspace select "$ENVIRONMENT" 2>/dev/null || terraform workspace new "$ENVIRONMENT"

# Run Terraform command
case $ACTION in
    plan)
        print_info "Running Terraform plan..."
        terraform plan \
            -var-file="environments/${ENVIRONMENT}/terraform.tfvars" \
            -out="terraform-${ENVIRONMENT}.tfplan"

        print_info "========================================="
        print_info "Plan completed successfully!"
        print_info "To apply this plan, run:"
        echo "  ./scripts/aws-setup.sh $ENVIRONMENT apply"
        print_info "========================================="
        ;;

    apply)
        print_warn "This will create/modify AWS resources in $ENVIRONMENT environment"
        read -p "Are you sure you want to continue? (yes/no): " confirm

        if [ "$confirm" != "yes" ]; then
            print_info "Operation cancelled"
            exit 0
        fi

        print_info "Applying Terraform configuration..."
        terraform apply \
            -var-file="environments/${ENVIRONMENT}/terraform.tfvars" \
            -auto-approve

        print_info "========================================="
        print_info "Infrastructure deployed successfully!"
        print_info "========================================="

        # Show outputs
        print_info "Outputs:"
        terraform output

        print_info "========================================="
        print_info "Next steps:"
        echo "  1. Configure kubectl:"
        terraform output -raw configure_kubectl
        echo ""
        echo "  2. Verify cluster connection:"
        echo "     kubectl get nodes"
        echo ""
        echo "  3. Deploy application:"
        echo "     ./scripts/k8s-deploy.sh $ENVIRONMENT"
        print_info "========================================="
        ;;

    destroy)
        print_error "WARNING: This will destroy all AWS resources in $ENVIRONMENT environment!"
        print_error "This action cannot be undone!"
        read -p "Type 'destroy-$ENVIRONMENT' to confirm: " confirm

        if [ "$confirm" != "destroy-$ENVIRONMENT" ]; then
            print_info "Operation cancelled"
            exit 0
        fi

        print_info "Destroying Terraform resources..."
        terraform destroy \
            -var-file="environments/${ENVIRONMENT}/terraform.tfvars" \
            -auto-approve

        print_info "========================================="
        print_info "Infrastructure destroyed successfully!"
        print_info "========================================="
        ;;
esac

cd - > /dev/null
