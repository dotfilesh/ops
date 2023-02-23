#!/usr/bin/env bash
set -o nounset
set -o errexit

# TODO: set working directory to root of repo
# TODO: set kubeconfig as a variable, do not assume it is kctl --whatever

# Initial setup, installs bare necessities (in this case flux)
kubectl --kubeconfig ${kubeconfig} apply -k k8s/init/bootstrap/

# I mean, creates a secret, that much is obvious.
# However I am not sure if this + the below kubectl command do the
# equivalent of `flux bootstrap` or if that needs to be done first.
printf "Please add this public key to the ops repository deploy keys\n"
flux --kubeconfig ${kubeconfig} create secret git github-token \
  --url=ssh://git@github.com/dotfilesh/ops \
  --ssh-key-algorithm=ed25519
# this command originally had a spelling error, which leads me to
# believe this whole script was just a set of dummy values.
kubectl --kubeconfig ${kubeconfig} apply --kustomize k8s/clusters/${site_id}/flux/flux-system/

# by this point, regardless of above, flux definately is set up.
# so it reconsiles everything from the ops repo and applies it
flux --kubeconfig ${kubeconfig} reconcile source git ops
