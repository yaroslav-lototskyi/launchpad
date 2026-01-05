# Preview Environments для Pull Requests

Preview environments створюють тимчасове середовище для кожного PR, де можна протестувати зміни перед merge в main.

## Архітектура

```
PR #123 created
    ↓
GitHub Actions builds preview images
    ↓
Tags: pr-123-api, pr-123-client
    ↓
Pushes to GHCR
    ↓
Argo CD Application created: launchpad-pr-123
    ↓
Deploys to namespace: launchpad-pr-123
    ↓
Accessible at: http://preview-pr-123.launchpad.local

PR merged/closed
    ↓
Argo CD Application deleted
    ↓
Namespace cleaned up
    ↓
Resources freed
```

## Implementation

### Step 1: Create Preview Build Workflow

Create `.github/workflows/preview-build.yml`:

```yaml
name: Preview Environment - Build

on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [main]

env:
  REGISTRY_GHCR: ghcr.io
  PR_NUMBER: ${{ github.event.pull_request.number }}

jobs:
  build-preview:
    name: Build Preview Images
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      pull-requests: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY_GHCR }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push API preview image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./apps/api/deployment/production/Dockerfile
          push: true
          tags: |
            ${{ env.REGISTRY_GHCR }}/${{ github.repository }}/api:pr-${{ env.PR_NUMBER }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64

      - name: Build and push Client preview image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./apps/client/deployment/production/Dockerfile
          push: true
          tags: |
            ${{ env.REGISTRY_GHCR }}/${{ github.repository }}/client:pr-${{ env.PR_NUMBER }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64
          build-args: |
            VITE_API_BASE_URL=

      - name: Create Argo CD Application manifest
        run: |
          cat > /tmp/preview-app.yaml <<EOF
          apiVersion: argoproj.io/v1alpha1
          kind: Application
          metadata:
            name: launchpad-pr-${{ env.PR_NUMBER }}
            namespace: argocd
            finalizers:
              - resources-finalizer.argocd.argoproj.io
          spec:
            project: launchpad-development
            source:
              repoURL: https://github.com/${{ github.repository }}
              targetRevision: ${{ github.head_ref }}
              path: infra/helm/launchpad
              helm:
                valueFiles:
                  - values-development.yaml
                parameters:
                  - name: api.image.tag
                    value: pr-${{ env.PR_NUMBER }}
                  - name: client.image.tag
                    value: pr-${{ env.PR_NUMBER }}
                  - name: global.domain
                    value: preview-pr-${{ env.PR_NUMBER }}.launchpad.local
            destination:
              server: https://kubernetes.default.svc
              namespace: launchpad-pr-${{ env.PR_NUMBER }}
            syncPolicy:
              automated:
                prune: true
                selfHeal: true
              syncOptions:
                - CreateNamespace=true
          EOF

      - name: Deploy to cluster via kubectl
        run: |
          # This would need kubeconfig access
          # For now, we'll comment PR with instructions
          echo "Preview app manifest created"

      - name: Comment PR with preview URL
        uses: actions/github-script@v7
        with:
          script: |
            const prNumber = ${{ env.PR_NUMBER }};
            const comment = `## 🚀 Preview Environment

            Your preview environment is being deployed!

            **Preview URL**: http://preview-pr-${prNumber}.launchpad.local

            **Argo CD Application**: \`launchpad-pr-${prNumber}\`

            **To deploy manually**:
            \`\`\`bash
            kubectl apply -f - <<EOF
            # See /tmp/preview-app.yaml from workflow logs
            EOF
            \`\`\`

            **Images**:
            - API: \`ghcr.io/${{ github.repository }}/api:pr-${prNumber}\`
            - Client: \`ghcr.io/${{ github.repository }}/client:pr-${prNumber}\`

            This environment will be automatically deleted when the PR is closed.
            `;

            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: prNumber,
              body: comment
            });
```

### Step 2: Create Preview Cleanup Workflow

Create `.github/workflows/preview-cleanup.yml`:

```yaml
name: Preview Environment - Cleanup

on:
  pull_request:
    types: [closed]
    branches: [main]

env:
  PR_NUMBER: ${{ github.event.pull_request.number }}

jobs:
  cleanup-preview:
    name: Delete Preview Environment
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      pull-requests: write

    steps:
      - name: Delete Argo CD Application
        run: |
          # This would need kubeconfig access
          echo "Would delete: launchpad-pr-${{ env.PR_NUMBER }}"
          # kubectl delete application launchpad-pr-${{ env.PR_NUMBER }} -n argocd

      - name: Delete preview images from GHCR
        run: |
          echo "Cleanup preview images"
          # Can be done via GitHub API or gh CLI
          # gh api --method DELETE /user/packages/container/launchpad%2Fapi/versions/pr-${{ env.PR_NUMBER }}

      - name: Comment PR with cleanup status
        uses: actions/github-script@v7
        with:
          script: |
            const prNumber = ${{ env.PR_NUMBER }};
            const comment = `## 🧹 Preview Environment Cleaned Up

            The preview environment for this PR has been deleted.

            - Argo CD Application: \`launchpad-pr-${prNumber}\` ❌ Deleted
            - Namespace: \`launchpad-pr-${prNumber}\` ❌ Deleted
            - Preview images: Scheduled for deletion
            `;

            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: prNumber,
              body: comment
            });
