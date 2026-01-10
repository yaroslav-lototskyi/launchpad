# Argo CD Password Management

Guide for managing Argo CD admin password.

## Default Behavior

### Random Password Generation

By default, Argo CD generates a **random password** on each installation:

```bash
./k8s/scripts/argocd-setup.sh

# Output:
# Password: Xln1lQWHlEopfKTN  # ← Random every time!
```

**Problem:** You need to save/copy this password each time you reinstall.

---

## Set Custom Password

### Method 1: Environment Variable (Recommended)

```bash
# Set password via environment variable
ARGOCD_ADMIN_PASSWORD='mySecurePassword123!' ./k8s/scripts/argocd-setup.sh

# Your custom password will be set automatically!
```

### Method 2: Export in Shell

For local development, you can export it in your shell profile:

```bash
# Add to ~/.bashrc or ~/.zshrc (LOCAL DEV ONLY!)
export ARGOCD_ADMIN_PASSWORD='myLocalDevPassword'

# Then just run:
./k8s/scripts/argocd-setup.sh
```

**⚠️ Security Warning:**

- **Never commit passwords to git!**
- **Never use this for production!**
- Only for local development with Kind cluster

---

## Retrieve Current Password

### If You Forgot the Password

```bash
# Get the current password from Kubernetes secret
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

**Note:** This secret is deleted if you set a custom password.

---

## Change Password After Installation

### Method 1: Using Argo CD CLI

```bash
# Login with current password
argocd login argocd.launchpad.local --username admin

# Update password interactively
argocd account update-password

# Or non-interactively
argocd account update-password \
  --current-password 'oldPassword' \
  --new-password 'newPassword'
```

### Method 2: Using kubectl

```bash
# Hash new password with bcrypt
NEW_PASSWORD='newSecurePassword'

# Requires htpasswd (from apache2-utils)
BCRYPT_HASH=$(htpasswd -nbBC 10 "" "$NEW_PASSWORD" | tr -d ':\n' | sed 's/^//')

# Update password in secret
kubectl -n argocd patch secret argocd-secret \
  -p "{\"stringData\": {\"admin.password\": \"$BCRYPT_HASH\", \"admin.passwordMtime\": \"$(date +%FT%T%Z)\"}}"
```

### Method 3: Via Argo CD UI

1. Login to Argo CD UI
2. User Info (top-right) → Update Password
3. Enter current password
4. Enter new password
5. Confirm

---

## Password Requirements

Argo CD doesn't enforce password complexity by default, but **recommended:**

- ✅ Minimum 12 characters
- ✅ Mix of uppercase and lowercase
- ✅ Include numbers
- ✅ Include special characters
- ✅ Not based on dictionary words

**Good examples:**

- `MyArgoCD2024!Local`
- `Dev#Secure$Pass123`
- `K8s_Argo_2024!`

**Bad examples:**

- `password` (too simple)
- `admin123` (too common)
- `argocd` (too obvious)

---

## Different Passwords for Different Environments

### Local Development (Kind)

```bash
ARGOCD_ADMIN_PASSWORD='localDevPassword123' ./k8s/scripts/argocd-setup.sh
```

### EC2 Development

```bash
ARGOCD_ADMIN_PASSWORD='ec2DevSecure!2024' ./k8s/scripts/argocd-setup.sh
```

### Production (Use Strong Password!)

```bash
# Generate strong random password
STRONG_PASSWORD=$(openssl rand -base64 32)

ARGOCD_ADMIN_PASSWORD="$STRONG_PASSWORD" ./k8s/scripts/argocd-setup.sh

# Save to password manager!
echo "Production Argo CD Password: $STRONG_PASSWORD"
```

---

## Reset Password (If Locked Out)

### Option 1: Delete and Recreate Secret

```bash
# Delete the admin secret
kubectl -n argocd delete secret argocd-secret

# Restart Argo CD server (will regenerate secret)
kubectl -n argocd rollout restart deployment argocd-server

# Wait for restart
kubectl -n argocd rollout status deployment argocd-server

# Get new password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### Option 2: Patch the Secret Directly

```bash
# Generate new password hash
NEW_PASSWORD='resetPassword123'
BCRYPT_HASH=$(htpasswd -nbBC 10 "" "$NEW_PASSWORD" | tr -d ':\n' | sed 's/^//')

