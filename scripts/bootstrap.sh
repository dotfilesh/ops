#!/usr/bin/env bash
# scripts/bootstrap.sh
#
# Full cluster bootstrap workflow for kclt-01:
#   1. Verify prerequisites
#   2. Generate Talos configs (talhelper)
#   3. Apply Talos configs to nodes
#   4. Bootstrap the Kubernetes control plane
#   5. Install ArgoCD + KSOPS
#   6. Apply the KSOPS age key secret
#   7. Apply the ArgoCD root Application (app-of-apps)
#
# Usage:
#   ./scripts/bootstrap.sh
#
# Prerequisites:
#   - age, sops, kubectl, talosctl, talhelper, argocd, kustomize
#   - SOPS_AGE_KEY_FILE set to the cluster age private key path
#   - Talos nodes reachable on the network
#
# NOTE: Steps 2-4 require manual node IP confirmation. Edit the NODES
#       and BOOTSTRAP_NODE variables below before running.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CLUSTER="kclt-01"
ARGOCD_NS="argocd"
K8S_DIR="${REPO_ROOT}/kubernetes"

# ── Talos node configuration ────────────────────────────────────────────────
# First control plane node (bootstrap etcd here)
BOOTSTRAP_NODE="10.64.6.1"
# All control plane nodes
CONTROL_NODES=("10.64.6.1" "10.64.6.2" "10.64.6.3" "10.64.6.8")
# Worker nodes
WORKER_NODES=("10.64.6.9" "10.64.6.10" "10.64.6.11" "10.64.6.12" "10.64.6.13" "10.64.6.14")

TALOS_CONFIG_DIR="${REPO_ROOT}/talos/clusters/${CLUSTER}"

# ── Colours ─────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()     { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Step 0: Prerequisites ────────────────────────────────────────────────────
info "Step 0: Checking prerequisites..."
for tool in age sops kubectl talosctl talhelper argocd kustomize; do
  command -v "$tool" &>/dev/null || die "Missing required tool: $tool"
done
[[ -n "${SOPS_AGE_KEY_FILE:-}" ]] || die "SOPS_AGE_KEY_FILE is not set"
[[ -f "${SOPS_AGE_KEY_FILE}" ]]   || die "Age key file not found: ${SOPS_AGE_KEY_FILE}"
info "All prerequisites satisfied."

# ── Step 1: Generate Talos configs ──────────────────────────────────────────
info "Step 1: Generating Talos configs (talhelper)..."
pushd "${TALOS_CONFIG_DIR}" > /dev/null
  talhelper genconfig
popd > /dev/null
info "Talos configs generated."

# ── Step 2: Apply Talos configs to nodes ────────────────────────────────────
info "Step 2: Applying Talos configs to control plane nodes..."
GENERATED_DIR="${TALOS_CONFIG_DIR}/clusterconfig"
for node in "${CONTROL_NODES[@]}"; do
  info "  → control plane: ${node}"
  talosctl apply-config --insecure --nodes "${node}" \
    --file "${GENERATED_DIR}/${CLUSTER}-${node}.yaml" || warn "Failed to apply to ${node}"
done

info "Applying Talos configs to worker nodes..."
for node in "${WORKER_NODES[@]}"; do
  info "  → worker: ${node}"
  talosctl apply-config --insecure --nodes "${node}" \
    --file "${GENERATED_DIR}/${CLUSTER}-${node}.yaml" || warn "Failed to apply to ${node}"
done

# ── Step 3: Bootstrap etcd on first control plane ───────────────────────────
info "Step 3: Bootstrapping Kubernetes (etcd) on ${BOOTSTRAP_NODE}..."
warn "Waiting 120s for Talos to reach 'running' state..."
sleep 120
talosctl bootstrap --nodes "${BOOTSTRAP_NODE}"
info "Bootstrap successful. Fetching kubeconfig..."
talosctl kubeconfig --nodes "${BOOTSTRAP_NODE}" --force
info "kubeconfig updated."

# ── Step 4: Wait for Kubernetes API ─────────────────────────────────────────
info "Step 4: Waiting for Kubernetes API to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s || warn "Some nodes not ready yet"

# ── Step 5: Install ArgoCD ───────────────────────────────────────────────────
info "Step 5: Installing ArgoCD (${ARGOCD_NS} namespace)..."
kubectl create namespace "${ARGOCD_NS}" --dry-run=client -o yaml | kubectl apply -f -
kustomize build --enable-alpha-plugins --enable-exec \
  "${K8S_DIR}/clusters/${CLUSTER}/argocd/install" | kubectl apply -f -
kubectl rollout status deployment argocd-server -n "${ARGOCD_NS}" --timeout=180s
info "ArgoCD installed."

# ── Step 6: Apply KSOPS age key secret ───────────────────────────────────────
info "Step 6: Creating KSOPS age key secret in ${ARGOCD_NS}..."
kubectl create secret generic ksops-age-key \
  --namespace="${ARGOCD_NS}" \
  --from-file=key.txt="${SOPS_AGE_KEY_FILE}" \
  --dry-run=client -o yaml | kubectl apply -f -
info "KSOPS age key secret applied."

# ── Step 7: Apply root Application ───────────────────────────────────────────
info "Step 7: Applying ArgoCD root Application (app-of-apps)..."
kubectl apply -f "${K8S_DIR}/clusters/${CLUSTER}/argocd/apps/root-app.yaml"
info "Root application applied. ArgoCD will now sync all apps."

echo ""
info "Bootstrap complete for cluster: ${CLUSTER}"
info "ArgoCD admin password:"
kubectl get secret argocd-initial-admin-secret \
  -n "${ARGOCD_NS}" -o jsonpath="{.data.password}" | base64 -d && echo ""
info "Access ArgoCD at: https://argocd.dotfile.sh (or port-forward port 8080)"
