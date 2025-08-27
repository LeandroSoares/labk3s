#!/bin/bash
# Script para aplicar as regras do Prometheus e configuração do Alertmanager

# Aplicar o ConfigMap do Alertmanager
echo "Aplicando a configuração do Alertmanager..."
kubectl apply -f alertmanager-config.yaml

# Aplicar as regras do Prometheus
echo "Aplicando as regras de alerta do Prometheus..."
kubectl apply -f prometheus-rules.yaml

# Criar um secret para o Alertmanager (quando for configurar integrações)
# kubectl create secret generic alertmanager-secrets \
#   --namespace=observability \
#   --from-literal=slack_url="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" \
#   --dry-run=client -o yaml | kubectl apply -f -

# Reiniciar o pod do Alertmanager para aplicar as novas configurações
echo "Reiniciando o pod do Alertmanager..."
ALERTMANAGER_POD=$(kubectl get pods -n observability | grep alertmanager | awk '{print $1}')
if [ ! -z "$ALERTMANAGER_POD" ]; then
  kubectl delete pod $ALERTMANAGER_POD -n observability
  echo "Pod do Alertmanager reiniciado com sucesso!"
else
  echo "Pod do Alertmanager não encontrado. Verifique se o Alertmanager está instalado."
fi

echo "Configuração concluída!"
