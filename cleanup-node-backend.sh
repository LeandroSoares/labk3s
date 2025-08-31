#!/bin/bash
# Script para remover o backend Node.js

# Remover os arquivos do backend Node.js
echo "Removendo arquivos do backend Node.js..."
git rm -r src/backend/
git rm k8s/app/backend.yaml

# Remover o workflow do backend Node.js
echo "Removendo workflow do backend Node.js..."
git rm .github/workflows/build-backend.yml

echo "Concluído! Por favor, verifique as alterações e faça o commit."
echo "Use: git commit -m \"chore: remove Node.js backend after successful migration to Go\""
