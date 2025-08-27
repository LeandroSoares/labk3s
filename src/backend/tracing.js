// tracing.js - Configuração do OpenTelemetry
const opentelemetry = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

// Configuração do exportador de traces
const exporter = new OTLPTraceExporter({
  url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://grafana-agent.observability.svc.cluster.local:4318/v1/traces',
});

// Configuração do SDK do OpenTelemetry
const sdk = new opentelemetry.NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'joke-api',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV || 'development',
  }),
  traceExporter: exporter,
  instrumentations: [
    getNodeAutoInstrumentations({
      // Habilitar instrumentação específica do Express
      '@opentelemetry/instrumentation-express': {
        enabled: true,
      },
      // Habilitar instrumentação HTTP
      '@opentelemetry/instrumentation-http': {
        enabled: true,
      },
      // Desabilitar instrumentações desnecessárias
      '@opentelemetry/instrumentation-grpc': {
        enabled: false,
      },
    }),
  ],
});

// Função para inicializar o tracing
function initTracing() {
  try {
    sdk.start();
    console.log('OpenTelemetry initialized');
    
    // Garantir que o SDK é desligado corretamente na saída do processo
    process.on('SIGTERM', () => {
      sdk.shutdown()
        .then(() => console.log('OpenTelemetry SDK shut down'))
        .catch((error) => console.error('Error shutting down OpenTelemetry SDK', error))
        .finally(() => process.exit(0));
    });
    
    return true;
  } catch (error) {
    console.error('Error initializing OpenTelemetry', error);
    return false;
  }
}

module.exports = { initTracing };
