{{/*
Chart name, release fullname and chart label.
*/}}
{{- define "flexo-mms.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "flexo-mms.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "flexo-mms.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Name of a component resource: <fullname>-<component>. Expects (dict "root" $ "component" "layer1").
*/}}
{{- define "flexo-mms.componentName" -}}
{{- $suffix := printf "-%s" .component }}
{{- printf "%s%s" (include "flexo-mms.fullname" .root | trunc (int (sub 63 (len $suffix))) | trimSuffix "-") $suffix }}
{{- end }}

{{/*
Labels. Selector labels are stable across upgrades; never add volatile labels to them.
*/}}
{{- define "flexo-mms.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flexo-mms.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "flexo-mms.labels" -}}
helm.sh/chart: {{ include "flexo-mms.chart" . }}
{{ include "flexo-mms.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: flexo-mms
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "flexo-mms.componentSelectorLabels" -}}
{{ include "flexo-mms.selectorLabels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Component labels. Expects (dict "root" $ "component" "layer1" "version" "v0.3.1"); version is optional.
*/}}
{{- define "flexo-mms.componentLabels" -}}
helm.sh/chart: {{ include "flexo-mms.chart" .root }}
{{ include "flexo-mms.componentSelectorLabels" . }}
app.kubernetes.io/version: {{ default .root.Chart.AppVersion .version | quote }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
app.kubernetes.io/part-of: flexo-mms
{{- with .root.Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "flexo-mms.annotations" -}}
{{- with .Values.commonAnnotations }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Image reference and pull secrets.
*/}}
{{- define "flexo-mms.image" -}}
{{- printf "%s:%s" .repository (toString .tag) }}
{{- end }}

{{- define "flexo-mms.imagePullSecrets" -}}
{{- $secrets := list }}
{{- range .Values.global.imagePullSecrets }}
{{- $secrets = append $secrets (dict "name" .) }}
{{- end }}
{{- if .Values.imagePullSecret.create }}
{{- $secrets = append $secrets (dict "name" (include "flexo-mms.imagePullSecretName" .)) }}
{{- end }}
{{- with $secrets }}
imagePullSecrets:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "flexo-mms.imagePullSecretName" -}}
{{- default (printf "%s-dockerhub" (include "flexo-mms.fullname" .)) .Values.imagePullSecret.name }}
{{- end }}

{{- define "flexo-mms.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "flexo-mms.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Security contexts: chart-wide defaults merged with the component's overrides. Expects (dict "root" $ "values" $component).
*/}}
{{- define "flexo-mms.podSecurityContext" -}}
{{- toYaml (mergeOverwrite (deepCopy .root.Values.podSecurityContext) (default (dict) .values.podSecurityContext)) }}
{{- end }}

{{- define "flexo-mms.containerSecurityContext" -}}
{{- toYaml (mergeOverwrite (deepCopy .root.Values.containerSecurityContext) (default (dict) .values.containerSecurityContext)) }}
{{- end }}

{{/*
Probe rendering: drops the `enabled` flag and runs the probe through tpl. Expects (dict "root" $ "probe" $probe).
*/}}
{{- define "flexo-mms.probe" -}}
{{- $probe := omit .probe "enabled" }}
{{- tpl (toYaml $probe) .root }}
{{- end }}

{{/*
In-cluster service URLs of the chart's own components.
*/}}
{{- define "flexo-mms.serviceUrl" -}}
{{- printf "http://%s.%s.svc:%v" (include "flexo-mms.componentName" (dict "root" .root "component" .component)) .root.Release.Namespace .port }}
{{- end }}

{{- define "flexo-mms.fusekiUrl" -}}
{{- include "flexo-mms.serviceUrl" (dict "root" . "component" "fuseki" "port" .Values.devStack.fuseki.service.port) }}
{{- end }}

{{- define "flexo-mms.fusekiDatasetUrl" -}}
{{- printf "%s/%s" (include "flexo-mms.fusekiUrl" .) .Values.devStack.fuseki.dataset }}
{{- end }}

{{/*
Quad store endpoints: explicit values win, then the dev-stack Fuseki, otherwise the value is required.
*/}}
{{- define "flexo-mms.quadStore.queryUrl" -}}
{{- if .Values.quadStore.queryUrl }}{{ .Values.quadStore.queryUrl }}
{{- else if .Values.devStack.enabled }}{{ include "flexo-mms.fusekiDatasetUrl" . }}/sparql
{{- end }}
{{- end }}

{{- define "flexo-mms.quadStore.updateUrl" -}}
{{- if .Values.quadStore.updateUrl }}{{ .Values.quadStore.updateUrl }}
{{- else if .Values.devStack.enabled }}{{ include "flexo-mms.fusekiDatasetUrl" . }}/update
{{- end }}
{{- end }}

