set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set default-list
set default-script
set script-interpreter := ['bash', '-euo', 'pipefail']

# topf runs from the cluster's directory (topf.yaml + patches)
dir := source_directory() + '/clusters/' + env('CLUSTER', 'kclt-01')

[doc('Apply Talos config to all nodes (shows a diff and asks first)')]
[group('talos')]
apply:
    cd "{{ dir }}"
    topf apply

[arg('mode', pattern='auto|reboot|no-reboot|staged|try')]
[doc('Apply Talos config to one node (shows a diff and asks first)')]
[group('talos')]
apply-node node mode='auto':
    cd "{{ dir }}"
    topf apply --nodes-filter "^{{ node }}$" --mode "{{ mode }}"

[doc('Show pending Talos config changes without applying them')]
[group('talos')]
diff:
    cd "{{ dir }}"
    topf apply --dry-run

[doc('Render machine configs to ./rendered (gitignored)')]
[group('talos')]
render:
    cd "{{ dir }}"
    topf render --output ./rendered

[doc('Upgrade Talos on all nodes, one at a time (asks first)')]
[group('talos')]
upgrade:
    cd "{{ dir }}"
    topf upgrade

# topf intentionally leaves Kubernetes upgrades to talosctl
[doc('Upgrade Kubernetes to kubernetesVersion in topf.yaml')]
[group('talos')]
upgrade-k8s:
    cd "{{ dir }}"
    talosctl --nodes "$(yq '[.nodes[] | select(.role == "control-plane")][0].ip' topf.yaml)" \
        upgrade-k8s --to "$(yq '.kubernetesVersion' topf.yaml)"

[confirm("Reset EVERY node of this cluster to maintenance mode? [y/N]")]
[doc('Reset all nodes to maintenance mode (DESTRUCTIVE)')]
[group('talos')]
reset:
    cd "{{ dir }}"
    topf reset --confirm=false
