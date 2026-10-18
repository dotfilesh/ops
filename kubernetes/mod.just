set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set default-list

[doc('Make Flux pull and apply the latest Git revision now')]
[group('kube')]
reconcile:
    flux --namespace flux-system reconcile kustomization flux-system --with-source

[doc('Show Flux Kustomizations and HelmReleases that are not Ready')]
[group('kube')]
status:
    flux get all --all-namespaces --status-selector ready=false
