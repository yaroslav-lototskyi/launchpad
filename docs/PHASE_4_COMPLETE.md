# Phase 4 Complete: AWS Infrastructure ✅

**Completion Date**: 2026-01-05

## Overview

Phase 4 introduces AWS infrastructure automation using Terraform, enabling production-ready cloud deployment of the Launchpad application on Amazon EKS.

## Deliverables

### 1. Terraform Infrastructure as Code

Created production-ready Terraform modules at `k8s/terraform/`:

```
k8s/terraform/
├── main.tf                    # Main configuration with providers
├── variables.tf               # Global variables
├── outputs.tf                 # Infrastructure outputs
├── README.md                  # Comprehensive documentation
├── modules/
│   ├── vpc/                  # VPC with public/private subnets
│   ├── eks/                  # EKS cluster and node groups
│   ├── ecr/                  # ECR container repositories
│   └── iam/                  # IAM roles and policies
└── environments/
    ├── development/          # Dev environment configuration
    ├── staging/              # Staging environment configuration
    └── production/           # Production environment configuration
```

### 2. VPC Module

**Features**:

- Multi-AZ deployment (configurable 2-3 AZs)
- Public subnets for load balancers
- Private subnets for EKS worker nodes
- Internet Gateway for public subnet access
- NAT Gateways for private subnet internet access (configurable: single or per-AZ)
- Route tables with proper routing
- Kubernetes subnet tags for auto-discovery

**Key Resources**:

- VPC with DNS hostnames and support enabled
- Public subnets with auto-assign public IP
- Private subnets for secure workload placement
- Elastic IPs for NAT Gateways
- NAT Gateways (1 or 3 depending on environment)
- Internet Gateway
- Route tables and associations

**Configuration Options**:

- `vpc_cidr`: VPC CIDR block
- `availability_zones`: List of AZs to use
- `public_subnet_cidrs`: CIDR blocks for public subnets
- `private_subnet_cidrs`: CIDR blocks for private subnets
- `enable_nat_gateway`: Enable/disable NAT Gateway
- `single_nat_gateway`: Use single NAT for cost optimization

### 3. EKS Module

**Features**:

- Managed Kubernetes control plane (v1.28)
- Configurable node groups with auto-scaling
- Public and private endpoint access
- CloudWatch logging for control plane
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- Security groups for cluster communication
- Multiple node groups support

**Key Resources**:

- EKS cluster with configurable version
- EKS node groups with auto-scaling
- Cluster security groups
- OIDC provider for IRSA
- IAM roles for cluster and nodes (optional)

**Node Group Configuration**:

- Instance types (t3.small, t3.medium, t3.large)
- Capacity type (ON_DEMAND or SPOT)
- Auto-scaling (min, max, desired size)
- Disk size
- Multiple node groups per cluster

**Logging**:

- API server logs
- Audit logs
- Authenticator logs
- Controller manager logs
- Scheduler logs

### 4. ECR Module

**Features**:

- Private Docker image repositories
- Image scanning on push
- Lifecycle policies for image retention
- Encryption at rest (AES256)
- Tag mutability

**Repositories**:

- `launchpad/api`: API service images
- `launchpad/client`: Client application images

**Lifecycle Policies**:

- Keep last 30 tagged images (with `v` prefix)
- Remove untagged images after 7 days
- Automatic cleanup to reduce storage costs

### 5. IAM Module

**Features**:

- EKS cluster IAM role
- EKS node group IAM role
- ALB controller IAM role (for AWS Load Balancer Controller)
- Custom ECR access policy
- Least privilege principle

**Roles and Policies**:

- **EKS Cluster Role**:
  - AmazonEKSClusterPolicy
  - AmazonEKSVPCResourceController

- **EKS Node Role**:
  - AmazonEKSWorkerNodePolicy
  - AmazonEKS_CNI_Policy
  - AmazonEC2ContainerRegistryReadOnly
  - Custom ECR access policy

- **ALB Controller Role**:
  - Elastic Load Balancing permissions
  - EC2 permissions for ALB management
  - WAFv2 and Shield integration

### 6. Environment Configurations

#### Development

**Purpose**: Development and testing

**Configuration**:

