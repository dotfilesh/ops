<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="left" width="144px" height="144px"/>

# Cloud Infrastructure Operations Repository

_... managed by ArgoCD and Renovate_

<div align="center">

[![Dynamic YAML Badge](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fdotfilesh%2Fops%2Fmain%2Ftalos%2Fclusters%2Fkclt-01%2Ftalconfig.yaml&query=talosVersion&style=for-the-badge&logo=linux&logoColor=white&label=Talos&color=FC500D&cacheSeconds=86400)](https://www.talos.dev/)
[![Dynamic YAML Badge](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fdotfilesh%2Fops%2Fmain%2Ftalos%2Fclusters%2Fkclt-01%2Ftalconfig.yaml&query=kubernetesVersion&style=for-the-badge&logo=kubernetes&logoColor=white&label=Kubernetes&color=326CE5&cacheSeconds=86400)](https://kubernetes.io/)
[![Static Badge](https://img.shields.io/badge/pre--commit-enabled-white?style=for-the-badge&logo=pre-commit&logoColor=white&label=Pre-Commit&color=FAB040)](https://github.com/pre-commit/pre-commit)

</div>

---

## Overview

This repository provides the configuration for our cloud infrastructure. Working to adhere to Infrastructure as Code (IaC) and GitOps practices, this system is intended for easy maintenance and use; along with making the system accessible, transparent, and more easily studied in a broader sense.

---

## Kubernetes

Clusters run on [Talos Linux](https://talos.dev/), an immutable and ephemeral Linux distribution built around Kubernetes, deployed on bare-metal. [Rook Ceph](https://rook.io/) running hyper-converged with workloads provides persistent block, object, and file storage.

### Talos

[talhelper](https://github.com/budimanjojo/talhelper) is used to organize the Talos config files.

### Core Components

| Component | Purpose |
|---|---|
| [ArgoCD](https://argo-cd.readthedocs.io/) | GitOps controller (app-of-apps pattern) |
| [KSOPS](https://github.com/viaduct-ai/kustomize-sops) | SOPS decryption plugin for ArgoCD |
| [Cilium](https://cilium.io/) | CNI + kube-proxy replacement + Gateway API |
| [Rook Ceph](https://rook.io/) | Distributed block, filesystem, and object storage |
| [cert-manager](https://cert-manager.io/) | TLS certificates via Let's Encrypt |
| [SOPS](https://github.com/getsops/sops) | Secret encryption with age keys |
| [go-task](https://taskfile.dev/) | Task runner for cluster operations |

### GitOps

[ArgoCD](https://argo-cd.readthedocs.io/) watches the [kubernetes/](./kubernetes/) directory and reconciles manifests via an app-of-apps pattern. A root Application in `kubernetes/argocd/apps/` references all child Application CRs.

[Renovate](https://github.com/renovatebot/renovate) watches the entire repository looking for dependency updates, when they are found a PR is automatically created. When PRs are merged, ArgoCD syncs the relevant changes to the cluster.

### Directory Structure

```
kubernetes/
  argocd/            # ArgoCD install + root app-of-apps
  apps/              # Application definitions by namespace
    <ns>/<app>/        # ArgoCD Application CR (helm-release.yaml)
  clusters/
    kclt-01/           # Cluster-specific config and bootstrap
talos/               # Talos Linux node configuration
oob/                 # Out-of-band infrastructure (BGP, NUT, etc.)
scripts/             # Bootstrap and helper scripts
Taskfile.yaml        # go-task definitions
```

### Quick Start

```sh
# Install/verify required tools
task deps

# Full cluster bootstrap (Talos + ArgoCD + KSOPS + root app)
task bootstrap

# Encrypt a new secret
task encrypt FILE=kubernetes/apps/auth/authentik/secret.sops.yaml
```

See `Taskfile.yaml` for all available tasks.

---

## Thanks

Thanks to all folks who donate their time to the [Kubernetes @Home](https://github.com/k8s-at-home/) community.