{{- define "flexo-mms.quadStore.graphStoreProtocolUrl" -}}
{{- if .Values.quadStore.graphStoreProtocolUrl }}{{ .Values.quadStore.graphStoreProtocolUrl }}
{{- else if .Values.devStack.enabled }}{{ include "flexo-mms.fusekiDatasetUrl" . }}/data
{{- end }}
{{- end }}

{{/*
Store service URL seen by layer1.
*/}}
{{- define "flexo-mms.layer1.storeServiceUrl" -}}
{{- if .Values.layer1.storeServiceUrl }}{{ .Values.layer1.storeServiceUrl }}
{{- else if .Values.store.enabled }}{{ include "flexo-mms.serviceUrl" (dict "root" . "component" "store" "port" .Values.store.service.port) }}/store
{{- end }}
{{- end }}

{{/*
Root context without a trailing slash, and the auth service's group-store context (with one).
*/}}
{{- define "flexo-mms.rootContext" -}}
{{- .Values.layer1.rootContext | trimSuffix "/" }}
{{- end }}

{{- define "flexo-mms.ldap.groupStoreContext" -}}
{{- default (printf "%s/" (include "flexo-mms.rootContext" .)) .Values.ldap.groupStoreContext }}
{{- end }}

{{- define "flexo-mms.ldap.location" -}}
{{- if .Values.ldap.location }}{{ .Values.ldap.location }}
{{- else if .Values.devStack.enabled }}{{ printf "ldap://%s.%s.svc:%v" (include "flexo-mms.componentName" (dict "root" . "component" "openldap")) .Release.Namespace .Values.devStack.openldap.service.port }}
{{- end }}
{{- end }}

{{- define "flexo-mms.ldap.userPattern" -}}
{{- if .Values.ldap.userPattern }}{{ .Values.ldap.userPattern }}
{{- else if .Values.devStack.enabled }}{{ printf "cn=%%s,ou=%s" .Values.devStack.openldap.userDc }}
{{- else }}cn=%s,ou=users
{{- end }}
{{- end }}

{{- define "flexo-mms.ldap.base" -}}
{{- if .Values.ldap.base }}{{ .Values.ldap.base }}
{{- else if .Values.devStack.enabled }}{{ .Values.devStack.openldap.root }}
{{- end }}
{{- end }}

{{/*
S3 endpoint and credentials Secret. The credentials come from (in order) s3.existingSecret, s3.accessKeyId, the dev-stack MinIO Secret.
*/}}
{{- define "flexo-mms.s3.endpoint" -}}
{{- if .Values.s3.endpoint }}{{ .Values.s3.endpoint }}
{{- else if .Values.devStack.enabled }}{{ include "flexo-mms.serviceUrl" (dict "root" . "component" "minio" "port" .Values.devStack.minio.service.port) }}
{{- end }}
{{- end }}

{{- define "flexo-mms.s3.createSecret" -}}
{{- if and (not .Values.s3.existingSecret) (or .Values.s3.accessKeyId .Values.s3.secretAccessKey) }}true{{- end }}
{{- end }}

{{- define "flexo-mms.s3.secretName" -}}
{{- if .Values.s3.existingSecret }}{{ .Values.s3.existingSecret }}
{{- else if include "flexo-mms.s3.createSecret" . }}{{ include "flexo-mms.componentName" (dict "root" . "component" "s3") }}
{{- else if .Values.devStack.enabled }}{{ include "flexo-mms.minio.secretName" . }}
{{- end }}
{{- end }}

{{- define "flexo-mms.s3.accessKeyIdKey" -}}
{{- if or .Values.s3.existingSecret (include "flexo-mms.s3.createSecret" .) }}{{ .Values.s3.existingSecretKeys.accessKeyId }}{{- else }}MINIO_ROOT_USER{{- end }}
{{- end }}

{{- define "flexo-mms.s3.secretAccessKeyKey" -}}
{{- if or .Values.s3.existingSecret (include "flexo-mms.s3.createSecret" .) }}{{ .Values.s3.existingSecretKeys.secretAccessKey }}{{- else }}MINIO_ROOT_PASSWORD{{- end }}
{{- end }}

{{- define "flexo-mms.minio.secretName" -}}
{{- default (include "flexo-mms.componentName" (dict "root" . "component" "minio")) .Values.devStack.minio.existingSecret }}
{{- end }}

{{- define "flexo-mms.openldap.secretName" -}}
{{- default (include "flexo-mms.componentName" (dict "root" . "component" "openldap")) .Values.devStack.openldap.existingSecret }}
{{- end }}

{{/*
JWT Secret. The dev stack falls back to the docker-compose secret so it works out of the box.
*/}}
{{- define "flexo-mms.jwt.secretName" -}}
{{- default (include "flexo-mms.componentName" (dict "root" . "component" "jwt")) .Values.jwt.existingSecret }}
{{- end }}

