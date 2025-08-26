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

# Namespace para observabilidade
resource "kubernetes_namespace" "observability" {
  metadata {
    name = var.namespace
  }
}

# Instalação do Prometheus Stack via Helm
resource "helm_release" "prometheus_stack" {
  name       = "prom-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  version    = var.prometheus_stack_version
  
  # Configuração para recursos limitados (2 CPU cores, 8GB RAM)
  set = [
    {
      name  = "prometheus.prometheusSpec.resources.requests.cpu"
      value = var.optimize_resources ? "100m" : "300m"
    },
    {
      name  = "prometheus.prometheusSpec.resources.requests.memory"
      value = var.optimize_resources ? "512Mi" : "1Gi"
    },
    {
      name  = "prometheus.prometheusSpec.resources.limits.cpu"
      value = var.optimize_resources ? "200m" : "500m"
    },
    {
      name  = "prometheus.prometheusSpec.resources.limits.memory"
      value = var.optimize_resources ? "1Gi" : "2Gi"
    },
  
    # Configuração para retenção reduzida em ambientes com recursos limitados
    {
      name  = "prometheus.prometheusSpec.retention"
      value = var.optimize_resources ? "5d" : "15d"
    },
    {
      name  = "prometheus.prometheusSpec.retentionSize"
      value = var.optimize_resources ? "5GB" : "15GB"
    },
  
    # Configuração para o Grafana
    {
      name  = "grafana.replicas"
      value = tostring(var.grafana_replicas)
    },
    {
      name  = "grafana.resources.requests.cpu"
      value = var.optimize_resources ? "50m" : "100m"
    },
    {
      name  = "grafana.resources.requests.memory"
      value = var.optimize_resources ? "128Mi" : "256Mi"
    },
    {
      name  = "grafana.resources.limits.cpu"
      value = var.optimize_resources ? "100m" : "200m"
    },
    {
      name  = "grafana.resources.limits.memory"
      value = var.optimize_resources ? "256Mi" : "512Mi"
    },
  
    # Configuração para desativar componentes não essenciais
    {
      name  = "alertmanager.enabled"
      value = var.optimize_resources ? "false" : "true"
    },
    {
      name  = "grafana.enabled"
      value = var.grafana_enabled ? "true" : "false"
    },
    {
      name  = "grafana.service.type"
      value = var.grafana_service_type
    },
    
    # Configuração para acesso via Ingress
    {
      name  = "grafana.ingress.enabled"
      value = "true"
    },
    {
      name  = "grafana.ingress.hosts[0]"
      value = "grafana.labk3s.online"
    },
    {
      name  = "grafana.ingress.annotations.kubernetes\\.io/ingress\\.class"
      value = "traefik"
    },
    {
      name  = "grafana.ingress.annotations.cert-manager\\.io/cluster-issuer"
      value = "letsencrypt-prod"
    },
    {
      name  = "grafana.ingress.tls[0].hosts[0]"
      value = "grafana.labk3s.online"
    },
    {
      name  = "grafana.ingress.tls[0].secretName"
      value = "grafana-tls"
    }
  ]

  # Valores para o Grafana - Senha do Admin e configuração de dashboards
  values = [
    <<-EOT
    grafana:
      adminPassword: "${var.prometheus_stack_values["grafana.adminPassword"]}"
      dashboardProviders:
        dashboardproviders.yaml:
          apiVersion: 1
          providers:
            - name: 'k3s-dashboards'
              orgId: 1
              folder: 'K3s'
              type: file
              disableDeletion: false
              editable: true
              options:
                path: /var/lib/grafana/dashboards/k3s
      dashboards:
        k3s:
          k3s-cluster-dashboard:
            file: dashboards/k3s-cluster-dashboard.json
      dashboardsConfigMaps:
        k3s: ${kubernetes_config_map.grafana_dashboards.metadata[0].name}
    EOT
  ]

  depends_on = [kubernetes_namespace.observability, kubernetes_config_map.grafana_dashboards]
}

# Configuração para expor o Grafana (se NodePort ou LoadBalancer for usado)
resource "kubernetes_service" "grafana_nodeport" {
  count = var.grafana_service_type == "ClusterIP" && var.expose_grafana ? 1 : 0

  metadata {
    name      = "grafana-external"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "grafana"
      "app.kubernetes.io/instance" = "prom-stack"
    }
    
    port {
      port        = 80
      target_port = 3000
      node_port   = var.grafana_nodeport
    }

    type = "NodePort"
  }

  depends_on = [helm_release.prometheus_stack]
}

# ConfigMap para armazenar os dashboards do Grafana
resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-k3s-dashboards"
    namespace = kubernetes_namespace.observability.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "k3s-cluster-dashboard.json" = file("${path.root}/../grafana-dashboards/k3s-cluster-dashboard.json")
  }

  depends_on = [kubernetes_namespace.observability]
}
