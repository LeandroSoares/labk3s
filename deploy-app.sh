#!/bin/bash
# Script para implantar a aplicação "Tell Me a Joke" no cluster K3s

set -e  # Termina script em caso de erro

# Cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Script de implantação da aplicação 'Tell Me a Joke' ===${NC}"
echo -e "${GREEN}=== By: LaboratorioK3s Project ===${NC}"
echo ""

# Configurações
DOCKER_USERNAME="seu-usuario-dockerhub"  # Altere para seu usuário no Docker Hub
APP_VERSION="latest"                      # Versão da aplicação
APP_DOMAIN="www.labk3s.online"           # Domínio configurado

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

# Solicitar usuário do Docker Hub se não foi definido
if [ "$DOCKER_USERNAME" = "seu-usuario-dockerhub" ]; then
    read -p "Digite seu usuário do Docker Hub: " DOCKER_USERNAME
    if [ -z "$DOCKER_USERNAME" ]; then
        echo -e "${RED}Usuário do Docker Hub não fornecido. Usando imagens de exemplo.${NC}"
        DOCKER_USERNAME="dockerhub-user"  # Valor de fallback
    fi
fi

# Verificar se o domínio está definido
if [ -z "$APP_DOMAIN" ]; then
    read -p "Digite o domínio para o ingress (pressione Enter para usar www.labk3s.online): " USER_DOMAIN
    if [ -n "$USER_DOMAIN" ]; then
        APP_DOMAIN="$USER_DOMAIN"
    else
        APP_DOMAIN="www.labk3s.online"
        echo -e "${YELLOW}Usando domínio padrão: ${APP_DOMAIN}${NC}"
    fi
fi

# Preparar arquivos YAML
step "Preparando arquivos de manifesto Kubernetes..."
mkdir -p k8s-temp

# Namespace
cat > k8s-temp/namespace.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: joke-app
EOF

# Backend
cat > k8s-temp/backend.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: joke-app
  labels:
    app: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: "3000"
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: backend
        image: ${DOCKER_USERNAME}/joke-backend:${APP_VERSION}
        ports:
        - containerPort: 3000
        resources:
          limits:
            cpu: "0.3"
            memory: "256Mi"
          requests:
            cpu: "0.1"
            memory: "128Mi"
            ephemeral-storage: "128Mi"
        volumeMounts:
        - name: sqlite-data
          mountPath: /data
      volumes:
      - name: sqlite-data
        persistentVolumeClaim:
          claimName: sqlite-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: joke-app
spec:
  selector:
    app: backend
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sqlite-pvc
  namespace: joke-app
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Frontend
cat > k8s-temp/frontend.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: joke-app
  labels:
    app: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 101
        fsGroup: 101
      containers:
      - name: frontend
        image: ${DOCKER_USERNAME}/joke-frontend:${APP_VERSION}
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: "0.2"
            memory: "128Mi"
          requests:
            cpu: "0.1"
            memory: "64Mi"
            ephemeral-storage: "64Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: joke-app
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Ingress (condicional baseado no domínio fornecido)
if [ -n "$APP_DOMAIN" ]; then
    cat > k8s-temp/ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: joke-app-ingress
  namespace: joke-app
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"  # Opcional, se você configurar cert-manager
spec:
  tls:  # Opcional, se você configurar cert-manager
  - hosts:
    - ${APP_DOMAIN}
    secretName: labk3s-tls
  rules:
  - host: ${APP_DOMAIN}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
EOF
else
    # Se não tiver domínio, configura um NodePort para o frontend
    cat > k8s-temp/nodeport.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: frontend-nodeport
  namespace: joke-app
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30081
  type: NodePort
EOF
fi

success "Arquivos de manifesto preparados"

# Aplicar manifestos
step "Implantando aplicação no cluster K3s..."
kubectl apply -f k8s-temp/namespace.yaml
kubectl apply -f k8s-temp/backend.yaml
kubectl apply -f k8s-temp/frontend.yaml

if [ -n "$APP_DOMAIN" ]; then
    kubectl apply -f k8s-temp/ingress.yaml
    success "Ingress configurado para o domínio $APP_DOMAIN"
else
    kubectl apply -f k8s-temp/nodeport.yaml
    success "NodePort configurado na porta 30081"
fi

# Limpar arquivos temporários
rm -rf k8s-temp

# Verificar status
step "Verificando status dos pods..."
kubectl get pods -n joke-app
success "Aplicação implantada com sucesso!"

# Obter informações de acesso
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo -e "\n${GREEN}=== Implantação da Aplicação Concluída! ===${NC}"
if [ -n "$APP_DOMAIN" ]; then
    echo -e "${YELLOW}Para acessar a aplicação:${NC}"
    echo -e "  URL: http://${APP_DOMAIN}"
    echo -e "  Nota: Certifique-se de que o DNS está configurado para apontar para $NODE_IP"
else
    echo -e "${YELLOW}Para acessar a aplicação:${NC}"
    echo -e "  URL: http://${NODE_IP}:30081"
fi

# Dicas adicionais
echo -e "\n${YELLOW}Dicas:${NC}"
echo -e "1. Para verificar os logs do backend:"
echo -e "   kubectl logs -f -l app=backend -n joke-app"
echo -e "2. Para verificar os logs do frontend:"
echo -e "   kubectl logs -f -l app=frontend -n joke-app"
echo -e "3. Para verificar o status dos serviços:"
echo -e "   kubectl get svc -n joke-app"

# Salvar informações em um arquivo
cat > joke-app-access-info.txt << EOF
=== Informações de Acesso à Aplicação "Tell Me a Joke" ===

EOF

if [ -n "$APP_DOMAIN" ]; then
    cat >> joke-app-access-info.txt << EOF
URL: http://${APP_DOMAIN}
Nota: Certifique-se de que o DNS está configurado para apontar para $NODE_IP
EOF
else
    cat >> joke-app-access-info.txt << EOF
URL: http://${NODE_IP}:30081
EOF
fi

cat >> joke-app-access-info.txt << EOF

Para verificar os logs do backend:
  kubectl logs -f -l app=backend -n joke-app

Para verificar os logs do frontend:
  kubectl logs -f -l app=frontend -n joke-app

Para verificar o status dos serviços:
  kubectl get svc -n joke-app
EOF

chmod 600 joke-app-access-info.txt
success "Arquivo de informações de acesso criado: joke-app-access-info.txt"
