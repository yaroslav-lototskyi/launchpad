# Local Development Guide

Complete guide for running Launchpad locally with Kind (Kubernetes in Docker) and Argo CD.

## Why Local Development?

- 🚀 Test full GitOps workflow without AWS
- 💰 Free - no cloud costs
- ⚡ Fast - everything runs on your machine
- 🔄 Full CI/CD pipeline simulation
- 🎯 Perfect for development and testing

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Install Required Tools](#2-install-required-tools)
3. [Setup Kind Cluster](#3-setup-kind-cluster)
4. [Install Argo CD](#4-install-argo-cd)
5. [Setup GitHub Container Registry Access](#5-setup-github-container-registry-access)
6. [Deploy Application](#6-deploy-application)
7. [Test Preview Environments](#7-test-preview-environments)
8. [Development Workflow](#8-development-workflow)
9. [Troubleshooting](#9-troubleshooting)
10. [Cleanup](#10-cleanup)

---

## 1. Prerequisites

### System Requirements

**Minimum:**

- CPU: 4 cores
- RAM: 8 GB
- Disk: 20 GB free space
- OS: macOS, Linux, or Windows with WSL2

**Recommended:**

- CPU: 6+ cores
- RAM: 16 GB
- Disk: 40 GB free space

### Required Software

- ✅ Docker Desktop (or Docker Engine)
- ✅ Git
- ✅ Node.js 18+ and pnpm
- ✅ kubectl (will be installed)
- ✅ Helm (will be installed)
- ✅ Kind (will be installed)

---

## 2. Install Required Tools

### Step 2.1: Install Docker Desktop

**macOS:**

```bash
# Download from: https://www.docker.com/products/docker-desktop
# Or via Homebrew:
brew install --cask docker

# Start Docker Desktop from Applications
# Verify
docker --version
docker ps
```

**Linux:**

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker --version
docker ps
```

**Windows:**

- Install WSL2: https://learn.microsoft.com/en-us/windows/wsl/install
- Install Docker Desktop: https://www.docker.com/products/docker-desktop

### Step 2.2: Install Development Tools

**macOS:**

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install kubectl helm kind

# Verify
kubectl version --client
helm version
kind version
```

**Linux:**

```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Verify
kubectl version --client
helm version
kind version
```

**Windows (WSL2):**

```bash
# Same as Linux commands above
# Run in WSL2 terminal
```

### Step 2.3: Install Node.js and pnpm

**macOS/Linux:**

```bash
# Install Node.js 18+
# Option 1: Via package manager
brew install node@18  # macOS
# or
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -  # Linux
sudo apt-get install -y nodejs  # Linux

# Option 2: Via nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18

# Install pnpm
npm install -g pnpm

# Verify
node --version  # Should be v18.x.x or higher
pnpm --version
```

---

## 3. Setup Kind Cluster

### Step 3.1: Clone Repository

```bash
# Clone the repository
git clone https://github.com/YOUR-USERNAME/launchpad.git
cd launchpad

# Install dependencies
pnpm install
```

### Step 3.2: Create Kind Cluster

```bash
# Run setup script
./k8s/scripts/k8s-setup-kind.sh

# This will:
# 1. Create Kind cluster named "launchpad-local"
# 2. Install NGINX Ingress Controller
# 3. Wait for ingress to be ready (~2 minutes)
```

**Expected output:**

```
🚀 Setting up local Kubernetes cluster with Kind...
📋 Creating Kind cluster: launchpad-local
✅ Kind cluster created successfully
📦 Installing NGINX Ingress Controller...
⏳ Waiting for NGINX Ingress Controller to be ready...
✅ NGINX Ingress Controller is ready
✅ Kind cluster setup complete!
```

### Step 3.3: Verify Cluster

```bash
# Check cluster
kubectl cluster-info
kubectl get nodes

# Should show:
# NAME                           STATUS   ROLES           AGE   VERSION
# launchpad-local-control-plane  Ready    control-plane   2m    v1.28.x

# Check ingress controller
kubectl get pods -n ingress-nginx

# All pods should be Running
```

### Step 3.4: Configure /etc/hosts

Add local domains to /etc/hosts:

```bash
# Add entries
sudo sh -c 'echo "127.0.0.1 launchpad.local" >> /etc/hosts'
sudo sh -c 'echo "127.0.0.1 argocd.launchpad.local" >> /etc/hosts'
sudo sh -c 'echo "127.0.0.1 preview-pr-1.launchpad.local" >> /etc/hosts'

# Verify
cat /etc/hosts | grep launchpad
```

**Note:** You'll need to add each preview environment manually:

```bash
sudo sh -c 'echo "127.0.0.1 preview-pr-2.launchpad.local" >> /etc/hosts'
```

---

## 4. Install Argo CD

### Step 4.1: Install Argo CD

```bash
# Run installation script
./k8s/scripts/argocd-setup.sh

# This takes 3-5 minutes
# Script will show admin password at the end
```

**Save the admin password!** Example:

```
Password: yMMtdbJ2ecDSGZUv
```

### Step 4.2: Configure Argo CD Ingress

```bash
# Set domain
export BASE_DOMAIN="launchpad.local"

# Generate Ingress
./k8s/scripts/configure-argocd-ingress.sh

# Apply Ingress
kubectl apply -f k8s/argocd/install/argocd-ingress.yaml
```

### Step 4.3: Access Argo CD UI

```bash
# Open browser
open http://argocd.launchpad.local

# Or
http://argocd.launchpad.local

# Login:
# Username: admin
# Password: (from installation step)
```

---

## 5. Setup GitHub Container Registry Access

### Step 5.1: Create GitHub Personal Access Token

For development, you'll pull images from GHCR (GitHub Container Registry):

```bash
# 1. Go to: https://github.com/settings/tokens/new
# 2. Token name: "launchpad-local-dev"
# 3. Expiration: 90 days (or custom)
# 4. Scopes: Select "read:packages"
# 5. Click "Generate token"
# 6. Copy the token (starts with ghp_...)
```

### Step 5.2: Login to GHCR

```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# Verify login
docker info | grep Username
```

### Step 5.3: Create Image Pull Secret

```bash
# Create secret for Kubernetes to pull from GHCR
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=$GITHUB_TOKEN \
  --namespace=launchpad-development

# Verify secret
kubectl get secret ghcr-secret -n launchpad-development
```

**Note:** You'll need to create this secret for each namespace (development, preview environments, etc.)

---

## 6. Deploy Application

### Step 6.1: Configure Argo CD Application

```bash
# Configure Application manifest
./k8s/scripts/configure-argocd-app.sh

# This auto-detects GitHub org/repo
```

### Step 6.2: Create Development Environment

**Using Argo CD (Recommended - GitOps way)**

```bash
# Apply Project
kubectl apply -f k8s/argocd/projects/development.yaml

# Apply Application
kubectl apply -f k8s/argocd/apps/launchpad-development.configured.yaml

# Watch deployment in Argo CD UI
open https://argocd.launchpad.local
```

Argo CD will automatically:

1. Pull `main` branch images from GHCR (tagged as `latest`)
2. Deploy to `launchpad-development` namespace
3. Configure domain as `launchpad.local`
4. Auto-sync on any changes

**Alternative: Direct Helm Deploy (Quick testing)**

If you want to test without Argo CD:

```bash
# Get your GitHub org/repo
GITHUB_ORG=$(git remote get-url origin | sed -n 's#.*github.com[:/]\([^/]*\)/.*#\1#p')
GITHUB_REPO=$(git remote get-url origin | sed -n 's#.*github.com[:/][^/]*/\(.*\)\.git#\1#p')

# Deploy with Helm directly
helm upgrade --install launchpad ./k8s/helm/launchpad \
  --namespace launchpad-development \
  --create-namespace \
  --set global.domain=launchpad.local \
  --set imageDefaults.registry=ghcr.io \
  --set imageDefaults.organization=$GITHUB_ORG \
  --set imageDefaults.repository=$GITHUB_REPO \
  --set api.image.tag=latest \
  --set client.image.tag=latest \
  --values k8s/helm/launchpad/values-development.yaml

# Watch deployment
kubectl get pods -n launchpad-development -w
```

### Step 6.3: Verify Deployment

```bash
# Check pods
kubectl get pods -n launchpad-development

# All pods should be Running:
# NAME                               READY   STATUS    RESTARTS   AGE
# launchpad-api-xxxxxxxxx-xxxxx      1/1     Running   0          2m
# launchpad-client-xxxxxxxxx-xxxxx   1/1     Running   0          2m

# Check services
kubectl get svc -n launchpad-development

# Check ingress
kubectl get ingress -n launchpad-development
```

### Step 6.4: Access Application

```bash
# Open browser
open http://launchpad.local

# Or
http://launchpad.local
```

---

## 7. Test Preview Environments

### Step 7.1: Setup ApplicationSet for PR Previews

```bash
# Create GitHub token with repo access (if not already created)
# Go to: https://github.com/settings/tokens/new
# Scopes: repo, read:packages

export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

kubectl create secret generic github-token \
  --from-literal=token=$GITHUB_TOKEN \
  -n argocd

# Configure ApplicationSet
export BASE_DOMAIN="launchpad.local"
./k8s/scripts/configure-argocd-applicationset.sh

# Apply ApplicationSet
kubectl apply -f k8s/argocd/applicationsets/launchpad-previews.configured.yaml
```

### Step 7.2: Test Preview with Real PR

1. **Create PR on GitHub** with code changes
2. **Add "deploy" label** to the PR
3. **GitHub Actions** will automatically build images with `pr-{number}` tag
4. **Argo CD ApplicationSet** will detect the PR and create preview environment
5. **Add domain to /etc/hosts**:

```bash
# For PR #123
sudo sh -c 'echo "127.0.0.1 preview-pr-123.launchpad.local" >> /etc/hosts'
```

6. **Access preview**:

```bash
open http://preview-pr-123.launchpad.local
```

### Step 7.3: Manual Preview Environment (Testing Only)

For quick local testing without creating a real PR:

```bash
# Get your GitHub org/repo
GITHUB_ORG=$(git remote get-url origin | sed -n 's#.*github.com[:/]\([^/]*\)/.*#\1#p')
GITHUB_REPO=$(git remote get-url origin | sed -n 's#.*github.com[:/][^/]*/\(.*\)\.git#\1#p')

# Create image pull secret for preview namespace
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=$GITHUB_TOKEN \
  --namespace=launchpad-pr-1

# Deploy preview manually (simulating PR #1)
helm upgrade --install launchpad-pr-1 ./k8s/helm/launchpad \
  --namespace launchpad-pr-1 \
  --create-namespace \
  --set global.domain=preview-pr-1.launchpad.local \
  --set imageDefaults.registry=ghcr.io \
  --set imageDefaults.organization=$GITHUB_ORG \
  --set imageDefaults.repository=$GITHUB_REPO \
  --set api.image.tag=pr-1 \
  --set client.image.tag=pr-1 \
  --values k8s/helm/launchpad/values-development.yaml

# Add to /etc/hosts
sudo sh -c 'echo "127.0.0.1 preview-pr-1.launchpad.local" >> /etc/hosts'

# Access preview
open http://preview-pr-1.launchpad.local
```

---

## 8. Development Workflow

### Recommended: Local Development with Hot Reload

For quick code changes, use Docker Compose (fastest option):

```bash
# Start with hot reload
docker-compose -f deployment/development/docker-compose.yml up

# Make changes - auto-reloads!
# Access:
# - API: http://localhost:3001
# - Client: http://localhost:5173

# Stop
docker-compose -f deployment/development/docker-compose.yml down
```

### Full GitOps Workflow

For testing the complete CI/CD pipeline:

```bash
# 1. Create a feature branch
git checkout -b feature/my-feature

# 2. Make code changes
vim apps/api/src/index.ts

# 3. Commit and push
git add .
git commit -m "feat: my feature"
git push origin feature/my-feature

# 4. Create PR on GitHub
# 5. Add "deploy" label to PR
# 6. GitHub Actions builds and pushes images with pr-{number} tag
# 7. Argo CD ApplicationSet automatically creates preview environment
# 8. Test on: http://preview-pr-{number}.launchpad.local
```

### Testing Changes in Kubernetes

If you need to test in Kubernetes without creating a PR:

```bash
# 1. Make changes and push to main branch
git push origin main

# 2. GitHub Actions builds and pushes images with 'latest' tag
# 3. Argo CD auto-syncs and deploys to development environment

# Or manually sync:
kubectl patch application launchpad-development -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'

# Watch deployment
kubectl get pods -n launchpad-development -w

# Check logs
kubectl logs -f deployment/launchpad-api -n launchpad-development

# Test
curl http://launchpad.local/api/v1/health
```

### Testing CI/CD Locally

```bash
# Run CI checks locally (same as GitHub Actions)
pnpm lint
pnpm type-check
pnpm test
pnpm build

# Test Docker builds
docker build -f apps/api/deployment/production/Dockerfile .
docker build -f apps/client/deployment/production/Dockerfile .
```

---

## 9. Troubleshooting

### Issue: Pods stuck in ImagePullBackOff

**Problem:** Can't pull images from GHCR

**Possible causes:**

1. **Missing image pull secret:**

```bash
# Check if secret exists
kubectl get secret ghcr-secret -n launchpad-development

# If missing, create it:
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=$GITHUB_TOKEN \
  --namespace=launchpad-development
```

2. **Image doesn't exist on GHCR:**

```bash
# Check if images exist
# Go to: https://github.com/YOUR_ORG/YOUR_REPO/pkgs/container/YOUR_REPO%2Fapi
# Or run workflow manually to build images
```

3. **Invalid token or permissions:**

```bash
# Verify token has read:packages scope
# Regenerate token: https://github.com/settings/tokens/new

# Test login
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# Recreate secret
kubectl delete secret ghcr-secret -n launchpad-development
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=$GITHUB_TOKEN \
  --namespace=launchpad-development
```

### Issue: Cannot access http://launchpad.local

**Problem:** DNS not resolving

**Solutions:**

1. Check /etc/hosts:

```bash
cat /etc/hosts | grep launchpad
# Should show: 127.0.0.1 launchpad.local
```

2. Check Ingress:

```bash
kubectl get ingress -n launchpad-development
# Should show HOST: launchpad.local
```

3. Check Ingress Controller:

```bash
kubectl get pods -n ingress-nginx
# All should be Running
```

4. Try port-forward as workaround:

```bash
kubectl port-forward -n launchpad-development svc/launchpad-client 8080:80
# Access: http://localhost:8080
```

### Issue: Argo CD 502 Bad Gateway

**Problem:** Getting 502 error when accessing Argo CD

**Cause:** Argo CD uses HTTPS by default. The Ingress must use HTTPS backend.

**Solution:**

```bash
# Check Argo CD server is running
kubectl get pods -n argocd | grep argocd-server

# Check Ingress configuration
kubectl get ingress argocd-server-ingress -n argocd -o yaml

# Should have annotation:
# nginx.ingress.kubernetes.io/backend-protocol: HTTPS

# Access via HTTPS (accept self-signed certificate warning)
open https://argocd.launchpad.local
```

### Issue: Argo CD showing "Unknown" health

**Problem:** Application not syncing

**Solution:**

```bash
# Force sync
argocd app sync launchpad-development

# Or via kubectl
kubectl patch application launchpad-development -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'

# Check Application status
kubectl get application launchpad-development -n argocd -o yaml
```

### Issue: Out of disk space

**Problem:** Docker using too much space

**Solution:**

```bash
# Clean Docker
docker system prune -a --volumes

# Remove old Kind images
docker rmi $(docker images -f "dangling=true" -q)

# Check disk usage
df -h
docker system df
```

### Issue: Kind cluster not starting

**Problem:** Port conflicts

**Solution:**

```bash
# Delete existing cluster
kind delete cluster --name launchpad-local

# Check what's using port 80
lsof -i :80

# Kill process if needed
sudo kill -9 <PID>

# Recreate cluster
./k8s/scripts/k8s-setup-kind.sh
```

---

## 10. Cleanup

### Delete Everything

```bash
# Delete Kind cluster (removes everything)
kind delete cluster --name launchpad-local

# Verify
kind get clusters
# Should be empty

# Remove /etc/hosts entries (optional)
sudo sed -i '' '/launchpad.local/d' /etc/hosts  # macOS
sudo sed -i '/launchpad.local/d' /etc/hosts     # Linux
```

### Keep Cluster, Delete Application

```bash
# Delete via Argo CD
kubectl delete application launchpad-development -n argocd

# Or delete namespace directly
kubectl delete namespace launchpad-development

# Keep cluster running for next deployment
```

---

## Summary

You now have:

✅ **Local Kubernetes cluster** with Kind
✅ **Argo CD** for GitOps
✅ **GHCR integration** for pulling images
✅ **Automated deployments** from main branch
✅ **Preview environments** for PRs
✅ **Complete CI/CD pipeline**

### Key URLs:

- **Application:** http://launchpad.local
- **Argo CD:** https://argocd.launchpad.local (accept self-signed cert)
- **API Health:** http://launchpad.local/api/v1/health

### Development Flow:

**Fast iteration (local):**

1. Start Docker Compose for hot reload
2. Make changes, auto-reloads
3. Test on localhost

**Full GitOps flow:**

1. Create PR with changes
2. Add "deploy" label
3. GitHub Actions builds images
4. Argo CD creates preview environment
5. Test on preview URL
6. Merge PR → auto-deploys to development

### Next Steps:

- Push code to main branch to trigger first build
- Create a PR and test preview environment
- Configure GitHub secrets for production deployment
- When AWS account is ready, follow `EC2_DEPLOYMENT_GUIDE.md`

Happy coding! 🚀
