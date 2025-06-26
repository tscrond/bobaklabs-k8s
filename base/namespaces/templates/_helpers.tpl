{{/*
Create a default app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "this.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "this.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "this.labels" -}}
helm.sh/chart: {{ include "this.chart" . | quote }}
app.kubernetes.io/name: {{ include "this.name" . | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "this.selectorLabels" -}}
app.kubernetes.io/name: {{ include "this.name" . | quote }}
{{- end }}

{{/*
Command for init - print in a single line
*/}}
{{- define "command.init" -}}
{{ printf "nucypher ursula init " }}
{{- range $key, $value := .Values.commands.init }}
{{- if not $value }}
{{- printf "--%s " $key }}
{{- else }}
{{- printf "--%s %s " $key $value }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Command for run - multiline
*/}}
{{- define "command.run" -}}
{{- range $key, $value := .Values.commands.run }}
{{- if not $value }}
- {{ printf "--%s" $key | quote }}
{{- else }}
- {{ printf "--%s" $key | quote }}
- {{ printf "%s" $value | quote }}
{{- end }}
{{- end }}
{{- end }}
