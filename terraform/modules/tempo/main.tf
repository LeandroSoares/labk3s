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

# Referência ao namespace de observabilidade existente ou criação de um novo
resource "kubernetes_namespace" "tempo_namespace" {
  count = var.use_existing_namespace ? 0 : 1
  
  metadata {
    name = var.namespace
  }
}

locals {
  namespace = var.use_existing_namespace ? var.namespace : kubernetes_namespace.tempo_namespace[0].metadata[0].name
}

# Instalação do Tempo via Helm
resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  namespace  = local.namespace
  version    = var.tempo_version
  
  values = [
    <<-EOT
    tempo:
      multitenancyEnabled: false
      repository: grafana/tempo
      tag: ${var.tempo_tag}
      
      global_overrides:
        per_tenant_override_config: /conf/overrides.yaml
      
      storage:
        trace:
          backend: local
          local:
            path: /var/tempo/traces
      
      resources:
        limits:
          cpu: ${var.optimize_resources ? "200m" : "500m"}
          memory: ${var.optimize_resources ? "512Mi" : "1Gi"}
        requests:
          cpu: ${var.optimize_resources ? "100m" : "200m"}
          memory: ${var.optimize_resources ? "256Mi" : "512Mi"}
      
      # Configuração de retenção de acordo com os recursos disponíveis
      retention: ${var.optimize_resources ? "24h" : "7d"}
    
    distributor:
      config:
        log_received_spans:
          enabled: ${var.enable_span_logging}
          include_all_attributes: false
          filter_by_status_error: true
    
    querier:
      config:
        max_concurrent_queries: ${var.optimize_resources ? 5 : 10}
    
    ingester:
      max_block_duration: ${var.optimize_resources ? "10m" : "15m"}
      max_block_bytes: ${var.optimize_resources ? 104857600 : 209715200} # 100MB ou 200MB
      resources:
        limits:
          cpu: ${var.optimize_resources ? "200m" : "500m"}
          memory: ${var.optimize_resources ? "512Mi" : "1Gi"}
        requests:
          cpu: ${var.optimize_resources ? "100m" : "200m"}
          memory: ${var.optimize_resources ? "256Mi" : "512Mi"}
    
    compactor:
      compaction:
        block_retention: ${var.optimize_resources ? "24h" : "7d"}
      resources:
        limits:
          cpu: ${var.optimize_resources ? "100m" : "200m"}
          memory: ${var.optimize_resources ? "256Mi" : "512Mi"}
        requests:
          cpu: ${var.optimize_resources ? "50m" : "100m"}
          memory: ${var.optimize_resources ? "128Mi" : "256Mi"}
    
    metricsGenerator:
      enabled: true
      config:
        processor:
          service_graphs:
            enabled: true
            dimensions: ['service.name', 'span.kind']
    
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: prom-stack
    
    persistence:
      enabled: true
      size: ${var.optimize_resources ? "5Gi" : "10Gi"}
      storageClass: ${var.storage_class_name}
    EOT
  ]

  depends_on = [
    kubernetes_namespace.tempo_namespace
  ]
}

# Configuração para integrar o Tempo com o Grafana existente
resource "kubernetes_config_map" "tempo_grafana_datasource" {
  metadata {
    name      = "tempo-grafana-datasource"
    namespace = local.namespace
    labels = {
      grafana_datasource = "1"
    }
  }

  data = {
    "tempo-datasource.yaml" = <<-EOT
      apiVersion: 1
      datasources:
      - name: Tempo
        type: tempo
        access: proxy
        orgId: 1
        url: http://tempo-tempo-query-frontend:3100
        basicAuth: false
        isDefault: false
        version: 1
        editable: true
        uid: tempo
        jsonData:
          httpMethod: GET
          serviceMap:
            datasourceUid: ${var.prometheus_datasource_uid}
    EOT
  }

  depends_on = [
    kubernetes_namespace.tempo_namespace
  ]
}
