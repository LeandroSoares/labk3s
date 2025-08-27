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
resource "kubernetes_namespace" "agent_namespace" {
  count = var.use_existing_namespace ? 0 : 1
  
  metadata {
    name = var.namespace
  }
}

locals {
  namespace = var.use_existing_namespace ? var.namespace : kubernetes_namespace.agent_namespace[0].metadata[0].name
}

# Instalação do Grafana Agent via Helm
resource "helm_release" "grafana_agent" {
  name       = "grafana-agent"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana-agent"
  namespace  = local.namespace
  version    = var.agent_version
  
  values = [
    <<-EOT
    agent:
      mode: "static"
      enableReporting: false
      configMap:
        create: true
        content: |
          metrics:
            global:
              scrape_interval: 15s
              external_labels:
                cluster: k3s-lab
            wal_directory: /tmp/wal
            configs:
              - name: k3s-metrics
                remote_write:
                  - url: http://prom-stack-kube-prometheus-prometheus.${local.namespace}.svc.cluster.local:9090/api/v1/write
                    basic_auth:
                      username: prometheus
                      password: prometheus
                scrape_configs:
                  # Configuração para scrapear métricas do próprio agent
                  - job_name: grafana-agent
                    static_configs:
                      - targets: ['localhost:12345']
                  # Configuração para scrapear métricas da app
                  - job_name: joke-app
                    kubernetes_sd_configs:
                      - role: pod
                        namespaces:
                          names: ['joke-app']
                    relabel_configs:
                      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
                        action: keep
                        regex: true
                      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
                        action: replace
                        target_label: __metrics_path__
                        regex: (.+)
                      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
                        action: replace
                        regex: (.+):(?:\\d+);(\\d+)
                        replacement: $${1}:$${2}
                        target_label: __address__
                      - source_labels: [__meta_kubernetes_pod_name]
                        action: replace
                        target_label: pod

          logs:
            configs:
            - name: k3s-logs
              positions:
                filename: /tmp/positions.yaml
              clients:
                - url: http://prom-stack-grafana.${local.namespace}.svc.cluster.local:3100/loki/api/v1/push
              scrape_configs:
                - job_name: kubernetes-pods
                  kubernetes_sd_configs:
                    - role: pod
                  pipeline_stages:
                    - docker: {}
                    - cri: {}
                  relabel_configs:
                    - action: labelmap
                      regex: __meta_kubernetes_pod_label_(.+)
                    - source_labels:
                        - __meta_kubernetes_pod_name
                      target_label: pod
                    - source_labels:
                        - __meta_kubernetes_namespace
                      target_label: namespace
                    - source_labels:
                        - __meta_kubernetes_pod_container_name
                      target_label: container
                    - source_labels:
                        - __meta_kubernetes_pod_node_name
                      target_label: node

          traces:
            configs:
            - name: k3s-traces
              receivers:
                otlp:
                  protocols:
                    grpc:
                      endpoint: 0.0.0.0:4317
                    http:
                      endpoint: 0.0.0.0:4318
                jaeger:
                  protocols:
                    thrift_http:
                      endpoint: 0.0.0.0:14268
              remote_write:
                - endpoint: ${var.tempo_endpoint}
                  insecure: true
              service_graphs:
                enabled: true

    resources:
      limits:
        cpu: ${var.optimize_resources ? "500m" : "1000m"}
        memory: ${var.optimize_resources ? "256Mi" : "512Mi"}
      requests:
        cpu: ${var.optimize_resources ? "100m" : "200m"}
        memory: ${var.optimize_resources ? "128Mi" : "256Mi"}
    
    service:
      annotations: 
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: "12345"
      ports:
        - name: http-metrics
          port: 12345
          targetPort: 12345
        - name: otlp-grpc
          port: 4317
          targetPort: 4317
        - name: otlp-http
          port: 4318
          targetPort: 4318
        - name: jaeger-http
          port: 14268
          targetPort: 14268
    
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: prom-stack
    EOT
  ]
}
