#!/usr/bin/env pwsh
# Script para compilar e executar o backend-go no Windows

Write-Host "Compilando e executando o backend-go..." -ForegroundColor Green

# Adicionar o GCC ao PATH
$env:PATH += ";$HOME\scoop\apps\mingw\current\bin"

# Configurar variáveis de ambiente
$env:CGO_ENABLED = "1"
$env:DISABLE_METRICS = "true"
$env:OTEL_SERVICE_NAME = "joke-api-go-local"

# Criar pasta de dados se não existir
$dataDir = "./data"
if (-not (Test-Path $dataDir)) {
    Write-Host "Criando diretório de dados..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $dataDir | Out-Null
}

# Compilar o aplicativo
Write-Host "Compilando o aplicativo..." -ForegroundColor Cyan
go build -o joke-api.exe .

# Verificar se a compilação foi bem-sucedida
if (-not $?) {
    Write-Host "Erro na compilação." -ForegroundColor Red
    exit 1
}

# Executar o aplicativo
Write-Host "Executando o aplicativo..." -ForegroundColor Green
.\joke-api.exe
