#!/usr/bin/env bash

set -o nounset
set -o errexit

# TODO: set working directory to root of repo
# TODO: set kubeconfig as a variable, do not assume it is kctl --whatever

kubectl --kubeconfig ${kubeconfig} apply -k k8s/global/init/bootstrap/
echo "Please add this public key to the ops repository deploy keys"
flux --kubeconfig ${kubeconfig} create secret git github-token \
  --url=ssh://git@github.com/dotfilesh/ops \
  --ssh-key-algorithm=ed25519
kubectl --kubeconfig ${kubeconfig} apply --kustomize k8s/clusters${site_id}/flux/flux-system/
flux --kubeconfig ${kubeconfig} reconcile source git flux-cluster
