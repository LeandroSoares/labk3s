#!/bin/bash
# Script de instalação e configuração do K3s para laboratório DevOps
# Este script deve ser executado com privilégios de root

set -e  # Termina script em caso de erro

# Cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Script de instalação do K3s ===${NC}"
echo -e "${GREEN}=== By: LaboratorioK3s Project ===${NC}"
echo ""

# Verifica se está executando como root
if [ "$(id -u)" -ne 0 ]; then
   echo -e "${RED}Este script deve ser executado como root${NC}" 
   exit 1
fi

# Configurações
K3S_VERSION="v1.27.5+k3s1"  # Altere para a versão desejada
NODE_IP=$(hostname -I | awk '{print $1}')
INSTALL_EXTRAS=true  # Instalar componentes extras (helm, kubectl)
CONFIGURE_FIREWALL=true  # Configurar firewall (ufw)

# Função para exibir mensagens de etapa
step() {
    echo -e "${YELLOW}>> $1${NC}"
}

# Função para exibir mensagens de sucesso
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Verificar sistema operacional
step "Verificando sistema operacional..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    success "Sistema operacional detectado: $OS $VER"
else
    echo -e "${RED}Sistema operacional não suportado${NC}"
    exit 1
fi

# Atualizar sistema
step "Atualizando pacotes do sistema..."
apt-get update && apt-get upgrade -y
success "Sistema atualizado"

# Instalar pacotes úteis
step "Instalando pacotes úteis..."
apt-get install -y curl wget vim htop iotop iftop net-tools jq unzip git
success "Pacotes básicos instalados"

# Configurar timezone
step "Configurando timezone para Brasília..."
timedatectl set-timezone America/Sao_Paulo
success "Timezone configurado"

# Configurar firewall se solicitado
if [ "$CONFIGURE_FIREWALL" = true ]; then
    step "Configurando firewall (UFW)..."
    apt-get install -y ufw
    ufw allow 22/tcp
    ufw allow 6443/tcp  # API Kubernetes
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    ufw allow 8472/udp  # VXLAN (Flannel)
    ufw allow 10250/tcp # Kubelet
    ufw allow 10251/tcp # kube-scheduler
    ufw allow 10252/tcp # kube-controller
    ufw allow 2379/tcp  # etcd client
    ufw allow 2380/tcp  # etcd peer
    ufw allow 30000:32767/tcp # NodePort Services
    
    # Habilitar firewall apenas se não estiver ativo
    if ! ufw status | grep -q "Status: active"; then
        echo "y" | ufw enable
    fi
    
    success "Firewall configurado"
fi

# Desativar swap (requisito para Kubernetes)
step "Desativando SWAP..."
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab
success "SWAP desativada"

# Ajustar configurações do sistema
step "Ajustando parâmetros do kernel..."
cat > /etc/sysctl.d/99-kubernetes.conf << EOF
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
vm.swappiness = 0
EOF
sysctl --system
success "Parâmetros do kernel ajustados"

# Instalar K3s
step "Instalando K3s ($K3S_VERSION)..."
export INSTALL_K3S_VERSION="$K3S_VERSION"
export INSTALL_K3S_EXEC="--advertise-address=$NODE_IP --node-ip=$NODE_IP"

# Se houver um token específico para o cluster, adicione aqui
# export K3S_TOKEN="seu-token-aqui"

curl -sfL https://get.k3s.io | sh -
success "K3s instalado!"

# Verificar status do serviço
step "Verificando status do serviço K3s..."
systemctl status k3s --no-pager
success "K3s está rodando"

# Instalar Helm se solicitado
if [ "$INSTALL_EXTRAS" = true ]; then
    step "Instalando Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    success "Helm instalado"
    
    step "Instalando kubectl..."
    apt-get update && apt-get install -y apt-transport-https
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
    apt-get update && apt-get install -y kubectl
    success "kubectl instalado"
    
    # Configurar autocomplete para kubectl
    kubectl completion bash > /etc/bash_completion.d/kubectl
    echo 'alias k=kubectl' >> /etc/profile.d/kubernetes.sh
    echo 'complete -o default -F __start_kubectl k' >> /etc/profile.d/kubernetes.sh
    success "Configuração de kubectl finalizada"
fi

# Configurar acesso ao kubectl para o usuário atual
step "Configurando acesso ao kubectl..."
mkdir -p $HOME/.kube
cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
chmod 600 $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config
echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.bashrc
success "Acesso ao kubectl configurado"

# Verificar nós do cluster
step "Verificando nós do cluster..."
kubectl get nodes
success "K3s está funcionando corretamente!"

# Mostrar informações do cluster
echo -e "\n${GREEN}=== Informações do Cluster K3s ===${NC}"
echo -e "${YELLOW}IP do Servidor:${NC} $NODE_IP"
echo -e "${YELLOW}Versão do K3s:${NC} $K3S_VERSION"
echo -e "${YELLOW}Arquivo kubeconfig:${NC} /etc/rancher/k3s/k3s.yaml"
echo -e "${YELLOW}Token do Cluster:${NC} $(cat /var/lib/rancher/k3s/server/node-token)"

# Criar arquivo com informações para acesso remoto
cat > k3s-access-info.txt << EOF
=== Informações de Acesso ao Cluster K3s ===
IP do Servidor: $NODE_IP
Versão do K3s: $K3S_VERSION
Arquivo kubeconfig: /etc/rancher/k3s/k3s.yaml
Token do Cluster: $(cat /var/lib/rancher/k3s/server/node-token)

=== Para acessar o cluster remotamente ===
1. Copie o arquivo kubeconfig para sua máquina local:
   scp usuario@$NODE_IP:/etc/rancher/k3s/k3s.yaml ~/.kube/config

2. Edite o arquivo ~/.kube/config e substitua "127.0.0.1" por "$NODE_IP"

3. Teste o acesso com:
   kubectl get nodes
EOF

chmod 600 k3s-access-info.txt
success "Arquivo de informações de acesso criado: k3s-access-info.txt"

echo -e "\n${GREEN}=== Instalação do K3s concluída com sucesso! ===${NC}"
echo -e "${YELLOW}Para obter informações de acesso, consulte o arquivo k3s-access-info.txt${NC}"
