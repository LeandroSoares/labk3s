# Outputs do Terraform

output "grafana_url" {
  description = "URL para acessar o Grafana"
  value       = module.observability.grafana_url
}

output "prometheus_url" {
  description = "URL para acessar o Prometheus"
  value       = module.observability.prometheus_url
}

output "namespace" {
  description = "Namespace onde os serviços foram instalados"
  value       = module.observability.namespace
}
