#!/bin/bash
# Script para configurar observabilidade no cluster K3s
# Este script instala Prometheus e Grafana usando Helm

set -e  # Termina script em caso de erro

# Cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

# Instalando Prometheus Stack
step "Instalando kube-prometheus-stack..."
helm install prom-stack prometheus-community/kube-prometheus-stack \
  --namespace observability \
  --set grafana.adminPassword=admin \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30080 \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=30090
success "Prometheus Stack instalado"

# Verificando status
step "Verificando status dos pods..."
kubectl get pods -n observability
success "Todos os pods estão sendo criados"

# Obter informações de acesso
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo -e "\n${GREEN}=== Instalação de Observabilidade Concluída! ===${NC}"
echo -e "${YELLOW}Para acessar o Grafana:${NC}"
echo -e "  URL: http://$NODE_IP:30080"
echo -e "  Usuário: admin"
echo -e "  Senha: admin"
echo -e "${YELLOW}Para acessar o Prometheus:${NC}"
echo -e "  URL: http://$NODE_IP:30090"

# Dica para configurar o datasource do Prometheus no Grafana (se necessário)
echo -e "\n${YELLOW}Dica: O datasource do Prometheus já deve estar configurado automaticamente no Grafana.${NC}"
echo -e "${YELLOW}Se não estiver, adicione manualmente usando a URL: http://prom-stack-kube-prometheus-prometheus.observability:9090${NC}"

# Salvar informações em um arquivo
cat > observability-access-info.txt << EOF
=== Informações de Acesso à Stack de Observabilidade ===

Grafana:
  URL: http://$NODE_IP:30080
  Usuário: admin
  Senha: admin

Prometheus:
  URL: http://$NODE_IP:30090

URL interna do Prometheus (para datasource do Grafana):
  http://prom-stack-kube-prometheus-prometheus.observability:9090

Para verificar o status dos pods:
  kubectl get pods -n observability

Para obter a senha do Grafana (caso necessário):
  kubectl get secret -n observability prom-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode; echo
EOF

chmod 600 observability-access-info.txt
success "Arquivo de informações de acesso criado: observability-access-info.txt"
