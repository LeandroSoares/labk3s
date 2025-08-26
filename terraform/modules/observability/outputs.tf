output "grafana_url" {
  description = "URL para acessar o Grafana"
  value       = var.expose_grafana ? "http://<IP-do-nó>:${var.grafana_nodeport}" : "Acesse via port-forward: kubectl port-forward svc/prom-stack-grafana 3000:80 -n ${var.namespace}"
}

output "prometheus_url" {
  description = "URL para acessar o Prometheus"
  value       = "Acesse via port-forward: kubectl port-forward svc/prom-stack-kube-prometheus-prometheus 9090:9090 -n ${var.namespace}"
}

output "namespace" {
  description = "Namespace onde os serviços foram instalados"
  value       = kubernetes_namespace.observability.metadata[0].name
}

output "prometheus_stack_name" {
  description = "Nome do release Helm do Prometheus Stack"
  value       = helm_release.prometheus_stack.name
}
