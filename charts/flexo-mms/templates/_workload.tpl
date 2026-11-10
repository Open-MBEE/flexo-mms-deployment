{{/*
Generic Deployment for a Flexo MMS component.
Expects (dict "root" $ "component" "layer1" "values" $.Values.layer1 "port" 8080 "env" <yaml> "envFrom" <yaml> "volumes" <yaml> "volumeMounts" <yaml> "checksums" (dict)).
*/}}
{{- define "flexo-mms.deployment" -}}
{{- $root := .root }}
{{- $c := .values }}
{{- $component := .component }}
{{- $meta := dict "root" $root "component" $component "version" (toString $c.image.tag) }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "flexo-mms.componentName" $meta }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    {{- include "flexo-mms.componentLabels" $meta | nindent 4 }}
  {{- with (include "flexo-mms.annotations" $root) }}
  annotations:
    {{- . | nindent 4 }}
  {{- end }}
spec:
  {{- if not (and $c.autoscaling $c.autoscaling.enabled) }}
  replicas: {{ $c.replicaCount }}
  {{- end }}
  {{- with $c.strategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "flexo-mms.componentSelectorLabels" $meta | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "flexo-mms.componentSelectorLabels" $meta | nindent 8 }}
        {{- with $c.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      annotations:
        {{- range $k, $v := .checksums }}
        checksum/{{ $k }}: {{ $v }}
        {{- end }}
        {{- with $c.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- include "flexo-mms.imagePullSecrets" $root | nindent 6 }}
      serviceAccountName: {{ include "flexo-mms.serviceAccountName" $root }}
      automountServiceAccountToken: {{ $root.Values.serviceAccount.automountServiceAccountToken }}
      securityContext:
        {{- include "flexo-mms.podSecurityContext" (dict "root" $root "values" $c) | nindent 8 }}
      {{- with $c.priorityClassName }}
      priorityClassName: {{ . }}
      {{- end }}
      {{- with $c.terminationGracePeriodSeconds }}
      terminationGracePeriodSeconds: {{ . }}
      {{- end }}
      containers:
        - name: {{ $component }}
          image: {{ include "flexo-mms.image" $c.image }}
          imagePullPolicy: {{ $c.image.pullPolicy }}
          securityContext:
            {{- include "flexo-mms.containerSecurityContext" (dict "root" $root "values" $c) | nindent 12 }}
          {{- with .args }}
          args:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          ports:
            - name: http
              containerPort: {{ .port }}
              protocol: TCP
          env:
            - name: TZ
              value: {{ $root.Values.timezone | quote }}
            {{- with .env }}
            {{- . | nindent 12 }}
            {{- end }}
            {{- with $c.extraEnv }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
          {{- if or .envFrom $c.extraEnvFrom }}
          envFrom:
            {{- with .envFrom }}
            {{- . | nindent 12 }}
            {{- end }}
            {{- with $c.extraEnvFrom }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
          {{- end }}
          {{- if and $c.startupProbe $c.startupProbe.enabled }}
          startupProbe:
            {{- include "flexo-mms.probe" (dict "root" $root "probe" $c.startupProbe) | nindent 12 }}
          {{- end }}
          {{- if and $c.livenessProbe $c.livenessProbe.enabled }}
          livenessProbe:
            {{- include "flexo-mms.probe" (dict "root" $root "probe" $c.livenessProbe) | nindent 12 }}
          {{- end }}
          {{- if and $c.readinessProbe $c.readinessProbe.enabled }}
          readinessProbe:
            {{- include "flexo-mms.probe" (dict "root" $root "probe" $c.readinessProbe) | nindent 12 }}
          {{- end }}
          resources:
            {{- toYaml $c.resources | nindent 12 }}
          volumeMounts:
            - name: tmp
              mountPath: /tmp
            {{- with .volumeMounts }}
            {{- . | nindent 12 }}
            {{- end }}
            {{- with $c.extraVolumeMounts }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
      volumes:
        - name: tmp
          emptyDir: {}
        {{- with .volumes }}
        {{- . | nindent 8 }}
        {{- end }}
        {{- with $c.extraVolumes }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- with $c.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $c.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $c.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $c.topologySpreadConstraints }}
      topologySpreadConstraints:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}

{{/*
Generic Service. Expects (dict "root" $ "component" "layer1" "values" $.Values.layer1 "port" 8080).
*/}}
{{- define "flexo-mms.service" -}}
{{- $meta := dict "root" .root "component" .component "version" (toString .values.image.tag) }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "flexo-mms.componentName" $meta }}
  namespace: {{ .root.Release.Namespace }}
  labels:
    {{- include "flexo-mms.componentLabels" $meta | nindent 4 }}
  {{- $annotations := merge (default (dict) .values.service.annotations) (default (dict) .root.Values.commonAnnotations) }}
  {{- with $annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .values.service.type }}
  ports:
    - name: http
      port: {{ .values.service.port }}
      targetPort: http
      protocol: TCP
  selector:
    {{- include "flexo-mms.componentSelectorLabels" $meta | nindent 4 }}
{{- end }}

{{/*
PodDisruptionBudget and HorizontalPodAutoscaler. Expects (dict "root" $ "component" "layer1" "values" $.Values.layer1).
*/}}
{{- define "flexo-mms.pdb" -}}
{{- if .values.podDisruptionBudget.enabled }}
{{- $meta := dict "root" .root "component" .component "version" (toString .values.image.tag) }}
apiVersion: policy/v1
kind: PodDisruptionBudget
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
  {{- if .values.podDisruptionBudget.maxUnavailable }}
  maxUnavailable: {{ .values.podDisruptionBudget.maxUnavailable }}
  {{- else }}
  minAvailable: {{ .values.podDisruptionBudget.minAvailable }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "flexo-mms.componentSelectorLabels" $meta | nindent 6 }}
{{- end }}
{{- end }}

{{- define "flexo-mms.hpa" -}}
{{- if .values.autoscaling.enabled }}
{{- $meta := dict "root" .root "component" .component "version" (toString .values.image.tag) }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
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
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "flexo-mms.componentName" $meta }}
  minReplicas: {{ .values.autoscaling.minReplicas }}
  maxReplicas: {{ .values.autoscaling.maxReplicas }}
  metrics:
    {{- with .values.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ . }}
    {{- end }}
    {{- with .values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ . }}
    {{- end }}
{{- end }}
{{- end }}