- VPC: 10.0.0.0/16
- AZs: 2 (us-east-1a, us-east-1b)
- NAT Gateway: Single (cost optimization)
- EKS Version: 1.28
- Node Group:
  - Instance Type: t3.small
  - Capacity: SPOT (cost optimization)
  - Scaling: 1-3 nodes
  - Disk: 20GB

**Cost**: ~$50-100/month

- EKS cluster: ~$73/month
- EC2 (SPOT): ~$15-45/month
- NAT Gateway: ~$33/month
- Data transfer: Variable

#### Staging

**Purpose**: Pre-production testing

**Configuration**:

- VPC: 10.1.0.0/16
- AZs: 3 (full high availability)
- NAT Gateway: 3 (one per AZ)
- EKS Version: 1.28
- Node Group:
  - Instance Type: t3.medium
  - Capacity: ON_DEMAND
  - Scaling: 2-5 nodes
  - Disk: 30GB

**Cost**: ~$150-300/month

- EKS cluster: ~$73/month
- EC2: ~$60-150/month
- NAT Gateways: ~$99/month (3 AZs)
- Data transfer: Variable

#### Production

**Purpose**: Production workloads

**Configuration**:

- VPC: 10.2.0.0/16
- AZs: 3 (full high availability)
- NAT Gateway: 3 (one per AZ)
- EKS Version: 1.28
- Node Group:
  - Instance Type: t3.large
  - Capacity: ON_DEMAND
  - Scaling: 3-10 nodes
  - Disk: 50GB

**Cost**: ~$500-1000/month

- EKS cluster: ~$73/month
- EC2: ~$200-600/month
- NAT Gateways: ~$99/month (3 AZs)
- Data transfer: Variable
- Additional services: Variable

### 7. Helper Scripts

#### `scripts/aws-setup.sh`

Main infrastructure deployment script:

**Features**:

- Environment validation
- AWS credentials check
- Terraform initialization
- Workspace management
- Plan/Apply/Destroy actions
- Colored output
- Safety confirmations

**Usage**:

```bash
# Plan infrastructure
./k8s/scripts/aws-setup.sh development plan

# Apply infrastructure
./k8s/scripts/aws-setup.sh development apply

# Destroy infrastructure
./k8s/scripts/aws-setup.sh development destroy
```

#### `scripts/aws-ecr-login.sh`

ECR authentication script:

**Features**:

- AWS account ID detection
- Docker login to ECR
- Region support
- Error handling

**Usage**:

```bash
./k8s/scripts/aws-ecr-login.sh [region]
```

#### `scripts/aws-push-images.sh`

Build and push Docker images to ECR:

**Features**:

- Multi-stage Docker builds
- Automatic tagging (latest + environment)
- ECR login integration
- Build caching
- Both API and Client images

**Usage**:

```bash
./k8s/scripts/aws-push-images.sh [environment] [tag] [region]

# Examples
./k8s/scripts/aws-push-images.sh development latest
./k8s/scripts/aws-push-images.sh staging v1.0.0 us-east-1
./k8s/scripts/aws-push-images.sh production v2.1.0
```

### 8. Documentation

**Terraform README** (`k8s/terraform/README.md`):

- Architecture overview
- Prerequisites and setup
- Quick start guide
- Environment configurations
- Module documentation
- Customization examples
- Terraform commands reference
- Backend configuration
- Troubleshooting guide
- Security considerations
- Cost optimization tips
- Next steps

## Key Features

### Infrastructure as Code

- **Declarative**: All infrastructure defined in code
- **Version Controlled**: Track changes in Git
- **Reproducible**: Same configuration = same infrastructure
- **Modular**: Reusable Terraform modules
- **Environment Parity**: Consistent across dev/staging/prod

### High Availability

- Multi-AZ deployment
- Redundant NAT Gateways (staging/production)
- Auto-scaling node groups
- EKS control plane managed by AWS

### Security

- Private subnets for workloads
- IAM roles with least privilege
- Security groups for network isolation
- ECR image scanning
- Encryption at rest
- OIDC provider for IRSA

### Cost Optimization

- SPOT instances for development
- Single NAT Gateway option
- Configurable instance types
- Auto-scaling to match demand
- Lifecycle policies for ECR

### Scalability

- Auto-scaling node groups
- Configurable min/max nodes
- Multiple node groups support
- Easy to add more capacity

## Deployment Workflow

### 1. Initialize Infrastructure

