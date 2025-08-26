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
  
  set {
    name  = "grafana.enabled"
    value = var.grafana_enabled
  }

  set {
    name  = "grafana.service.type"
    value = var.grafana_service_type
  }

  # Adicionar valores personalizados conforme necessidade
  dynamic "set" {
    for_each = var.prometheus_stack_values
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [kubernetes_namespace.observability]
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
