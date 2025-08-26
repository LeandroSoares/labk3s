output "cert_manager_namespace" {
  description = "Namespace onde o cert-manager está instalado"
  value       = kubernetes_namespace.cert_manager.metadata[0].name
}

output "cluster_issuer_name" {
  description = "Nome do ClusterIssuer criado"
  value       = "letsencrypt-prod"
}

output "cluster_issuer_instructions" {
  description = "Instruções para aplicar o ClusterIssuer manualmente"
  value       = "Execute o comando: kubectl apply -f ${path.module}/cluster-issuer.yaml"
}
