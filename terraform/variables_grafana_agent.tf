# Variáveis para o módulo Grafana Agent
variable "grafana_agent_enabled" {
  description = "Habilitar ou desabilitar a instalação do Grafana Agent"
  type        = bool
  default     = true  # Alterado para true para habilitar por padrão
}

variable "grafana_agent_version" {
  description = "Versão do Helm chart do Grafana Agent"
  type        = string
  default     = "0.44.2"  # Atualizado para a versão mais recente disponível
}

variable "grafana_agent_log_level" {
  description = "Nível de log do Grafana Agent"
  type        = string
  default     = "info"
}
