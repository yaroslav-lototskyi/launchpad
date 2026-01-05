# EC2 + k3s + Argo CD Manual Setup Guide

This guide will help you set up a single-node Kubernetes cluster using k3s on AWS EC2, with Argo CD for GitOps deployments.

## Prerequisites

- AWS Account
- GitHub account with launchpad repository
- Local machine with kubectl and ssh

## Step 1: Create EC2 Instance

### 1.1 Launch EC2 Instance

**Via AWS Console:**

1. Go to EC2 Dashboard
2. Click "Launch Instance"
3. Configure:
   - **Name**: `launchpad-k3s`
   - **AMI**: Ubuntu Server 22.04 LTS (64-bit ARM or x86)
   - **Instance type**: `t3.medium` (2 vCPU, 4GB RAM)
   - **Key pair**: Create new or use existing
   - **Network settings**:
     - Auto-assign public IP: Yes
     - Security group: Create new
   - **Storage**: 30 GB gp3

### 1.2 Security Group Rules

**Inbound rules:**

| Type       | Protocol | Port Range | Source    | Description               |
| ---------- | -------- | ---------- | --------- | ------------------------- |
| SSH        | TCP      | 22         | Your IP   | SSH access                |
| HTTP       | TCP      | 80         | 0.0.0.0/0 | Ingress HTTP              |
| HTTPS      | TCP      | 443        | 0.0.0.0/0 | Ingress HTTPS             |
| Custom TCP | TCP      | 6443       | Your IP   | Kubernetes API (optional) |

**Outbound rules:** Allow all

### 1.3 Elastic IP (Optional but recommended)

1. Allocate Elastic IP
2. Associate with instance
3. Use this IP for DNS records

## Step 2: Install k3s

### 2.1 SSH to Instance

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<EC2-PUBLIC-IP>
```

### 2.2 Install k3s

```bash
# Install k3s with Traefik disabled (we'll use nginx-ingress)
curl -sfL https://get.k3s.io | sh -s - \
  --disable traefik \
  --write-kubeconfig-mode 644

# Verify installation
sudo k3s kubectl get nodes
```

### 2.3 Get kubeconfig

```bash
# On EC2 instance
sudo cat /etc/rancher/k3s/k3s.yaml
```

Copy the output.

### 2.4 Configure Local kubectl

```bash
# On your local machine
mkdir -p ~/.kube

# Create config file
cat > ~/.kube/config-k3s <<EOF
# Paste the k3s.yaml content here
# Replace 127.0.0.1 with your EC2 public IP
EOF

# Update server URL
sed -i '' 's/127.0.0.1/<EC2-PUBLIC-IP>/' ~/.kube/config-k3s

# Set context
export KUBECONFIG=~/.kube/config-k3s
kubectl config use-context default

# Test connection
kubectl get nodes
```

## Step 3: Install NGINX Ingress Controller

```bash
# Install nginx-ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml

# Wait for it to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Verify
kubectl get pods -n ingress-nginx
```

## Step 4: Install Argo CD

```bash
# Clone your repository (or use the script)
cd /tmp
git clone https://github.com/yaroslav-lototskyi/launchpad.git
cd launchpad

# Run Argo CD setup script
./k8s/scripts/argocd-setup.sh

# Install Image Updater when prompted: y
```

**Alternative manual installation:**

```bash
# Create namespace
kubectl create namespace argocd

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.9.3/manifests/install.yaml

# Wait for pods
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server \
  deployment/argocd-repo-server \
  -n argocd

# Install Image Updater
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Step 5: Configure DNS (Optional)

### Option A: Use Elastic IP + Route53

1. Create Route53 Hosted Zone for your domain
2. Create A records:
   - `launchpad.example.com` → Elastic IP
   - `argocd.example.com` → Elastic IP
   - `*.preview.example.com` → Elastic IP

### Option B: Use /etc/hosts (local only)

```bash
# On your local machine
sudo nano /etc/hosts

# Add:
<EC2-PUBLIC-IP> launchpad.local
<EC2-PUBLIC-IP> argocd.launchpad.local
<EC2-PUBLIC-IP> preview-pr-123.launchpad.local
```

## Step 6: Deploy Argo CD Ingress

```bash
# Apply Argo CD Ingress
kubectl apply -f k8s/argocd/install/argocd-ingress.yaml
```

## Step 7: Create Argo CD Project and Application

```bash
# Apply Project
kubectl apply -f k8s/argocd/projects/development.yaml

# Apply Application
kubectl apply -f k8s/argocd/apps/launchpad-development.yaml
```

## Step 8: Access Argo CD UI

### Via Ingress (if DNS configured):

```
http://argocd.launchpad.local
Username: admin
Password: <from Step 4>
```

### Via Port Forward (if no DNS):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open: https://localhost:8080

## Step 9: Verify Deployment

```bash
# Check Argo CD Application
kubectl get application -n argocd

# Check pods
kubectl get pods -n launchpad-development

# Check ingress
kubectl get ingress -A
```

## Step 10: Access Application

```
http://launchpad.local
```

## Troubleshooting

### k3s not starting

```bash
# Check status
sudo systemctl status k3s

# View logs
sudo journalctl -u k3s -f

# Restart
sudo systemctl restart k3s
```

### Pods in ImagePullBackOff

```bash
# Check if images are public in GHCR
docker pull ghcr.io/yaroslav-lototskyi/launchpad/api:latest

# If private, create pull secret:
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=yaroslav-lototskyi \
  --docker-password=<GITHUB_PAT> \
  -n launchpad-development
```

### Cannot access from browser

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check if port 80/443 are open
curl http://<EC2-PUBLIC-IP>

# Check security group rules
```

## Costs

**EC2 t3.medium:**

- On-Demand: ~$0.0416/hour = ~$30/month
- Spot Instance: ~$0.0125/hour = ~$9/month (risky for production)

**Elastic IP:**

- Free when associated with running instance
- $0.005/hour (~$3.60/month) when not associated

**Data Transfer:**

- First 100 GB/month: Free
- After: $0.09/GB

**Total: ~$30-35/month**

## Next Steps

1. **Setup Branch Protection** (see BRANCH_PROTECTION.md)
2. **Setup Preview Environments** (see PREVIEW_ENVIRONMENTS.md)
3. **Configure monitoring** (Prometheus + Grafana)
4. **Setup backups** (etcd snapshots)
5. **SSL certificates** (cert-manager + Let's Encrypt)

## Cleanup

```bash
# Delete k3s
sudo /usr/local/bin/k3s-uninstall.sh

# Terminate EC2 instance via AWS Console
# Release Elastic IP
```
