# Dashboards do Grafana

Este diretório contém dashboards do Grafana prontos para uso no seu cluster K3s.

## K3s Cluster e Aplicações Dashboard

Este dashboard fornece uma visão geral do seu cluster K3s e das aplicações em execução. Ele inclui:

- **Visão Geral do Cluster**:
  - Número de nós
  - Número de namespaces
  - Uso de memória do cluster
  - Uso de CPU do cluster

- **Status da Aplicação**:
  - Pods prontos por namespace
  - Tempo de resposta da aplicação
  - Requisições de memória por pod
  - Requisições de CPU por pod

## Alertmanager Status Dashboard

Este dashboard fornece uma visão detalhada do status do Alertmanager e dos alertas ativos:

- **Status do Alertmanager**:
  - Estado operacional do serviço
  - Total de alertas ativos
  - Distribuição de alertas por severidade
  - Taxa de notificações

- **Alertas Ativos**:
  - Alertas por estado (firing/pending)
  - Duração dos alertas ativos
  - Histórico de alertas disparados
  - Alertas por label/anotação

## Como importar

Os dashboards são provisionados automaticamente pelo Terraform, mas você também pode importá-los manualmente:

1. Acesse seu Grafana em `https://grafana.labk3s.online`
2. Faça login com as credenciais configuradas
3. Clique em "+ Import" no menu lateral
4. Clique em "Upload JSON file" e selecione um dos arquivos JSON
5. Clique em "Import"

## Personalização

Este dashboard foi criado para funcionar com as métricas padrão coletadas pelo Prometheus no seu cluster K3s. 
Algumas métricas específicas da aplicação (como `http_request_duration_ms`) podem não estar disponíveis por padrão
e podem precisar de instrumentação adicional.

## Métricas personalizadas

Para métricas personalizadas da sua aplicação, você pode instrumentar seu código usando bibliotecas compatíveis com 
Prometheus para sua linguagem de programação:

- Para Node.js: [prom-client](https://github.com/siimon/prom-client)
- Para Python: [prometheus_client](https://github.com/prometheus/client_python)
- Para Go: [prometheus/client_golang](https://github.com/prometheus/client_golang)
- Para Java: [Micrometer](https://micrometer.io/) com `micrometer-registry-prometheus`
