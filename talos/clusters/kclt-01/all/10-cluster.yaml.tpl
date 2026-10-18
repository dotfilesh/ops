machine:
  certSANs:
    - "{{ .Data.apiAddr }}"
    - "127.0.0.1"
---
apiVersion: v1alpha1
kind: KubeNetworkConfig
podSubnets: ["{{ .Data.podCIDR }}"]
serviceSubnets: ["{{ .Data.svcCIDR }}"]
