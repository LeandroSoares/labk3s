variable "namespace" {
  description = "Namespace para instalação do Tempo e OpenTelemetry"
  type        = string
  default     = "observability"
}

variable "use_existing_namespace" {
  description = "Usar um namespace existente em vez de criar um novo"
  type        = bool
  default     = true
}

variable "tempo_version" {
  description = "Versão do Helm chart do Tempo"
  type        = string
  default     = "1.7.1" # Verifique a versão mais recente no momento da implementação
}

variable "tempo_tag" {
  description = "Tag da imagem do Tempo"
  type        = string
  default     = "2.3.1" # Verifique a versão mais recente no momento da implementação
}

variable "opentelemetry_collector_version" {
  description = "Versão do Helm chart do OpenTelemetry Collector"
  type        = string
  default     = "0.71.1" # Verifique a versão mais recente no momento da implementação
}

variable "optimize_resources" {
  description = "Otimizar recursos para VPS com recursos limitados"
  type        = bool
  default     = false
}

variable "enable_span_logging" {
  description = "Habilitar o logging de spans recebidos"
  type        = bool
  default     = false
}

variable "storage_class_name" {
  description = "Nome da StorageClass para os volumes persistentes"
  type        = string
  default     = "local-path" # Usa a StorageClass padrão do K3s
}

variable "tempo_ingress_enabled" {
  description = "Habilitar ingress para o Tempo"
  type        = bool
  default     = true
}

variable "tempo_domain" {
  description = "Domínio para o ingress do Tempo"
  type        = string
  default     = "tempo.example.com"
}

variable "tempo_ingress_annotations" {
  description = "Anotações para o ingress do Tempo"
  type        = map(string)
  default     = {}
}

variable "cert_manager_issuer" {
  description = "Nome do ClusterIssuer do cert-manager para TLS"
  type        = string
  default     = "letsencrypt-prod"
}

variable "enable_tls" {
  description = "Habilitar TLS para o ingress"
  type        = bool
  default     = true
}

variable "grafana_datasource_name" {
  description = "Nome do datasource do Tempo no Grafana"
  type        = string
  default     = "Tempo"
}

variable "prometheus_datasource_uid" {
  description = "UID do datasource do Prometheus no Grafana para integração com o Tempo"
  type        = string
  default     = "prometheus"
}
