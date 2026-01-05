{{/*
Expand the name of the chart.
*/}}
{{- define "launchpad.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "launchpad.fullname" -}}
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
{{- define "launchpad.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "launchpad.labels" -}}
helm.sh/chart: {{ include "launchpad.chart" . }}
{{ include "launchpad.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "launchpad.selectorLabels" -}}
app.kubernetes.io/name: {{ include "launchpad.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "launchpad.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "launchpad.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
API labels
*/}}
{{- define "launchpad.api.labels" -}}
{{ include "launchpad.labels" . }}
app.kubernetes.io/component: api
{{- end }}

{{/*
API selector labels
*/}}
{{- define "launchpad.api.selectorLabels" -}}
{{ include "launchpad.selectorLabels" . }}
app.kubernetes.io/component: api
{{- end }}

{{/*
Client labels
*/}}
{{- define "launchpad.client.labels" -}}
{{ include "launchpad.labels" . }}
app.kubernetes.io/component: client
{{- end }}

{{/*
Client selector labels
*/}}
{{- define "launchpad.client.selectorLabels" -}}
{{ include "launchpad.selectorLabels" . }}
app.kubernetes.io/component: client
{{- end }}

{{/*
API image repository with default
Can be overridden via values or dynamically via Argo CD
*/}}
{{- define "launchpad.api.image" -}}
{{- if .Values.api.image.repository -}}
{{- .Values.api.image.repository }}:{{ .Values.api.image.tag | default .Chart.AppVersion }}
{{- else -}}
{{- $registry := .Values.imageDefaults.registry -}}
{{- $org := .Values.imageDefaults.organization -}}
{{- $repo := .Values.imageDefaults.repository -}}
{{- if and $registry $org $repo -}}
{{- printf "%s/%s/%s/api:%s" $registry $org $repo (.Values.api.image.tag | default .Chart.AppVersion) -}}
{{- else -}}
{{- fail "imageDefaults.registry, imageDefaults.organization, and imageDefaults.repository must be set" -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Client image repository with default
Can be overridden via values or dynamically via Argo CD
*/}}
{{- define "launchpad.client.image" -}}
{{- if .Values.client.image.repository -}}
{{- .Values.client.image.repository }}:{{ .Values.client.image.tag | default .Chart.AppVersion }}
{{- else -}}
{{- $registry := .Values.imageDefaults.registry -}}
{{- $org := .Values.imageDefaults.organization -}}
{{- $repo := .Values.imageDefaults.repository -}}
{{- if and $registry $org $repo -}}
{{- printf "%s/%s/%s/client:%s" $registry $org $repo (.Values.client.image.tag | default .Chart.AppVersion) -}}
{{- else -}}
{{- fail "imageDefaults.registry, imageDefaults.organization, and imageDefaults.repository must be set" -}}
{{- end -}}
{{- end -}}
{{- end }}