{{- define "flexo-mms.jwt.secretValue" -}}
{{- if .Values.jwt.secret }}{{ .Values.jwt.secret }}
{{- else if .Values.devStack.enabled }}thisissomethingreallylong1234567801234567890
{{- else }}
{{- $existing := lookup "v1" "Secret" .Release.Namespace (include "flexo-mms.jwt.secretName" .) }}
{{- if and $existing $existing.data (index $existing.data .Values.jwt.existingSecretKey) }}{{ index $existing.data .Values.jwt.existingSecretKey | b64dec }}
{{- else }}{{ randAlphaNum 64 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "flexo-mms.jwt.jwksUrl" -}}
{{- if .Values.jwt.jwksUrl }}{{ .Values.jwt.jwksUrl }}
{{- else if .Values.sso.enabled }}{{ include "flexo-mms.serviceUrl" (dict "root" . "component" "sso" "port" .Values.sso.service.port) }}{{ .Values.sso.contextPath }}/.well-known/jwks.json
{{- end }}
{{- end }}

{{/*
SSO helpers.
*/}}
{{- define "flexo-mms.sso.secretName" -}}
{{- include "flexo-mms.componentName" (dict "root" . "component" "sso") }}
{{- end }}

{{- define "flexo-mms.sso.redirectUri" -}}
{{- if .Values.sso.oidc.redirectUri }}{{ .Values.sso.oidc.redirectUri }}
{{- else if and .Values.ingress.enabled .Values.ingress.hosts }}{{ printf "%s://%s%s/login/oauth2/code/oidc" (ternary "https" "http" (not (empty .Values.ingress.tls))) (first .Values.ingress.hosts) .Values.sso.contextPath }}
{{- end }}
{{- end }}

{{/*
Shared JWT env entries for the Flexo MMS containers.
*/}}
{{- define "flexo-mms.jwtEnv" -}}
- name: JWT_DOMAIN
  value: {{ .Values.jwt.domain | quote }}
- name: JWT_AUDIENCE
  value: {{ .Values.jwt.audience | quote }}
- name: JWT_REALM
  value: {{ .Values.jwt.realm | quote }}
- name: JWT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "flexo-mms.jwt.secretName" . }}
      key: {{ .Values.jwt.existingSecretKey }}
{{- end }}

{{/*
Logback fragment mount shared by the Ktor services.
*/}}
{{- define "flexo-mms.logback.configMapName" -}}
{{- default (include "flexo-mms.componentName" (dict "root" . "component" "logback")) .Values.logback.existingConfigMap }}
{{- end }}

{{- define "flexo-mms.logbackVolume" -}}
- name: logback
  configMap:
    name: {{ include "flexo-mms.logback.configMapName" . }}
    items:
      - key: {{ .Values.logback.existingConfigMapKey }}
        path: loggers-include.xml
{{- end }}

{{- define "flexo-mms.logbackVolumeMount" -}}
- name: logback
  mountPath: /mnt/config/logback
  readOnly: true
{{- end }}

{{/*
Test credentials: explicit values, else the first dev-stack user.
*/}}
{{- define "flexo-mms.tests.username" -}}
{{- if .Values.tests.username }}{{ .Values.tests.username }}
{{- else if and .Values.devStack.enabled .Values.devStack.openldap.users }}{{ first .Values.devStack.openldap.users }}
{{- end }}
{{- end }}

{{- define "flexo-mms.tests.password" -}}
{{- if .Values.tests.password }}{{ .Values.tests.password }}
{{- else if and .Values.devStack.enabled .Values.devStack.openldap.passwords }}{{ first .Values.devStack.openldap.passwords }}
{{- end }}
{{- end }}

{{/*
Settings that have no value and no dev-stack fallback; NOTES.txt prints them.
*/}}
{{- define "flexo-mms.missingSettings" -}}
{{- $missing := list }}
{{- if not .Values.devStack.enabled }}
{{- if and .Values.layer1.enabled (not .Values.quadStore.queryUrl) }}{{ $missing = append $missing "quadStore.queryUrl" }}{{ end }}
{{- if and .Values.layer1.enabled (not .Values.quadStore.updateUrl) }}{{ $missing = append $missing "quadStore.updateUrl" }}{{ end }}
{{- if and .Values.layer1.enabled (not .Values.quadStore.graphStoreProtocolUrl) }}{{ $missing = append $missing "quadStore.graphStoreProtocolUrl" }}{{ end }}
{{- if and .Values.auth.enabled (not .Values.ldap.location) }}{{ $missing = append $missing "ldap.location" }}{{ end }}
{{- if and .Values.auth.enabled (not .Values.ldap.base) }}{{ $missing = append $missing "ldap.base" }}{{ end }}
{{- end }}
{{- join " " $missing }}
{{- end }}
