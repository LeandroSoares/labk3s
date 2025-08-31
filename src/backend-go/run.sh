#!/bin/bash

# Compilar e executar o backend em Go localmente
cd "$(dirname "$0")"

echo "Compilando o backend em Go..."
go build -o joke-api .

echo "Executando o backend..."
export GO_ENV=development
export PORT=3000
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318/v1/traces"
export OTEL_SERVICE_NAME="joke-api-go"

./joke-api
