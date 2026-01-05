# Launchpad AWS Infrastructure with Terraform

This directory contains Terraform configuration for deploying Launchpad infrastructure on AWS.

## Architecture Overview

The infrastructure includes:

- **VPC**: Virtual Private Cloud with public and private subnets across multiple availability zones
- **EKS**: Managed Kubernetes cluster for running containers
- **ECR**: Container registry for Docker images
- **IAM**: Roles and policies for EKS cluster and node groups
- **NAT Gateway**: For private subnet internet access
- **OIDC Provider**: For IAM Roles for Service Accounts (IRSA)

## Directory Structure

```
terraform/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Global variables
├── outputs.tf                 # Output values
├── modules/
│   ├── vpc/                  # VPC module
│   ├── eks/                  # EKS cluster module
│   ├── ecr/                  # ECR repositories module
│   └── iam/                  # IAM roles and policies module
└── environments/
    ├── development/          # Development environment config
    ├── staging/              # Staging environment config
    └── production/           # Production environment config
```

## Prerequisites

1. **AWS CLI**:

   ```bash
   brew install awscli
   aws configure
   ```

2. **Terraform**:

   ```bash
   brew install terraform
   ```

3. **kubectl**:

   ```bash
   brew install kubectl
   ```

4. **AWS Credentials**: Configure AWS credentials with appropriate permissions:
   - VPC management
   - EKS cluster creation
   - ECR repository management
   - IAM role creation
   - EC2 instance management

## Quick Start

### 1. Initialize Terraform

```bash
cd infra/terraform
terraform init
```

### 2. Plan Infrastructure (Development)

```bash
./scripts/aws-setup.sh development plan
```

### 3. Apply Infrastructure

```bash
./scripts/aws-setup.sh development apply
```

### 4. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name launchpad-development
kubectl get nodes
```

### 5. Push Images to ECR

```bash
./scripts/aws-push-images.sh development latest
```

### 6. Deploy Application

```bash
./scripts/k8s-deploy.sh development
```

## Environment Configurations

### Development

- **Purpose**: Local development and testing
- **VPC**: 10.0.0.0/16
- **Subnets**: 2 AZs
- **NAT Gateway**: Single (cost optimization)
- **EKS Nodes**: 1-3 t3.small SPOT instances
- **Cost**: ~$50-100/month

### Staging

- **Purpose**: Pre-production testing
- **VPC**: 10.1.0.0/16
- **Subnets**: 3 AZs
- **NAT Gateway**: 3 (high availability)
- **EKS Nodes**: 2-5 t3.medium ON_DEMAND instances
- **Cost**: ~$150-300/month

### Production

- **Purpose**: Production workloads
- **VPC**: 10.2.0.0/16
- **Subnets**: 3 AZs
- **NAT Gateway**: 3 (high availability)
- **EKS Nodes**: 3-10 t3.large ON_DEMAND instances
- **Cost**: ~$500-1000/month

## Terraform Modules

### VPC Module

Creates VPC with:

- Public subnets for load balancers
- Private subnets for EKS nodes
- Internet Gateway
- NAT Gateways
- Route tables

**Key Features**:

- Multi-AZ deployment
- Kubernetes tags for subnet discovery
- Configurable NAT Gateway (single or per AZ)

### EKS Module

Creates EKS cluster with:

- Control plane
- Node groups
- Security groups
- OIDC provider for IRSA

**Key Features**:

- Configurable Kubernetes version
- Auto-scaling node groups
- Public/private endpoint access
- CloudWatch logging

### ECR Module

Creates ECR repositories with:

- Image scanning on push
- Lifecycle policies
- Encryption at rest

**Repositories**:

- `launchpad/api`
- `launchpad/client`

### IAM Module

Creates IAM roles for:

- EKS cluster
- EKS node groups
- ALB controller
- Custom ECR access

## Customization

### Modify Environment Configuration

Edit the appropriate tfvars file:

```bash
# Development
vim infra/terraform/environments/development/terraform.tfvars

