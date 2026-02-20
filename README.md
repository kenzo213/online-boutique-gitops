# DevSecOps Platform — Online Boutique

A production-grade DevSecOps platform built on Kubernetes using Google Online Boutique microservices demo.

## Repos
- **online-boutique-app** — application code, Dockerfile, CI pipeline
- **online-boutique-gitops** — K8s manifests, Terraform, Argo CD apps

## Architecture Flow
```
Developer pushes code to dev branch
        ↓
GitHub Actions CI Pipeline
  ├── Semgrep SAST scan
  ├── SonarQube code quality gate
  ├── Docker image build
  ├── Trivy image vulnerability scan
  └── Push image to Docker Hub
        ↓
CI updates image tag in GitOps repo
        ↓
Argo CD detects change and deploys to boutique-dev
        ↓
OPA Gatekeeper validates manifests at admission
Istio enforces mTLS between all services
Falco monitors runtime syscalls
Prometheus + Grafana provide observability
```

## Stack

| Layer | Tool | Purpose |
|-------|------|---------|
| CI/CD | GitHub Actions | Build, scan, push |
| GitOps | Argo CD | Automated deployment |
| IaC | Terraform + Helm | Infrastructure provisioning |
| Manifests | Kustomize | Multi-environment config |
| SAST | Semgrep | Source code scanning |
| Code Quality | SonarQube | Quality gates |
| Image Scanning | Trivy | CVE detection |
| Policy | OPA Gatekeeper | Admission control |
| Service Mesh | Istio | mTLS + Zero Trust |
| Runtime Security | Falco | Syscall monitoring |
| Metrics | Prometheus | Metrics collection |
| Dashboards | Grafana | Visualization |
| Logs | Loki | Log aggregation |

## Phases

### Phase 1 — Terraform Infrastructure
All cluster tooling provisioned via Terraform Helm provider:
- Argo CD v5.55.0 (argocd namespace)
- Istio v1.20.0 + CNI plugin (istio-system namespace)
- OPA Gatekeeper v3.14.0 (gatekeeper-system namespace)
- Falco modern-bpf (host systemd service)
- kube-prometheus-stack v55.5.0 (monitoring namespace)
- Loki v2.10.2 (monitoring namespace)
```bash
cd online-boutique-gitops/terraform
terraform init
terraform apply -auto-approve
```

### Phase 2 — Kustomize Manifests
Base + overlays pattern for multi-environment deployments.

| Setting | Dev | Staging | Prod |
|---------|-----|---------|------|
| Replicas | 1 | 2 | 3 |
| Namespace | boutique-dev | boutique-staging | boutique-prod |
```bash
kubectl kustomize manifests/overlays/dev/ > /dev/null && echo "dev OK"
kubectl kustomize manifests/overlays/staging/ > /dev/null && echo "staging OK"
kubectl kustomize manifests/overlays/prod/ > /dev/null && echo "prod OK"
```

### Phase 3 — GitHub Actions CI Pipeline
Jobs run in sequence on every push to dev/staging/main:

1. **Semgrep** — SAST scan on source code
2. **SonarQube** — code quality gate
3. **Build + Trivy** — build image, scan for CVEs, push to Docker Hub
4. **Update GitOps** — update image tag in GitOps repo (dev branch only)

Required GitHub Secrets:

| Secret | Description |
|--------|-------------|
| DOCKER_USERNAME | Docker Hub username |
| DOCKER_PASSWORD | Docker Hub access token |
| SONAR_TOKEN | SonarQube auth token |
| SONAR_HOST_URL | SonarQube server URL |
| GITOPS_TOKEN | GitHub PAT with repo + workflow scopes |

### Phase 4 — Argo CD GitOps
Argo CD watches the GitOps repo main branch and auto-syncs to the cluster.
```bash
# Apply Argo CD application
kubectl apply -f argocd/application.yaml

# Access UI
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Username: admin
# Password: kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d
```

### Phase 5 — OPA Gatekeeper Policies
Three policies enforced in DENY mode:

| Policy | What it Blocks | Why |
|--------|---------------|-----|
| no-latest-tag | :latest or untagged images | Unpredictable, can't roll back |
| require-limits | Missing CPU/memory limits | Runaway pods starve the node |
| require-labels | Missing app label | Breaks service discovery |
```bash
kubectl apply -f policies/gatekeeper/no-latest-tag.yaml
sleep 30
kubectl apply -f policies/gatekeeper/require-limits.yaml
kubectl apply -f policies/gatekeeper/require-labels.yaml
kubectl get constraints
```

NIST 800-53 Mapping:
- require-limits → SC-6 Resource Availability
- no-latest-tag → SI-2 Flaw Remediation
- require-labels → CM-8 Component Inventory

### Phase 6 — Istio mTLS
Enable sidecar injection and enforce strict mTLS between all services.
```bash
# Enable injection
kubectl label namespace boutique-dev istio-injection=enabled
kubectl rollout restart deployment -n boutique-dev

# Enforce mTLS
kubectl apply -f manifests/overlays/dev/mtls.yaml

# Verify
kubectl get peerauthentication -n boutique-dev
```

After restart all pods show 2/2 READY — second container is the Envoy sidecar proxy.

### Phase 7 — Observability
```bash
# Grafana UI
http://<node-ip>:32000
# Username: admin / Password: admin123

# Prometheus UI
http://<node-ip>:32001
```

## Falco Note
Falco deployed as host systemd service due to GCC version mismatch between
Falco Debian container images (GCC 12) and CentOS Stream 10 kernel (GCC 14.3.1).
Uses modern eBPF driver — no kernel module compilation required.
```bash
sudo systemctl status falco-modern-bpf
sudo journalctl -u falco-modern-bpf -f
```

## Branching Strategy
```
main       → production (protected, PR required)
staging    → staging environment
dev        → development (CI triggers on push)
feature/*  → developer branches
```

## Troubleshooting

| Issue | Diagnosis | Fix |
|-------|-----------|-----|
| ImagePullBackOff | kubectl describe pod | Check registry, tag, repo visibility |
| OOMKilled (exit 137) | kubectl describe pod | Increase memory limit |
| Pending | kubectl top nodes | Free up cluster resources |
| Service unreachable | kubectl get endpoints | Fix selector label mismatch |
| Gatekeeper blocking | kubectl get constraints | Check policy violations |
| Istio not injecting | kubectl get ns --show-labels | Add istio-injection=enabled label |

## Key Interview Talking Points

**On GitOps:**
"CI only updates Git — Argo CD inside the cluster pulls and applies.
Git is the single source of truth, full audit trail, self-healing,
and no cluster credentials in the pipeline. Rollback is git revert."

**On Istio mTLS:**
"Istio injects an Envoy sidecar into every pod. The sidecar enforces mTLS
between all services using certificates Istio manages automatically.
Zero Trust — every connection authenticated and encrypted inside the cluster."

**On OPA Gatekeeper:**
"Gatekeeper sits at the admission controller layer — every resource request
goes through it before being accepted, regardless of who submitted it.
Maps directly to NIST 800-53 and Container STIGs for DoD compliance."

**On Falco:**
"In RHEL-based environments I deploy Falco as a host systemd service
using the modern eBPF driver. Gives direct kernel access for syscall
monitoring without container image compatibility issues."
