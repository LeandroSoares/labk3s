# Transição do Backend: Node.js para Go

Este documento descreve a migração do backend da aplicação de piadas de Node.js para Go.

## Motivações para a Migração

1. **Desempenho**: Go oferece melhor desempenho e uso mais eficiente de recursos
2. **Segurança**: Redução da superfície de ataque com menos dependências
3. **Tipagem Estática**: Segurança de tipos e detecção de erros em tempo de compilação
4. **Concorrência**: Melhor suporte para processamento concorrente com goroutines
5. **Ferramentas de Build**: Compilação para binários nativos sem dependências externas

## Mudanças de Arquitetura

### Estrutura do Projeto

Criamos uma nova pasta `backend-go` no diretório `src` com a implementação Go completa. A implementação original em Node.js foi completamente substituída.

### Endpoints da API

Todos os endpoints foram preservados:

- `GET /jokes/random` - Retorna uma piada aleatória
- `GET /jokes` - Retorna todas as piadas
- `GET /health` - Endpoint de verificação de saúde
- `GET /metrics` - Endpoint para métricas do Prometheus

### Persistência de Dados

Mantivemos a compatibilidade com o banco de dados SQLite existente, usando o mesmo esquema e estrutura de tabelas.

### Observabilidade

Implementamos:
- Rastreamento com OpenTelemetry
- Métricas do Prometheus
- Logs estruturados

## Novos Componentes

1. **Framework Web**: Utilizamos o [Gin](https://github.com/gin-gonic/gin) para roteamento HTTP
2. **Banco de Dados**: Usamos o driver [go-sqlite3](https://github.com/mattn/go-sqlite3) para SQLite
3. **Telemetria**: Implementamos o [OpenTelemetry Go SDK](https://github.com/open-telemetry/opentelemetry-go)
4. **Métricas**: Adicionamos suporte ao [Prometheus Go Client](https://github.com/prometheus/client_golang)

## Vantagens da Nova Implementação

- **Tamanho do Container**: Redução significativa (de ~200MB para ~20MB)
- **Utilização de Memória**: Menor footprint de memória
- **Tempo de Inicialização**: Inicialização mais rápida
- **Tempos de Resposta**: Latência reduzida para todas as operações
- **Segurança**: Menos dependências, menos vulnerabilidades

## Como Executar Localmente

### Usando os Scripts

No Windows:
```
cd src/backend-go
.\run.bat
```

No Linux/macOS:
```
cd src/backend-go
./run.sh
```

### Compilação Manual

```bash
cd src/backend-go
go build -o backend-go
./backend-go
```

## Implantação em Kubernetes

Atualizamos o arquivo `k8s/app/kustomization.yaml` para remover a configuração do backend Node.js e manter apenas a versão em Go.

O backend em Go está configurado no arquivo `k8s/app/backend-go.yaml` e pode ser implantado com:

```bash
kubectl apply -f k8s/app/backend-go.yaml
```

## CI/CD

Removemos o workflow do backend Node.js e mantivemos apenas o workflow para o backend Go em `.github/workflows/build-backend-go.yml` que:

1. Compila o código Go
2. Constrói a imagem Docker
3. Executa verificações de segurança com Trivy
4. Publica a imagem no Docker Hub

## Migração Concluída

A migração do backend Node.js para Go foi concluída com sucesso. O backend Node.js foi completamente removido e substituído pela implementação em Go.

## Próximos Passos

- Implementar testes unitários e de integração para o backend em Go
- Configurar monitoramento específico para comparar desempenho entre as versões
- Atualizar documentação e guias para desenvolvedores
