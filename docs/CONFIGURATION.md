# Configuration Guide

This guide explains how to configure dynamic values for deployments.

## Environment Variables

### GitHub Repository Variables

Create these in GitHub Settings → Secrets and variables → Actions → Variables:

| Variable Name | Description                      | Example Value                       | Required |
| ------------- | -------------------------------- | ----------------------------------- | -------- |
| `BASE_DOMAIN` | Base domain for all environments | `launchpad.io` or `launchpad.local` | Yes      |

**How to create:**

1. Go to: `https://github.com/<your-org>/<your-repo>/settings/variables/actions`
2. Click "New repository variable"
3. Name: `BASE_DOMAIN`
4. Value: `launchpad.local` (or your actual domain)
5. Click "Add variable"

### How It Works

**Without BASE_DOMAIN variable:**

- Default: `launchpad.local`
- Preview: `preview-pr-123.launchpad.local`
- Argo CD: `argocd.launchpad.local`

**With BASE_DOMAIN = "example.com":**

- Production: `example.com`
- Preview: `preview-pr-123.example.com`
- Argo CD: `argocd.example.com`

## Dynamic Image Repositories

Image repositories are automatically detected from your GitHub repository.

### How It Works

**In GitHub Actions:**

```yaml
# Automatically extracts from ${{ github.repository }}
# Example: yaroslav-lototskyi/launchpad

REPO_LOWER=$(echo "${{ github.repository }}" | tr '[:upper:]' '[:lower:]')
# Result: yaroslav-lototskyi/launchpad

IMAGE: ghcr.io/yaroslav-lototskyi/launchpad/api:latest
```

**In Helm Charts:**

```yaml
# values.yaml sets defaults
imageDefaults:
  registry: ghcr.io
  organization: '' # Auto-detected
  repository: '' # Auto-detected

# Can be overridden via Argo CD parameters
parameters:
  - name: imageDefaults.organization
    value: 'your-github-org'
  - name: imageDefaults.repository
    value: 'your-repo-name'
```

## Configure Argo CD Application

### Automatic Configuration

Use the helper script:

```bash
# Run from project root
./k8s/scripts/configure-argocd-app.sh
```

This will:

1. Detect your GitHub org/repo from git remote
2. Replace `{{GITHUB_ORG}}` and `{{GITHUB_REPO}}` placeholders
3. Generate `launchpad-development.configured.yaml`

### Manual Configuration

Edit `k8s/argocd/apps/launchpad-development.yaml`:

Replace placeholders:

- `{{GITHUB_ORG}}` → Your GitHub organization/username
- `{{GITHUB_REPO}}` → Your repository name

**Example:**

```yaml
# Before
repoURL: https://github.com/{{GITHUB_ORG}}/{{GITHUB_REPO}}
argocd-image-updater.argoproj.io/image-list: |
  api=ghcr.io/{{GITHUB_ORG}}/{{GITHUB_REPO}}/api:latest

# After
repoURL: https://github.com/yaroslav-lototskyi/launchpad
argocd-image-updater.argoproj.io/image-list: |
  api=ghcr.io/yaroslav-lototskyi/launchpad/api:latest
```

### Apply Configuration

```bash
# Option 1: Using configured file
kubectl apply -f k8s/argocd/apps/launchpad-development.configured.yaml

# Option 2: Direct with sed
cat k8s/argocd/apps/launchpad-development.yaml | \
  sed 's/{{GITHUB_ORG}}/yaroslav-lototskyi/g' | \
  sed 's/{{GITHUB_REPO}}/launchpad/g' | \
  kubectl apply -f -
```

## Configure Argo CD Ingress

### Automatic Configuration

```bash
# Use default domain (launchpad.local)
./k8s/scripts/configure-argocd-ingress.sh

# Use custom domain
./k8s/scripts/configure-argocd-ingress.sh example.com

# Or with environment variable
BASE_DOMAIN=example.com ./k8s/scripts/configure-argocd-ingress.sh
```

This generates `argocd-ingress.yaml` from `argocd-ingress.template.yaml`.

### Manual Configuration

Edit `k8s/argocd/install/argocd-ingress.yaml`:

Replace `{{BASE_DOMAIN}}` with your domain:

```yaml
# Before
host: argocd.{{BASE_DOMAIN}}

# After
host: argocd.launchpad.local
```

