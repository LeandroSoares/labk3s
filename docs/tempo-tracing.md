# Módulo de Tracing com Grafana Tempo e OpenTelemetry

Este módulo implementa um sistema completo de tracing distribuído utilizando Grafana Tempo como backend e OpenTelemetry como coletor de telemetria.

## Componentes

1. **Grafana Tempo**: Sistema de armazenamento e visualização de traces
2. **OpenTelemetry Collector**: Receptor e processador de dados de telemetria
3. **Integração com Grafana**: Datasource configurado automaticamente

## Arquitetura

```
Aplicações (instrumentadas com OpenTelemetry) 
       ↓
OpenTelemetry Collector
       ↓
Grafana Tempo
       ↓
Visualização no Grafana
```

## Recursos do módulo

### Instalados via Terraform

- Grafana Tempo (backend de tracing)
- OpenTelemetry Collector (coletor de telemetria)
- Configuração de datasource no Grafana

### Requisitos

- Cluster Kubernetes/K3s em execução
- Helm 3.x
- Grafana (instalado pelo módulo `observability`)

## Utilização

1. **Ativar o módulo**: Configure `tempo_enabled = true` em `terraform.auto.tfvars`
2. **Aplicar a configuração**: Execute `terraform apply`
3. **Instrumentar aplicações**: Utilize as bibliotecas OpenTelemetry para seus serviços

## Instrumentação de aplicações

### Node.js

```javascript
// Instale as dependências:
// npm install @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node @opentelemetry/exporter-trace-otlp-http

// tracing.js
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'http://otel-collector-opentelemetry-collector.observability.svc.cluster.local:4318/v1/traces'
  }),
  instrumentations: [getNodeAutoInstrumentations()]
});

sdk.start();
```

### Frontend (JavaScript)

```javascript
// Instale via CDN ou npm:
// <script src="https://unpkg.com/@opentelemetry/web@0.24.0/dist/opentelemetry-web.js"></script>

// Configure OpenTelemetry
const { WebTracerProvider } = OpenTelemetry.web;
const { SimpleSpanProcessor } = OpenTelemetry.tracing;
const { CollectorTraceExporter } = OpenTelemetry.exporter;

const provider = new WebTracerProvider();
const exporter = new CollectorTraceExporter({
  url: '/opentelemetry/v1/traces'
});

provider.addSpanProcessor(new SimpleSpanProcessor(exporter));
provider.register();

const tracer = provider.getTracer('frontend-tracer');
```

## Acesso

- Interface do Tempo: https://tempo.labk3s.online
- Visualização de traces no Grafana: https://grafana.labk3s.online/explore

## Configuração avançada

Consulte o arquivo `variables.tf` no módulo `tempo` para conhecer todas as opções de configuração disponíveis.
