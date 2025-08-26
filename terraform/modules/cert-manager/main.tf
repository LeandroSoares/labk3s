terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.0.0"
    }
  }
}

# Namespace para cert-manager
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# Instalação do cert-manager via Helm
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  version    = var.cert_manager_version

  # Habilitar CRDs e configurar recursos
  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "resources.requests.cpu"
      value = "50m"
    },
    {
      name  = "resources.requests.memory"
      value = "64Mi"
    },
    {
      name  = "resources.limits.cpu"
      value = "100m"
    },
    {
      name  = "resources.limits.memory"
      value = "128Mi"
    }
  ]
}

# Comentando o ClusterIssuer direto para evitar erros de CRD
# resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
#   manifest = {
#     apiVersion = "cert-manager.io/v1"
#     kind       = "ClusterIssuer"
#     metadata = {
#       name = "letsencrypt-prod"
#     }
#     spec = {
#       acme = {
#         server = "https://acme-v02.api.letsencrypt.org/directory"
#         email  = var.email
#         privateKeySecretRef = {
#           name = "letsencrypt-prod-key"
#         }
#         solvers = [
#           {
#             http01 = {
#               ingress = {
#                 class = "traefik"
#               }
#             }
#           }
#         ]
#       }
#     }
#   }
#   
#   # Dependência do cert-manager estar instalado
#   depends_on = [helm_release.cert_manager]
# }

# Em vez disso, gere um arquivo YAML que pode ser aplicado manualmente
resource "local_file" "cluster_issuer" {
  content = <<-EOT
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${var.email}
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          class: traefik
EOT
  filename = "${path.module}/cluster-issuer.yaml"
  
  depends_on = [helm_release.cert_manager]
}
