# Dependency paths
$parameterScriptPath = "scripts/parameters.ps1"
$entraScriptPath = "scripts/deploy-entra.ps1"
$infraDeployScriptPath = "scripts/deploy-infra.ps1"
$apiDeployScriptPath = "scripts/deploy-app.ps1"

# Dependency checks
if (-not (Test-Path $parameterScriptPath)) {
    Write-Host "Project parameters script not found." -ForegroundColor Red
    exit
}
if (-not (Test-Path $entraScriptPath)) {
    Write-Host "Azure Entra setup script not found." -ForegroundColor Red
    exit
}
if (-not (Test-Path $infraDeployScriptPath)) {
    Write-Host "Azure IaaS deployment script not found." -ForegroundColor Red
    exit
}
if (-not (Test-Path $apiDeployScriptPath)) {
    Write-Host "API deployment script not found." -ForegroundColor Red
    exit
}

# PARAMETERS
Write-Host "Setting up project parameters..."
. .\$parameterScriptPath
Write-Host "Setting up project parameters... Done" -ForegroundColor Green

# ENTRA
Write-Host "Creating Azure Entra resources..."
. .\$entraScriptPath
Write-Host "Creating Azure Entra resources... Done" -ForegroundColor Green

# AZURE INFRA
Write-Host "Deploying infrastructure resources..."
. .\$infraDeployScriptPath
Write-Host "Deploying infrastructure resources... Done" -ForegroundColor Green

# CONTAINER APP
Write-Host "Deploying API to Azure Container App..."
. .\$apiDeployScriptPath
Write-Host "Deploying API to Azure Container App... Done" -ForegroundColor Green

Write-Host "Initialization complete." -ForegroundColor Green
