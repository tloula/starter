# Dependency paths
$parameterScriptPath = "scripts/parameters.ps1"
$entraScriptPath = "scripts/deploy-entra.ps1"
$iaasDeployScriptPath = "scripts/deploy-iaas.ps1"
$apiDeployScriptPath = "scripts/deploy-api.ps1"

# Dependency checks
if (-not (Test-Path $parameterScriptPath)) {
    Write-Host "Project parameters script not found." -ForegroundColor Red
    exit
}
if (-not (Test-Path $entraScriptPath)) {
    Write-Host "Azure Entra setup script not found." -ForegroundColor Red
    exit
}
if (-not (Test-Path $iaasDeployScriptPath)) {
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

# AZURE IaaS
Write-Host "Deploying infrastructure resources..."
. .\$iaasDeployScriptPath
Write-Host "Deploying infrastructure resources... Done" -ForegroundColor Green

# API
Write-Host "Deploying API to Azure Container App..."
. .\$apiDeployScriptPath
Write-Host "Deploying API to Azure Container App... Done" -ForegroundColor Green

Write-Host "Initialization complete." -ForegroundColor Green
