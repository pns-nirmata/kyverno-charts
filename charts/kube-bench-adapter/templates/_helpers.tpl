{{/*
Expand the name of the chart.
*/}}
{{- define "kube-bench.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kube-bench.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kube-bench.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kube-bench.labels" -}}
app.kubernetes.io/instance: nirmata
app.kubernetes.io/name: nirmata
helm.sh/chart: {{ include "kube-bench.chart" . }}
{{ include "kube-bench.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* matchLabels */}}
{{- define "kube-bench.matchLabels" -}}
app.kubernetes.io/name: nirmata
app.kubernetes.io/instance: nirmata
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "kube-bench.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kube-bench.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kube-bench.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kube-bench.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create secret to access docker registry
*/}}
{{- define "imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.image.pullSecrets.registry (printf "%s:%s" .Values.image.pullSecrets.username .Values.image.pullSecrets.password | b64enc) | b64enc }}
{{- end }}

{{- define "kube-bench.jobTemplate" }}
spec:
  template:
    metadata:
      labels:
            {{- include "kube-bench.labels" . | nindent 12 }}
    spec:
      containers:
      - name: {{ include "kube-bench.fullname" . }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        command: ["./{{ .Values.kubeBench.command }}"]
        args: [
        "-name","{{ .Values.kubeBench.name}}",
        "-category", "{{ .Values.kubeBench.category }}",
        "-namespace", "{{ .Values.kubeBench.namespace }}",
        "-kube-bench-image", "{{ .Values.kubeBench.kubeBenchImg }}",
        "-kubeconfig", "{{ .Values.kubeBench.kubeconfig }}",
        "-kube-bench-targets", "{{ .Values.kubeBench.kubeBenchTargets }}",
        "-kube-bench-benchmark", "{{ .Values.kubeBench.kubeBenchBenchmark }}",
        ]
        {{- with .Values.resources }}
        resources: {{ tpl (toYaml .) $ | nindent 14 }}
        {{- end }}
        {{- with .Values.livenessProbe }}
        livenessProbe: {{ tpl (toYaml .) $ | nindent 14 }}
        {{- end }}
        {{- with .Values.readinessProbe }}
        readinessProbe: {{ tpl (toYaml .) $ | nindent 14 }}
        {{- end }}
        {{- with .Values.securityContext }}
        securityContext: {{ tpl (toYaml .) $ | nindent 14 }}
        {{- end }}
      {{- if .Values.image.pullSecrets.create }}
      imagePullSecrets:
      - name: {{ .Values.image.pullSecrets.name }}
      {{- end }}
      restartPolicy: Never
      serviceAccountName:   {{ include "kube-bench.fullname" . }}
{{- end}}
