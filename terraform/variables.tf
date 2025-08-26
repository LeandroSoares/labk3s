# Variáveis para customização do projeto

variable "kube_config_path" {
  description = "Caminho para o arquivo kubeconfig"
  type        = string
  default     = "~/.kube/config"
}

variable "namespace" {
  description = "Namespace para os serviços"
  type        = string
  default     = "observability"
}

variable "prometheus_stack_version" {
  description = "Versão do Helm chart kube-prometheus-stack"
  type        = string
  default     = "45.27.2"  # Substitua pela versão mais recente
}

variable "grafana_enabled" {
  description = "Habilitar ou desabilitar a instalação do Grafana junto com o Prometheus Stack"
  type        = bool
  default     = true
}

variable "grafana_service_type" {
  description = "Tipo de serviço para o Grafana (ClusterIP, NodePort, LoadBalancer)"
  type        = string
  default     = "ClusterIP"
}

variable "expose_grafana" {
  description = "Expor o Grafana através de um serviço NodePort adicional"
  type        = bool
  default     = true
}

variable "grafana_nodeport" {
  description = "Porta NodePort para expor o Grafana (se expose_grafana=true)"
  type        = number
  default     = 30080
}

variable "grafana_admin_password" {
  description = "Senha de administrador para o Grafana"
  type        = string
  default     = "admin"  # Altere para uma senha segura ou use variáveis de ambiente
  sensitive   = true
}
