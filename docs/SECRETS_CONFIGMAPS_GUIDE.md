# Secrets and ConfigMaps - Complete Guide

## Table of Contents

- [What are they?](#what-are-they)
- [ConfigMaps](#configmaps)
- [Secrets](#secrets)
- [Comparison](#comparison)
- [Best Practices](#best-practices)

---

## What are they?

Both **ConfigMaps** and **Secrets** are Kubernetes resources for storing configuration data separately from application code.

```
┌─── Pod ───────────────┐
│                       │
│  App Container        │
│  ├─ Code             │
│  ├─ ENV ← ConfigMap  │  Configuration (non-sensitive)
│  └─ ENV ← Secret     │  Credentials (sensitive)
│                       │
└───────────────────────┘
```

**Key Difference:**

- **ConfigMap** - Plain text configuration (database host, timeouts, feature flags)
- **Secret** - Sensitive data (passwords, API keys, certificates)

---

## ConfigMaps

### Creating ConfigMaps

#### Method 1: From literal values

```bash
kubectl create configmap app-config \
  --from-literal=database.host=postgres.local \
  --from-literal=database.port=5432 \
  --from-literal=api.timeout=30 \
  -n launchpad-development
```

#### Method 2: From files

```bash
# Create config file
cat > app.properties << EOF
database.host=postgres.local
database.port=5432
api.timeout=30
EOF

# Create ConfigMap from file
kubectl create configmap app-config \
  --from-file=app.properties \
  -n launchpad-development
```

#### Method 3: From directory

```bash
# Create multiple config files
mkdir configs
echo "server=prod" > configs/server.conf
echo "timeout=30" > configs/timeout.conf

# Create ConfigMap from all files in directory
kubectl create configmap app-config \
  --from-file=configs/ \
  -n launchpad-development
```

#### Method 4: From YAML manifest

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: launchpad-development
data:
  # Simple key-value pairs
  database.host: 'postgres.local'
  database.port: '5432'
  api.timeout: '30'

  # Multi-line configuration file
  nginx.conf: |
    server {
      listen 80;
      server_name launchpad.local;

      location /api {
        proxy_pass http://api:3001;
      }
    }

  # JSON configuration
  app.json: |
    {
      "server": {
        "port": 3000,
        "host": "0.0.0.0"
      },
      "features": {
        "auth": true,
        "payments": false
      }
    }
```

```bash
kubectl apply -f configmap.yaml
```

### Using ConfigMaps

#### Option 1: As Environment Variables

**Single value:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
    - name: app
      image: myapp:latest
      env:
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database.host

        - name: DATABASE_PORT
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database.port
```

**All keys as environment variables:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
    - name: app
      image: myapp:latest
      envFrom:
        - configMapRef:
            name: app-config
```

Result inside container:

```bash
echo $database_host  # postgres.local
echo $database_port  # 5432
echo $api_timeout    # 30
```

#### Option 2: As Volume (Files)

**Mount entire ConfigMap:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
    - name: app
      image: myapp:latest
      volumeMounts:
        - name: config
          mountPath: /etc/config
          readOnly: true

  volumes:
    - name: config
      configMap:
        name: app-config
```

Result inside container:

```bash
ls /etc/config
# database.host
# database.port
# api.timeout
# nginx.conf
# app.json

cat /etc/config/database.host
# postgres.local
```

**Mount specific key as file:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
    - name: nginx
      image: nginx:alpine
      volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: nginx.conf

  volumes:
    - name: nginx-config
      configMap:
        name: app-config
        items:
          - key: nginx.conf
            path: nginx.conf
```

Result:

```bash
cat /etc/nginx/conf.d/default.conf
# server {
#   listen 80;
#   ...
# }
```

### Updating ConfigMaps

**Edit directly:**

```bash
kubectl edit configmap app-config -n launchpad-development
```

**Update from file:**

```bash
kubectl create configmap app-config \
  --from-file=app.properties \
  -n launchpad-development \
  --dry-run=client -o yaml | kubectl apply -f -
```

**IMPORTANT**: Pods need to be restarted to pick up ConfigMap changes when used as environment variables. When mounted as volumes, changes are reflected automatically (may take up to 60 seconds).

```bash
# Restart deployment to pick up changes
kubectl rollout restart deployment myapp -n launchpad-development
```

---

## Secrets

### Types of Secrets

1. **Opaque** - Generic secret (default)
2. **kubernetes.io/service-account-token** - Service account token
3. **kubernetes.io/dockerconfigjson** - Docker registry credentials
4. **kubernetes.io/tls** - TLS certificate and key
5. **kubernetes.io/ssh-auth** - SSH private key
6. **kubernetes.io/basic-auth** - Basic authentication credentials

### Creating Secrets

#### Generic Secret (Opaque)

```bash
# From literal values
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=supersecret123 \
  -n launchpad-development

# From files
echo -n 'admin' > username.txt
echo -n 'supersecret123' > password.txt
kubectl create secret generic db-credentials \
  --from-file=username=username.txt \
  --from-file=password=password.txt \
  -n launchpad-development

# From YAML (need to base64 encode manually)
echo -n 'admin' | base64
# YWRtaW4=
echo -n 'supersecret123' | base64
# c3VwZXJzZWNyZXQxMjM=
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: launchpad-development
type: Opaque
data:
  username: YWRtaW4=
  password: c3VwZXJzZWNyZXQxMjM=
```

**OR** use `stringData` (no base64 needed):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: launchpad-development
type: Opaque
stringData:
  username: admin
  password: supersecret123
```

#### Docker Registry Secret

```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=yaroslav-lototskyi \
  --docker-password=ghp_xxxxxxxxxxxx \
  --docker-email=email@example.com \
  -n launchpad-development
```

Use in Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  imagePullSecrets:
    - name: ghcr-secret
  containers:
    - name: app
      image: ghcr.io/yaroslav-lototskyi/myapp:latest
```

#### TLS Secret

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=launchpad.local"

# Create secret
kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key \
  -n launchpad-development
```

Use in Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: launchpad
spec:
  tls:
    - hosts:
        - launchpad.local
      secretName: tls-secret
  rules:
    - host: launchpad.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: client
                port:
                  number: 80
```

#### SSH Auth Secret

```bash
kubectl create secret generic ssh-key-secret \
  --from-file=ssh-privatekey=$HOME/.ssh/id_rsa \
  --from-file=ssh-publickey=$HOME/.ssh/id_rsa.pub \
  -n launchpad-development
```

### Using Secrets

#### Option 1: As Environment Variables

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
    - name: app
      image: myapp:latest
      env:
        # Single secret value
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username

        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
```

**All keys as environment variables:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
    - name: app
      image: myapp:latest
      envFrom:
        - secretRef:
            name: db-credentials
```

#### Option 2: As Volume (Files)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
    - name: app
      image: myapp:latest
      volumeMounts:
        - name: secrets
          mountPath: /etc/secrets
          readOnly: true

  volumes:
    - name: secrets
      secret:
        secretName: db-credentials
```

Result:

```bash
cat /etc/secrets/username
# admin

cat /etc/secrets/password
# supersecret123
```

**Mount specific key:**

```yaml
volumes:
  - name: db-password
    secret:
      secretName: db-credentials
      items:
        - key: password
          path: database-password
          mode: 0400 # Readonly for owner only
```

### Viewing Secrets

```bash
# List secrets
kubectl get secrets -n launchpad-development

# Show secret (values are base64 encoded)
kubectl get secret db-credentials -n launchpad-development -o yaml

# Decode specific value
kubectl get secret db-credentials -n launchpad-development \
  -o jsonpath='{.data.password}' | base64 --decode

# Describe (doesn't show values)
kubectl describe secret db-credentials -n launchpad-development
```

### Editing Secrets

```bash
# Edit interactively (values in base64)
kubectl edit secret db-credentials -n launchpad-development

# Update from literal
kubectl create secret generic db-credentials \
  --from-literal=username=newuser \
  --from-literal=password=newpassword \
  -n launchpad-development \
  --dry-run=client -o yaml | kubectl apply -f -

# Delete and recreate
kubectl delete secret db-credentials -n launchpad-development
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=newsecret \
  -n launchpad-development
```

---

## Comparison

| Feature                | ConfigMap                   | Secret              |
| ---------------------- | --------------------------- | ------------------- |
| **Purpose**            | Non-sensitive configuration | Sensitive data      |
| **Storage**            | Plain text                  | Base64 encoded      |
| **Encryption at rest** | No                          | No (by default)\*   |
| **Size limit**         | 1MB                         | 1MB                 |
| **Use as env vars**    | ✅ Yes                      | ✅ Yes              |
| **Use as volumes**     | ✅ Yes                      | ✅ Yes              |
| **Visible in `get`**   | ✅ Yes                      | ⚠️ Base64 encoded   |
| **RBAC**               | Same as other resources     | Can restrict access |

\*Encryption at rest can be enabled with [KMS provider](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)

---

## Best Practices

### ConfigMaps

1. **Separate by environment**

   ```yaml
   # configmap-dev.yaml
   data:
     database.host: "postgres-dev.local"

   # configmap-prod.yaml
   data:
     database.host: "postgres-prod.rds.amazonaws.com"
   ```

2. **Use namespaces for isolation**

   ```bash
   kubectl create configmap app-config -n dev
   kubectl create configmap app-config -n prod
   ```

3. **Document configuration**

   ```yaml
   data:
     # Database connection settings
     database.host: 'postgres.local'
     database.port: '5432' # Default PostgreSQL port
   ```

4. **Use volume mounts for large configs**
   - Env vars have size limits
   - Files are better for nginx.conf, application.properties

5. **Restart pods after ConfigMap changes**
   ```bash
   kubectl rollout restart deployment myapp -n dev
   ```

### Secrets

1. **NEVER commit secrets to Git**

   ```bash
   # .gitignore
   secrets/
   *.secret.yaml
   ```

2. **Use external secret management** (production)
   - [External Secrets Operator](https://external-secrets.io/)
   - [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
   - [Vault](https://www.vaultproject.io/)
   - AWS Secrets Manager
   - Google Secret Manager

3. **Limit RBAC access to secrets**

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: secret-reader
   rules:
     - apiGroups: ['']
       resources: ['secrets']
       verbs: ['get', 'list']
       resourceNames: ['specific-secret-only']
   ```

4. **Use imagePullSecrets for private registries**

   ```yaml
   spec:
     imagePullSecrets:
       - name: ghcr-secret
   ```

5. **Enable encryption at rest** (production)

   ```bash
   # Configure etcd encryption
   # https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
   ```

6. **Rotate secrets regularly**

   ```bash
   # Update secret
   kubectl create secret generic db-credentials \
     --from-literal=password=new-password \
     --dry-run=client -o yaml | kubectl apply -f -

   # Restart pods
   kubectl rollout restart deployment myapp
   ```

7. **Use secret projection to combine multiple secrets**
   ```yaml
   volumes:
     - name: all-secrets
       projected:
         sources:
           - secret:
               name: db-credentials
           - secret:
               name: api-keys
           - configMap:
               name: app-config
   ```

### General

1. **Name consistently**

   ```
   Good:
   - app-config
   - app-secrets
   - db-credentials

   Bad:
   - config1
   - secret_data
   - myConfigMap
   ```

2. **Use labels**

   ```yaml
   metadata:
     labels:
       app: launchpad
       component: api
       environment: production
   ```

3. **Validate before applying**

   ```bash
   # Dry run
   kubectl apply -f configmap.yaml --dry-run=client

   # Validate
   kubectl apply -f configmap.yaml --validate=true
   ```

4. **Backup important configs**
   ```bash
   kubectl get configmap app-config -n prod -o yaml > backup-config.yaml
   kubectl get secret db-credentials -n prod -o yaml > backup-secret.yaml
   ```

---

## Real-World Example

### Helm Chart with ConfigMaps and Secrets

**values.yaml:**

```yaml
config:
  database:
    host: postgres.local
    port: 5432
  api:
    timeout: 30
    rateLimit: 100

secrets:
  database:
    username: admin
    password: supersecret
```

**templates/configmap.yaml:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "app.fullname" . }}-config
data:
  database.host: {{ .Values.config.database.host | quote }}
  database.port: {{ .Values.config.database.port | quote }}
  api.timeout: {{ .Values.config.api.timeout | quote }}
  api.rateLimit: {{ .Values.config.api.rateLimit | quote }}
```

**templates/secret.yaml:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "app.fullname" . }}-secrets
type: Opaque
stringData:
  database.username: {{ .Values.secrets.database.username }}
  database.password: {{ .Values.secrets.database.password }}
```

**templates/deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "app.fullname" . }}
spec:
  template:
    spec:
      containers:
        - name: app
          image: myapp:latest
          env:
            # From ConfigMap
            - name: DATABASE_HOST
              valueFrom:
                configMapKeyRef:
                  name: {{ include "app.fullname" . }}-config
                  key: database.host

            # From Secret
            - name: DATABASE_USERNAME
              valueFrom:
                secretKeyRef:
                  name: {{ include "app.fullname" . }}-secrets
                  key: database.username

            - name: DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "app.fullname" . }}-secrets
                  key: database.password
```

---

## Quick Reference

### ConfigMap Commands

```bash
# Create
kubectl create configmap NAME --from-literal=key=value
kubectl create configmap NAME --from-file=path/to/file
kubectl apply -f configmap.yaml

# View
kubectl get configmaps
kubectl describe configmap NAME
kubectl get configmap NAME -o yaml

# Edit
kubectl edit configmap NAME

# Delete
kubectl delete configmap NAME
```

### Secret Commands

```bash
# Create
kubectl create secret generic NAME --from-literal=key=value
kubectl create secret docker-registry NAME --docker-server=SERVER
kubectl create secret tls NAME --cert=path --key=path
kubectl apply -f secret.yaml

# View
kubectl get secrets
kubectl describe secret NAME
kubectl get secret NAME -o yaml
kubectl get secret NAME -o jsonpath='{.data.key}' | base64 --decode

# Edit
kubectl edit secret NAME

# Delete
kubectl delete secret NAME
```

---

## Resources

- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [External Secrets Operator](https://external-secrets.io/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