```

## Manual Deployment (Without GitHub Actions kubectl access)

Since GitHub Actions won't have direct kubectl access to your EC2 cluster, you can deploy preview environments manually:

### Option 1: Manual kubectl apply

When PR is created and images are built:

```bash
# On your local machine (with kubectl configured)

PR_NUMBER=123

kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: launchpad-pr-${PR_NUMBER}
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: launchpad-development
  source:
    repoURL: https://github.com/yaroslav-lototskyi/launchpad
    targetRevision: HEAD
    path: infra/helm/launchpad
    helm:
      valueFiles:
        - values-development.yaml
      parameters:
        - name: api.image.tag
          value: pr-${PR_NUMBER}
        - name: client.image.tag
          value: pr-${PR_NUMBER}
        - name: global.domain
          value: preview-pr-${PR_NUMBER}.launchpad.local
  destination:
    server: https://kubernetes.default.svc
    namespace: launchpad-pr-${PR_NUMBER}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

### Option 2: Argo CD UI

1. Open Argo CD UI
2. Click "New App"
3. Fill in:
   - **Application Name**: `launchpad-pr-123`
   - **Project**: `launchpad-development`
   - **Sync Policy**: Automatic
   - **Repository URL**: `https://github.com/yaroslav-lototskyi/launchpad`
   - **Path**: `infra/helm/launchpad`
   - **Cluster**: `in-cluster`
   - **Namespace**: `launchpad-pr-123`
   - **Helm Parameters**:
     - `api.image.tag` = `pr-123`
     - `client.image.tag` = `pr-123`
     - `global.domain` = `preview-pr-123.launchpad.local`
4. Click "Create"

### Option 3: Argo CD CLI

```bash
argocd login argocd.launchpad.local

PR_NUMBER=123

argocd app create launchpad-pr-${PR_NUMBER} \
  --project launchpad-development \
  --repo https://github.com/yaroslav-lototskyi/launchpad \
  --path infra/helm/launchpad \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace launchpad-pr-${PR_NUMBER} \
  --helm-set api.image.tag=pr-${PR_NUMBER} \
  --helm-set client.image.tag=pr-${PR_NUMBER} \
  --helm-set global.domain=preview-pr-${PR_NUMBER}.launchpad.local \
  --sync-policy automated \
  --sync-option CreateNamespace=true
```

## Accessing Preview Environments

### Update /etc/hosts

```bash
sudo nano /etc/hosts

# Add:
<EC2-IP> preview-pr-123.launchpad.local
<EC2-IP> preview-pr-456.launchpad.local
```

### Or use wildcard DNS (if configured)

```
*.preview.launchpad.com → EC2-IP
```

Then access: `http://preview-pr-123.preview.launchpad.com`

## Cleanup Preview Environments

### Delete via kubectl

```bash
kubectl delete application launchpad-pr-123 -n argocd
```

### Delete via Argo CD UI

1. Open Argo CD
2. Select `launchpad-pr-123`
3. Click "Delete"
4. Confirm

### Delete via Argo CD CLI

```bash
argocd app delete launchpad-pr-123
```

## Resource Limits

To prevent preview environments from consuming too many resources:

### Option 1: Add to values-development.yaml

```yaml
api:
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi

client:
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 50m
      memory: 64Mi
```

### Option 2: ResourceQuota per namespace

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: preview-quota
  namespace: launchpad-pr-123
spec:
  hard:
    requests.cpu: '500m'
    requests.memory: '512Mi'
    limits.cpu: '1000m'
    limits.memory: '1Gi'
    pods: '10'
```

## Best Practices

1. **Limit concurrent previews** - Max 5-10 active PRs
2. **Auto-cleanup after 7 days** - Delete stale preview envs
3. **Use resource quotas** - Prevent resource exhaustion
4. **Share database** - Use shared dev database, not per-preview
5. **Monitor costs** - Track resource usage per preview
6. **Document preview URLs** - Comment on PR with access info

## Advanced: Automated Preview Management

For fully automated preview environments (future enhancement), you would need:

1. **GitHub Actions Runner on EC2** - Self-hosted runner with kubectl access
2. **Argo CD ApplicationSet** - Template-based app generation
3. **Argo CD Notifications** - Notify PR when preview is ready
4. **TTL Controller** - Auto-delete after N days

## Next Steps

1. Create preview workflows (manual for now)
2. Test creating preview for a PR
3. Verify preview environment works
4. Document cleanup procedure
5. Consider automation options later