### Apply Configuration

```bash
kubectl apply -f k8s/argocd/install/argocd-ingress.yaml
```

## Preview Environments

Preview environments use the `deploy` label.

### Trigger Preview Deployment

**Via GitHub UI:**

1. Open Pull Request
2. Go to Labels (right sidebar)
3. Add label: `deploy`
4. GitHub Actions automatically builds preview images
5. Check PR comments for deployment instructions

**Via GitHub CLI:**

```bash
# Add deploy label
gh pr edit <PR-NUMBER> --add-label deploy

# Remove deploy label (triggers cleanup)
gh pr edit <PR-NUMBER> --remove-label deploy
```

### Preview Domain

Preview environments use pattern: `preview-pr-{NUMBER}.{BASE_DOMAIN}`

**Examples:**

- PR #123 with `BASE_DOMAIN=launchpad.local`:
  - URL: `preview-pr-123.launchpad.local`

- PR #456 with `BASE_DOMAIN=example.com`:
  - URL: `preview-pr-456.example.com`

## Complete Setup Example

```bash
# 1. Configure GitHub repository variable
# Go to GitHub Settings → Variables → Add BASE_DOMAIN

# 2. Configure Argo CD Application
./k8s/scripts/configure-argocd-app.sh

# 3. Configure Argo CD Ingress
./k8s/scripts/configure-argocd-ingress.sh

# 4. Apply to cluster
kubectl apply -f k8s/argocd/projects/development.yaml
kubectl apply -f k8s/argocd/apps/launchpad-development.configured.yaml
kubectl apply -f k8s/argocd/install/argocd-ingress.yaml

# 5. Update /etc/hosts
sudo sh -c 'echo "<EC2-IP> argocd.launchpad.local" >> /etc/hosts'
sudo sh -c 'echo "<EC2-IP> launchpad.local" >> /etc/hosts'

# 6. Access Argo CD
open http://argocd.launchpad.local
```

## Docker Build Configuration

Docker builds automatically use repository information:

```yaml
# .github/workflows/docker-build.yml
steps:
  - name: Extract image repository
    run: |
      REPO_LOWER=$(echo "${{ github.repository }}" | tr '[:upper:]' '[:lower:]')
      echo "api_image=ghcr.io/${REPO_LOWER}/api" >> $GITHUB_OUTPUT
```

No hardcoded values needed!

## Helm Chart Overrides

You can override any value via Argo CD parameters:

```yaml
# In Argo CD Application
spec:
  source:
    helm:
      parameters:
        # Override image repository
        - name: api.image.repository
          value: ghcr.io/custom-org/custom-repo/api

        # Override domain
        - name: global.domain
          value: custom.example.com

        # Override image defaults
        - name: imageDefaults.registry
          value: docker.io
        - name: imageDefaults.organization
          value: mycompany
```

## Troubleshooting

### Images not pulling

**Problem:** Pods stuck in `ImagePullBackOff`

**Solution:** Check image repository in Argo CD Application:

```bash
# Check current image
kubectl get deployment -n launchpad-development -o yaml | grep image:

# Should show correct format:
# image: ghcr.io/yaroslav-lototskyi/launchpad/api:latest
```

### Wrong domain in Ingress

**Problem:** Ingress has wrong hostname

**Solution:** Re-run configuration script:

```bash
./k8s/scripts/configure-argocd-ingress.sh your-domain.com
kubectl apply -f k8s/argocd/install/argocd-ingress.yaml
```

### Preview environment not deploying

**Problem:** Added `deploy` label but nothing happens

**Solution:** Check GitHub Actions:

1. Go to Actions tab
2. Look for "Preview Environment - Deploy" workflow
3. Check if it ran and succeeded
4. Review PR comments for instructions

## Best Practices

1. **Use GitHub Variables** for domains - easier to change
2. **Run config scripts** before applying to cluster
3. **Don't commit configured files** - use templates with placeholders
4. **Use lowercase** for GHCR image names (required by GHCR)
5. **Keep BASE_DOMAIN in Variables** - not in code

## Next Steps

- **Setup DNS** for production domains
- **Configure TLS** with cert-manager
- **Setup monitoring** for all environments
- **Automate cleanup** of old preview environments
