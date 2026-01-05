# GitHub Actions CI/CD Setup Guide

This guide explains how to configure GitHub Actions for automated CI/CD pipelines.

## Required Secrets

Configure these secrets in your GitHub repository: **Settings → Secrets and variables → Actions**

### AWS Secrets (for ECR and EKS deployment)

#### `AWS_ROLE_TO_ASSUME`

IAM Role ARN for GitHub Actions OIDC authentication.

**Setup**:

1. Create OIDC Identity Provider in AWS:

   ```bash
   aws iam create-open-id-connect-provider \
     --url "https://token.actions.githubusercontent.com" \
     --client-id-list "sts.amazonaws.com" \
     --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1"
   ```

2. Create IAM Role for GitHub Actions:

   ```bash
   # Create trust policy
   cat > github-actions-trust-policy.json <<EOF
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/launchpad:*"
           }
         }
       }
     ]
   }
   EOF

   # Create role
   aws iam create-role \
     --role-name GitHubActionsRole \
     --assume-role-policy-document file://github-actions-trust-policy.json
   ```

3. Attach required policies:

   ```bash
   # ECR access
   aws iam attach-role-policy \
     --role-name GitHubActionsRole \
     --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

   # EKS access
   aws iam attach-role-policy \
     --role-name GitHubActionsRole \
     --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
   ```

4. Add role ARN to GitHub Secrets:
   ```
   Name: AWS_ROLE_TO_ASSUME
   Value: arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole
   ```

## Workflows Overview

### 1. CI Workflow (`ci.yml`)

**Triggers**: Pull requests and pushes to `main`/`develop`

**Jobs**:

- **Lint**: ESLint and code formatting
- **Type Check**: TypeScript type validation
- **Test API**: Unit and integration tests for API
- **Test Client**: Unit tests for Client
- **Build API**: Production build verification
- **Build Client**: Production build verification
- **Security Scan**: Trivy vulnerability scanning

**No secrets required** - runs on all PRs

### 2. Docker Build (`docker-build.yml`)

**Triggers**: Pushes to `main`/`develop`, tags, manual dispatch

**Jobs**:

- **Build API (GHCR)**: Build and push to GitHub Container Registry
- **Build Client (GHCR)**: Build and push to GitHub Container Registry
- **Build ECR** (optional): Build and push to AWS ECR

**Required secrets**:

- `AWS_ROLE_TO_ASSUME` (for ECR builds only)
- `GITHUB_TOKEN` (automatically provided)

**Image tagging strategy**:

- `main` branch → `latest`, `production`
- `develop` branch → `develop`, `staging`
- Tags `v*` → `v1.0.0`, `1.0`, `1`
- Commits → `main-sha123456`

### 3. Deploy Workflow (`deploy.yml`)

**Triggers**: Manual dispatch, after successful Docker build

**Jobs**:

- **Deploy**: Deploy to EKS using Helm

**Required secrets**:

- `AWS_ROLE_TO_ASSUME`

**Deployment strategy**:

- `main` branch → Production environment
- `develop` branch → Staging environment
- Manual → Choose environment

**Steps**:

1. Configure AWS credentials
2. Login to ECR
3. Install kubectl and Helm
4. Configure kubectl for EKS cluster
5. Deploy with Helm
6. Verify deployment
7. Run smoke tests

### 4. PR Validation (`pr-validation.yml`)

**Triggers**: Pull request opened/updated

**Jobs**:

- **Validate PR**: Check PR title, conflicts, file sizes, tests
- **Docker Build Test**: Verify Docker images build successfully

**No secrets required**

**Checks**:

- ✅ PR title follows conventional commits
- ✅ No merge conflicts
- ✅ No large files (>10MB)
- ✅ Code formatting
- ✅ Linting
- ✅ Type checking
- ✅ Tests
- ✅ Docker builds
- ✅ Security scan

## Workflow Permissions

GitHub Actions uses OIDC (OpenID Connect) for AWS authentication, which is more secure than using access keys.

**Benefits**:

- ✅ No long-lived credentials
- ✅ Automatic token rotation
- ✅ Fine-grained access control
- ✅ Audit trail in CloudTrail

## Environment Variables

Workflows use these environment variables:

- `NODE_VERSION`: Node.js version (20)
- `PNPM_VERSION`: pnpm version (8.15.1)
- `AWS_REGION`: AWS region (us-east-1)
- `KUBECTL_VERSION`: kubectl version (1.28.0)
- `HELM_VERSION`: Helm version (3.13.0)

## Manual Deployment

Trigger manual deployment:

1. Go to **Actions** tab
2. Select **Deploy to Kubernetes** workflow
3. Click **Run workflow**
4. Choose:
   - **Environment**: development/staging/production
   - **Image tag**: specific tag or `latest`
