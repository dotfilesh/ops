apiVersion: v1alpha1
kind: UnattendedInstallConfig
provisioning:
  diskSelector:
    match: {{ with index .Node.Data "installDisk" }}{{ . }}{{ else }}{{ $.Data.installDisk }}{{ end }}