# Staging
vim infra/terraform/environments/staging/terraform.tfvars

# Production
vim infra/terraform/environments/production/terraform.tfvars
```

### Add More Node Groups

```hcl
# terraform.tfvars
eks_node_groups = {
  general = {
    desired_size   = 2
    min_size       = 1
    max_size       = 5
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
  }
  compute = {
    desired_size   = 1
    min_size       = 0
    max_size       = 10
    instance_types = ["c5.large"]
    capacity_type  = "SPOT"
    disk_size      = 30
  }
}
```

### Change AWS Region

```hcl
# terraform.tfvars
aws_region = "eu-west-1"
availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
```

## Terraform Commands

### Initialize

```bash
terraform init
```

### Plan

```bash
terraform plan -var-file=environments/development/terraform.tfvars
```

### Apply

```bash
terraform apply -var-file=environments/development/terraform.tfvars
```

### Destroy

```bash
terraform destroy -var-file=environments/development/terraform.tfvars
```

### Show Outputs

```bash
terraform output
```

### Show State

```bash
terraform show
```

## Outputs

After applying Terraform, you'll get outputs like:

```
eks_cluster_name = "launchpad-development"
eks_cluster_endpoint = "https://..."
ecr_repository_urls = {
  api = "123456789.dkr.ecr.us-east-1.amazonaws.com/launchpad/api"
  client = "123456789.dkr.ecr.us-east-1.amazonaws.com/launchpad/client"
}
vpc_id = "vpc-..."
configure_kubectl = "aws eks update-kubeconfig --region us-east-1 --name launchpad-development"
```

## Backend Configuration

For production use, configure S3 backend for state management:

1. Create S3 bucket for state:

   ```bash
   aws s3 mb s3://launchpad-terraform-state-production
   ```

2. Create DynamoDB table for locking:

   ```bash
   aws dynamodb create-table \
     --table-name launchpad-terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

3. Uncomment backend configuration in `main.tf`:
   ```hcl
   backend "s3" {
     bucket         = "launchpad-terraform-state-production"
     key            = "terraform.tfstate"
     region         = "us-east-1"
     encrypt        = true
     dynamodb_table = "launchpad-terraform-locks"
   }
   ```

## Troubleshooting

### EKS Cluster Not Accessible

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name launchpad-development

# Verify connection
kubectl get nodes
```

### ECR Push Denied

```bash
# Login to ECR
./scripts/aws-ecr-login.sh us-east-1

# Or manually
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Terraform State Locked

```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### NAT Gateway Costs

To reduce costs in development:

```hcl
# environments/development/terraform.tfvars
single_nat_gateway = true  # Use one NAT gateway for all AZs
```

Or disable NAT Gateway entirely (nodes won't have internet access):

```hcl
enable_nat_gateway = false
```

## Security Considerations

1. **IAM Roles**: Use least privilege principle
2. **Security Groups**: Restrict access to necessary ports only
3. **Private Subnets**: Run workloads in private subnets
4. **Encryption**: Enable encryption for ECR and EBS volumes
5. **Secrets**: Use AWS Secrets Manager or Kubernetes Secrets
6. **OIDC**: Use IRSA for pod-level IAM permissions

## Cost Optimization

1. **Spot Instances**: Use for non-critical workloads
2. **Single NAT Gateway**: In development environment
3. **Right-sizing**: Choose appropriate instance types
4. **Auto-scaling**: Scale down during off-hours
5. **Reserved Instances**: For production workloads

## Next Steps

After infrastructure is deployed:

1. Install ALB Ingress Controller
2. Configure Route53 DNS
3. Set up cert-manager for SSL certificates
4. Deploy monitoring (Prometheus/Grafana)
5. Configure logging (CloudWatch)
6. Set up CI/CD pipelines

## References

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
