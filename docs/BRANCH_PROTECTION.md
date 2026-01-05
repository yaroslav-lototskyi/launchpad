# Branch Protection Setup

This guide configures GitHub branch protection to enforce:

- No direct pushes to `main`
- All changes via Pull Requests only
- PR can only be merged after CI passes
- Require code review approval

## Step 1: Configure Branch Protection Rules

### Via GitHub UI:

1. Go to your repository: `https://github.com/yaroslav-lototskyi/launchpad`
2. Click **Settings** → **Branches**
3. Under "Branch protection rules", click **Add rule**

### Protection Settings:

**Branch name pattern:**

```
main
```

**Protect matching branches - Enable:**

✅ **Require a pull request before merging**

- ✅ Require approvals: `1` (or more if you have a team)
- ✅ Dismiss stale pull request approvals when new commits are pushed
- ⬜ Require review from Code Owners (optional)

✅ **Require status checks to pass before merging**

- ✅ Require branches to be up to date before merging
- **Status checks that are required:**
  - ✅ `Lint`
  - ✅ `Type Check`
  - ✅ `Test API`
  - ✅ `Test Client`
  - ✅ `Build API`
  - ✅ `Build Client`
  - ✅ `Security Scan`
  - ✅ `Docker Build Check`

✅ **Require conversation resolution before merging**

- All review comments must be resolved

✅ **Require linear history**

- No merge commits, only fast-forward or squash merges

⬜ **Require deployments to succeed before merging** (optional)

✅ **Lock branch**

- Prevent any pushes to matching branches (even admins need PR)

⬜ **Do not allow bypassing the above settings**

- Recommended: disabled for solo dev (you can force push if needed)
- Enable for teams

✅ **Restrict pushes that create matching branches**

- Only specific people/teams can create `main` branch

**Save changes**

## Step 2: Test Branch Protection

### Try Direct Push (should fail):

```bash
git checkout main
echo "test" >> README.md
git add README.md
git commit -m "test: direct push"
git push origin main
```

**Expected result:**

```
remote: error: GH006: Protected branch update failed
remote: error: Changes must be made through a pull request
```

### Correct Workflow:

```bash
# 1. Create feature branch
git checkout -b feature/add-something

# 2. Make changes
echo "feature" >> README.md
git add README.md
git commit -m "feat: add something"

# 3. Push feature branch
git push origin feature/add-something

# 4. Create PR via GitHub UI
# 5. Wait for CI to pass
# 6. Get approval (if required)
# 7. Merge PR
```

## Step 3: Workflow After Branch Protection

### Development Flow:

```
1. Create feature branch from main
   git checkout -b feature/new-feature

2. Write code, commit locally
   git add .
   git commit -m "feat: implement new feature"

3. Push to remote
   git push origin feature/new-feature

4. Create Pull Request on GitHub
   - CI automatically runs
   - Lint, Type Check, Tests, Build, Docker Build

5. CI must pass (all checks green ✅)
   - If fails: fix code, push new commit
   - CI runs again automatically

6. Request review (if required)
   - Teammate reviews code
   - Approves or requests changes

7. All checks passed + approved → Merge PR
   - Squash and merge (recommended)
   - Delete branch after merge

8. After merge to main:
   - docker-build.yml runs automatically
   - Builds multi-platform images
   - Pushes to GHCR
   - Argo CD detects new image
   - Auto-deploys to production
```

## Step 4: Required Status Checks Configuration

The following jobs from `ci.yml` must pass:

**From CI workflow** (`/.github/workflows/ci.yml`):

- `lint` - ESLint checks
- `type-check` - TypeScript compilation
- `test-api` - API unit/integration tests
- `test-client` - Client component tests
- `build-api` - Production build test
- `build-client` - Production build test
- `security-scan` - Trivy vulnerability scan
- `docker-build-check` - Docker image build test (no push)

## Step 5: Auto-merge Configuration (Optional)

Enable auto-merge for PRs when all checks pass:

```bash
# Via GitHub CLI
gh pr merge <PR-NUMBER> --auto --squash

# Or enable in PR UI:
# Click "Enable auto-merge" → "Squash and merge"
```

PR will automatically merge when:

- All CI checks pass ✅
- Required approvals received ✅
- No merge conflicts ✅

## Step 6: Status Badge (Optional)

Add CI status badge to README:

```markdown
![CI](https://github.com/yaroslav-lototskyi/launchpad/actions/workflows/ci.yml/badge.svg)
```

## Common Scenarios

### Scenario 1: CI Failed

```
PR created → CI runs → Tests fail ❌

Fix:
1. Fix the failing test locally
2. git commit -m "fix: resolve test failure"
3. git push origin feature/branch
4. CI runs again automatically
5. All pass ✅ → Can merge
```

### Scenario 2: Merge Conflict

```
PR created → Another PR merged → Conflict ⚠️

Fix:
1. git checkout main
2. git pull origin main
3. git checkout feature/branch
4. git merge main (or git rebase main)
5. Resolve conflicts
6. git push origin feature/branch
7. CI runs again
```

### Scenario 3: Need to Bypass Protection (Emergency)

```
Critical hotfix needed, can't wait for CI

Option A: Temporarily disable protection
1. Settings → Branches → Edit rule
2. Uncheck required checks
3. Merge PR
4. Re-enable protection

Option B: Admin override (if enabled)
1. Merge with admin privileges
2. Fix CI in follow-up PR
```

## Best Practices

1. **Keep PRs small** - Easier to review, faster CI
2. **Run CI locally first** - `pnpm lint && pnpm type-check && pnpm test`
3. **Write good commit messages** - Use conventional commits
4. **Squash commits** - Keep main branch clean
5. **Delete branches** - After merge, delete feature branches
6. **Review your own PR** - Check the diff before requesting review

## Troubleshooting

### Status checks not appearing

**Problem:** Created PR but no status checks running

**Solution:**

1. Check `.github/workflows/ci.yml` exists
2. Verify trigger includes PR:
   ```yaml
   on:
     pull_request:
       branches: [main]
   ```
3. Check Actions tab for errors

### Can't merge even though checks passed

**Problem:** All green but "Merge" button disabled

**Possible reasons:**

- Branch not up to date with main → Update branch
- Required reviews missing → Get approval
- Conversations not resolved → Resolve comments
- Conflicts with main → Resolve conflicts

### Check names don't match

**Problem:** Required checks don't show as passed

**Solution:**
Check exact job names in protection rules match workflow:

```yaml
# In ci.yml:
jobs:
  lint:
    name: Lint # <-- This exact name
```

Match with Settings → Branches → Required status checks.

## Next Steps

- **Setup Preview Environments** - See PREVIEW_ENVIRONMENTS.md
- **Configure CODEOWNERS** - Auto-assign reviewers
- **Setup Dependabot** - Automatic dependency updates
