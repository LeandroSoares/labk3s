# Variáveis para o módulo Grafana Agent
variable "grafana_agent_enabled" {
  description = "Habilitar ou desabilitar a instalação do Grafana Agent"
  type        = bool
  default     = false
}

variable "grafana_agent_version" {
  description = "Versão do Helm chart do Grafana Agent"
  type        = string
  default     = "0.25.1"
}

variable "grafana_agent_log_level" {
  description = "Nível de log do Grafana Agent"
  type        = string
  default     = "info"
}
