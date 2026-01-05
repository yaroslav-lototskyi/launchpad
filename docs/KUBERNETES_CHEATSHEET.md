# Kubernetes Cheatsheet - Essential Commands

## 🎯 Basics

### Context (Clusters)

```bash
# Show all available clusters
kubectl config get-contexts

# Switch to different cluster
kubectl config use-context kind-launchpad-local

# Show current context
kubectl config current-context

# Show current configuration
kubectl config view
```

### Namespaces

```bash
# Show all namespaces
kubectl get namespaces
kubectl get ns  # short version

# Create namespace
kubectl create namespace my-namespace

# Delete namespace (WARNING: deletes EVERYTHING inside!)
kubectl delete namespace my-namespace

# Set default namespace for current context
kubectl config set-context --current --namespace=launchpad-development

# Now you don't need to write -n constantly:
kubectl get pods  # shows pods from launchpad-development
```

---

## 📦 Pods

### Viewing Pods

```bash
# Show all pods in namespace
kubectl get pods -n launchpad-development

# Show pods with additional info (IP, Node)
kubectl get pods -n launchpad-development -o wide

# Show pods in all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A  # short version

# Show pods with label selector
kubectl get pods -l app.kubernetes.io/component=api -n launchpad-development

# Watch mode (auto-refresh)
kubectl get pods -n launchpad-development -w
```

### Details and Logs

```bash
# Detailed information about pod
kubectl describe pod <pod-name> -n launchpad-development

# Pod logs
kubectl logs <pod-name> -n launchpad-development

# Logs in real-time (tail -f)
kubectl logs <pod-name> -n launchpad-development -f

# Last 50 lines of logs
kubectl logs <pod-name> -n launchpad-development --tail=50

# Logs by label
kubectl logs -l app.kubernetes.io/component=api -n launchpad-development -f

# Logs from last 1h
kubectl logs <pod-name> -n launchpad-development --since=1h

# Previous logs (if pod restarted)
kubectl logs <pod-name> -n launchpad-development --previous
```

### Executing Commands in Pod

```bash
# Run bash in pod
kubectl exec -it <pod-name> -n launchpad-development -- /bin/sh
kubectl exec -it <pod-name> -n launchpad-development -- /bin/bash

# Execute single command
kubectl exec <pod-name> -n launchpad-development -- ls -la
kubectl exec <pod-name> -n launchpad-development -- env

# If pod has multiple containers
kubectl exec -it <pod-name> -c <container-name> -n launchpad-development -- sh
```

### Copying Files

```bash
# From pod to local machine
kubectl cp launchpad-development/<pod-name>:/app/logs.txt ./logs.txt

# From local machine to pod
kubectl cp ./config.json launchpad-development/<pod-name>:/app/config.json
```

### Deleting Pods

```bash
# Delete pod (automatically creates new one via Deployment)
kubectl delete pod <pod-name> -n launchpad-development

# Force delete (if stuck)
kubectl delete pod <pod-name> -n launchpad-development --force --grace-period=0
```

---

## 🚀 Deployments

```bash
# Show deployments
kubectl get deployments -n launchpad-development
kubectl get deploy -n launchpad-development  # short version

# Detailed information
kubectl describe deployment <deployment-name> -n launchpad-development

# Scale deployment
kubectl scale deployment launchpad-api --replicas=3 -n launchpad-development

# Restart deployment (recreate all pods)
kubectl rollout restart deployment launchpad-api -n launchpad-development

# Rollout history
kubectl rollout history deployment launchpad-api -n launchpad-development

# Rollback to previous version
kubectl rollout undo deployment launchpad-api -n launchpad-development

# Rollout status
kubectl rollout status deployment launchpad-api -n launchpad-development

# Pause/Resume rollout
kubectl rollout pause deployment launchpad-api -n launchpad-development
kubectl rollout resume deployment launchpad-api -n launchpad-development

# Update image
kubectl set image deployment/launchpad-api api=launchpad/api:v2 -n launchpad-development
```

---

## 🌐 Services

```bash
# Show services
kubectl get services -n launchpad-development
kubectl get svc -n launchpad-development  # short version

# Detailed information
kubectl describe service launchpad-api -n launchpad-development

# Show endpoints (which pods are behind service)
kubectl get endpoints -n launchpad-development

# Port forwarding (access service from local machine)
kubectl port-forward service/launchpad-api 3001:3001 -n launchpad-development
# Now you can: curl http://localhost:3001/api/v1/health
```

