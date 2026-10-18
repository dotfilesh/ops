set quiet
set minimum-version := '1.55.1'
set default-list
set default-script
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']

# Cluster every recipe acts on (mise sets it; override with CLUSTER=…)
export CLUSTER := env('CLUSTER', 'kclt-01')

[group('bootstrap')]
mod bootstrap 'bootstrap'

[group('kubernetes')]
mod kube 'kubernetes'

[group('talos')]
mod talos 'talos'

[doc('Render and test the Flux tree offline (what CI runs)')]
[group('ci')]
test:
    .github/scripts/flate-ratchet.sh flate

[private]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}
