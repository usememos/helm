{{/*
Expand the name of the chart.
*/}}
{{- define "memos.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name, truncated to the 63 characters a DNS
label allows. A release name that already contains the chart name is used as is.
*/}}
{{- define "memos.fullname" -}}
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
Chart name and version as used by the chart label.
*/}}
{{- define "memos.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "memos.labels" -}}
helm.sh/chart: {{ include "memos.chart" . }}
{{ include "memos.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "memos.selectorLabels" -}}
app.kubernetes.io/name: {{ include "memos.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the service account the pod runs as.
*/}}
{{- define "memos.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "memos.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Container image reference.
*/}}
{{- define "memos.image" -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- end }}

{{/*
Name of the Secret holding the database connection string, empty when Memos
uses its default SQLite file.
*/}}
{{- define "memos.databaseSecretName" -}}
{{- if .Values.database.existingSecret.name }}
{{- .Values.database.existingSecret.name }}
{{- else if .Values.database.dsn }}
{{- printf "%s-database" (include "memos.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Name of the persistent volume claim behind the data volume.
*/}}
{{- define "memos.claimName" -}}
{{- .Values.persistence.existingClaim | default (include "memos.fullname" .) }}
{{- end }}

{{/*
Whether a declarative configuration directory is mounted.
*/}}
{{- define "memos.hasConfig" -}}
{{- if or .Values.config.files .Values.config.existingConfigMap .Values.config.existingSecret }}true{{ end }}
{{- end }}

{{/*
Reject combinations of values that cannot produce a working instance.
*/}}
{{- define "memos.validate" -}}
{{- $driver := .Values.database.driver }}
{{- if and (ne $driver "sqlite") (not (include "memos.databaseSecretName" .)) }}
{{- fail (printf "database.driver %q needs a connection string: set database.dsn or database.existingSecret.name" $driver) }}
{{- end }}
{{- if and .Values.database.dsn .Values.database.existingSecret.name }}
{{- fail "set either database.dsn or database.existingSecret.name, not both" }}
{{- end }}
{{- if and (eq $driver "sqlite") (gt (int .Values.replicaCount) 1) }}
{{- fail "SQLite supports a single replica: set replicaCount to 1 or use database.driver mysql or postgres" }}
{{- end }}
{{- range $name, $_ := .Values.config.files }}
{{- if not (hasSuffix ".json" $name) }}
{{- fail (printf "config.files key %q must end in .json, or Memos does not read it" $name) }}
{{- end }}
{{- end }}
{{- if and .Values.httpRoute.enabled (not .Values.httpRoute.parentRefs) }}
{{- fail "httpRoute.enabled needs at least one entry in httpRoute.parentRefs" }}
{{- end }}
{{- end }}
