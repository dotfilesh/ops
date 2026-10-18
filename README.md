<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="left" width="144px" height="144px"/>

# Cloud Infrastructure Operations Repository 🐱‍💻
_... managed by Flux and Renovate_ 🤖

<div align="center">

[![Talos](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fdotfilesh%2Fops%2Fmain%2Ftalos%2Fclusters%2Fkclt-01%2Ftopf.yaml&query=talosVersion&style=for-the-badge&logo=linux&logoColor=white&label=Talos&color=FC500D&cacheSeconds=86400)](https://www.talos.dev/)
[![Kubernetes](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fdotfilesh%2Fops%2Fmain%2Ftalos%2Fclusters%2Fkclt-01%2Ftopf.yaml&query=kubernetesVersion&style=for-the-badge&logo=kubernetes&logoColor=white&label=Kubernetes&color=326CE5&cacheSeconds=86400)](https://kubernetes.io/)
[![Pre-Commit](https://img.shields.io/badge/pre--commit-enabled-white?style=for-the-badge&logo=pre-commit&logoColor=white&label=Pre-Commit&color=FAB040)](https://github.com/pre-commit/pre-commit)

</div>

---

## 📖 Overview

GitOps configuration for my homelab: bare-metal [Talos Linux](https://talos.dev/) nodes running Kubernetes, reconciled from this repository by [Flux](https://fluxcd.io/), with dependencies kept current by [Renovate](https://docs.renovatebot.com/). The layout follows [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template), extended so several clusters can share one set of app definitions.

Clusters are named after the nearest airport plus a sequence number: `kclt-01` is the first cluster near Charlotte.

## 📁 Layout

```sh
📁 kubernetes
├─📁 apps                  # Shared app definitions: apps/<namespace>/<app>/{ks.yaml,app/}
├─📁 components
│ └─📁 global-vars         # Settings + secrets shared by every cluster
└─📁 clusters
  └─📁 kclt-01
    ├─📁 flux              # Flux sync entrypoint (cluster-apps Kustomization)
    ├─📁 apps              # Which shared apps this cluster runs, plus per-cluster values
    └─📁 components        # This cluster's settings, secrets and Flux alerts
📁 talos/clusters/kclt-01  # topf.yaml + Talos patches (all/, control-plane/, …)
📁 bootstrap               # helmfile + recipes to bring up a cluster from nothing
│ └─📁 clover              # NVMe boot shim for the Dell 13th-gen nodes
📁 keys                    # Age private keys, encrypted to PGP only (disaster recovery)
📁 oob                     # Out-of-band services (UPS, mail, netboot)
```

**How a cluster is assembled.** Flux Operator's `FluxInstance` syncs `kubernetes/clusters/<cluster>/flux`. That holds one Kustomization, `cluster-apps`, which applies `kubernetes/clusters/<cluster>/apps`. There, each namespace's `kustomization.yaml`:

- picks the shared apps the cluster runs (`../../../../apps/<ns>/<app>/ks.yaml`);
- adds the `global-vars`, `cluster-vars` and `flux-alerts` components to that namespace.

`cluster-apps` stamps SOPS decryption, `${VAR}` substitution (`global-settings`, `global-secrets`, `cluster-settings`, `cluster-secrets`) and HelmRelease defaults onto every app Kustomization, so the shared `ks.yaml` files stay small.

**Per-cluster differences** come from variables. Where variables aren't enough, a shared HelmRelease reads a values ConfigMap that each cluster generates. For example, Rook's disk layout lives in `clusters/kclt-01/apps/rook-ceph/rook-ceph-cluster-values.yaml`.

**Adding a cluster:**
- Copy `talos/clusters/kclt-01` and `kubernetes/clusters/kclt-01`.
- Change the nodes, settings and app selection.
- Add a SOPS rule for the new cluster's key in `.sops.yaml`.

## ⛵ Components

| Area | What |
|---|---|
| OS | Talos Linux, configured with [topf](https://github.com/postfinance/topf) |
| GitOps | Flux (via [Flux Operator](https://fluxcd.control-plane.io/operator/)), SOPS + age |
| Networking | Cilium (kube-proxy replacement, L2-announced LoadBalancers), CoreDNS |
| Ingress | Envoy Gateway (`envoy-internal` on the LAN, `envoy-external` behind Cloudflare Tunnel), external-dns, k8s-gateway for split DNS |
| Certificates | cert-manager with Let's Encrypt DNS-01 via Cloudflare |
| Storage | Rook Ceph, hyper-converged |
| Databases | CloudNativePG (+ Barman Cloud plugin) |
| Observability | kube-prometheus-stack, Grafana, Goldilocks/VPA |
| Apps | Authentik, Jellyfin, Immich, Minecraft, Satisfactory |

Jellyfin and Immich are only on `envoy-internal`. Cloudflare's CDN terms don't allow serving video or bulk media through the free proxy that the tunnel uses.

## 🚀 Bootstrap

Tools are pinned in `.mise/config.toml`: `mise install`, then `just` lists every recipe. Recipes act on `$CLUSTER` (default `kclt-01`).

1. Boot every node into Talos maintenance mode (Dells: via the Clover USB, see `bootstrap/clover`).
2. `just bootstrap wipe-ceph-disks`: clear old OSDs from the disks Rook will use.
3. `just bootstrap talos`: `topf apply --auto-bootstrap`, then writes `talosconfig` and `kubeconfig` (both gitignored).
4. `just bootstrap apps`:
   - creates the namespaces and the `sops-age` secret;
   - applies the CRDs;
   - helmfile-installs Cilium, CoreDNS, cert-manager and Flux.

   Flux then adopts those releases and reconciles everything else.

Day two: `just talos diff|apply|upgrade|upgrade-k8s`, `just kube reconcile|status`, and `just test` (offline render, same as CI).

## 🔐 Secrets

Everything secret is SOPS-encrypted. `.sops.yaml` picks the key by path:
- the **cluster** age key for `talos/clusters/<cluster>` and `kubernetes/clusters/<cluster>`;
- the **global** age key for the rest of `kubernetes/`.

Both keys can also be decrypted with my PGP keys, and the age keys themselves are backed up under `keys/`, encrypted to PGP only. App Secrets hold `${SECRET_*}` references, not values, so the shared definitions contain nothing secret.

## ✅ CI

- **Lint**: pre-commit (yamllint, a check that every `*.sops*` file is actually encrypted, whitespace fixers).
- **Renovate config**: `renovate-config-validator --strict`.
- **Flate**: renders every cluster's Flux tree offline with [flate](https://github.com/home-operations/flate), checking that every chart, values schema, Kustomization and substitution resolves. Failures must be fixed; `.github/flate-known-failures.txt` stays empty.

---

## 🤝 Thanks

Thanks to all folks who donate their time to the [Home Operations](https://github.com/home-operations) community, and to [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template), which this layout is built on.
