variable "namespace" {
  description = "Namespace para instalação do Grafana Agent"
  type        = string
  default     = "observability"
}

variable "use_existing_namespace" {
  description = "Usar um namespace existente em vez de criar um novo"
  type        = bool
  default     = true
}

variable "agent_version" {
  description = "Versão do Helm chart do Grafana Agent"
  type        = string
  default     = "0.44.2"  # Atualizado para a versão mais recente disponível
}

variable "log_level" {
  description = "Nível de log do Grafana Agent"
  type        = string
  default     = "info"
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "O nível de log deve ser um dos seguintes: debug, info, warn, error."
  }
}

variable "optimize_resources" {
  description = "Otimizar recursos para VPS com recursos limitados"
  type        = bool
  default     = false
}

variable "loki_enabled" {
  description = "Se o Loki está habilitado para enviar logs"
  type        = bool
  default     = false
}

variable "tempo_endpoint" {
  description = "Endpoint do Tempo para envio de traces"
  type        = string
  default     = "tempo:4317"
}
