# Projeto: Stack DevOps com K3s, Terraform e Observabilidade

## Objetivo
Demonstrar conhecimentos em DevOps, implementando um cluster Kubernetes (K3s) com stack de observabilidade (Prometheus + Grafana) e certificados TLS utilizando Terraform para automação de componentes de terceiros e Kustomize para recursos da aplicação.

## Status do Projeto
✅ **Implementado e funcionando**  
O projeto foi completamente implementado e está funcionando corretamente, com todos os componentes integrados e acessíveis conforme planejado.

## Arquitetura do Projeto

### Terraform (Componentes de Terceiros)
- **Módulos Terraform**:
  - **observability**: Prometheus e Grafana para monitoramento
  - **cert-manager**: Gerenciamento de certificados TLS com Let's Encrypt

### Kustomize (Recursos da Aplicação)
- **k8s/app**: Contém os manifestos Kubernetes da aplicação
  - Frontend
  - Backend
  - Configurações de Ingress
  - Serviços

## Acesso
A aplicação está acessível em: [https://www.labk3s.online](https://www.labk3s.online)  
Dashboard Grafana: [https://grafana.labk3s.online](https://grafana.labk3s.online) (usuário: admin, senha: definida no terraform.tfvars)  
Dashboard Prometheus: [https://prometheus.labk3s.online](https://prometheus.labk3s.online)

---

## Arquitetura do Projeto Atualizada

```
VPS com K3s
  ├── Terraform (Infraestrutura como Código)
  │   ├── Módulo de Observabilidade
  │   │   ├── Prometheus
  │   │   └── Grafana
  │   └── Módulo cert-manager (Let's Encrypt)
  ├── Aplicação "Tell Me a Joke"
  │   ├── Frontend (Nginx + HTML/JS)
  │   ├── Backend (Node.js + Express)
  │   └── Armazenamento (SQLite)
  └── Configuração de Rede
      ├── Traefik Ingress Controller
      └── TLS com Let's Encrypt
```

## Estrutura do Projeto

```
laboratoriok3s/
├── terraform/                    # Configuração do Terraform
│   ├── modules/
│   │   ├── cert-manager/         # Módulo para gerenciamento de certificados TLS
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── observability/        # Módulo para monitoramento
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── main.tf                   # Configuração principal do Terraform
│   ├── variables.tf              # Variáveis do Terraform
│   ├── outputs.tf                # Outputs do Terraform
│   ├── variables_cert_manager.tf # Variáveis específicas do cert-manager
│   └── terraform-optimized.tfvars # Valores otimizados para recursos limitados
├── k8s/                          # Configurações Kubernetes
│   ├── app/                      # Manifestos da aplicação
│   │   ├── namespace.yaml        # Namespace da aplicação
│   │   ├── frontend.yaml         # Deployment e Service do frontend
│   │   ├── frontend-nodeport.yaml # Serviço NodePort opcional
│   │   ├── backend.yaml          # Deployment, Service e PVC do backend
│   │   ├── ingress.yaml          # Ingress para a aplicação principal
│   │   ├── api-route.yaml        # Ingress para as rotas da API
│   │   ├── letsencrypt-issuer.yaml # Emissor para certificados
│   │   └── kustomization.yaml    # Configuração do Kustomize
├── src/                          # Código-fonte da aplicação
│   ├── frontend/                 # Frontend da aplicação
│   │   ├── index.html            # Página HTML principal
│   │   ├── script.js             # JavaScript do frontend
│   │   ├── nginx.conf            # Configuração do Nginx
│   │   └── Dockerfile            # Dockerfile para o frontend
│   └── backend/                  # Backend da aplicação
│       ├── server.js             # Servidor Node.js
│       ├── package.json          # Dependências do Node.js
│       └── Dockerfile            # Dockerfile para o backend
├── grafana-dashboards/           # Dashboards pré-configurados para o Grafana
│   ├── k3s-cluster-dashboard.json # Dashboard para monitorar o cluster K3s
│   └── README.md                 # Documentação dos dashboards
├── install-k3s.sh                # Script para instalação do K3s
├── cluster-issuer.yaml           # ClusterIssuer para Let's Encrypt
└── readme.md                     # Este arquivo
```

---

## Aplicação "Tell Me a Joke"

A aplicação implementada consiste em um site simples que exibe e permite adicionar piadas aleatórias:

### Componentes
- **Frontend**: Interface web responsiva com HTML, CSS (Tailwind) e JavaScript, servida pelo Nginx
- **Backend**: API REST em Node.js/Express que fornece piadas aleatórias e métricas para o Prometheus
- **Armazenamento**: Banco de dados SQLite com persistência via PersistentVolumeClaim

### Funcionalidades
1. **Exibição de piadas aleatórias**
   - Clique no botão "Nova Piada" para obter uma piada aleatória do backend
   - As piadas são selecionadas aleatoriamente do banco de dados SQLite

2. **Adição de novas piadas**
   - Clique no botão "Adicionar Piada" para abrir um formulário
   - Insira sua piada e clique em "Salvar"
   - A piada será adicionada ao banco de dados e poderá aparecer nas próximas requisições

3. **Integração com Observabilidade**
   - O backend expõe métricas Prometheus em `/metrics`
   - Contador personalizado para requisições de piadas (`joke_requests_total`)
   - Link direto para o dashboard do Grafana no canto inferior direito da aplicação

### Implantação
A aplicação é implantada no cluster K3s usando Kustomize:

```sh
# Criar o namespace e todos os recursos necessários
kubectl apply -k k8s/app

# Verificar o status da implantação
kubectl get pods -n joke-app
kubectl get svc -n joke-app
kubectl get ingress -n joke-app
```

## Passo a Passo de Implementação

### 1. Pré-requisitos
- VPS Linux com Ubuntu/Debian
- Domínio configurado para apontar para o IP da VPS
- Portas 80, 443, 6443 (API K3s) liberadas no firewall

### 2. Instalação do K3s
```sh
# Na sua VPS
chmod +x install-k3s.sh
./install-k3s.sh
```
Este script:
- Instala o K3s na versão especificada (v1.27.5+k3s1)
- Configura o firewall para permitir o tráfego necessário
- Desativa swap (requisito do Kubernetes)
- Instala kubectl e Helm
- Configura acesso ao cluster

### 3. Configuração do TLS
```sh
# Configurar o ClusterIssuer para Let's Encrypt
kubectl apply -f cluster-issuer.yaml
```

### 4. Instalação via Terraform
```sh
# No diretório terraform
terraform init
terraform apply -var="optimize_resources=true" -var="letsencrypt_email=seu-email@exemplo.com" -var="domain_name=labk3s.online"
```

Este processo:
- Instala o cert-manager para gerenciamento de certificados TLS
- Configura a stack de observabilidade (Prometheus e Grafana)
- Cria os Ingress necessários para acessar Grafana e Prometheus

### 5. Implantação da Aplicação
```sh
# Implantar todos os recursos da aplicação usando Kustomize
kubectl apply -k k8s/app
```

### 6. Verificação da Implantação
```sh
# Verificar os pods
kubectl get pods -n joke-app

# Verificar os serviços
kubectl get svc -n joke-app

# Verificar os ingresses
kubectl get ingress -n joke-app

# Verificar certificados
kubectl get certificates -n joke-app
```

---

## Stack de Observabilidade

### Componentes
- **Prometheus**: Sistema de monitoramento e alerta
  - Coleta métricas de todos os componentes do cluster
  - Configurado para uso otimizado de recursos (CPU/memória)
  - Exposto em [https://prometheus.labk3s.online](https://prometheus.labk3s.online)

- **Grafana**: Visualização de métricas e dashboards
  - Pré-configurado com dashboard para monitoramento do cluster K3s
  - Interface gráfica intuitiva para análise de métricas
  - Exposto em [https://grafana.labk3s.online](https://grafana.labk3s.online)

### Dashboards Incluídos
- **K3s Cluster Dashboard**: Visão geral do estado do cluster
  - Métricas de uso de CPU e memória por nó
  - Estado dos pods e deployments
  - Uso de rede e disco

### Monitoramento da Aplicação
O backend da aplicação expõe métricas no formato Prometheus:
- Contador de requisições à API (`joke_requests_total`)
- Métricas padrão do Node.js (memória, CPU, GC)
- Acessível em `/metrics` no backend

### Otimizações para VPS com Recursos Limitados
- Prometheus configurado com retenção reduzida (5 dias)
- Alertmanager desativado para economizar recursos
- Limites de CPU e memória ajustados para todos os componentes
- Grafana com recursos minimizados

---

## Boas Práticas DevOps Implementadas

### 1. Infraestrutura como Código (IaC)
- Uso do Terraform para provisionar e gerenciar componentes de terceiros
- Organização em módulos reutilizáveis para melhor manutenção
- Variáveis configuráveis para personalização fácil

### 2. Containerização
- Aplicações encapsuladas em contêineres Docker
- Dockerfile otimizados para cada componente
- Configuração declarativa com manifestos Kubernetes

### 3. Gerenciamento de Configuração
- Kustomize para recursos da aplicação
- ConfigMaps para dashboards do Grafana
- Valores configuráveis para ambientes com diferentes recursos

### 4. Observabilidade
- Monitoramento completo com Prometheus
- Visualização com Grafana
- Métricas personalizadas para a aplicação

### 5. Segurança
- TLS automatizado com Let's Encrypt
- Redirecionamento automático HTTP para HTTPS
- Controle de recursos para evitar negação de serviço

### 6. Automação
- Scripts de instalação e configuração
- Terraform para provisionamento automatizado
- Kustomize para gerenciar recursos relacionados

2. **Contêinerização**
   - Aplicações em containers no Kubernetes
   - Configuração declarativa com Dockerfiles otimizados

## Perguntas Frequentes

### É necessário um Nginx adicional para expor serviços do K3s?

Não. O K3s já vem com o Traefik Ingress Controller embutido, que funciona como proxy reverso e controller de ingress. O Traefik está configurado para expor serviços diretamente usando o IP da VPS, eliminando a necessidade de um Nginx adicional.

### Como são gerenciados os certificados TLS?

O projeto utiliza cert-manager para gerenciar certificados TLS automaticamente através do Let's Encrypt. O arquivo `cluster-issuer.yaml` configura o emissor de certificados, e os ingresses utilizam a anotação `cert-manager.io/cluster-issuer: "letsencrypt-prod"` para solicitar certificados automaticamente.

### Como monitorar a saúde da aplicação?

A stack de observabilidade (Prometheus + Grafana) coleta métricas de todos os componentes do cluster, incluindo a aplicação. O Grafana vem pré-configurado com dashboards para monitorar o cluster K3s, além de métricas específicas da aplicação "Tell Me a Joke" através da rota `/metrics` exposta pelo backend.

### Como otimizar o uso de recursos em uma VPS com recursos limitados?

Para VPS com recursos limitados (2 cores, 8GB de RAM), o projeto já inclui várias otimizações:

1. **Parâmetro de otimização no Terraform**:
   ```sh
   terraform apply -var="optimize_resources=true"
   ```
   
2. **Arquivo de variáveis otimizado**:
   ```sh
   terraform apply -var-file="terraform-optimized.tfvars"
   ```
   
3. **Configurações aplicadas automaticamente**:
   - Recursos do Prometheus limitados a 200m CPU e 1Gi memória
   - Recursos do Grafana limitados a 100m CPU e 256Mi memória
   - AlertManager desativado para economizar recursos
   - Período de retenção reduzido para 5 dias
   - Limites de recursos configurados para frontend e backend

---

## Principais Recursos

### 1. Infraestrutura
- K3s como distribuição leve do Kubernetes
- Terraform para gerenciamento de recursos de terceiros
- Kustomize para recursos da aplicação

### 2. Aplicação
- Frontend responsivo com Tailwind CSS
- Backend Node.js com métricas Prometheus
- Persistência de dados com SQLite e PVC

### Arquitetura de Rede

A arquitetura de rede do projeto utiliza o Traefik Ingress Controller nativo do K3s:

1. **Traefik Ingress Controller**: 
   - Vem pré-instalado com o K3s
   - Funciona como ponto de entrada para todo o tráfego HTTP/HTTPS
   - Gerencia rotas para diferentes serviços

2. **Ingress para Aplicação**:
   - Definidos em `k8s/app/ingress.yaml` e `k8s/app/api-route.yaml`
   - Configura rotas para o frontend e API backend
   - Utiliza certificados TLS gerenciados pelo cert-manager

3. **Ingress para Observabilidade**:
   - Criados automaticamente pelo Terraform
   - Configura rotas para Grafana e Prometheus
   - Utiliza os mesmos certificados TLS e ClusterIssuer

4. **Certificados TLS**:
   - Gerenciados automaticamente pelo cert-manager
   - Utilizando o Let's Encrypt como provedor
   - Renovação automática antes da expiração

### 4. Observabilidade
- Prometheus para coleta de métricas
- Grafana para visualização
- Dashboards pré-configurados

---

## Conclusão

Este projeto demonstra a implementação de uma infraestrutura Kubernetes completa usando K3s, com foco em observabilidade e boas práticas DevOps. A aplicação "Tell Me a Joke" serve como exemplo funcional que utiliza todos os recursos implementados.

Os principais pontos de destaque incluem:

1. **Integração completa**: Todos os componentes trabalham juntos harmoniosamente - aplicação, ingress, certificados TLS e stack de observabilidade.

2. **Automação e IaC**: O uso do Terraform para provisionar componentes de infraestrutura e Kustomize para recursos da aplicação demonstra boas práticas de Infraestrutura como Código.

3. **Observabilidade**: O monitoramento com Prometheus e visualização com Grafana proporcionam visibilidade completa do estado do cluster e da aplicação.

4. **Otimização de recursos**: O projeto foi cuidadosamente otimizado para funcionar em VPS com recursos limitados, mantendo todas as funcionalidades.

O sistema está completamente funcional e acessível através dos domínios configurados, com toda a infraestrutura necessária implementada e monitorada.

---

## Referências
- [K3s](https://k3s.io/)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
- [kube-prometheus-stack Helm Chart](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack)
- [Traefik](https://traefik.io/)
- [cert-manager](https://cert-manager.io/)
- [Let's Encrypt](https://letsencrypt.org/)
