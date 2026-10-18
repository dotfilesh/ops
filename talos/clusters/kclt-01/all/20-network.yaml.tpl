# Every node exposes its uplink as bond0 (a one-link bond where there is
# only one NIC), so Cilium's `devices: bond0+`, the L2 announcement policy and
# the API VIP see the same interface name everywhere.
{{- $mac := index .Node.Data "macAddr" }}
{{- if $mac }}
---
apiVersion: v1alpha1
kind: LinkAliasConfig
name: uplink0
selector:
  match: glob("{{ $mac }}", mac(link.hardware_addr))
{{- end }}
---
apiVersion: v1alpha1
kind: BondConfig
name: bond0
links:
  - {{ if $mac }}uplink0{{ else }}{{ index .Node.Data "link" }}{{ end }}
bondMode: {{ .Node.Data.bondMode }}
mtu: {{ .Node.Data.mtu }}
addresses:
  - address: "{{ .Node.IP }}/20"
routes:
  - gateway: "{{ .Data.gateway }}"
{{- if eq .Node.Role "control-plane" }}
---
apiVersion: v1alpha1
kind: Layer2VIPConfig
link: bond0
name: "{{ .Data.apiAddr }}"
{{- end }}
