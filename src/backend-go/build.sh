#!/bin/sh
set -e

# Se go.sum não existir, execute go mod tidy para criá-lo
if [ ! -f go.sum ]; then
    echo "Arquivo go.sum não encontrado, gerando..."
    go mod tidy
fi

# Certifique-se de que todas as dependências estão atualizadas
go mod download

# Execute o comando original de compilação
CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -ldflags "-s -w" -o joke-api .
