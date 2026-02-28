# ArgoCD Skeleton — 2026 Rebuild

> **Source plan:** `ops-rebuild-plan.md §2026`
>
> This directory contains the incremental 2026 rebuild of the ops repo, migrating from
> Flux v2 to ArgoCD + KSOPS. It lives alongside the legacy tree (`k8s/`, `talos/`,
> `bootstrap/`) and must **not** overwrite any legacy content.

---

## Overview

| Component | Version | Notes |
|---|---|---|
| [ArgoCD](https://argo-cd.readthedocs.io/) | v2.13 | Replaces Flux v2 as GitOps controller |
| [KSOPS](https://github.com/viaduct-ai/kustomize-sops) | v4.3 | SOPS decryption plugin for ArgoCD/kustomize |
| [Talos Linux](https://talos.dev/) | v1.8 | Immutable OS, unchanged from legacy |
| [Kubernetes](https://kubernetes.io/) | v1.31 | Cluster version bump |
| [Cilium](https://cilium.io/) | v1.16 | CNI + BGP + load-balancer |
| [cert-manager](https://cert-manager.io/) | v1.16 | TLS certificates |
| [Rook-Ceph](https://rook.io/) | v1.15 | Hyper-converged storage |
| [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts) | v65 | Monitoring stack |
| [CloudNative PG](https://cloudnative-pg.io/) | v0.22 | PostgreSQL operator |
| [Authentik](https://goauthentik.io/) | 2024.12 | Identity provider |
| [go-task](https://taskfile.dev/) | v3 | Task runner (see `Taskfile.yaml`) |

---

## Directory Layout

```
copilot/argocd-skeleton/
├── README.md                     # This file
├── Taskfile.yaml                 # go-task tasks (bootstrap, encrypt, talos, etc.)
├── scripts/                      # Bootstrap helper scripts
│   ├── bootstrap.sh              # Full cluster bootstrap workflow
│   ├── talos-apply.sh            # Apply Talos config to nodes
│   └── encrypt.sh                # SOPS encrypt/decrypt helpers
└── kubernetes/
    ├── clusters/
    │   └── kclt-01/              # Cluster: kclt-01 (ICAO closest: CLT)
    │       ├── argocd/
    │       │   ├── install/      # ArgoCD Helm install (kustomize + KSOPS)
    │       │   ├── applicationsets/ # ApplicationSet templates (cluster-apps)
    │       │   └── apps/         # Root Application (app-of-apps pattern)
    │       ├── bootstrap/        # Bootstrap secrets (SOPS age keys)
    │       ├── vars/             # Cluster ConfigMap (non-secret cluster vars)
    │       └── talos/            # Talos config stubs (generated, gitignored)
    └── apps/                     # Application definitions, by namespace
        ├── auth/                 # Namespace: auth (Authentik)
        ├── backup/               # Namespace: backup (Volsync)
        ├── cert-manager/         # Namespace: cert-manager
        ├── database/             # Namespace: database (CloudNative PG)
        ├── default/              # Namespace: default (echo-server, etc.)
        ├── kube-system/          # Namespace: kube-system (Cilium, etc.)
        ├── monitoring/           # Namespace: monitoring (kube-prometheus-stack)
        ├── networking/           # Namespace: networking (ingress-nginx, etc.)
        ├── security/             # Namespace: security (Kyverno)
        └── storage/              # Namespace: storage (Rook-Ceph)
```

---

## Cluster Details

| Property | Value |
|---|---|
| Cluster name | `kclt-01` |
| Domain | `dotfile.sh` |
| Kube API VIP | `10.64.6.0/24` subnet, VIP via Talos |
| Pod CIDR | `10.244.0.0/16` |
| Service CIDR | `10.96.0.0/12` |
| LB pool CIDR | `10.64.3.0/24` (Cilium BGP) |
| BGP AS | 65420 |
| CNI | Cilium (BGP mode, kube-proxy disabled) |
| Storage | Rook-Ceph (block + filesystem + object) |

---

## Secret Management (KSOPS)

Secrets use [KSOPS](https://github.com/viaduct-ai/kustomize-sops) (age-only keys) as the
SOPS plugin for ArgoCD. See `.sops.yaml` for encryption rules.

- Cluster secrets: encrypted with `kclt-01` age key
- Global secrets: encrypted with global age key
- **Never** commit plaintext key material (`.agekey`, `.dirtysops` files are gitignored)

---

## Quick Start

```sh
# Install dependencies (see Taskfile.yaml for full list)
task deps

# Bootstrap cluster (Talos + ArgoCD + KSOPS)
task bootstrap

# Encrypt a new secret
task encrypt FILE=kubernetes/apps/auth/authentik/secret.sops.yaml

# Apply Talos config to a node
task talos:apply NODE=10.64.6.1
```

See `Taskfile.yaml` for all available tasks and descriptions.
