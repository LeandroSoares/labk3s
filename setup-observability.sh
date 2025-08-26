#!/bin/bash
# Script para configurar observabilidade no cluster K3s
# Este script instala Prometheus e Grafana usando Helm

set -e  # Termina script em caso de erro

# Cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Processar argumentos
VALUES_FILE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --values-file)
      VALUES_FILE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

echo -e "${GREEN}=== Script de configuração de observabilidade para K3s ===${NC}"
echo -e "${GREEN}=== By: LaboratorioK3s Project ===${NC}"
echo ""

# Verifica se kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl não está instalado. Por favor, instale primeiro.${NC}"
    exit 1
fi

# Verifica se helm está instalado
if ! command -v helm &> /dev/null; then
    echo -e "${RED}helm não está instalado. Por favor, instale primeiro.${NC}"
    exit 1
fi

# Função para exibir mensagens de etapa
step() {
    echo -e "${YELLOW}>> $1${NC}"
}

# Função para exibir mensagens de sucesso
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Verificar acesso ao cluster
step "Verificando acesso ao cluster K3s..."
if ! kubectl get nodes &> /dev/null; then
    echo -e "${RED}Não foi possível acessar o cluster K3s. Verifique se o cluster está funcionando e se o kubeconfig está configurado corretamente.${NC}"
    exit 1
fi
success "Cluster K3s acessível"

# Adicionar repositórios Helm
step "Adicionando repositórios Helm..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
success "Repositórios Helm adicionados"

# Criar namespace para observabilidade
step "Criando namespace 'observability'..."
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
success "Namespace criado"

# Verificar se foi fornecido um arquivo de valores personalizado
if [ -n "$VALUES_FILE" ] && [ -f "$VALUES_FILE" ]; then
  step "Usando arquivo de valores otimizados: $VALUES_FILE"
  
  # Instalando Prometheus Stack com valores otimizados
  step "Instalando kube-prometheus-stack com configurações otimizadas..."
  helm install prom-stack prometheus-community/kube-prometheus-stack \
    --namespace observability \
    --values "$VALUES_FILE"
  success "Prometheus Stack instalado com configurações otimizadas"
else
  # Instalando Prometheus Stack com valores padrão
  step "Instalando kube-prometheus-stack com configurações padrão..."
  helm install prom-stack prometheus-community/kube-prometheus-stack \
    --namespace observability \
    --set grafana.adminPassword=admin \
    --set grafana.service.type=NodePort \
    --set grafana.service.nodePort=30080 \
    --set prometheus.service.type=NodePort \
    --set prometheus.service.nodePort=30090
  success "Prometheus Stack instalado com configurações padrão"
  echo -e "${YELLOW}NOTA: Para otimizar recursos em VPS limitadas, considere usar --values-file com prometheus-values-optimized.yaml${NC}"
fi

# Verificando status
step "Verificando status dos pods..."
kubectl get pods -n observability
success "Todos os pods estão sendo criados"

# Obter informações de acesso
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo -e "\n${GREEN}=== Instalação de Observabilidade Concluída! ===${NC}"

if [ -n "$VALUES_FILE" ] && [ -f "$VALUES_FILE" ]; then
  echo -e "${GREEN}Stack de observabilidade instalada com configurações otimizadas para economia de recursos!${NC}"
  echo -e "${YELLOW}Acesso via Ingress (recomendado):${NC}"
  echo -e "  Grafana: https://grafana.labk3s.online"
  echo -e "  Prometheus: https://prometheus.labk3s.online"
  echo -e "  Usuário Grafana: admin"
  echo -e "  Senha Grafana: admin"
  
  echo -e "\n${YELLOW}Para configurar o acesso via Ingress, execute:${NC}"
  echo -e "  kubectl apply -f k8s/observability/ingress.yaml"
else
  echo -e "${YELLOW}Para acessar o Grafana:${NC}"
  echo -e "  URL: http://$NODE_IP:30080"
  echo -e "  Usuário: admin"
  echo -e "  Senha: admin"
  echo -e "${YELLOW}Para acessar o Prometheus:${NC}"
  echo -e "  URL: http://$NODE_IP:30090"
fi

# Dica para configurar o datasource do Prometheus no Grafana (se necessário)
echo -e "\n${YELLOW}Dica: O datasource do Prometheus já deve estar configurado automaticamente no Grafana.${NC}"
echo -e "${YELLOW}Se não estiver, adicione manualmente usando a URL: http://prom-stack-kube-prometheus-prometheus.observability:9090${NC}"

# Salvar informações em um arquivo
cat > observability-access-info.txt << EOF
=== Informações de Acesso à Stack de Observabilidade ===

Grafana:
  URL: http://$NODE_IP:30080 ou https://grafana.labk3s.online (com Ingress)
  Usuário: admin
  Senha: admin

Prometheus:
  URL: http://$NODE_IP:30090 ou https://prometheus.labk3s.online (com Ingress)
EOF

URL interna do Prometheus (para datasource do Grafana):
  http://prom-stack-kube-prometheus-prometheus.observability:9090

Para verificar o status dos pods:
  kubectl get pods -n observability

Para obter a senha do Grafana (caso necessário):
  kubectl get secret -n observability prom-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode; echo
EOF

chmod 600 observability-access-info.txt
success "Arquivo de informações de acesso criado: observability-access-info.txt"
