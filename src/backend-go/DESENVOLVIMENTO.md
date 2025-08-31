# Guia de Desenvolvimento Local para Backend Go

## Pré-requisitos

Para desenvolver localmente, você precisa:

1. Go 1.21 ou superior
2. GCC (necessário para SQLite via CGO)
3. Docker (opcional, para construção de imagens)

## Configuração do Ambiente Windows

### Instalação do Go

Se você ainda não tem Go instalado:

```powershell
scoop install go
```

### Instalação do GCC (para SQLite)

```powershell
scoop install mingw
```

Certifique-se de que o GCC está no PATH:

```powershell
$env:PATH += ";$HOME\scoop\apps\mingw\current\bin"
```

## Executando o Aplicativo

### Opção 1: Execução Direta

```powershell
cd ~/projects/laboratoriok3s/src/backend-go
$env:CGO_ENABLED="1"
$env:DISABLE_METRICS="true"
go run .
```

### Opção 2: Usando o Script

```powershell
cd ~/projects/laboratoriok3s/src/backend-go
./run-local.ps1
```

### Opção 3: Usando Docker

```powershell
cd ~/projects/laboratoriok3s/src/backend-go
docker build -t backend-go-dev -f Dockerfile.dev .
docker run -p 3000:3000 backend-go-dev
```

## Resolução de Problemas

### Erro: "cgo: C compiler "gcc" not found"

Isso significa que o GCC não está instalado ou não está no PATH. Use a seguinte solução:

1. Instale o GCC: `scoop install mingw`
2. Adicione ao PATH: `$env:PATH += ";$HOME\scoop\apps\mingw\current\bin"`

### Erro na conexão com o Docker

Se você encontrar erros como "error during connect", certifique-se de que:

1. O Docker Desktop ou Rancher Desktop está instalado e em execução
2. Você tem permissão para usar o Docker

## Desenvolvimento

### Estrutura do Projeto

- `main.go` - Ponto de entrada do aplicativo
- `metrics.go` - Configuração do OpenTelemetry para métricas
- `Dockerfile` - Para construção de imagem de produção
- `Dockerfile.dev` - Para desenvolvimento e testes

### Variáveis de Ambiente

- `CGO_ENABLED=1` - Necessário para SQLite
- `DISABLE_METRICS=true` - Desativa a exportação de métricas em desenvolvimento
- `PORT=3000` - Porta do servidor (padrão: 3000)
- `OTEL_SERVICE_NAME` - Nome do serviço para telemetria

## Build para Produção

```powershell
cd ~/projects/laboratoriok3s/src/backend-go
docker build -t backend-go:latest .
```
