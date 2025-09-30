{{/*
Expand the name of the chart.
*/}}
{{- define "default.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "default.fullname" -}}
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
{{- define "default.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "default.labels" -}}
helm.sh/chart: {{ include "default.chart" . }}
{{ include "default.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "default.selectorLabels" -}}
app.kubernetes.io/name: {{ include "default.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/* Create the name of the service account to use */}}
{{- define "default.serviceAccountName" -}}
{{- if .Values.main.serviceAccount.create }}
{{- default (include "default.fullname" .) .Values.main.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.main.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* PVC existing, emptyDir, Dynamic */}}
{{- define "default.pvc" -}}
{{- if or (not .Values.main.persistence.enabled) (eq .Values.main.persistence.type "emptyDir") -}}
          emptyDir: {}
{{- else if and .Values.main.persistence.enabled .Values.main.persistence.existingClaim -}}
          persistentVolumeClaim:
            claimName: {{ .Values.main.persistence.existingClaim }}
{{- else if and .Values.main.persistence.enabled (eq .Values.main.persistence.type "dynamic")  -}}
          persistentVolumeClaim:
            claimName: {{ include "default.fullname" . }}
{{- end }}
{{- end }}


{{/* Create environment variables from yaml tree */}}
{{- define "toEnvVars" -}}
    {{- $prefix := "" }}
    {{- if .prefix }}
        {{- $prefix = printf "%s_" .prefix }}
    {{- end }}
    {{- range $key, $value := .values }}
        {{- if kindIs "map" $value -}}
            {{- dict "values" $value "prefix" (printf "%s%s" $prefix ($key | upper)) "isSecret" $.isSecret | include "toEnvVars" -}}
        {{- else -}}
            {{- if $.isSecret -}}
{{ $prefix }}{{ $key | upper }}: {{ $value | toString | b64enc }}{{ "\n" }}
            {{- else -}}
{{ $prefix }}{{ $key | upper }}: {{ $value | toString | quote }}{{ "\n" }}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end }}

