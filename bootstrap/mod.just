set quiet
set no-exit-message
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']
set default-list
set default-script

repo := source_directory() + '/..'
cluster := env('CLUSTER', 'kclt-01')
talos_dir := repo + '/talos/clusters/' + cluster
kube_dir := repo + '/kubernetes'

# Full bring-up of a razed cluster: boot every node into Talos maintenance
# mode first (on kclt-01's Dells, via the Clover USB in bootstrap/clover).
[doc('Install Talos on every node and fetch admin configs')]
[group('bootstrap')]
talos: talos-apply talos-configs

[doc('Install the base apps and hand the cluster to Flux')]
[group('bootstrap')]
apps: apps-ready apps-namespaces apps-sops apps-crds apps-helm
    just log info "Bootstrapped {{ cluster }}; Flux now syncs kubernetes/clusters/{{ cluster }}/flux"

# Rook refuses disks that still carry an old Ceph OSD. Run this while the
# nodes are in maintenance mode, before `just bootstrap talos`. It wipes only
# the devices listed in the cluster's rook-ceph-cluster values, matched by WWN.
[confirm("Wipe every Ceph OSD disk listed for this cluster? Data on them is destroyed. [y/N]")]
[doc('Wipe the Ceph OSD disks of a razed cluster (DESTRUCTIVE, maintenance mode)')]
[group('bootstrap')]
wipe-ceph-disks:
    values="{{ kube_dir }}/clusters/{{ cluster }}/apps/rook-ceph/rook-ceph-cluster-values.yaml"
    topf="{{ talos_dir }}/topf.yaml"
    for node in $(yq '.cephClusterSpec.storage.nodes[].name' "$values"); do
        ip="$(yq ".nodes[] | select(.host == \"$node\") | .ip" "$topf")"
        disks="$(talosctl get disks --insecure --nodes "$ip" --output yaml)"
        for dev in $(yq ".cephClusterSpec.storage.nodes[] | select(.name == \"$node\") | .devices[].name" "$values"); do
            wwn="${dev##*/wwn-0x}"
            name="$(yq -N "select(.spec.wwid == \"naa.$wwn\") | .metadata.id" <<<"$disks")"
            [[ -n "$name" ]] || { just log warn "No disk with this WWN" node "$node" wwn "$wwn"; continue; }
            just log info "Wiping" node "$node" disk "$name" wwn "$wwn"
            talosctl wipe disk "$name" --insecure --nodes "$ip" --drop-partition
        done
    done

[private]
talos-apply:
    cd "{{ talos_dir }}"
    just log info "Applying Talos config and bootstrapping etcd" cluster "{{ cluster }}"
    topf apply --auto-bootstrap --confirm=false

# topf issues short-lived admin certs by default; a year keeps them usable.
[private]
talos-configs:
    cd "{{ talos_dir }}"
    topf talosconfig > talosconfig
    topf kubeconfig --validity 8760h > kubeconfig
    just log info "Wrote talosconfig and kubeconfig" dir "{{ talos_dir }}"

# Nodes register Ready=False until the CNI (Cilium) is installed.
[private]
apps-ready:
    just log info "Waiting for nodes to register"
    deadline=$((SECONDS + 600))
    until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null \
        || kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; do
        (( SECONDS < deadline )) || { just log fatal "Timed out waiting for nodes"; }
        sleep 5
    done

[private]
apps-namespaces:
    for ns in "{{ kube_dir }}/clusters/{{ cluster }}/apps"/*/; do
        ns="$(basename "$ns")"
        kubectl create namespace "$ns" --dry-run=client -o yaml \
            | kubectl apply --server-side --filename - >/dev/null
        just log info "Namespace ready" namespace "$ns"
    done

# Flux decrypts with the age keys .sops.yaml names; only those are copied
# from the local key file, never anything else it may contain.
[private]
apps-sops:
    keyfile="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
    keys=""
    while read -r key; do
        pub="$(age-keygen -y <<<"$key")"
        grep -q "$pub" "{{ repo }}/.sops.yaml" && keys+="$key"$'\n'
    done < <(grep -oE 'AGE-SECRET-KEY-[A-Z0-9]+' "$keyfile")
    [[ -n "$keys" ]] || just log fatal "No age key from .sops.yaml found in $keyfile"
    kubectl --namespace flux-system create secret generic sops-age \
        --from-file=age.agekey=<(printf '%s' "$keys") --dry-run=client -o yaml \
        | kubectl apply --server-side --filename - >/dev/null
    just log info "Applied sops-age" keys "$(grep -c . <<<"$keys")"

[private]
[working-directory('helmfile')]
apps-crds:
    just log info "Applying CRDs"
    source <(just bootstrap env)
    helmfile --file crds.yaml template --quiet \
        | yq eval-all --exit-status 'select(.kind == "CustomResourceDefinition")' \
        | kubectl apply --server-side --force-conflicts --filename - >/dev/null

[private]
[working-directory('helmfile')]
apps-helm:
    just log info "Installing base apps with helmfile"
    source <(just bootstrap env)
    helmfile --file apps.yaml sync --hide-notes

# Flux ${VARS} for helmfile's envsubst, from the same settings/secrets the
# cluster uses (global then cluster, so cluster values win).
[private]
env:
    yq -o shell '.data' "{{ kube_dir }}/components/global-vars/global-settings.yaml" | sed 's/^/export /'
    sops decrypt "{{ kube_dir }}/components/global-vars/global-secrets.sops.yaml" | yq -o shell '.stringData' | sed 's/^/export /'
    yq -o shell '.data' "{{ kube_dir }}/clusters/{{ cluster }}/components/cluster-vars/cluster-settings.yaml" | sed 's/^/export /'
    sops decrypt "{{ kube_dir }}/clusters/{{ cluster }}/components/cluster-vars/cluster-secrets.sops.yaml" | yq -o shell '.stringData' | sed 's/^/export /'
