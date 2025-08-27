# Variáveis para o módulo de tracing com Tempo
variable "tempo_enabled" {
  description = "Habilitar ou desabilitar a instalação do Grafana Tempo"
  type        = bool
  default     = false
}

variable "tempo_version" {
  description = "Versão do Helm chart do Tempo"
  type        = string
  default     = "1.7.1"
}

variable "tempo_domain" {
  description = "Domínio para acesso ao Tempo"
  type        = string
  default     = "tempo.labk3s.online"
}

variable "enable_span_logging" {
  description = "Habilitar o logging de spans recebidos"
  type        = bool
  default     = false
}

variable "tempo_storage_size" {
  description = "Tamanho do volume persistente para o Tempo"
  type        = string
  default     = "5Gi"
}

variable "tempo_retention" {
  description = "Período de retenção de traces"
  type        = string
  default     = "24h"
}