5. Click **Run workflow**

## Deployment Environments

### Development

- **Namespace**: `launchpad-development`
- **Cluster**: `launchpad-development`
- **Trigger**: Manual only
- **Image tag**: `latest` or custom

### Staging

- **Namespace**: `launchpad-staging`
- **Cluster**: `launchpad-staging`
- **Trigger**: Push to `develop` branch
- **Image tag**: `develop` or commit SHA

### Production

- **Namespace**: `launchpad-production`
- **Cluster**: `launchpad-production`
- **Trigger**: Push to `main` branch or tag
- **Image tag**: `production` or semantic version

## Monitoring Deployments

### View Workflow Runs

1. Go to **Actions** tab
2. Select workflow
3. Click on specific run
4. View logs for each job

### Check Deployment Status

After deployment, check:

```bash
# Pods
kubectl get pods -n launchpad-production

# Services
kubectl get svc -n launchpad-production

# Ingress
kubectl get ingress -n launchpad-production

# Deployment rollout status
kubectl rollout status deployment/launchpad-api -n launchpad-production
```

## Troubleshooting

### Docker Build Fails

**Issue**: Docker build fails with OOM error

**Solution**:

- Reduce concurrent builds
- Use multi-stage builds (already implemented)
- Enable BuildKit cache

### Deployment Fails

**Issue**: Helm deployment fails with timeout

**Solution**:

```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name> -n <namespace>
```

### AWS Authentication Fails

**Issue**: `Error: could not get token: AccessDenied`

**Solution**:

1. Verify IAM role trust policy includes correct repository
2. Check role has required permissions
3. Verify OIDC provider is configured correctly

### Image Pull Errors

**Issue**: `ImagePullBackOff`

**Solution**:

1. Verify image exists in ECR:
   ```bash
   aws ecr describe-images --repository-name launchpad/api
   ```
2. Check EKS nodes have ECR access (IAM role)
3. Verify image tag is correct

## Best Practices

### 1. Branch Protection

Enable branch protection for `main` and `develop`:

- ✅ Require PR reviews
- ✅ Require status checks (CI must pass)
- ✅ Require branches to be up to date
- ✅ Include administrators

### 2. Semantic Versioning

Use semantic versioning for releases:

```bash
# Create release tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

This triggers Docker build with tags: `v1.0.0`, `1.0`, `1`, `latest`

### 3. Environment Promotion

Follow this promotion path:

```
Development → Staging → Production
    ↓            ↓           ↓
  Manual    Auto (develop)  Manual (main)
```

### 4. Rollback Strategy

To rollback a deployment:

```bash
# Rollback to previous version
kubectl rollout undo deployment/launchpad-api -n launchpad-production

# Rollback to specific revision
kubectl rollout undo deployment/launchpad-api --to-revision=2 -n launchpad-production

# View rollout history
kubectl rollout history deployment/launchpad-api -n launchpad-production
```

### 5. Secrets Management

**Never commit secrets!**

- ✅ Use GitHub Secrets for sensitive data
- ✅ Use AWS Secrets Manager for application secrets
- ✅ Use Kubernetes Secrets for cluster secrets
- ❌ Don't commit `.env` files
- ❌ Don't hardcode credentials

## Advanced Configuration

### Matrix Builds

Build for multiple platforms:

```yaml
strategy:
  matrix:
    platform: [linux/amd64, linux/arm64]
```

### Conditional Deployments

Deploy only on specific conditions:

```yaml
if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

### Caching

GitHub Actions caches:

- ✅ pnpm dependencies (`cache: 'pnpm'`)
- ✅ Docker layers (`cache-from: type=gha`)
- ✅ Build artifacts

### Notifications

Add Slack/Discord notifications:

```yaml
- name: Notify Slack
  if: always()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "Deployment ${{ job.status }}: ${{ github.repository }}"
      }
```

## Security Considerations

1. **OIDC over Access Keys**: Use OpenID Connect for AWS authentication
2. **Least Privilege**: Grant minimal IAM permissions
3. **Secret Scanning**: Enable GitHub secret scanning
4. **Dependabot**: Enable automated dependency updates
5. **Code Scanning**: Use CodeQL for security analysis
6. **Image Scanning**: Trivy scans all Docker images

## Next Steps

After setting up CI/CD:

1. ✅ Configure branch protection rules
2. ✅ Add Slack/Discord notifications
3. ✅ Set up monitoring (Phase 6)
4. ✅ Configure automatic backups
5. ✅ Implement blue-green deployments
6. ✅ Add canary deployments

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS OIDC Authentication](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Helm Documentation](https://helm.sh/docs/)
