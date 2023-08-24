#!/bin/bash

# This is kinda ugly as it has to handle sensitive information.
# that is why the umask and log is set up like it is.


#This script will install Talos Linux onto a site's servers.
#It is expected to have all nodes ready for imaging, and the following
#software is installed:
# - age
# - cut
# - sops
# - talosctl
# - talhelper
# - yq




# explicit PATH, and umask
export PATH=/usr/bin:/bin/:/usr/sbin:/sbin
umask 0077

# Start logging things, put both STDERR and STDOUT into said log.
me=$(basename "${0}")
abs_dir=$(dirname "$(realpath "${0}")")
exec 3>&2 >> "${abs_dir}"/"${me}"-"$(date +%s)".log.nocommit 2>&1
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
cd "${abs_dir}"
cd "$(git rev-parse --show-toplevel)"

# run talhelper to generate config files
cd talos/clusters/"${CLUSTER_NAME}"/
talhelper genconfig
export TALOSCONFIG="$(realname clusterconfig/talosconfig)"
cd -

# Apply the yaml.
function apply_yaml () {
    for file in talos/clusters/"${CLUSTER_NAME}"/clusterconfig/*.yaml
    do
        node_ip=$(yq -r '.machine.network.interfaces[0].addresses[0]' \
            "${file}" | cut -f1 -d"/")
    talosctl -n "${node_ip}" apply-config --file "${file}" --insecure
    done
}
apply_yaml

# TODO: expand this to iterate over all control planes.
function bootstrap_cluster () {
    node_ip=$(yq -r ".contexts.${CLUSTER_NAME}.endpoints[0]" \
        talos/clusters/"${CLUSTER_NAME}"/clusterconfig/talosconfig)
    talosctl -n "${node_ip}" bootstrap
    talosctl -n "${node_ip}" kubeconfig -f
}
bootstrap_cluster
echo "Export your TALOSCONFIG to ${TALOSCONFIG} in your .bashrc"

# Finally install the CNI and CSR approver, which are absolute necessities for anything.
kubectl kustomize --enable-helm \
    ./k8s/clusters/"${CLUSTER_NAME}"/bootstrap/cni | kubectl apply -f -
kubectl kustomize --enable-helm \
    ./k8s/clusters/"${CLUSTER_NAME}"/bootstrap/kubelet-csr-approver | \
    kubectl apply -f -

# end of script. Therefore the only time failure should be untrapped.
trap - EXIT
