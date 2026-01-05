# Preview Environments Setup with ApplicationSet

This guide explains how to setup automatic preview environments using Argo CD ApplicationSet with Pull Request Generator.

## How It Works

```
1. Create PR
2. Add label "deploy" to PR
   ↓
3. Argo CD ApplicationSet detects PR with label
   ↓
4. Automatically creates Application: launchpad-pr-123
   ↓
5. Argo CD deploys to namespace: launchpad-pr-123
   ↓
6. Preview available at: preview-pr-123.{BASE_DOMAIN}
   ↓
7. New commits → Argo CD auto-syncs
   ↓
8. Remove "deploy" label OR close PR
   ↓
9. Argo CD automatically deletes Application + namespace
```

**No manual kubectl commands needed!**

## Prerequisites

1. Argo CD installed in cluster
2. GitHub Personal Access Token (PAT)
3. Docker images built for PR (via GitHub Actions)

## Step 1: Create GitHub Personal Access Token

Argo CD needs read-only access to GitHub API to watch PRs.

**Create token:**

1. Go to: https://github.com/settings/tokens/new
2. Token name: `argo-cd-pr-generator`
3. Expiration: No expiration (or custom)
4. Scopes (select only these):
   - ✅ `repo` → `public_repo` (for public repos)
   - ✅ `repo` (full) - if private repo
5. Click "Generate token"
6. **Copy token** - you won't see it again!

**Example token:** `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## Step 2: Create Kubernetes Secret

```bash
# Replace with your actual token
GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

kubectl create secret generic github-token \
  --from-literal=token=${GITHUB_TOKEN} \
  -n argocd

# Verify
kubectl get secret github-token -n argocd
```

**Security note:** This token only needs read access to pull requests.

## Step 3: Configure ApplicationSet

The ApplicationSet template uses placeholders that need to be replaced.

### Option A: Using Configuration Script

```bash
# Run from project root
./k8s/scripts/configure-argocd-applicationset.sh

# This will:
# 1. Detect GitHub org/repo from git remote
# 2. Replace placeholders in template
# 3. Generate configured file
```

### Option B: Manual Configuration

Edit `k8s/argocd/applicationsets/launchpad-previews.yaml`:

Replace:

- `{{GITHUB_ORG}}` → Your GitHub org/username (e.g., `yaroslav-lototskyi`)
- `{{GITHUB_REPO}}` → Your repo name (e.g., `launchpad`)
- `{{BASE_DOMAIN}}` → Your base domain (e.g., `launchpad.local`)

**Example:**

```yaml
# Before
owner: '{{GITHUB_ORG}}'
repo: '{{GITHUB_REPO}}'
value: 'preview-pr-{{number}}.{{BASE_DOMAIN}}'

# After
owner: 'yaroslav-lototskyi'
repo: 'launchpad'
value: 'preview-pr-{{number}}.launchpad.local'
```

## Step 4: Apply ApplicationSet

```bash
# Option A: Using configured file
kubectl apply -f k8s/argocd/applicationsets/launchpad-previews.configured.yaml

# Option B: Direct with sed (quick)
cat k8s/argocd/applicationsets/launchpad-previews.yaml | \
  sed 's/{{GITHUB_ORG}}/yaroslav-lototskyi/g' | \
  sed 's/{{GITHUB_REPO}}/launchpad/g' | \
  sed 's/{{BASE_DOMAIN}}/launchpad.local/g' | \
  kubectl apply -f -
```

## Step 5: Verify Setup

```bash
# Check ApplicationSet
kubectl get applicationset -n argocd

# Should show:
# NAME                  AGE
# launchpad-previews    10s

# Describe to see status
kubectl describe applicationset launchpad-previews -n argocd
```

## Usage

### Create Preview Environment

1. **Create Pull Request** on GitHub
2. **Add label** `deploy` to the PR (Labels → Add label → deploy)
3. **Wait 3 minutes** (Argo CD checks every 3 min)
4. **Check Argo CD UI**:
   - New Application appears: `launchpad-pr-123`
   - Status: Syncing → Healthy
5. **Add to /etc/hosts**:
   ```bash
   sudo sh -c 'echo "<EC2-IP> preview-pr-123.launchpad.local" >> /etc/hosts'
   ```
6. **Access preview**: http://preview-pr-123.launchpad.local

### Update Preview (New Commits)

1. **Push new commits** to PR branch
2. **Wait ~3 minutes**
3. Argo CD **automatically syncs** new changes

### Delete Preview Environment

**Option A: Remove label**

- Go to PR → Labels → Remove "deploy" label
- Wait ~3 minutes
- Argo CD automatically deletes Application

**Option B: Close/Merge PR**

- Close or merge the PR
- Argo CD automatically deletes Application

## Monitoring

### Via Argo CD UI

1. Open Argo CD: `http://argocd.launchpad.local`
2. Filter by label: `preview=true`
3. See all preview environments
4. Click on any to see details

