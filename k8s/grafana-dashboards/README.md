# Configuração dos Dashboards do Grafana com Kustomize

Esta pasta contém a configuração Kustomize para implantar os dashboards do Grafana no cluster Kubernetes.

## Pré-requisitos

- O ambiente de infraestrutura já deve estar implantado pelo Terraform
- O Grafana deve estar em execução no namespace `observability`
- kubectl configurado para acessar o cluster

## Como implantar os dashboards

Após a implantação da infraestrutura com o Terraform, aplique a configuração dos dashboards com o comando:

```bash
kubectl apply -k k8s/grafana-dashboards/
```

## Estrutura dos arquivos

- `kustomization.yaml`: Configura os ConfigMaps para os dashboards
- `namespace.yaml`: Define o namespace observability (caso não exista)
- `dashboard-provider.yaml`: Configura o provider de dashboards do Grafana

## Dashboards incluídos

- **K3s Cluster Dashboard**: Dashboard para monitoramento do cluster K3s
- **Alertmanager Status**: Dashboard para monitoramento do Alertmanager

## Como adicionar novos dashboards

1. Adicione o arquivo JSON do dashboard na pasta `terraform/grafana-dashboards/`
2. Atualize o `kustomization.yaml` para incluir o novo dashboard no ConfigMap apropriado
3. Se necessário, atualize o `dashboard-provider.yaml` para adicionar um novo provider
4. Aplique novamente a configuração com `kubectl apply -k k8s/grafana-dashboards/`
