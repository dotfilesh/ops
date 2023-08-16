#!/bin/bash

##########################################
# DO NOT USE. NOT DONE. FIX. GODDAMN IT. #
##########################################

# explicit PATH, and umask
export PATH=/usr/bin:/bin/:/usr/sbin:/sbin
umask 2

# Start logging things, put both STDERR and STDOUT into said log.
ME=$(basename "$0")
exec 3>&2 >> /opt/log/${ME}.log.nocommit 2>&1
# sets:
# - errexit: exit if simple command fails (nonzero return value)
# - nounset: write message to stderr if trying to expand unset variable
# - verbose: Write input to standard error as it is read.
# - xtrace : Write to stderr trace for each command after expansion.
set -euvx
uname -a
date

# TODO: make sure script runs in root of repo as working dir.

# Install flux
kubectl --kubeconfig ${kubeconfig} apply --server-side --kustomize ./k8s/global/bootstrap/

# Compile agekey file using site_id + global key into secret and apply.
# TODO: figure out how to make this happen securely.
sops --config <(echo '') --decrypt ./k8s/clusters/${site_id}/bootstrap/site.agekey.dirtysops >> #???
sops --config <(echo '') --decrypt ./k8s/global/bootstrap/global.agekey.dirtysops >> # ???
kubectl create secret generic sops-age \
  --namespace=flux-system \
  --from-file=age.agekey= # ???


# Decrypt and apply GitHub deploy key.
sops  --decrept ./k8s/clusters/${site_id}/bootstrap/github-deploy-key.sops.yaml | kubectl apply -f -

# Apply values for flux variable substitution
kubectl apply -f ./k8s/global/config/global-config.yaml
kubectl apply -f ./k8s/clusters/${site_id}/flux/vars/cluser-config.yaml
sops --decrypt ../k8s/global/config/global-secrets.sops.yaml | kubectl apply -f -
sops --decrypt ./k8s/clusters/${site_id}/flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
  
# this command originally had a spelling error, which leads me to
# believe this whole script was just a set of dummy values.
kubectl --kubeconfig ${kubeconfig} apply --kustomize k8s/clusters/${site_id}/flux/config/
