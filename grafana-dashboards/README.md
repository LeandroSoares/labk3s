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

## Como importar

1. Acesse seu Grafana em `https://grafana.labk3s.online`
2. Faça login com as credenciais configuradas
3. Clique em "+ Import" no menu lateral
4. Clique em "Upload JSON file" e selecione o arquivo `k3s-cluster-dashboard.json`
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
