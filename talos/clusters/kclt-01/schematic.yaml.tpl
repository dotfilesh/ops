customization:
  systemExtensions:
    officialExtensions:
      {{- range .Node.Data.extensions }}
      - {{ . }}
      {{- end }}
