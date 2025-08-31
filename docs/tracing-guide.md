# Guia de Tracing com Grafana Tempo e Grafana Agent

Este guia descreve a implementação de tracing distribuído no projeto LaboratorioK3s usando Grafana Tempo e Grafana Agent.

## Componentes de Tracing

A solução de tracing implementada consiste em:

1. **Grafana Tempo**: Backend para armazenamento e consulta de traces
2. **Grafana Agent**: Coletor unificado para métricas, logs e traces (substituiu o OpenTelemetry Collector)
3. **OpenTelemetry**: Instrumentação do frontend e backend da aplicação

## Arquitetura

```
Backend (Go + OpenTelemetry) ────┐
                                 │
                                 ▼
Frontend (JS + OpenTelemetry) ────► Grafana Agent ────► Grafana Tempo ────► Visualização no Grafana
```

## Acesso ao Tracing

- **Dashboard do Grafana**: https://grafana.labk3s.online/d/tempo-traces-dashboard
- **Explorador do Grafana**: https://grafana.labk3s.online/explore?left=%7B%22datasource%22:%22tempo%22%7D
- **Interface do Tempo**: https://tempo.labk3s.online

## Implementação

A implementação de tracing está integrada diretamente nos manifestos da aplicação:

```
k8s/
  app/
    backend-go.yaml       # Configurado com variáveis para Grafana Agent
    frontend.yaml         # Configurado com ConfigMap para Nginx
    network-policies.yaml # Inclui políticas para comunicação com Grafana Agent
```

Para aplicar a configuração:

```bash
kubectl apply -k k8s/app
```

## Instrumentação das Aplicações

### Backend (Go)

O backend em Go está instrumentado com OpenTelemetry. O framework Gin e chamadas HTTP são automaticamente rastreados.

Exemplo de uso para criar spans personalizados em Go:

```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/trace"
    "context"
)

// Obtenha um tracer
tracer := otel.Tracer("joke-api")

// Criar um span personalizado
ctx, span := tracer.Start(context.Background(), "operacao-personalizada")
defer span.End()

// Adicionar atributos ao span
span.SetAttributes(attribute.String("chave", "valor"))
```
const span = tracer.startSpan('operacao-personalizada');
try {
  // Lógica da operação
  span.setAttributes({
    'custom.attribute': 'valor'
  });
} catch (error) {
  span.recordException(error);
  span.setStatus({ code: SpanStatusCode.ERROR });
  throw error;
} finally {
  span.end();
}
```

### Frontend (JavaScript)

O frontend usa uma implementação simplificada em `src/frontend/telemetry.js` que envia dados para o Grafana Agent.

## Benefícios do Grafana Agent

- **Binário único** para coleta de métricas, logs e traces
- **Baixo consumo de recursos** em comparação com coletores separados
- **Integração nativa** com a stack Grafana (Prometheus, Loki, Tempo)
- **Configuração unificada** para todos os tipos de telemetria

## Migração do OpenTelemetry Collector para Grafana Agent

A implementação inicial usava o OpenTelemetry Collector para coletar traces. Migramos para o Grafana Agent devido a:

1. **Menor consumo de recursos**: O Grafana Agent tem uma pegada de memória menor
2. **Configuração simplificada**: Uma única configuração para todos os tipos de telemetria
3. **Melhor integração**: Integração nativa com a stack Grafana
4. **Suporte a logs**: Preparação para futura implementação do Loki

### Configuração do Grafana Agent

O Grafana Agent é configurado via Terraform no módulo `terraform/modules/grafana-agent` com:

- Receptor OTLP para traces nas portas 4317 (gRPC) e 4318 (HTTP)
- Processador de lotes para otimização de envio
- Exportador para o Tempo
- Coletor de métricas do Prometheus
- Preparação para logs com Loki (futuro)

### Kustomize Overlays

Os arquivos de patch do Kustomize para aplicações incluem:

- `nginx-patch.yaml`: Atualiza a configuração do Nginx para redirecionar telemetria do frontend para o Grafana Agent
- `backend-patch.yaml`: Atualiza as variáveis de ambiente do backend para apontar para o Grafana Agent

## Resolução de Problemas

Se os traces não estiverem sendo exibidos:

1. Verifique se o Grafana Agent está em execução:
   ```
   kubectl get pods -n observability | grep grafana-agent
   ```

2. Verifique os logs do Grafana Agent:
   ```
   kubectl logs -n observability deployment/grafana-agent
   ```

3. Verifique se o Tempo está recebendo dados:
   ```
   kubectl logs -n observability deployment/tempo
   ```

4. Confirme que o datasource do Tempo está configurado no Grafana:
   - Acesse Grafana > Configuration > Data sources > Tempo