---

## 🔀 Ingress

```bash
# Show ingress
kubectl get ingress -n launchpad-development
kubectl get ing -n launchpad-development  # short version

# Detailed information
kubectl describe ingress launchpad -n launchpad-development

# Check Ingress Controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx <ingress-controller-pod> -f
```

---

## 📊 All Resources

```bash
# Show ALL resources in namespace
kubectl get all -n launchpad-development

# Show specific resource types
kubectl get pods,svc,deploy,ing -n launchpad-development

# JSON/YAML output
kubectl get deployment launchpad-api -n launchpad-development -o yaml
kubectl get deployment launchpad-api -n launchpad-development -o json

# Custom columns
kubectl get pods -n launchpad-development -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP
```

---

## 🔍 Debug and Troubleshooting

### Events (important for diagnostics!)

```bash
# Show events in namespace
kubectl get events -n launchpad-development

# Events sorted by timestamp
kubectl get events -n launchpad-development --sort-by='.lastTimestamp'

# Watch events
kubectl get events -n launchpad-development -w
```

### Health Check

```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Check component status
kubectl get componentstatuses
kubectl get cs  # short version

# Top resource consumers
kubectl top nodes
kubectl top pods -n launchpad-development
```

### Problem Diagnostics

```bash
# Pod not starting - check events
kubectl describe pod <pod-name> -n launchpad-development | grep -A 10 Events

# ImagePullBackOff - check image
kubectl get pod <pod-name> -n launchpad-development -o yaml | grep image

# CrashLoopBackOff - check logs
kubectl logs <pod-name> -n launchpad-development --previous

# Pending - check resources
kubectl describe pod <pod-name> -n launchpad-development | grep -A 5 "Events"

# Network issues - DNS check
kubectl run -it --rm debug --image=busybox --restart=Never -n launchpad-development -- nslookup kubernetes.default
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n launchpad-development -- curl http://launchpad-api:3001/api/v1/health
```

---

## ⚙️ Helm

### Basic Commands

```bash
# Show installed releases
helm list -n launchpad-development
helm ls -n launchpad-development  # short version

# Show in all namespaces
helm list --all-namespaces
helm list -A  # short version

# Install chart
helm install <release-name> <chart-path> -n <namespace>
helm install launchpad ./infra/helm/launchpad -n launchpad-development

# Install with custom values
helm install launchpad ./infra/helm/launchpad -n launchpad-development \
  --values ./infra/helm/launchpad/values-development.yaml \
  --set api.image.tag=v2.0

# Upgrade release
helm upgrade launchpad ./infra/helm/launchpad -n launchpad-development

# Install or upgrade (if exists)
helm upgrade --install launchpad ./infra/helm/launchpad -n launchpad-development

# Uninstall release
helm uninstall launchpad -n launchpad-development

# Show values
helm get values launchpad -n launchpad-development

# Show manifest
helm get manifest launchpad -n launchpad-development

# Release history
helm history launchpad -n launchpad-development

# Rollback to previous version
helm rollback launchpad -n launchpad-development
helm rollback launchpad 1 -n launchpad-development  # to specific version

# Dry run (preview what will be created WITHOUT actual deploy)
helm install launchpad ./infra/helm/launchpad -n launchpad-development --dry-run --debug

# Template rendering (show generated YAML)
helm template launchpad ./infra/helm/launchpad
```

---

## 🔧 Kind (Local Cluster)

```bash
# Show clusters
kind get clusters

# Create cluster
kind create cluster --name my-cluster

# Create with config
kind create cluster --name my-cluster --config kind-config.yaml

# Delete cluster
kind delete cluster --name launchpad-local

# Load Docker image into Kind
kind load docker-image my-image:tag --name launchpad-local

# Export logs from cluster
kind export logs --name launchpad-local
```

---

## 🎨 Useful Aliases (add to ~/.zshrc or ~/.bashrc)

```bash
# Add to ~/.zshrc:
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kdel='kubectl delete'
alias kl='kubectl logs'
alias kx='kubectl exec -it'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deploy'
alias kgi='kubectl get ingress'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kaf='kubectl apply -f'
alias kdelf='kubectl delete -f'

# Helm
alias h='helm'
alias hl='helm list'
alias hi='helm install'
alias hu='helm upgrade'
alias hd='helm uninstall'

# Context
alias kctx='kubectl config current-context'
alias kns='kubectl config set-context --current --namespace'
```

