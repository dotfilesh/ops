# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

GitOps-managed Kubernetes infrastructure. ArgoCD watches `kubernetes/` and reconciles manifests via an app-of-apps pattern. Renovate auto-creates PRs for dependency updates.

## Key Tools Required

- `argocd` — ArgoCD CLI
- `kubectl` — Kubernetes CLI
- `kustomize` — Kustomize CLI (used with KSOPS plugin)
- `talosctl` / `talhelper` — Talos Linux management
- `sops` — secret encryption/decryption
- `age` — key management for SOPS
- `task` — go-task runner (see `Taskfile.yaml`)
- `pre-commit` — runs yamllint and sops secret-leak checks

## Common Commands

```bash
# Show all available tasks
task

# Lint YAML
task lint

# Full cluster bootstrap (Talos + ArgoCD + KSOPS + root app)
task bootstrap

# Generate Talos configs
task talos:gen

# Apply Talos config to a node
task talos:apply NODE=10.64.6.1

# Install ArgoCD
task argocd:install

# Apply root Application (app-of-apps)
task argocd:root-app

# Encrypt a secret
task encrypt FILE=kubernetes/apps/auth/authentik/secret.sops.yaml

# Decrypt a secret to stdout
task decrypt FILE=path/to/file.sops.yaml

# Build a kustomization (preview)
task kustomize:build DIR=kubernetes/argocd/apps
```

## Architecture

### Directory Layout

```
kubernetes/
  argocd/
    apps/             # Root kustomization + root-app.yaml (app-of-apps)
    install/          # ArgoCD install manifests + KSOPS patches
  apps/               # Application definitions, by namespace
    <ns>/
      <app>/
        helm-release.yaml   # ArgoCD Application CR (Helm chart source)
        httproute.yaml      # HTTPRoute for Gateway API (if exposed)
        secret.sops-dummy.yaml  # Dummy secret template (if needed)
  clusters/
    kclt-01/
      bootstrap/      # KSOPS age key secret template
      vars/           # cluster-config.yaml (reference ConfigMap)
talos/
  clusters/kclt-01/   # talhelper config for Talos Linux nodes
oob/                  # Out-of-band infrastructure (BGP, NUT, etc.)
scripts/              # Bootstrap, encrypt, and talos-apply helper scripts
Taskfile.yaml         # go-task definitions
```

### ArgoCD App-of-Apps Flow

1. `root-app` Application points at `kubernetes/argocd/apps/`
2. The kustomization.yaml there references all Application CRs under `kubernetes/apps/`
3. Each Application CR deploys a Helm chart (via `source.chart`) to its namespace
4. `CreateNamespace=true` in syncOptions — no separate namespace YAML needed
5. HTTPRoutes are deployed via a dedicated `httproutes` Application

### Secret Management (KSOPS)

Secrets use KSOPS (age-only keys) as the SOPS plugin for ArgoCD.

- Filename pattern: `*.sops.yaml`
- Dummy templates: `*.sops-dummy.yaml` (copy, fill in, encrypt)
- The `.sops.yaml` at repo root determines encryption keys by path:
  - `kubernetes/clusters/kclt-01/**` → cluster age key
  - `kubernetes/**` → global age key
  - `talos/**` → global age key
  - Everything else → PGP keys only
- ArgoCD decrypts via the `ksops-age-key` Secret mounted in argocd-repo-server
- `kustomize.buildOptions: "--enable-alpha-plugins --enable-exec"` in argocd-cm enables KSOPS globally

### Networking: Cilium Gateway API

- **CNI**: Cilium with kube-proxy replacement, BGP control plane, L2 announcements
- **Ingress**: Cilium Gateway API (replaces ingress-nginx)
- **Gateway**: Shared `external-gateway` in networking namespace (`*.dotfile.sh`)
- **Routes**: HTTPRoute resources per app, deployed via the `httproutes` Application

### Cluster: kclt-01

- **Location**: US East, 4 control-plane nodes + 6 workers
- **OS**: Talos Linux (immutable, managed via talhelper)
- **CNI**: Cilium (kube-proxy disabled, BGP AS 65420)
- **Storage**: Rook Ceph (block, filesystem, object)
- **Cert management**: cert-manager with Let's Encrypt
- **Auth**: Authentik (SSO)
- **Databases**: CloudNativePG (Postgres operator)
- **Monitoring**: kube-prometheus-stack + Grafana

### Adding a New App

1. Create `kubernetes/apps/<namespace>/<app>/helm-release.yaml` — an ArgoCD Application CR with Helm chart source
2. Add the `helm-release.yaml` reference to `kubernetes/argocd/apps/kustomization.yaml`
3. If the app needs secrets, create a `secret.sops-dummy.yaml` template
4. If the app needs external access, create an `httproute.yaml` and add it to `kubernetes/apps/networking/httproutes/resources/kustomization.yaml`

### Pre-commit Hooks

The `sops-pre-commit` hook (`forbid-secrets`) will block commits if unencrypted secret patterns are detected. YAML linting uses `.github/linters/.yamllint.yaml`.
