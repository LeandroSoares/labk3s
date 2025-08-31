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

### Go

```go
// Instale as dependências:
// go get go.opentelemetry.io/otel go.opentelemetry.io/otel/sdk go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp

package main

import (
	"context"
	"log"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
)

func initTracer() func() {
	exporter, err := otlptracehttp.New(context.Background(),
		otlptracehttp.WithEndpoint("otel-collector-opentelemetry-collector.observability.svc.cluster.local:4318"),
		otlptracehttp.WithURLPath("/v1/traces"),
		otlptracehttp.WithInsecure(),
	)
	if err != nil {
		log.Fatalf("Failed to create exporter: %v", err)
	}

	resources := resource.NewWithAttributes(
		semconv.SchemaURL,
		semconv.ServiceNameKey.String("joke-api"),
		semconv.ServiceVersionKey.String("1.0.0"),
	)

	provider := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(resources),
	)
	otel.SetTracerProvider(provider)

	return func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := provider.Shutdown(ctx); err != nil {
			log.Fatalf("Failed to shutdown provider: %v", err)
		}
	}
}
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
