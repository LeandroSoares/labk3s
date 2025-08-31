# Projeto: Stack DevOps com K3s, Terraform e Observabilidade

## Objetivo
Demonstrar conhecimentos em DevOps, implementando um cluster Kubernetes (K3s) com stack de observabilidade (Prometheus + Grafana) e certificados TLS utilizando Terraform para automação de componentes de terceiros e Kustomize para recursos da aplicação.

## Arquitetura

A aplicação é composta por:

- **Frontend**: Interface web simples feita com HTML, JavaScript e Tailwind CSS
- **Backend**: Implementação em Go com:
  - API RESTful para servir piadas
  - Banco de dados SQLite para persistência
  - Rastreamento com OpenTelemetry
  - Métricas com Prometheus
- **Observabilidade**:
  - Rastreamento com OpenTelemetry
  - Métricas com Prometheus
  - Dashboards no Grafana

## Executando Localmente

### Backend Go
```bash
# Windows
cd src/backend-go
.\run.bat

# Linux/macOS
cd src/backend-go
./run.sh
```

### Frontend
```bash
cd src/frontend
# Abra o arquivo index.html no navegador
```

## Documentação

- [Migração do Backend para Go](./docs/backend-go-migration.md)
- [Guia de Troubleshooting Frontend-Backend](./docs/troubleshooting-frontend-backend.md)
- [Configuração do Alertmanager](./docs/alertmanager-guide.md)
- [Configuração de Tracing](./docs/tracing-guide.md)
