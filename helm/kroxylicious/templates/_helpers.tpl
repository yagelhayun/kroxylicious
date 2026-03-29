{{- define "kroxylicious.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kroxylicious.fullname" -}}
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

{{- define "kroxylicious.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "kroxylicious.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "kroxylicious.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kroxylicious.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Full path to the downloaded CA bundle inside the pod */}}
{{- define "kroxylicious.caBundlePath" -}}
{{- .Values.caBundle.certPath -}}
{{- end }}

{{/*
Renders the full kroxylicious config.yaml content (unindented).
Use  include "kroxylicious.config" . | indent 4  in the ConfigMap.
*/}}
{{- define "kroxylicious.config" -}}
management:
  bindAddress: {{ .Values.management.bindAddress | quote }}
  port: {{ .Values.management.port }}
  endpoints:
    prometheus: {}

{{- if .Values.authorization.enabled }}
filterDefinitions:
  - name: acl-authorization
    type: Authorization
    config:
      authorizer: AclAuthorizerService
      authorizerConfig:
        aclFile: /config/acl-rules.txt
{{- end }}
virtualClusters:
  - name: {{ .Values.virtualClusterName }}
{{- if .Values.authorization.enabled }}
    filters:
      - acl-authorization
{{- end }}
    targetCluster:
      bootstrapServers: {{ .Values.targetCluster.bootstrapServers }}
      tls:
        key:
          privateKeyFile: /certs/upstream/{{ .Values.targetCluster.tls.keyFile }}
          certificateFile: /certs/upstream/{{ .Values.targetCluster.tls.certFile }}
        trust:
          storeFile: {{ include "kroxylicious.caBundlePath" . }}
          storeType: PEM
    gateways:
      - name: gateway
        sniHostIdentifiesNode:
          bootstrapAddress: {{ .Values.gateway.bootstrapHost }}:{{ .Values.gateway.port }}
          advertisedBrokerAddressPattern: {{ .Values.gateway.brokerAddressPattern }}:{{ .Values.gateway.port }}
        tls:
          key:
            privateKeyFile: /certs/downstream/{{ .Values.gateway.tls.keyFile }}
            certificateFile: /certs/downstream/{{ .Values.gateway.tls.certFile }}
          trust:
            storeFile: {{ include "kroxylicious.caBundlePath" . }}
            storeType: PEM
{{- end }}