### Via kubectl

```bash
# List all preview Applications
kubectl get applications -n argocd -l preview=true

# Get details for specific preview
kubectl describe application launchpad-pr-123 -n argocd

# Check preview pods
kubectl get pods -n launchpad-pr-123

# View preview logs
kubectl logs -n launchpad-pr-123 -l app.kubernetes.io/component=api
```

### Via Argo CD CLI

```bash
# Login
argocd login argocd.launchpad.local

# List preview apps
argocd app list -l preview=true

# Get app details
argocd app get launchpad-pr-123

# View sync status
argocd app sync launchpad-pr-123 --dry-run
```

## Docker Images for Previews

Preview environments need Docker images tagged with PR number.

### GitHub Actions Workflow

When label "deploy" is added, GitHub Actions should build images:

```yaml
# .github/workflows/docker-build.yml
on:
  pull_request:
    types: [labeled]

jobs:
  build-preview:
    if: github.event.label.name == 'deploy'
    # Build and push images with pr-{number} tag
```

See `docs/CONFIGURATION.md` for details.

## Troubleshooting

### ApplicationSet not creating Applications

**Problem:** Added "deploy" label but no Application created

**Solutions:**

1. Check ApplicationSet exists:

   ```bash
   kubectl get applicationset launchpad-previews -n argocd
   ```

2. Check ApplicationSet status:

   ```bash
   kubectl describe applicationset launchpad-previews -n argocd
   # Look for errors in Events
   ```

3. Check GitHub token:

   ```bash
   kubectl get secret github-token -n argocd
   # Should exist with 'token' key
   ```

4. Check Argo CD logs:
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller
   # Look for GitHub API errors
   ```

### Application created but not syncing

**Problem:** Application exists but stuck in "OutOfSync"

**Solutions:**

1. Check if images exist:

   ```bash
   docker pull ghcr.io/yaroslav-lototskyi/launchpad/api:pr-123
   ```

2. Check Application status:

   ```bash
   argocd app get launchpad-pr-123
   # Look for sync errors
   ```

3. Check pod events:
   ```bash
   kubectl get events -n launchpad-pr-123 --sort-by='.lastTimestamp'
   ```

### Preview domain not accessible

**Problem:** Cannot access preview URL

**Solutions:**

1. Check Ingress:

   ```bash
   kubectl get ingress -n launchpad-pr-123
   ```

2. Check /etc/hosts:

   ```bash
   cat /etc/hosts | grep preview-pr-123
   ```

3. Check pods running:
   ```bash
   kubectl get pods -n launchpad-pr-123
   ```

### GitHub API rate limit

**Problem:** ApplicationSet stops working, logs show rate limit errors

**Solutions:**

1. Use authenticated token (should have higher limits)
2. Increase `requeueAfterSeconds` in ApplicationSet (check less often)
3. Check rate limit status:
   ```bash
   curl -H "Authorization: token ${GITHUB_TOKEN}" \
     https://api.github.com/rate_limit
   ```

## Resource Limits

To prevent preview environments from consuming too much resources:

### Per-namespace Quotas

Create ResourceQuota for all preview namespaces:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: preview-quota
  namespace: launchpad-pr-{{ number }}
spec:
  hard:
    requests.cpu: '500m'
    requests.memory: '512Mi'
    limits.cpu: '1000m'
    limits.memory: '1Gi'
    pods: '10'
```

### Limit Preview Count

In ApplicationSet, you can limit concurrent previews:

```yaml
# Only create previews for last 5 PRs
generators:
- pullRequest:
    ...
    # Add filter
    filters:
    - maxNumber: 5
```

## Best Practices

1. **Use label "deploy"** - explicit opt-in for previews
2. **Set resource limits** - prevent resource exhaustion
3. **Clean up old PRs** - close/merge PRs when done
4. **Monitor preview count** - limit concurrent previews
5. **Use preview for testing** - not for long-term environments
6. **Add PR link** - annotations help track back to PR

## Advanced: Notifications

Get Slack/email notifications when preview is ready:

```yaml
# In ApplicationSet template
metadata:
  annotations:
    notifications.argoproj.io/subscribe.on-sync-succeeded.slack: previews-channel
```

See Argo CD Notifications documentation.

## Next Steps

- Configure DNS wildcard for preview domains
- Setup TLS with cert-manager
- Add preview URL to PR comments (via GitHub Actions)
- Setup automatic cleanup after N days
- Configure monitoring for preview environments
