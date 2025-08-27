output "tempo_query_endpoint" {
  description = "Endpoint do serviço de consulta do Tempo"
  value       = "http://tempo-tempo-query-frontend.${var.namespace}.svc.cluster.local:3100"
}

output "tempo_distributor_endpoint" {
  description = "Endpoint do serviço distributor do Tempo (para envio de telemetria)"
  value       = "tempo-tempo-distributor.${var.namespace}.svc.cluster.local:4317"
}

output "opentelemetry_collector_endpoint" {
  description = "Endpoint do coletor OpenTelemetry"
  value       = "http://otel-collector-opentelemetry-collector.${var.namespace}.svc.cluster.local:4318"
}

output "opentelemetry_collector_grpc_endpoint" {
  description = "Endpoint gRPC do coletor OpenTelemetry"
  value       = "otel-collector-opentelemetry-collector.${var.namespace}.svc.cluster.local:4317"
}
