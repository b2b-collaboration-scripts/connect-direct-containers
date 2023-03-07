{{/*
Route name
*/}}
{{- define "itx.rs.routeName" }}
  {{- "itx-rs-route" }}
{{- end }}

{{/*
Service name
*/}}
{{- define "itx.rs.serviceName" }}
  {{- "itx-rs-svc" }}
{{- end }}

{{/*
Application name
*/}}
{{- define "itx.rs.appName" }}
  {{- "itx-rs" }}
{{- end }}

{{/*
Labels for resources 
*/}}
{{- define "itx.rs.labels" -}}
app.kubernetes.io/name: {{ include "itx.rs.appName" . | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
helm.sh/chart: {{ .Chart.Name | quote }}
release: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Annotations for metering
*/}}
{{- define "itx.rs.metering" -}}
productID: "e3ea97bcc2ae4e39b9a0ac4fe309f546"
productName: "IBM Sterling Transformation Extender for Red Hat OpenShift"
productVersion: "10.1.1"
productMetric: "VIRTUAL_PROCESSOR_CORE"
productChargedContainers: "All"
{{- end -}}

{{/*
Node affinity settings
*/}}
{{- define "itx.rs.affinity" -}}
nodeAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - preference:
      matchExpressions:
      - key: kubernetes.io/arch
        operator: In
        values:
        - amd64
    weight: 3
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      - key: kubernetes.io/arch
        operator: In
        values:
        - amd64
{{- end -}}
