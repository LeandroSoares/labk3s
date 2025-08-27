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
      mode: "flow"
      enableReporting: false
      configMap:
        create: true
        content: |
          logging {
            level = "${var.log_level}"
          }

          prometheus.remote_write "default" {
            endpoint {
              url = "http://prom-stack-kube-prometheus-prometheus.${local.namespace}.svc.cluster.local:9090/api/v1/write"
              
              basic_auth {
                username = "prometheus"
                password = "prometheus"
              }
            }
          }

          prometheus.scrape "agent" {
            targets = [{
              __address__ = "localhost:12345",
            }]
            forward_to = [prometheus.remote_write.default.receiver]
          }

          # Scrape configurado para pods no namespace joke-app
          prometheus.scrape "joke-app" {
            kubernetes_sd {
              role = "pod"
              namespaces {
                names = ["joke-app"]
              }
            }
            
            relabel {
              source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
              regex = "true"
              action = "keep"
            }
            
            relabel {
              source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
              regex = "(.+)"
              target_label = "__metrics_path__"
              action = "replace"
            }
            
            relabel {
              source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
              regex = "(.+):(?:\\d+);(\\d+)"
              replacement = "$${1}:$${2}"
              target_label = "__address__"
              action = "replace"
            }
            
            relabel {
              source_labels = ["__meta_kubernetes_pod_name"]
              target_label = "pod"
              action = "replace"
            }
            
            forward_to = [prometheus.remote_write.default.receiver]
          }

          loki.source.kubernetes "pod_logs" {
            targets = kubernetes.pod_logs.targets
            forward_to = [loki.write.default.receiver]
          }

          loki.write "default" {
            endpoint {
              url = "${var.loki_enabled ? "http://loki-gateway.${local.namespace}.svc.cluster.local:80/loki/api/v1/push" : "http://prom-stack-grafana.${local.namespace}.svc.cluster.local:3100/loki/api/v1/push"}"
            }
          }

          kubernetes.pod_logs "targets" {
            ${var.optimize_resources ? "sync_period = \"30s\"" : "sync_period = \"10s\""}
          }

          otelcol.receiver.otlp "receiver" {
            grpc {
              endpoint = "0.0.0.0:4317"
            }
            http {
              endpoint = "0.0.0.0:4318"
            }
            output {
              traces = [otelcol.processor.batch.default.input]
            }
          }

          otelcol.processor.batch "default" {
            timeout = "5s"
            send_batch_size = ${var.optimize_resources ? "100" : "1000"}
            output {
              traces = [otelcol.exporter.otlp.tempo.input]
            }
          }

          otelcol.exporter.otlp "tempo" {
            endpoint = "${var.tempo_endpoint}"
            tls {
              insecure = true
            }
          }

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
