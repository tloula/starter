# Dependency paths
$mainBicepPath = "bicep/main.bicep"
$bicepParametersPath = "bicep/.bicepparam"

if (-not (az account show)) {
    Write-Host "Logging in to Azure..."
    az login
    Write-Host "Logging in to Azure... Done"
}

# Dependency checks
if (-not (Test-Path $mainBicepPath)) {
    Write-Host "Bicep template not found." -ForegroundColor Red
    exit
}
if (-not (Test-Path $bicepParametersPath)) {
    Write-Host "Bicep parameters file not found." -ForegroundColor Red
    exit
}

# Environment variables required in .bicepparam file
if (-not ($env:PROJECT_NAME)) {
    Write-Host "PROJECT_NAME environment variable not set. Exiting..." -ForegroundColor Red
    exit
}
if (-not ($env:CONTAINER_NAME)) {
    Write-Host "CONTAINER_NAME environment variable not set. Exiting..." -ForegroundColor Red
    exit
}
if (-not ($env:LOCATION)) {
    Write-Host "LOCATION environment variable not set. Exiting..." -ForegroundColor Red
    exit
}
if (-not ($env:AZURE_CLIENT_SECRET)) {
    # AZURE_CLIENT_SECRET is set in the entra-setup.ps1 script but not saved to the .env.dev file
    Write-Host "AZURE_CLIENT_SECRET environment variable not set. Exiting..." -ForegroundColor Red
    exit
}
if (-not ($env:TM_GROUP_OBJECT_ID)) {
    Write-Host "TM_GROUP_OBJECT_ID environment variable not set. Exiting..." -ForegroundColor Red
    exit
}

az deployment sub create --location $env:LOCATION --template-file $mainBicepPath --parameters $bicepParametersPath
