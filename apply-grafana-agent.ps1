#!/bin/pwsh
# Script para aplicar as mudanças no Terraform para o Grafana Agent

Write-Host "Iniciando a aplicação das mudanças no Grafana Agent..." -ForegroundColor Green

# 1. Verificar se existem pods do Grafana Agent em execução
Write-Host "1. Verificando pods do Grafana Agent existentes..." -ForegroundColor Yellow
kubectl get pods -n observability | Select-String agent

# 2. Remover a instalação atual do Grafana Agent
Write-Host "2. Removendo a instalação atual do Grafana Agent..." -ForegroundColor Yellow
kubectl delete deployment -n observability grafana-agent
kubectl delete configmap -n observability grafana-agent-config
kubectl delete service -n observability grafana-agent

# 2.1 Limpar completamente todos os recursos do Grafana Agent no namespace observability
Write-Host "2.1 Limpando completamente todos os recursos relacionados..." -ForegroundColor Yellow
kubectl delete --all deployments -n observability --selector=app=grafana-agent
kubectl delete --all services -n observability --selector=app=grafana-agent
kubectl delete --all configmaps -n observability --selector=app=grafana-agent

# 2.2 Verificar se ainda existem recursos com o nome grafana-agent
Write-Host "2.2 Verificando se ainda existem recursos com o nome grafana-agent..." -ForegroundColor Yellow
kubectl get all -n observability | Select-String grafana-agent

# 3. Inicializar o Terraform
Write-Host "3. Inicializando o Terraform..." -ForegroundColor Yellow
terraform -chdir=terraform init

# 4. Aplicar apenas o módulo do Grafana Agent
Write-Host "4. Aplicando o módulo do Grafana Agent..." -ForegroundColor Yellow
# Tentativa com --replace para forçar a substituição de recursos existentes
terraform -chdir=terraform apply -var "grafana_agent_enabled=true" -var "grafana_agent_version=0.44.2" -var "grafana_agent_log_level=info" --target=module.grafana_agent

# 4.1 Se falhar, tentar deletar mais recursos
if ($LASTEXITCODE -ne 0) {
    Write-Host "4.1 Primeira tentativa falhou. Tentando remover mais recursos do Kubernetes..." -ForegroundColor Red
    
    # Listar todos os recursos no namespace e filtrar por grafana-agent
    kubectl get all -n observability -o name | Select-String grafana-agent | ForEach-Object {
        $resource = $_.ToString().Trim()
        Write-Host "Removendo recurso: $resource" -ForegroundColor Yellow
        kubectl delete -n observability $resource --force --grace-period=0
    }
    
    # Tentar novamente com força
    Write-Host "4.2 Tentando aplicar novamente com --replace..." -ForegroundColor Yellow
    terraform -chdir=terraform apply -var "grafana_agent_enabled=true" -var "grafana_agent_version=0.44.2" -var "grafana_agent_log_level=info" --target=module.grafana_agent
}

# 5. Verificar se o Grafana Agent está em execução
Write-Host "5. Verificando se o Grafana Agent está em execução..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
kubectl get pods -n observability | Select-String agent

# 6. Verificar logs do Grafana Agent para confirmar que está funcionando
Write-Host "6. Verificando logs do Grafana Agent..." -ForegroundColor Yellow
$agentPod = kubectl get pods -n observability | Select-String agent
if ($agentPod) {
    $podName = ($agentPod -split '\s+')[0]
    kubectl logs -n observability $podName
}

# 7. Se tudo estiver funcionando, atualizar o frontend para usar o Grafana Agent novamente
Write-Host "7. Depois que o Grafana Agent estiver funcionando, execute o comando abaixo para atualizar o frontend:" -ForegroundColor Green
Write-Host "kubectl apply -f k8s/app/frontend-with-tracing.yaml" -ForegroundColor Cyan

Write-Host "Processo concluído!" -ForegroundColor Green
