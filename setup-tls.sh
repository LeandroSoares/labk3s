#!/bin/bash
# Script para instalar e configurar cert-manager para TLS
# Este script configura certificados automáticos com Let's Encrypt

set -e  # Termina script em caso de erro

# Cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Script de instalação do cert-manager para HTTPS ===${NC}"
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

# Configurar domínio
DOMAIN=${1:-"www.labk3s.online"}
EMAIL=${2:-"admin@labk3s.online"}

step "Configurando para domínio: $DOMAIN com email: $EMAIL"

# Instalar cert-manager com Helm
step "Instalando cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.12.0
success "cert-manager instalado"

# Aguardar pods do cert-manager
step "Aguardando pods do cert-manager estarem prontos..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=120s
success "Todos os pods do cert-manager estão prontos"

# Criar ClusterIssuer para Let's Encrypt
step "Criando ClusterIssuer para Let's Encrypt..."
cat > letsencrypt-issuer.yaml << EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${EMAIL}
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
    - http01:
        ingress:
          class: traefik
EOF

kubectl apply -f letsencrypt-issuer.yaml
success "ClusterIssuer criado"

# Verificar status do ClusterIssuer
step "Verificando status do ClusterIssuer..."
sleep 5
kubectl get clusterissuer letsencrypt-prod -o wide
success "ClusterIssuer configurado"

echo -e "\n${GREEN}=== Instalação do cert-manager concluída! ===${NC}"
echo -e "${YELLOW}Seu domínio $DOMAIN agora está configurado para usar HTTPS automaticamente.${NC}"
echo -e "${YELLOW}Os certificados serão emitidos automaticamente quando você criar Ingress com TLS.${NC}"

echo -e "\n${YELLOW}Dica: Adicione estas anotações aos seus Ingress:${NC}"
echo -e "  annotations:"
echo -e "    kubernetes.io/ingress.class: \"traefik\""
echo -e "    cert-manager.io/cluster-issuer: \"letsencrypt-prod\""
echo -e "\n${YELLOW}E adicione a seção TLS:${NC}"
echo -e "  tls:"
echo -e "  - hosts:"
echo -e "    - $DOMAIN"
echo -e "    secretName: labk3s-tls"
