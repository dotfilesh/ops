#!/bin/bash

# This is kinda ugly as it has to handle sensitive information.
# that is why the umask and log is set up like it is.


# This script will bootstrap FluxCD on a Talos cluster.
# running talos.sh is a prerequisite to this. If you have not yet
# prepared the machines: DO THAT FIRST!!!

# This script assumes the following:
# - age
# - flux
# - kubectl
# - sops
# if you do not have these installed, or do not have the necessary
# decryption keys for the SOPS encrypted files: DO THAT FIRST!!!




# explicit PATH, and umask
export PATH=/usr/bin:/bin/:/usr/sbin:/sbin
umask 0077

# Start logging things, put both STDERR and STDOUT into said log.
ME=$(basename "${0}")
ABS_DIR=$(dirname "$(realpath "${0}")")
exec 3>&2 >> "${ABS_DIR}"/"${ME}"-$(date +%s).log.nocommit 2>&1
# sets:
# - errexit: exit if simple command fails (nonzero return value)
# - nounset: write message to stderr if trying to expand unset variable
# - verbose: Write input to standard error as it is read.
# - xtrace : Write to stderr trace for each command after expansion.
set -euvx
uname -a
date

failure () { echo FAILED. >&3; exit 1; }
trap failure EXIT

# move to root of repo. This does assume the script is "somewhere" in
# the repo. Which I think is a perfectly healthy assumption to make.
cd "${ABS_DIR}"
cd "$(git rev-parse --show-toplevel)"

# Install flux
kubectl --kubeconfig "${KUBECONFIG}" apply --server-side --kustomize \
  ./k8s/global/bootstrap/

# This decrypts the sops-encrypted global and site age keys, 
# concatenates them through an array (TODO: there's gotta be a better
# way), and creates a kubernetes secret with the data in a format
# expected by flux.
# Special thanks to Kay for helping me with this.
{ sops --config <(echo '') --decrypt \
  ./k8s/clusters/"${CLUSTER_NAME}"/bootstrap/site.agekey.dirtysops ; \
  sops --config <(echo '') --decrypt \
  ./k8s/global/bootstrap/global.agekey.dirtysops ; } | \
  kubectl create secret generic sops-age \
  --namespace=flux-system \
  --from-file=age.agekey=/dev/stdin


# Decrypt and apply GitHub deploy key.
sops --decrypt \
  ./k8s/clusters/"${CLUSTER_NAME}"/bootstrap/github-token.sops.yaml \
  | kubectl apply -f -

# Apply values for flux variable substitution
kubectl apply -f ./k8s/global/config/global-config.yaml
kubectl apply -f \
  ./k8s/clusters/"${CLUSTER_NAME}"/flux/vars/cluster-config.yaml
sops --decrypt ./k8s/global/config/global-secrets.sops.yaml |\
  kubectl apply -f -
sops --decrypt \
  ./k8s/clusters/"${CLUSTER_NAME}"/flux/vars/cluster-secrets.sops.yaml |\
  kubectl apply -f -
  
# Begin reconciling flux repository.
kubectl --kubeconfig "${KUBECONFIG}" apply --kustomize \
  k8s/clusters/"${CLUSTER_NAME}"/flux/config/

echo "Please delete the log file, as it contains HIGHLY SENSITIVE INFORMATION."

# end of script. Therefore the only time failure should be untrapped.
trap - EXIT
