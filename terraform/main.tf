# Configurar o provider Kubernetes
provider "kubernetes" {
  # O caminho para o arquivo kubeconfig
  config_path = var.kube_config_path
}

# Configurar o provider Helm
provider "helm" {
  kubernetes = {
    config_path = var.kube_config_path
  }
}

# Módulo para cert-manager e Let's Encrypt
module "cert_manager" {
  source = "./modules/cert-manager"

  cert_manager_version = var.cert_manager_version
  email                = var.letsencrypt_email
  domain_name          = var.domain_name
}

# Módulo de observabilidade com Prometheus e Grafana
module "observability" {
  source = "./modules/observability"

  namespace                = var.namespace
  prometheus_stack_version = var.prometheus_stack_version
  grafana_enabled          = var.grafana_enabled
  grafana_replicas         = var.grafana_replicas
  grafana_service_type     = var.grafana_service_type
  expose_grafana           = var.expose_grafana
  grafana_nodeport         = var.grafana_nodeport
  optimize_resources       = var.optimize_resources
  alertmanager_enabled     = var.alertmanager_enabled

  # Dashboards do Grafana para provisionar
  grafana_dashboards = {
    "k3s-cluster-dashboard.json" = file("${path.module}/grafana-dashboards/k3s-cluster-dashboard.json"),
    "alertmanager-status.json"   = file("${path.module}/grafana-dashboards/alertmanager-status.json")
  }

  # Valores personalizados para o Prometheus Stack
  prometheus_stack_values = {
    "grafana.adminPassword" = var.grafana_admin_password
  }
}

# Configurar Ingress para os serviços de observabilidade
resource "kubernetes_ingress_v1" "observability_ingress" {
  count = var.create_ingress ? 1 : 0

  metadata {
    name      = "observability-ingress"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class"    = "traefik"
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
  }

  spec {
    rule {
      host = "grafana.labk3s.online"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "prom-stack-grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {
      host = "prometheus.labk3s.online"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "prom-stack-kube-prometheus-prometheus"
              port {
                number = 9090
              }
            }
          }
        }
      }
    }

    rule {
      host = "alertmanager.labk3s.online"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "prom-stack-kube-prometheus-alertmanager"
              port {
                number = 9093
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = ["grafana.labk3s.online", "prometheus.labk3s.online", "alertmanager.labk3s.online"]
      secret_name = "observability-tls"
    }
  }
}
