#!/bin/bash
# Script para configurar o Traefik para acesso externo e redirecionamento HTTPS

set -e  # Termina script em caso de erro

# Cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Script de configuração do Traefik Ingress ===${NC}"
echo -e "${GREEN}=== By: LaboratorioK3s Project ===${NC}"
echo ""

# Verifica se kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl não está instalado. Por favor, instale primeiro.${NC}"
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

# Obter IP da VPS
VPS_IP=$(hostname -I | awk '{print $1}')
step "Detectado IP da VPS: $VPS_IP"

# Substitui o IP no arquivo de configuração do Traefik
step "Configurando o Traefik com seu IP..."
sed -i "s/YOUR_VPS_IP/$VPS_IP/g" k8s/traefik-config.yaml

# Aplicar configuração do Traefik
step "Aplicando configuração do Traefik..."
kubectl apply -f k8s/traefik-config.yaml
success "Configuração aplicada"

# Aguardar reinicialização do Traefik
step "Reiniciando o Traefik para aplicar as alterações..."
kubectl -n kube-system rollout restart deployment traefik
kubectl -n kube-system rollout status deployment traefik --timeout=120s
success "Traefik reiniciado com sucesso"

# Verificar status
step "Verificando serviços expostos pelo Traefik..."
kubectl get svc -n kube-system traefik
success "Traefik está configurado e expondo serviços na porta 80 e 443"

echo -e "\n${GREEN}=== Configuração do Traefik concluída! ===${NC}"
echo -e "${YELLOW}Seus serviços agora podem ser acessados via:${NC}"
echo -e "  http://${VPS_IP} (será redirecionado para HTTPS)"
echo -e "  https://${VPS_IP} (requer certificado válido)"
echo -e "  https://www.labk3s.online (quando o DNS estiver configurado)"

echo -e "\n${YELLOW}Para verificar o status do Ingress:${NC}"
echo -e "  kubectl get ingress --all-namespaces"
