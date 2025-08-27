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

  # Valores personalizados para o Prometheus Stack
  prometheus_stack_values = {
    "grafana.adminPassword" = var.grafana_admin_password
  }
}

# Módulo de tracing com Grafana Tempo e OpenTelemetry
module "tempo" {
  source = "./modules/tempo"
  count  = var.tempo_enabled ? 1 : 0

  namespace                     = var.namespace
  use_existing_namespace        = true  # Usar o namespace criado pelo módulo de observabilidade
  tempo_version                 = var.tempo_version
  opentelemetry_collector_version = var.opentelemetry_collector_version
  optimize_resources            = var.optimize_resources
  enable_span_logging           = var.enable_span_logging
  tempo_domain                  = var.tempo_domain
  
  # Usar o ClusterIssuer configurado pelo cert-manager
  cert_manager_issuer           = "letsencrypt-prod"
  
  # Integração com Prometheus
  prometheus_datasource_uid     = "prometheus"
}

# Módulo do Grafana Agent para coleta unificada de métricas, logs e traces
module "grafana_agent" {
  source = "./modules/grafana-agent"
  count  = var.grafana_agent_enabled ? 1 : 0

  namespace                = var.namespace
  use_existing_namespace   = true  # Usar o namespace criado pelo módulo de observabilidade
  agent_version            = var.grafana_agent_version
  log_level                = var.grafana_agent_log_level
  optimize_resources       = var.optimize_resources
  loki_enabled             = false # Será habilitado quando implementarmos o Loki
  tempo_endpoint           = "tempo:4317"  # Endpoint do serviço Tempo dentro do cluster
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

    rule {
      host = var.tempo_enabled ? var.tempo_domain : ""
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "tempo"
              port {
                number = 3200
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = concat(
        ["grafana.labk3s.online", "prometheus.labk3s.online", "alertmanager.labk3s.online"],
        var.tempo_enabled ? [var.tempo_domain] : []
      )
      secret_name = "observability-tls"
    }
  }
}

# Adicionar o ClusterIssuer para Let's Encrypt
resource "kubernetes_manifest" "letsencrypt_cluster_issuer" {
  # Dependência do módulo cert-manager para garantir que este seja instalado primeiro
  depends_on = [module.cert_manager]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email  # Usar a variável já definida
        privateKeySecretRef = {
          name = "letsencrypt-prod-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "traefik"
              }
            }
          }
        ]
      }
    }
  }
}
