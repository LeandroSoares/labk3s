output "agent_service_name" {
  description = "Nome do serviço do Grafana Agent"
  value       = "grafana-agent"
}

output "agent_service_endpoint_otlp_http" {
  description = "Endpoint OTLP HTTP do Grafana Agent"
  value       = "http://grafana-agent.${var.namespace}.svc.cluster.local:4318"
}

output "agent_service_endpoint_otlp_grpc" {
  description = "Endpoint OTLP gRPC do Grafana Agent"
  value       = "grafana-agent.${var.namespace}.svc.cluster.local:4317"
}

output "agent_service_endpoint_jaeger" {
  description = "Endpoint Jaeger HTTP do Grafana Agent"
  value       = "http://grafana-agent.${var.namespace}.svc.cluster.local:14268/api/traces"
}
