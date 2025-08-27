variable "kube_config_content" {
  description = "Conteúdo do arquivo kubeconfig para conexão ao cluster K3s"
  type        = string
  default     = ""
  sensitive   = true
}

variable "kube_config_context" {
  description = "Contexto a ser usado no arquivo kubeconfig"
  type        = string
  default     = ""
}
