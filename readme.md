# Projeto: Stack DevOps com K3s, Terraform e Observabilidade

## Objetivo
Demonstrar conhecimentos em DevOps, implementando um cluster Kubernetes (K3s) com stack de observabilidade (Prometheus + Grafana) utilizando Terraform para automação.

## Acesso
A aplicação está acessível em: [https://www.labk3s.online](https://www.labk3s.online)  
Dashboard Grafana: [https://grafana.labk3s.online](https://grafana.labk3s.online)
Dashboard Prometheus: [https://prometheus.labk3s.online](https://prometheus.labk3s.online)

---

## Arquitetura do Projeto Atualizada

```
VPS com K3s
  ├── Terraform (Infraestrutura como Código)
  │   ├── Módulo de Observabilidade
  │   │   ├── Prometheus
  │   │   └── Grafana
  │   └── Aplicação de Exemplo
  ├── Aplicação "Tell Me a Joke"
  │   ├── Frontend (Nginx + HTML/JS)
  │   ├── Backend (Node.js + Express)
  │   └── Banco de Dados (SQLite)
  └── CI/CD (GitHub Actions)
```

## Estrutura do Projeto

```
laboratoriok3s/
├── terraform/
│   ├── modules/
│   │   └── observability/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── k8s/
│   ├── app/
│   │   ├── namespace.yaml
│   │   ├── frontend.yaml
│   │   └── backend.yaml
│   ├── prometheus.yaml
│   └── grafana.yaml
├── src/
│   ├── frontend/
│   │   ├── index.html
│   │   ├── nginx.conf
│   │   └── Dockerfile
│   └── backend/
│       ├── server.js
│       ├── package.json
│       └── Dockerfile
├── .github/
│   └── workflows/
│       └── build-deploy.yml
└── readme.md
```

---

## Aplicação "Tell Me a Joke"

A aplicação de exemplo consiste em um site simples que exibe piadas aleatórias:

### Componentes
- **Frontend**: Interface web simples com HTML, CSS e JavaScript, servida pelo Nginx
- **Backend**: API REST em Node.js/Express que fornece piadas aleatórias
- **Banco de dados**: SQLite para armazenamento das piadas

### Implantação
Para implantar a aplicação:

```sh
# Criar o namespace
kubectl apply -f k8s/app/namespace.yaml

# Implantar backend e frontend
kubectl apply -f k8s/app/backend.yaml
kubectl apply -f k8s/app/frontend.yaml
```

### CI/CD com GitHub Actions

O projeto inclui um pipeline de CI/CD configurado com GitHub Actions que:

1. Constrói imagens Docker do frontend e backend
2. Publica as imagens no Docker Hub
3. Atualiza os manifestos Kubernetes com as novas versões
4. (Opcional) Implanta automaticamente no cluster K3s

Para configurar:
1. Configurado environment "production" no GitHub com as seguintes secrets:
   - `DOCKERHUB_USERNAME`: Usuário do Docker Hub
   - `DOCKERHUB_PASSWORD`: Senha do Docker Hub
   - `KUBECONFIG`: Conteúdo do arquivo kubeconfig para deploy automático

2. O pipeline agora está configurado para:
   - Construir e publicar imagens Docker para o registry
   - Atualizar manifestos Kubernetes com as novas versões de imagens
   - Implantar automaticamente no cluster K3s
   - Verificar o status da implantação

### Acesso à Aplicação

A aplicação está configurada para ser acessada através do domínio:
- **URL**: [http://www.labk3s.online](http://www.labk3s.online)

O frontend web permite visualizar e interagir com piadas aleatórias, enquanto o backend fornece uma API RESTful com endpoints para listar, adicionar e obter piadas aleatórias.

## Passo a Passo de Implementação

### 1. Pré-requisitos
- VPS Linux já provisionada e acessível
- K3s instalado e rodando
- Terraform instalado localmente
- Kubectl configurado para acessar o cluster K3s
- Helm instalado localmente (opcional se usar apenas Terraform)

### 2. Instalação via Terraform (Recomendado)

1. Configure seu ambiente:
   ```sh
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edite terraform.tfvars com suas configurações
   ```

2. Inicialize e aplique o Terraform:
   ```sh
   terraform init
   terraform plan
   terraform apply
   ```

3. Acesse os dashboards:
   ```sh
   # Os URLs serão exibidos nos outputs do Terraform
   terraform output
   ```

### 3. Instalação via Helm (Alternativa)

Se preferir usar Helm diretamente:

1. Adicione os repositórios Helm:
   ```sh
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo add grafana https://grafana.github.io/helm-charts
   helm repo update
   ```

2. Instale o Prometheus Stack:
   ```sh
   helm install prom-stack prometheus-community/kube-prometheus-stack --namespace observability --create-namespace
   ```

3. Verifique os serviços:
   ```sh
   kubectl get svc -n observability
   ```

### 4. Customização

#### Via Terraform
Edite o arquivo `terraform.tfvars` para personalizar:
- Versões dos componentes
- Configurações do Grafana
- Tipo de serviço (NodePort, ClusterIP, etc.)

#### Via Helm
Use um arquivo `values.yaml` customizado:
```sh
helm install prom-stack prometheus-community/kube-prometheus-stack -f values.yaml --namespace observability
```

---

## Scripts de Automação

O projeto inclui scripts shell para automatizar todo o processo de instalação e configuração:

### 1. Instalação do K3s
```sh
# Na sua VPS, como usuário root
chmod +x install-k3s.sh
./install-k3s.sh
```
Este script:
- Instala o K3s na versão especificada
- Configura o firewall para permitir o tráfego necessário
- Desativa swap (requisito do Kubernetes)
- Instala kubectl e Helm
- Configura acesso ao cluster

### 2. Configuração do Traefik Ingress
```sh
# Na sua VPS, após instalar o K3s
chmod +x setup-traefik.sh
./setup-traefik.sh
```
Este script:
- Configura o Traefik Ingress Controller do K3s
- Define redirecionamento automático HTTP para HTTPS
- Expõe o serviço Traefik usando o IP da VPS
- Não é necessário Nginx adicional para expor serviços

### 3. Configuração da Stack de Observabilidade
```sh
# Na sua VPS, após configurar o Traefik
chmod +x setup-observability.sh
./setup-observability.sh
```
Este script:
- Adiciona os repositórios Helm necessários
- Cria o namespace para observabilidade
- Instala o Prometheus e Grafana via Helm
- Configura acesso via NodePort
- Gera informações de acesso

### 4. Configuração de TLS com Let's Encrypt
```sh
# Na sua VPS, após configurar o Traefik
chmod +x setup-tls.sh
./setup-tls.sh www.labk3s.online seu-email@exemplo.com
```
Este script:
- Instala e configura o cert-manager
- Cria um ClusterIssuer para Let's Encrypt
- Configura emissão automática de certificados HTTPS
- Prepara o cluster para usar TLS com o domínio www.labk3s.online
- Gera informações de acesso

---

## Boas Práticas DevOps Implementadas

1. **Infraestrutura como Código (IaC)**
   - Uso do Terraform para provisionar e gerenciar recursos
   - Organização em módulos reutilizáveis

2. **Contêinerização**
   - Aplicações em containers no Kubernetes
   - Configuração declarativa com Dockerfiles otimizados

## Perguntas Frequentes

### É necessário um Nginx adicional para expor serviços do K3s?

Não. O K3s já vem com o Traefik Ingress Controller embutido, que funciona como proxy reverso e controller de ingress. O script `setup-traefik.sh` configura o Traefik para expor serviços diretamente usando o IP da VPS, eliminando a necessidade de um Nginx adicional.

### Como são gerenciados os certificados TLS?

O projeto utiliza cert-manager para gerenciar certificados TLS automaticamente através do Let's Encrypt. O script `setup-tls.sh` configura todo o processo, e os certificados são renovados automaticamente antes de expirarem.

### Como monitorar a saúde da aplicação?

A stack de observabilidade (Prometheus + Grafana) coleta métricas de todos os componentes do cluster, incluindo a aplicação. O Grafana vem pré-configurado com dashboards para monitorar o cluster K3s, além de dashboards específicos para a aplicação "Tell Me a Joke".

---

## Principais Recursos

1. **Infraestrutura**
   - K3s como distribuição leve do Kubernetes
   - Infraestrutura como código com Terraform
   - Módulos Terraform reutilizáveis

---

## Referências
- [K3s](https://k3s.io/)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
- [kube-prometheus-stack Helm Chart](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack)
