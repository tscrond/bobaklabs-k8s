{{- define "this.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "this.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


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
