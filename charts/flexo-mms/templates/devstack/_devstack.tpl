{{/*
Persistence volume for a dev-stack component. Expects (dict "root" $ "component" "fuseki" "values" $.Values.devStack.fuseki).
*/}}
{{- define "flexo-mms.devStack.dataVolume" -}}
- name: data
{{- if .values.persistence.enabled }}
  persistentVolumeClaim:
    claimName: {{ default (include "flexo-mms.componentName" (dict "root" .root "component" .component)) .values.persistence.existingClaim }}
{{- else }}
  emptyDir: {}
{{- end }}
{{- end }}

{{- define "flexo-mms.devStack.pvc" -}}
{{- if and .values.persistence.enabled (not .values.persistence.existingClaim) }}
{{- $meta := dict "root" .root "component" .component "version" (toString .values.image.tag) }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "flexo-mms.componentName" $meta }}
  namespace: {{ .root.Release.Namespace }}
  labels:
    {{- include "flexo-mms.componentLabels" $meta | nindent 4 }}
  {{- with (include "flexo-mms.annotations" .root) }}
  annotations:
    {{- . | nindent 4 }}
  {{- end }}
spec:
  accessModes:
    {{- toYaml .values.persistence.accessModes | nindent 4 }}
  {{- with .values.persistence.storageClass }}
  storageClassName: {{ . | quote }}
  {{- end }}
  resources:
    requests:
      storage: {{ .values.persistence.size }}
{{- end }}
{{- end }}
