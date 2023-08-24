<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="left" width="144px" height="144px"/>

# Cloud Infrastructure Operations Repository 🐱‍💻
_... managed by Flux and Renovate_ 🤖

<div align="center">

[![talos](https://img.shields.io/badge/talos-v1.5.0-brightgreen?style=for-the-badge&logo=linux&logoColor=white)](https://www.talos.dev/)
[![kubernetes](https://img.shields.io/badge/kubernetes-v1.28.0-brightgreen?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)

</div>

---

## 📖 Overview

This repository provides the configuration for our cloud infrastructure. Working to adhere to Infrastructure as Code (IaC) and GitOps practices, this system is intended for easy maintenance and use; along with making the system accessible, transparent, and more easily studied in a broader sense.

---

## ⛵ Kubernetes

This repo borrows heavily from [k8s-at-home/template-cluster-k3](https://github.com/k8s-at-home/template-cluster-k3s) and its derivatives such as [Devil Buhl's home-ops](https://github.com/onedr0p/home-ops) and [Toboshii Nakama's](https://github.com/toboshii/home-ops) in structure and practices.

### Installation

Clusters run on [Talos Linux](https://talos.dev/), an immutable and ephemeral Linux distribution built around Kubernetes, deployed on bare-metal. [Rook Ceph](https://rook.io/) running hyper-converged with workloads provides persistent block, object, and file storage.

### ☸️ Talos

[talhelper](https://github.com/budimanjojo/talhelper) is used to organize the Talos config files.

### Core Components

- [cilium/cilium](https://github.com/cilium/cilium): Internal Kubernetes networking plugin.
- [rook/rook](https://github.com/rook/rook): Distributed block storage for peristent storage.
- [mozilla/sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): Manages secrets for Kubernetes, Ansible and Terraform.
- [jetstack/cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for cluster services.
- [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx/): Ingress controller to expose HTTP traffic to pods over DNS.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches the [k8s](./k8s/) directory and makes changes based on the YAML manifests.

[Renovate](https://github.com/renovatebot/renovate) watches the entire repository looking for dependency updates, when they are found a PR is automatically created. When PRs are merged, [Flux](https://github.com/fluxcd/flux2) applies the relevant changes to the cluster.

### Directories

> The cloud infrastructure is intended to be able to support multiple clusters, and as such provides a distinction between [global configuration](./k8s/global/) and [cluster deployments || config](./k8s/clusters/). Clusters are named based on the airport geographically closest (\*ish) + sequential discriminator.

```sh
📁 k8s       # All k8s infrastructure defined below
├─📁 clusters  # all instantiated k8s clusters, defined as code
│ └─📁 icao-00   # example cluster
│   ├─📁 apps      # Apps in cluster by namespace
│   ├─📁 bootstrap # Cluster-specific keys
│   └─📁 flux      # Flux configuration.
└─📁 global    # global resources
  ├─📁 bootstrap # Bootstrapping data (flux installation, global key)
  ├─📁 config    # Universal config data
  └─📁 repos     # (Helm|Git)Repository Flux sources
```


### Networking:

Some cilium nightmare.

### Data Backup

Ok question time is over now. go home.


---

## 🤝 Thanks

Thanks to all folks who donate their time to the [Kubernetes @Home](https://github.com/k8s-at-home/) community.