After adding:

```bash
source ~/.zshrc
```

Now you can:

```bash
k get pods -n launchpad-development
kl <pod-name> -n launchpad-development -f
kx <pod-name> -n launchpad-development -- sh
```

---

## 🚨 YAML Manifests

### Creating Resources

```bash
# Apply (create or update)
kubectl apply -f deployment.yaml
kubectl apply -f ./infra/k8s/  # entire directory

# Create (only create, error if exists)
kubectl create -f deployment.yaml

# Delete
kubectl delete -f deployment.yaml

# Dry run (generate YAML without creating)
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment.yaml

# Export existing resource
kubectl get deployment launchpad-api -n launchpad-development -o yaml > api-deployment.yaml
```

---

## 📝 Labels and Selectors

```bash
# Show labels
kubectl get pods --show-labels -n launchpad-development

# Filter by label
kubectl get pods -l app.kubernetes.io/name=launchpad -n launchpad-development
kubectl get pods -l 'environment in (dev,staging)' -n launchpad-development

# Add label
kubectl label pod <pod-name> environment=dev -n launchpad-development

# Remove label
kubectl label pod <pod-name> environment- -n launchpad-development

# Overwrite label
kubectl label pod <pod-name> environment=prod --overwrite -n launchpad-development
```

---

## 🔐 Secrets and ConfigMaps

```bash
# ConfigMaps
kubectl get configmaps -n launchpad-development
kubectl describe configmap <name> -n launchpad-development
kubectl create configmap my-config --from-file=config.json -n launchpad-development
kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2

# Secrets
kubectl get secrets -n launchpad-development
kubectl describe secret <name> -n launchpad-development
kubectl create secret generic my-secret --from-literal=password=mysecret -n launchpad-development
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=username \
  --docker-password=token \
  -n launchpad-development

# Decode secret
kubectl get secret my-secret -n launchpad-development -o jsonpath='{.data.password}' | base64 --decode
```

---

## 📊 Monitoring and Metrics

```bash
# Resource usage (requires metrics-server)
kubectl top nodes
kubectl top pods -n launchpad-development
kubectl top pods -n launchpad-development --containers

# Watch resources
watch kubectl get pods -n launchpad-development
# or
kubectl get pods -n launchpad-development -w
```

---

## 🔄 Auto-completion

```bash
# For zsh (add to ~/.zshrc)
source <(kubectl completion zsh)
echo '[[ $commands[kubectl] ]] && source <(kubectl completion zsh)' >> ~/.zshrc

# For bash
source <(kubectl completion bash)
echo 'source <(kubectl completion bash)' >> ~/.bashrc

# Now you can:
kubectl get po[TAB]  # autocomplete to pods
kubectl get pods -n launchpad-[TAB]  # autocomplete namespace
```

---

## 🎯 Quick Scenarios

### Full Application Restart

```bash
kubectl rollout restart deployment launchpad-api -n launchpad-development
kubectl rollout restart deployment launchpad-client -n launchpad-development
```

### Check Why Pod Not Working

```bash
# 1. Status
kubectl get pod <pod-name> -n launchpad-development

# 2. Events
kubectl describe pod <pod-name> -n launchpad-development | grep -A 20 Events

# 3. Logs
kubectl logs <pod-name> -n launchpad-development --tail=100

# 4. Previous logs (if restarted)
kubectl logs <pod-name> -n launchpad-development --previous
```

### Quick API Test

```bash
# Port forward
kubectl port-forward svc/launchpad-api 3001:3001 -n launchpad-development &

# Test
curl http://localhost:3001/api/v1/health

# Kill port-forward
killall kubectl
```

### Clean Everything

```bash
# Delete namespace (deletes EVERYTHING inside)
kubectl delete namespace launchpad-development

# Delete Kind cluster
kind delete cluster --name launchpad-local

# Delete all pods with label
kubectl delete pods -l app=myapp -n launchpad-development
```

---

## 📚 Useful Resources

- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Kubectl Cheat Sheet (official)](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Helm Docs](https://helm.sh/docs/)
- [Kind Docs](https://kind.sigs.k8s.io/)

---

**Tip**: Install `kubectx` and `kubens` for fast switching:

```bash
brew install kubectx

# Quick context switch
kubectx kind-launchpad-local

# Quick namespace switch
kubens launchpad-development
```
