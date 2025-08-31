package main

import (
	"context"
	"os"
	"time"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
)

var (
	// Meter global
	meter metric.Meter

	// Métricas específicas
	httpRequestsTotal    metric.Int64Counter
	httpRequestDuration  metric.Float64Histogram
	databaseQueriesTotal metric.Int64Counter
	activeRequests       metric.Int64UpDownCounter
	jokesCount           metric.Int64Counter
)

// initMeter configura o OpenTelemetry Metrics
func initMeter() (*sdkmetric.MeterProvider, error) {
	// Verificar se as métricas estão desativadas para desenvolvimento local
	if os.Getenv("DISABLE_METRICS") == "true" {
		// Criar um provider vazio para evitar erros
		mp := sdkmetric.NewMeterProvider()
		meter = mp.Meter("joke-api")
		
		// Inicializar métricas vazias (noop)
		httpRequestsTotal, _ = meter.Int64Counter("http.requests.total")
		httpRequestDuration, _ = meter.Float64Histogram("http.request.duration")
		databaseQueriesTotal, _ = meter.Int64Counter("database.queries.total")
		activeRequests, _ = meter.Int64UpDownCounter("http.active_requests")
		jokesCount, _ = meter.Int64Counter("jokes.count")
		
		return mp, nil
	}

	endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	if endpoint == "" {
		endpoint = "grafana-agent:4318" // Removido o prefixo http:// pois ele é adicionado automaticamente
	}

	exporter, err := otlpmetrichttp.New(
		context.Background(),
		otlpmetrichttp.WithEndpoint(endpoint),
		otlpmetrichttp.WithURLPath("/v1/metrics"),
		otlpmetrichttp.WithInsecure(),
	)
	if err != nil {
		return nil, err
	}

	// Criar resource com informações do serviço
	serviceName := os.Getenv("OTEL_SERVICE_NAME")
	if serviceName == "" {
		serviceName = "joke-api-go"
	}

	r := resource.NewWithAttributes(
		semconv.SchemaURL,
		semconv.ServiceNameKey.String(serviceName),
		semconv.ServiceVersionKey.String("1.0.0"),
		attribute.String("environment", os.Getenv("GO_ENV")),
	)

	// Criar e configurar o provider
	mp := sdkmetric.NewMeterProvider(
		sdkmetric.WithReader(sdkmetric.NewPeriodicReader(exporter, sdkmetric.WithInterval(15*time.Second))),
		sdkmetric.WithResource(r),
	)

	// Configurar o meter
	meter = mp.Meter("joke-api")

	// Inicializar métricas
	var err1, err2, err3, err4, err5 error

	httpRequestsTotal, err1 = meter.Int64Counter(
		"http.requests.total",
		metric.WithDescription("Total number of HTTP requests"),
		metric.WithUnit("{request}"),
	)

	httpRequestDuration, err2 = meter.Float64Histogram(
		"http.request.duration",
		metric.WithDescription("HTTP request duration in milliseconds"),
		metric.WithUnit("ms"),
	)

	databaseQueriesTotal, err3 = meter.Int64Counter(
		"database.queries.total",
		metric.WithDescription("Total number of database queries"),
		metric.WithUnit("{query}"),
	)

	activeRequests, err4 = meter.Int64UpDownCounter(
		"http.requests.active",
		metric.WithDescription("Number of in-flight requests"),
		metric.WithUnit("{request}"),
	)

	jokesCount, err5 = meter.Int64Counter(
		"jokes.count",
		metric.WithDescription("Number of jokes served"),
		metric.WithUnit("{joke}"),
	)

	// Verificar erros
	for _, err := range []error{err1, err2, err3, err4, err5} {
		if err != nil {
			return nil, err
		}
	}

	return mp, nil
}

// RecordRequestStart registra o início de uma requisição HTTP
func RecordRequestStart(endpoint string) {
	if activeRequests != nil {
		activeRequests.Add(context.Background(), 1, metric.WithAttributes(
			attribute.String("endpoint", endpoint),
		))
	}
}

// RecordRequestEnd registra o fim de uma requisição HTTP
func RecordRequestEnd(endpoint string, method string, statusCode int, durationMs float64) {
	ctx := context.Background()
	
	if activeRequests != nil {
		activeRequests.Add(ctx, -1, metric.WithAttributes(
			attribute.String("endpoint", endpoint),
		))
	}
	
	if httpRequestsTotal != nil {
		httpRequestsTotal.Add(ctx, 1, metric.WithAttributes(
			attribute.String("endpoint", endpoint),
			attribute.String("method", method),
			attribute.Int("status", statusCode),
		))
	}
	
	if httpRequestDuration != nil {
		httpRequestDuration.Record(ctx, durationMs, metric.WithAttributes(
			attribute.String("endpoint", endpoint),
			attribute.String("method", method),
			attribute.Int("status", statusCode),
		))
	}
}

// RecordDatabaseQuery registra uma consulta ao banco de dados
func RecordDatabaseQuery(operation string, table string, success bool) {
	if databaseQueriesTotal != nil {
		databaseQueriesTotal.Add(context.Background(), 1, metric.WithAttributes(
			attribute.String("operation", operation),
			attribute.String("table", table),
			attribute.Bool("success", success),
		))
	}
}

// RecordJokeServed registra que uma piada foi servida
func RecordJokeServed(endpoint string, jokeId int64) {
	if jokesCount != nil {
		jokesCount.Add(context.Background(), 1, metric.WithAttributes(
			attribute.String("endpoint", endpoint),
			attribute.Int64("joke_id", jokeId),
		))
	}
}
