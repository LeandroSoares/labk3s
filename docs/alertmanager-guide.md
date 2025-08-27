# Guia de Uso do Alertmanager

Este documento explica como utilizar o Alertmanager implementado no projeto LaboratorioK3s.

## Acesso ao Alertmanager

O Alertmanager está disponível através da URL:
- https://alertmanager.labk3s.online

## Componentes Implementados

1. **Alertmanager**: Gerencia e roteia alertas para diferentes canais de notificação (configurado apenas com webhook básico por enquanto)
2. **Regras de Alerta**: Configuradas para monitorar:
   - Saúde do cluster K3s (CPU, memória, disco)
   - Aplicação "Tell Me a Joke" (taxa de requisições, erros, pods reiniciando)
   - Traefik Ingress Controller (taxa de erros)
3. **Dashboard Grafana**: Visualização do status dos alertas em tempo real

## Estrutura das Regras de Alerta

As regras de alerta estão organizadas em três grupos:

### Alertas do Cluster K3s
- **K3sNodeMemoryHigh**: Uso de memória acima de 85% por 5 minutos
- **K3sNodeCPUHigh**: Uso de CPU acima de 80% por 5 minutos
- **K3sNodeDiskSpaceLow**: Espaço em disco abaixo de 15% por 5 minutos
- **K3sNodeDiskSpaceCritical**: Espaço em disco abaixo de 5% por 5 minutos

### Alertas da Aplicação "Tell Me a Joke"
- **JokeAppHighRequestRate**: Taxa de requisições acima de 5 req/s por 5 minutos
- **JokeAppHighErrorRate**: Taxa de erros 5xx acima de 5% por 2 minutos
- **JokeAppPodRestarting**: Pod da aplicação reiniciando mais de 3 vezes em 15 minutos
- **JokeAppBackendDown**: Backend da aplicação indisponível por 1 minuto

### Alertas do Traefik
- **TraefikHighErrorRate**: Taxa de erros 5xx acima de 5% por 2 minutos

## Configuração de Notificações

Atualmente, o Alertmanager está configurado apenas com um receptor webhook básico sem integração real. Para implementar integrações com canais de notificação, você pode:

1. **Slack**: Adicionar um webhook do Slack ao arquivo de configuração
2. **Email**: Configurar um servidor SMTP para envio de emails
3. **PagerDuty**: Integrar com PagerDuty para alertas críticos
4. **Webhook Personalizado**: Integrar com sistemas internos através de webhooks

## Silenciamento de Alertas

O Alertmanager está configurado com regras de inibição para evitar tempestades de alertas:

1. Alertas de warning são silenciados quando há alertas críticos para o mesmo serviço
2. Todos os alertas de um nó são silenciados quando o nó está indisponível

Para silenciar manualmente alertas:
1. Acesse a interface web do Alertmanager
2. Clique em "Silences" no menu superior
3. Clique em "New Silence"
4. Configure os critérios e duração do silenciamento

## Próximos Passos

Para expandir a implementação do Alertmanager, considere:

1. Configurar integrações reais com Slack, Email, etc.
2. Ajustar os thresholds das regras com base no comportamento normal do sistema
3. Implementar templates personalizados para as notificações
4. Configurar rotas mais específicas para direcionar alertas para as equipes corretas

## Manutenção

Após alterações nas regras de alerta ou na configuração do Alertmanager:

1. Aplique as alterações com `kubectl apply -f k8s/prometheus-rules.yaml`
2. Aplique a nova configuração com `kubectl apply -f k8s/alertmanager-config.yaml`
3. Reinicie o pod do Alertmanager para aplicar as mudanças:
   ```bash
   kubectl delete pod -n observability $(kubectl get pods -n observability | grep alertmanager | awk '{print $1}')
   ```
