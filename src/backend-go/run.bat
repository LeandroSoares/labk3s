@echo off
REM Compilar e executar o backend em Go localmente

echo Compilando o backend em Go...
go build -o joke-api.exe .

echo Executando o backend...
set GO_ENV=development
set PORT=3000
set OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318/v1/traces
set OTEL_SERVICE_NAME=joke-api-go

joke-api.exe
