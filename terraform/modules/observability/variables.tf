variable "namespace" {
  description = "Namespace para os serviços de observabilidade"
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

variable "grafana_replicas" {
  description = "Número de réplicas para o Grafana"
  type        = number
  default     = 1
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

variable "prometheus_stack_values" {
  description = "Valores personalizados para o Helm chart kube-prometheus-stack"
  type        = map(string)
  default     = {}
}

variable "optimize_resources" {
  description = "Otimizar recursos para VPS com recursos limitados (2 cores, 8GB RAM)"
  type        = bool
  default     = false
}
