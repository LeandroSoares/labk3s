# Script para configurar ambiente de desenvolvimento no Windows
Write-Host "Configurando ambiente de desenvolvimento para backend-go no Windows..." -ForegroundColor Green

# Verificar se o MinGW/GCC está instalado
$gccInstalled = $false
try {
    $gccVersion = & gcc --version
    Write-Host "GCC já instalado: $gccVersion" -ForegroundColor Green
    $gccInstalled = $true
} catch {
    Write-Host "GCC não encontrado. Vamos instalar..." -ForegroundColor Yellow
}

if (-not $gccInstalled) {
    # Verificar se o Chocolatey está instalado
    $chocoInstalled = $false
    try {
        $chocoVersion = & choco --version
        Write-Host "Chocolatey já instalado: $chocoVersion" -ForegroundColor Green
        $chocoInstalled = $true
    } catch {
        Write-Host "Chocolatey não encontrado. Tentando usar Scoop..." -ForegroundColor Yellow
    }
    
    # Verificar se o Scoop está instalado
    $scoopInstalled = $false
    try {
        $scoopVersion = & scoop --version
        Write-Host "Scoop já instalado" -ForegroundColor Green
        $scoopInstalled = $true
    } catch {
        Write-Host "Scoop não encontrado." -ForegroundColor Yellow
    }
    
    # Instalar GCC usando Chocolatey ou Scoop
    if ($chocoInstalled) {
        Write-Host "Instalando MinGW (GCC) via Chocolatey..." -ForegroundColor Cyan
        & choco install mingw -y
    } elseif ($scoopInstalled) {
        Write-Host "Instalando GCC via Scoop..." -ForegroundColor Cyan
        & scoop install gcc
    } else {
        Write-Host "Não foi possível instalar GCC. Por favor, instale manualmente o MinGW ou GCC." -ForegroundColor Red
        Write-Host "Você pode instalar o Chocolatey (https://chocolatey.org/) ou Scoop (https://scoop.sh/) para facilitar a instalação." -ForegroundColor Yellow
        exit 1
    }
}

# Configurar ambiente para desenvolvimento
Write-Host "Configurando variáveis de ambiente para desenvolvimento..." -ForegroundColor Cyan
$env:CGO_ENABLED = "1"
$env:DISABLE_METRICS = "true"

# Criar banco de dados SQLite se não existir
$dataDir = "./data"
if (-not (Test-Path $dataDir)) {
    Write-Host "Criando diretório de dados..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $dataDir | Out-Null
}

# Verificar dependências do Go
Write-Host "Verificando dependências do Go..." -ForegroundColor Cyan
& go mod tidy

Write-Host "Ambiente de desenvolvimento configurado com sucesso!" -ForegroundColor Green
Write-Host "Para executar o aplicativo, use: go run ." -ForegroundColor Cyan
Write-Host "OU" -ForegroundColor Yellow
Write-Host "Para compilar e executar: go build -o joke-api.exe && ./joke-api.exe" -ForegroundColor Cyan