```bash
# Plan changes
./k8s/scripts/aws-setup.sh development plan

# Review plan and apply
./k8s/scripts/aws-setup.sh development apply
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name launchpad-development
kubectl get nodes
```

### 3. Build and Push Images

```bash
# Build and push to ECR
./k8s/scripts/aws-push-images.sh development latest

# Verify images
aws ecr list-images --repository-name launchpad/api
```

### 4. Deploy Application

```bash
# Update Helm values to use ECR
# Then deploy
./k8s/scripts/k8s-deploy.sh development
```

### 5. Verify Deployment

```bash
kubectl get pods -n launchpad-development
kubectl get svc -n launchpad-development
kubectl get ingress -n launchpad-development
```

## Terraform Outputs

After applying Terraform:

- `vpc_id`: VPC ID
- `eks_cluster_name`: EKS cluster name
- `eks_cluster_endpoint`: Kubernetes API endpoint
- `ecr_repository_urls`: ECR repository URLs
- `configure_kubectl`: Command to configure kubectl

## Backend Configuration

For production use, configure S3 backend:

```hcl
backend "s3" {
  bucket         = "launchpad-terraform-state-production"
  key            = "terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "launchpad-terraform-locks"
}
```

**Benefits**:

- Remote state storage
- State locking
- Team collaboration
- State versioning

## Security Best Practices

1. **Network Isolation**: Workloads in private subnets
2. **IAM Least Privilege**: Minimal permissions for roles
3. **Encryption**: ECR images and EBS volumes encrypted
4. **Security Groups**: Restrict traffic to necessary ports
5. **IRSA**: Pod-level IAM permissions
6. **Secrets Management**: Use AWS Secrets Manager or K8s Secrets
7. **Image Scanning**: Automatic vulnerability scanning

## Cost Breakdown

### Development (~$50-100/month)

- EKS Cluster: $73/month
- EC2 (1-3 t3.small SPOT): $15-45/month
- NAT Gateway (single): $33/month
- Data Transfer: $5-10/month
- ECR Storage: $1-3/month

### Staging (~$150-300/month)

- EKS Cluster: $73/month
- EC2 (2-5 t3.medium): $60-150/month
- NAT Gateways (3): $99/month
- ALB: $20-25/month
- Data Transfer: $10-20/month
- ECR Storage: $2-5/month

### Production (~$500-1000/month)

- EKS Cluster: $73/month
- EC2 (3-10 t3.large): $200-600/month
- NAT Gateways (3): $99/month
- ALB: $20-25/month
- Data Transfer: $30-100/month
- ECR Storage: $5-10/month
- CloudWatch Logs: $10-20/month
- Backups: $20-40/month

## Next Steps (Phase 5)

With AWS infrastructure deployed, Phase 5 will focus on:

1. **AWS Load Balancer Controller**:
   - Install ALB Ingress Controller
   - Configure Application Load Balancer
   - SSL/TLS termination

2. **DNS and Certificates**:
   - Route53 DNS configuration
   - cert-manager for automatic SSL certificates
   - Domain configuration

3. **CI/CD Pipeline**:
   - GitHub Actions for automated deployments
   - Build and push images to ECR
   - Deploy to EKS on merge to main
   - Environment-specific workflows

4. **Observability** (Phase 6):
   - Prometheus for metrics
   - Grafana for visualization
   - ELK/CloudWatch for logging
   - Alerting and notifications

## Troubleshooting

### EKS Cluster Not Accessible

```bash
aws eks update-kubeconfig --region us-east-1 --name launchpad-development
kubectl get nodes
```

### ECR Push Denied

```bash
./k8s/scripts/aws-ecr-login.sh us-east-1
```

### Terraform State Locked

```bash
terraform force-unlock <lock-id>
```

### High Costs

- Use SPOT instances for dev
- Single NAT Gateway in dev
- Scale down during off-hours
- Review CloudWatch logs retention

## Metrics

- **Terraform Modules**: 4 (VPC, EKS, ECR, IAM)
- **Lines of Terraform**: ~800
- **Environment Configs**: 3
- **Helper Scripts**: 3
- **AWS Resources**: 30+ per environment
- **Documentation Pages**: 2

## References

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)

---

**Phase 4 Status**: ✅ Complete
**Next Phase**: Phase 5 - CI/CD Pipeline
