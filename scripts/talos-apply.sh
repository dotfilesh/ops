#!/usr/bin/env bash
# scripts/talos-apply.sh
#
# Apply Talos machine config to one or all nodes.
#
# Usage:
#   # Apply to a single node:
#   ./scripts/talos-apply.sh --node 10.64.6.1
#
#   # Apply to all nodes (control plane + workers):
#   ./scripts/talos-apply.sh --all
#
#   # Apply with --insecure (initial bootstrap, before certificates):
#   ./scripts/talos-apply.sh --node 10.64.6.1 --insecure
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CLUSTER="kclt-01"
TALOS_CONFIG_DIR="${REPO_ROOT}/talos/clusters/${CLUSTER}/clusterconfig"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# All cluster nodes (control plane + workers)
ALL_NODES=(
  "10.64.6.1"   # woglinde   — control plane
  "10.64.6.2"   # wellgunde  — control plane
  "10.64.6.3"   # flosshilde — control plane
  "10.64.6.8"   # junks      — control plane (temp)
  "10.64.6.9"   # formula    — worker
  "10.64.6.10"  # urban      — worker
  "10.64.6.11"  # lailah     — worker
  "10.64.6.12"  # verus      — worker
  "10.64.6.13"  # mastema    — worker
  "10.64.6.14"  # amdusias   — worker
)

NODE=""
ALL=false
INSECURE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --node)    NODE="$2"; shift 2 ;;
    --all)     ALL=true;  shift ;;
    --insecure) INSECURE="--insecure"; shift ;;
    *) die "Unknown argument: $1" ;;
  esac
done

apply_node() {
  local node="$1"
  local config="${TALOS_CONFIG_DIR}/${CLUSTER}-${node}.yaml"
  if [[ ! -f "${config}" ]]; then
    warn "Config not found for ${node}: ${config} (skipping)"
    return
  fi
  info "Applying Talos config to ${node}..."
  # shellcheck disable=SC2086
  talosctl apply-config ${INSECURE} --nodes "${node}" --file "${config}"
  info "Done: ${node}"
}

if [[ "${ALL}" == true ]]; then
  info "Applying Talos configs to all ${#ALL_NODES[@]} nodes in cluster ${CLUSTER}..."
  for node in "${ALL_NODES[@]}"; do
    apply_node "${node}" || warn "Failed to apply to ${node}"
  done
  info "All nodes done."
elif [[ -n "${NODE}" ]]; then
  apply_node "${NODE}"
else
  die "Usage: $0 --node <ip> | --all [--insecure]"
fi