# Patch secret
kubectl -n argocd patch secret argocd-secret \
  -p "{\"stringData\": {\"admin.password\": \"$BCRYPT_HASH\", \"admin.passwordMtime\": \"$(date +%FT%T%Z)\"}}"

# Login with new password
```

### Option 3: Nuclear Option (Fresh Install)

```bash
# Delete Argo CD completely
kubectl delete namespace argocd

# Reinstall
./k8s/scripts/argocd-setup.sh
```

---

## Security Best Practices

### ✅ DO

- **Use strong, unique passwords** for each environment
- **Store passwords in password manager** (1Password, LastPass, Bitwarden)
- **Use environment variables** for automation
- **Rotate passwords periodically** (every 90 days for production)
- **Enable MFA** in production (via OIDC/SSO)
- **Use RBAC** - create separate users, don't share admin account

### ❌ DON'T

- **Never commit passwords** to git
- **Never hardcode passwords** in scripts
- **Never use same password** across environments
- **Never share passwords** via email/Slack
- **Never use weak passwords** like "admin", "password"
- **Never store passwords in plain text files**

---

## Production Recommendations

### 1. Use SSO/OIDC Instead of Password

For production, integrate with your identity provider:

```yaml
# In argocd-cm ConfigMap
data:
  url: https://argocd.example.com
  dex.config: |
    connectors:
    - type: github
      id: github
      name: GitHub
      config:
        clientID: $GITHUB_CLIENT_ID
        clientSecret: $GITHUB_CLIENT_SECRET
        orgs:
        - name: your-org
```

### 2. Disable Admin Account After Setup

```bash
# After configuring SSO, disable local admin
argocd account update-password \
  --current-password 'current' \
  --new-password "$(openssl rand -base64 32)"

# Store new password in secure vault
# Only use for emergency access
```

### 3. Use Secrets Management

Store Argo CD password in:

- **AWS Secrets Manager** (for EC2)
- **HashiCorp Vault**
- **Kubernetes External Secrets**
- **SOPS** (Secrets OPerationS)

---

## Troubleshooting

### Issue: Password not working after setting

**Solution:**

```bash
# Check if password was actually set
kubectl get secret argocd-secret -n argocd -o jsonpath='{.data.admin\.password}' | base64 -d

# If empty, password wasn't set correctly
# Try again with argocd CLI installed
```

### Issue: "argocd CLI not found"

**Solution:**

```bash
# macOS
brew install argocd

# Linux
curl -sSL -o /usr/local/bin/argocd \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Windows (WSL)
curl -sSL -o /usr/local/bin/argocd \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```

### Issue: "htpasswd command not found"

**Solution:**

```bash
# macOS
brew install httpd  # includes htpasswd

# Ubuntu/Debian
sudo apt-get install apache2-utils

# RHEL/CentOS
sudo yum install httpd-tools
```

---

## Quick Reference

```bash
# ============================================
# Common Password Operations
# ============================================

# 1. Install with custom password
ARGOCD_ADMIN_PASSWORD='myPass123!' ./k8s/scripts/argocd-setup.sh

# 2. Get current password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# 3. Change password (CLI)
argocd account update-password

# 4. Reset password (if locked out)
kubectl -n argocd delete secret argocd-secret
kubectl -n argocd rollout restart deployment argocd-server

# 5. Generate strong password
openssl rand -base64 32
```

---

## Summary

- 🔐 Default: Random password generated each time
- 🎯 Recommended: Set custom password via `ARGOCD_ADMIN_PASSWORD` env var
- 🔄 Easy to change: Use `argocd account update-password`
- 🚨 If locked out: Delete secret and restart
- 🏭 Production: Use SSO/OIDC instead of passwords

For local development, using a simple custom password is fine. For production, always use strong passwords or SSO!
