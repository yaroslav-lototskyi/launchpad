# Complete EC2 Deployment Guide

This guide walks you through the complete process of deploying the Launchpad application to AWS EC2 with k3s and Argo CD.

## Prerequisites

- AWS Account
- Domain name (optional, can use /etc/hosts for testing)
- GitHub account with repository access
- Local machine with SSH client

## Table of Contents

1. [Create EC2 Instance](#1-create-ec2-instance)
2. [Configure Security Groups](#2-configure-security-groups)
3. [Connect to EC2](#3-connect-to-ec2)
4. [Install k3s](#4-install-k3s)
5. [Install Argo CD](#5-install-argo-cd)
6. [Configure Domain Access](#6-configure-domain-access)
7. [Setup Argo CD Applications](#7-setup-argo-cd-applications)
8. [Setup Preview Environments](#8-setup-preview-environments)
9. [Configure GitHub](#9-configure-github)
10. [Test the Deployment](#10-test-the-deployment)

---

## 1. Create EC2 Instance

### Step 1.0: Choose AWS Region

**Before starting, select your AWS region!**

1. **Top-right corner** of AWS Console → Click region dropdown
2. **Choose based on:**
   - **Proximity to users** (lower latency)
   - **Cost** (us-east-1 and us-west-2 are cheapest)
   - **Compliance** (data residency requirements)

**Recommended regions:**

- **US East (N. Virginia) - us-east-1**: Cheapest, most services
- **US West (Oregon) - us-west-2**: Cheap, good for West Coast
- **Europe (Ireland) - eu-west-1**: Good for EU users
- **Europe (Frankfurt) - eu-central-1**: GDPR compliance

**All steps below apply to any region you choose.**

### Step 1.1: Launch Instance

1. **Login to AWS Console**
   - Go to https://console.aws.amazon.com/
   - **Verify correct region is selected** (top-right corner)
   - Navigate to EC2 Dashboard

2. **Click "Launch Instance"**

3. **Configure Instance:**

   **Name:**

   ```
   launchpad-k3s-production
   ```

   **Application and OS Images (Amazon Machine Image):**
   - **AMI:** Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
   - **Architecture:** 64-bit (x86)

   **Instance Type:**
   - **Recommended:** `t3.medium`
     - 2 vCPU
     - 4 GB RAM
     - Cost: ~$30-35/month (varies by region)
   - **Minimum:** `t3.small` (2 vCPU, 2 GB RAM) - may struggle with Argo CD
   - **For production with traffic:** `t3.large` or higher

   **Key Pair:**
   - Click "Create new key pair"
   - Name: `launchpad-prod-key`
   - Key pair type: RSA
   - Private key format: `.pem` (for Mac/Linux) or `.ppk` (for Windows/PuTTY)
   - Download and save securely!

   **Network Settings:**
   - VPC: Default VPC (or create new)
   - Subnet: No preference
   - Auto-assign public IP: **Enable**

   **Configure Storage:**
   - Size: **20 GB minimum, 30 GB recommended**
   - Volume type: gp3 (General Purpose SSD)
   - Delete on termination: Enable

   **Advanced Details:**
   - Keep defaults

4. **Click "Launch Instance"**

### Step 1.2: Wait for Instance to Start

- Status checks should show "2/2 checks passed" (takes 2-3 minutes)
- Note your **Public IPv4 address** - you'll need this!

Example: `54.123.45.67`

---

## 2. Configure Security Groups

### Step 2.1: Edit Inbound Rules

1. Go to EC2 Dashboard → Instances
2. Select your instance
3. Click **Security** tab
4. Click on the Security Group link
5. Click **Edit inbound rules**

### Step 2.2: Add Required Rules

Add the following rules:

| Type  | Protocol | Port Range | Source    | Description            |
| ----- | -------- | ---------- | --------- | ---------------------- |
| SSH   | TCP      | 22         | My IP     | SSH access             |
| HTTP  | TCP      | 80         | 0.0.0.0/0 | HTTP traffic           |
| HTTPS | TCP      | 443        | 0.0.0.0/0 | HTTPS traffic (future) |

**Security Note:**

- Set SSH source to "My IP" for security
- If you need to access from multiple locations, add multiple rules
- For Kubernetes API access (optional): Add TCP 6443 with your IP

### Step 2.3: Save Rules

Click **Save rules**

---

## 3. Connect to EC2

### Step 3.1: Set Key Permissions (Mac/Linux)

```bash
# Navigate to where you saved the key
cd ~/Downloads

# Set correct permissions
chmod 400 launchpad-prod-key.pem

# Move to secure location (recommended)
mkdir -p ~/.ssh/aws-keys
mv launchpad-prod-key.pem ~/.ssh/aws-keys/
```

### Step 3.2: Connect via SSH

```bash
# Replace with your actual IP
export EC2_IP="54.123.45.67"

# Connect
ssh -i ~/.ssh/aws-keys/launchpad-prod-key.pem ubuntu@$EC2_IP
```

**First connection will ask:**

```
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Type `yes` and press Enter.

### Step 3.3: Update System

```bash
# Update package list
sudo apt update

# Upgrade installed packages
sudo apt upgrade -y

# Install useful utilities
sudo apt install -y curl wget git htop
```

---

## 4. Install k3s

### Step 4.1: Install k3s

```bash
# Install k3s (lightweight Kubernetes)
curl -sfL https://get.k3s.io | sh -

# This takes 2-3 minutes
```

### Step 4.2: Verify Installation

```bash
# Check k3s status
sudo systemctl status k3s

# Should show "active (running)"
# Press 'q' to exit

# Check Kubernetes nodes
sudo kubectl get nodes

# Should show:
# NAME               STATUS   ROLES                  AGE   VERSION
# ip-xxx-xxx-xxx-xxx Ready    control-plane,master   1m    v1.28.x+k3s1
```

### Step 4.3: Configure kubectl Access

```bash
# Make kubectl accessible without sudo
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

# Set KUBECONFIG environment variable
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
source ~/.bashrc

# Test
kubectl get nodes
# Should work without sudo now
```

### Step 4.4: Configure Local kubectl Access (Optional)

If you want to manage the cluster from your local machine:

```bash
# On EC2 instance
sudo cat /etc/rancher/k3s/k3s.yaml

# Copy the output
```

On your local machine:

```bash
# Create config file
nano ~/.kube/launchpad-prod-config

# Paste the content
# IMPORTANT: Replace 127.0.0.1 with your EC2 PUBLIC IP
# Change:
#   server: https://127.0.0.1:6443
# To:
#   server: https://54.123.45.67:6443

# Use this config
export KUBECONFIG=~/.kube/launchpad-prod-config

# Test
kubectl get nodes
```

**Note:** You need to add port 6443 to Security Group for this to work.

---

## 5. Install Argo CD

### Step 5.1: Clone Repository (on EC2)

```bash
# Clone your repository
git clone https://github.com/YOUR-USERNAME/launchpad.git
cd launchpad
```

### Step 5.2: Install Argo CD

```bash
# Run installation script
chmod +x k8s/scripts/argocd-setup.sh
./k8s/scripts/argocd-setup.sh

# This takes 3-5 minutes
# Script will:
# 1. Create argocd namespace
# 2. Install Argo CD
# 3. Wait for pods to be ready
# 4. Show initial admin password
```

**Save the admin password shown at the end!**

Example output:

```
========================================
Argo CD installed successfully!
========================================
Access Argo CD:

  1. Port-forward:
     kubectl port-forward svc/argocd-server -n argocd 8080:443

  2. Login:
     URL: https://localhost:8080
     Username: admin
     Password: Xjk9sKl2mPq5
========================================
```

### Step 5.3: Verify Argo CD Installation

```bash
# Check all Argo CD pods are running
kubectl get pods -n argocd

# All pods should show "Running" and "1/1" or "2/2" ready
```

### Step 5.4: Access Argo CD UI via Port Forward (Temporary)

```bash
# On EC2 instance
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# On local machine, create SSH tunnel
ssh -i ~/.ssh/aws-keys/launchpad-prod-key.pem -L 8080:localhost:8080 ubuntu@$EC2_IP

# Now open browser: https://localhost:8080
# Username: admin
# Password: (from previous step)
```

**Note:** We'll setup proper domain access in the next step.

---

## 6. Configure Domain Access

### Option A: Using Real Domain (Recommended for Production)

#### Step 6.1: Configure DNS

Add these DNS records in your domain provider (e.g., Cloudflare, Route53, Namecheap):

| Type | Name   | Value        | TTL  |
| ---- | ------ | ------------ | ---- |
| A    | @      | 54.123.45.67 | Auto |
| A    | argocd | 54.123.45.67 | Auto |
| A    | \*     | 54.123.45.67 | Auto |

Replace `54.123.45.67` with your actual EC2 IP.

The wildcard (\*) enables preview environments: `preview-pr-123.your-domain.com`

#### Step 6.2: Wait for DNS Propagation

```bash
# Test DNS resolution (on local machine)
nslookup argocd.your-domain.com

# Should return your EC2 IP
```

DNS propagation takes 5 minutes to 48 hours (usually < 1 hour).

#### Step 6.3: Configure Argo CD Ingress

```bash
# On EC2 instance
cd ~/launchpad

# Set your domain
export BASE_DOMAIN="your-domain.com"

# Generate Ingress configuration
./k8s/scripts/configure-argocd-ingress.sh

# Apply Ingress
kubectl apply -f k8s/argocd/install/argocd-ingress.yaml
```

#### Step 6.4: Access Argo CD

```bash
# Open browser
http://argocd.your-domain.com

# Login:
# Username: admin
# Password: (from installation step)
```

### Option B: Using /etc/hosts (Testing Only)

If you don't have a domain yet:

```bash
# On your local machine
export EC2_IP="54.123.45.67"  # Your actual IP

sudo sh -c "echo '$EC2_IP argocd.launchpad.local' >> /etc/hosts"
sudo sh -c "echo '$EC2_IP launchpad.local' >> /etc/hosts"
sudo sh -c "echo '$EC2_IP preview-pr-1.launchpad.local' >> /etc/hosts"

# Note: You'll need to add each preview environment manually
```

Configure Ingress:

```bash
# On EC2
export BASE_DOMAIN="launchpad.local"
./k8s/scripts/configure-argocd-ingress.sh
kubectl apply -f k8s/argocd/install/argocd-ingress.yaml
```

Access: http://argocd.launchpad.local

---

## 7. Setup Argo CD Applications

### Step 7.1: Configure Development Application

```bash
# On EC2, in launchpad directory
cd ~/launchpad

# This script auto-detects GitHub org/repo from git remote
./k8s/scripts/configure-argocd-app.sh

# Output:
# =========================================
# Argo CD Application Configuration
# =========================================
# GitHub Organization: your-username
# GitHub Repository: launchpad
# =========================================
# Created: k8s/argocd/apps/launchpad-development.configured.yaml
```

### Step 7.2: Create Argo CD Project

```bash
# Create development project
kubectl apply -f k8s/argocd/projects/development.yaml

# Verify
kubectl get appproject -n argocd
```

### Step 7.3: Create Development Application

```bash
# Apply configured Application
kubectl apply -f k8s/argocd/apps/launchpad-development.configured.yaml

# Verify
kubectl get application -n argocd

# Should show:
# NAME                    SYNC STATUS   HEALTH STATUS
# launchpad-development   OutOfSync     Missing
```

### Step 7.4: Sync Application

The Application shows "OutOfSync" because images don't exist yet (we haven't pushed any).

**Option 1: Via Argo CD UI**

1. Go to http://argocd.your-domain.com
2. Click on "launchpad-development"
3. Wait for first GitHub Actions build, then click "Sync"

**Option 2: Via CLI**

```bash
# Install Argo CD CLI (on EC2)
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd

# Login
argocd login argocd.your-domain.com \
  --username admin \
  --password YOUR_PASSWORD \
  --insecure

# Sync
argocd app sync launchpad-development
```

---

## 8. Setup Preview Environments

### Step 8.1: Create GitHub Personal Access Token

Argo CD needs to watch GitHub PRs.

1. Go to https://github.com/settings/tokens/new
2. **Note:** `argo-cd-pr-generator`
3. **Expiration:** 90 days (or custom)
4. **Scopes:**
   - ✅ `repo` (if private repo)
   - ✅ `public_repo` (if public repo)
5. Click "Generate token"
6. **Copy the token!** (starts with `ghp_...`)

Example: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### Step 8.2: Create Kubernetes Secret

```bash
# On EC2
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

kubectl create secret generic github-token \
  --from-literal=token=$GITHUB_TOKEN \
  -n argocd

# Verify
kubectl get secret github-token -n argocd
```

### Step 8.3: Configure ApplicationSet

```bash
# Set your domain
export BASE_DOMAIN="your-domain.com"

# Configure ApplicationSet
./k8s/scripts/configure-argocd-applicationset.sh

# If BASE_DOMAIN is not set, script will prompt you

# Output:
# =========================================
# Argo CD ApplicationSet Configuration
# =========================================
# GitHub Organization: your-username
# GitHub Repository: launchpad
# Base Domain: your-domain.com
# =========================================
# Created: k8s/argocd/applicationsets/launchpad-previews.configured.yaml
```

### Step 8.4: Apply ApplicationSet

```bash
kubectl apply -f k8s/argocd/applicationsets/launchpad-previews.configured.yaml

# Verify
kubectl get applicationset -n argocd

# Should show:
# NAME                 AGE
# launchpad-previews   10s
```

### Step 8.5: Check ApplicationSet Status

```bash
kubectl describe applicationset launchpad-previews -n argocd

# Look for:
# - No errors in Events
# - Status should be healthy
```

---

## 9. Configure GitHub

### Step 9.1: Add Repository Variable

1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions → Variables tab
3. Click "New repository variable"
4. **Name:** `BASE_DOMAIN`
5. **Value:** `your-domain.com` (your actual domain)
6. Click "Add variable"

### Step 9.2: Configure Branch Protection

1. Settings → Branches
2. Click "Add rule"
3. **Branch name pattern:** `main`
4. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
5. **Status checks:** Select these (they'll appear after first PR):
   - `lint`
   - `type-check`
   - `test`
   - `docker-build-check`
6. Click "Create"

See `docs/BRANCH_PROTECTION.md` for detailed guide.

### Step 9.3: Enable GitHub Actions

1. Settings → Actions → General
2. **Actions permissions:** Allow all actions and reusable workflows
3. **Workflow permissions:** Read and write permissions
4. Click "Save"

---

## 10. Test the Deployment

### Step 10.1: Test CI Pipeline

```bash
# On local machine
git checkout -b test/ci-pipeline

# Make a small change
echo "# Test" >> README.md

git add README.md
git commit -m "test: CI pipeline"
git push origin test/ci-pipeline
```

Create PR on GitHub:

1. Go to repository → Pull requests → New pull request
2. Base: `main` ← Compare: `test/ci-pipeline`
3. Create pull request

**Expected:**

- ✅ CI workflow runs all checks (lint, type-check, test, docker-build-check)
- ✅ All checks pass
- ❌ Cannot merge yet (needs status checks)

### Step 10.2: Test Docker Build & Push

After CI passes, merge the PR:

1. Click "Merge pull request"
2. Confirm merge

**Expected:**

- ✅ Docker Build workflow triggers on push to main
- ✅ Builds images: `api:latest` and `client:latest`
- ✅ Pushes to GHCR: `ghcr.io/your-username/launchpad/api:latest`

Check in GitHub:

- Go to repository main page
- Packages (right sidebar)
- Should see: `launchpad/api` and `launchpad/client`

### Step 10.3: Test Argo CD Auto-Sync

After images are pushed:

```bash
# Watch Argo CD sync
kubectl get application -n argocd -w

# In Argo CD UI:
# - launchpad-development should auto-sync
# - Should pull latest images
# - Status: Synced, Healthy
```

Access application:

```bash
http://your-domain.com
```

### Step 10.4: Test Preview Environment

Create PR with "deploy" label:

```bash
# Create feature branch
git checkout -b feature/preview-test
echo "# Preview Test" >> README.md
git add README.md
git commit -m "feat: test preview environment"
git push origin feature/preview-test
```

On GitHub:

1. Create PR
2. Add label "deploy" (Labels → deploy)

**Expected:**

- ✅ Docker Build workflow triggers (builds `pr-123` images)
- ✅ After ~3 minutes, Argo CD ApplicationSet creates `launchpad-pr-123`
- ✅ Application deploys to namespace `launchpad-pr-123`
- ✅ Accessible at: `http://preview-pr-123.your-domain.com`

Check in Argo CD UI:

- Should see new Application: `launchpad-pr-123`
- Filter by label: `preview=true`

### Step 10.5: Test Preview Cleanup

Remove label from PR:

- PR → Labels → Remove "deploy"

**Expected:**

- ✅ After ~3 minutes, Argo CD deletes Application
- ✅ Namespace `launchpad-pr-123` deleted
- ✅ Application removed from Argo CD UI

---

## Troubleshooting

### Issue: kubectl permission denied

```bash
# Fix k3s.yaml permissions
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

### Issue: Cannot access Argo CD UI

```bash
# Check Ingress
kubectl get ingress -n argocd

# Check Ingress controller
kubectl get pods -n kube-system | grep traefik

# Check DNS
nslookup argocd.your-domain.com
```

### Issue: Application stuck in "Progressing"

```bash
# Check pods
kubectl get pods -n launchpad-development

# Check events
kubectl get events -n launchpad-development --sort-by='.lastTimestamp'

# Common issues:
# - Images don't exist (need to push first)
# - ImagePullBackOff (wrong image name or not public)
# - CrashLoopBackOff (app error, check logs)
```

### Issue: Preview environment not created

```bash
# Check ApplicationSet
kubectl describe applicationset launchpad-previews -n argocd

# Check if GitHub token works
kubectl get secret github-token -n argocd

# Check ApplicationSet controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller

# Common issues:
# - Wrong GitHub token
# - Label not exactly "deploy"
# - GitHub API rate limit
```

### Issue: Images not pulling from GHCR

Images are private by default. Make them public:

1. Go to package page: `https://github.com/users/YOUR-USERNAME/packages/container/launchpad%2Fapi`
2. Package settings
3. Change visibility → Public
4. Repeat for client package

Or create imagePullSecret (for private images):

```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR-USERNAME \
  --docker-password=YOUR-GITHUB_TOKEN \
  -n launchpad-development
```

---

## Cost Estimate

**Monthly costs (approximate, varies by region):**

| Resource      | Type      | Cost/Month  | Notes                           |
| ------------- | --------- | ----------- | ------------------------------- |
| EC2 t3.medium | 730 hours | ~$30-35     | Cheaper in us-east-1, us-west-2 |
| EBS 30GB gp3  | Storage   | ~$2.40      | Standard across regions         |
| Data Transfer | Out       | ~$1-5       | Depends on traffic              |
| **Total**     |           | **~$33-42** |                                 |

**Regional pricing examples:**

- **us-east-1** (N. Virginia): ~$30/month (cheapest)
- **us-west-2** (Oregon): ~$30/month
- **eu-west-1** (Ireland): ~$33/month
- **eu-central-1** (Frankfurt): ~$35/month
- **ap-southeast-1** (Singapore): ~$37/month

**Cost optimization:**

- Use Reserved Instance: Save 30-40%
- Use Savings Plan: Save up to 72%
- Stop instance when not needed (development)
- Choose region closer to users but consider cost

---

## Next Steps

1. ✅ **Setup TLS/HTTPS** - Use cert-manager with Let's Encrypt
2. ✅ **Setup Monitoring** - Prometheus + Grafana
3. ✅ **Setup Logging** - ELK or Loki
4. ✅ **Backup Strategy** - Automated backups
5. ✅ **CI/CD Optimization** - Caching, parallel jobs
6. ✅ **Security Hardening** - Network policies, RBAC

---

## Summary

You now have:

- ✅ EC2 instance running k3s
- ✅ Argo CD managing deployments
- ✅ Development environment auto-syncing from main branch
- ✅ Preview environments on PR with "deploy" label
- ✅ GitHub Actions building and pushing images
- ✅ Complete GitOps workflow

**Workflow:**

1. Create PR → CI checks run
2. Add "deploy" label → Preview environment created
3. Merge PR → Development auto-updates
4. Tag release → Production deployment (when configured)

**Resources:**

- Argo CD: `http://argocd.your-domain.com`
- Development: `http://your-domain.com`
- Preview: `http://preview-pr-{NUMBER}.your-domain.com`
- GitHub Packages: Check repository packages

Enjoy your automated deployment pipeline! 🚀
