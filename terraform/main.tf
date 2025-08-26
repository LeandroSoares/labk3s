terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.0.0"
    }
  }
}

provider "kubernetes" {
  config_path = var.kube_config_path
}

provider "helm" {
  kubernetes {
    config_path = var.kube_config_path
  }
}

# Módulo de observabilidade com Prometheus e Grafana
module "observability" {
  source = "./modules/observability"
  
  namespace              = var.namespace
  prometheus_stack_version = var.prometheus_stack_version
  grafana_enabled        = var.grafana_enabled
  grafana_service_type   = var.grafana_service_type
  expose_grafana         = var.expose_grafana
  grafana_nodeport       = var.grafana_nodeport
  
  # Valores personalizados para o Prometheus Stack
  prometheus_stack_values = {
    "grafana.adminPassword" = var.grafana_admin_password
  }
}

# Exemplo de aplicação para testar a observabilidade
resource "kubernetes_deployment" "sample_app" {
  metadata {
    name      = "sample-app"
    namespace = var.namespace
    labels = {
      app = "sample-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "sample-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "sample-app"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/metrics"
          "prometheus.io/port"   = "8080"
        }
      }

      spec {
        container {
          image = "prom/prometheus:v2.40.0"
          name  = "sample-app"

          port {
            container_port = 8080
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [module.observability]
}

resource "kubernetes_service" "sample_app" {
  metadata {
    name      = "sample-app"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.sample_app.metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 8080
    }
  }
}
