# Script para otimização de recursos do K3s
# Uso em VPS com recursos limitados (2 cores, 8GB RAM)

#!/bin/bash
set -e

# Cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Script de otimização de recursos para K3s ===${NC}"
echo -e "${GREEN}=== Recomendado para VPS com 2 cores e 8GB RAM ===${NC}"
echo ""

# Verificar se estamos executando como root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Este script deve ser executado como root${NC}"
  exit 1
fi

# Verificar se o K3s está instalado
if ! command -v kubectl &> /dev/null; then
  echo -e "${RED}kubectl não encontrado. Por favor, instale o K3s primeiro.${NC}"
  exit 1
fi

# Verificar se o Helm está instalado
if ! command -v helm &> /dev/null; then
  echo -e "${RED}Helm não encontrado. Por favor, instale o Helm primeiro.${NC}"
  exit 1
fi

echo -e "${YELLOW}>> Ajustando limites de memória para o kubelet${NC}"
# Adicionar configuração de eviction ao kubelet
mkdir -p /var/lib/rancher/k3s/server/manifests/
cat > /var/lib/rancher/k3s/server/kubelet.yaml << EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
evictionHard:
  memory.available: "500Mi"
  nodefs.available: "10%"
  nodefs.inodesFree: "5%"
evictionSoft:
  memory.available: "750Mi"
  nodefs.available: "15%"
evictionSoftGracePeriod:
  memory.available: "1m"
  nodefs.available: "1m"
evictionPressureTransitionPeriod: "30s"
EOF

echo -e "${YELLOW}>> Ajustando limite de arquivos abertos${NC}"
# Aumentar o limite de arquivos abertos para evitar erros
cat > /etc/security/limits.d/k3s.conf << EOF
*       soft    nofile  65535
*       hard    nofile  65535
root    soft    nofile  65535
root    hard    nofile  65535
EOF

echo -e "${YELLOW}>> Configurando parâmetros do kernel para melhor desempenho${NC}"
# Otimizações do kernel
cat > /etc/sysctl.d/99-kubernetes.conf << EOF
vm.swappiness = 0
vm.overcommit_memory = 1
kernel.panic = 10
kernel.panic_on_oops = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10
fs.inotify.max_user_watches = 65536
fs.inotify.max_user_instances = 8192
EOF

sysctl --system

echo -e "${YELLOW}>> Configurando valores otimizados para Prometheus e Grafana${NC}"
# Criar arquivo de valores otimizados para o Prometheus Stack
cat > prometheus-values-optimized.yaml << EOF
prometheus:
  prometheusSpec:
    retention: 5d
    retentionSize: 5GB
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 200m
        memory: 512Mi
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 5Gi
grafana:
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 100m
      memory: 256Mi
alertmanager:
  enabled: false
kubeStateMetrics:
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi
nodeExporter:
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi
prometheusOperator:
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi
EOF

echo -e "${YELLOW}>> Configurando limites de recursos para a aplicação${NC}"
# Criar arquivo com limites de recursos para a aplicação
cat > app-resources.yaml << EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: joke-app
spec:
  template:
    spec:
      containers:
      - name: frontend
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: joke-app
spec:
  template:
    spec:
      containers:
      - name: backend
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "100m"
EOF

echo -e "${YELLOW}>> Aplicando configurações ao cluster${NC}"
# Aplicar configurações de recursos para aplicação
kubectl patch -f app-resources.yaml --type=merge

echo -e "${GREEN}=== Otimizações de recursos aplicadas! ===${NC}"
echo -e "${YELLOW}Para aplicar as configurações do Prometheus otimizadas, execute:${NC}"
echo -e "  helm upgrade -i prom-stack prometheus-community/kube-prometheus-stack -f prometheus-values-optimized.yaml -n observability"

echo -e "\n${YELLOW}Recomendações adicionais:${NC}"
echo -e "1. Monitore o uso de recursos com 'kubectl top nodes' e 'kubectl top pods --all-namespaces'"
echo -e "2. Considere desativar componentes não essenciais do K3s durante a instalação:"
echo -e "   INSTALL_K3S_EXEC=\"--disable=traefik,servicelb,metrics-server\" ./install.sh"
echo -e "3. Configure o armazenamento persistente com limites apropriados para sua VPS"
echo -e "4. Revise e ajuste periodicamente as configurações de recursos com base no uso real"
